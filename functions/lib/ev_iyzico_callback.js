"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.evIyzicoCallback = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const params_1 = require("firebase-functions/params");
const logger = __importStar(require("firebase-functions/logger"));
const crypto = __importStar(require("crypto"));
const axios_1 = __importDefault(require("axios"));
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = (0, firestore_1.getFirestore)();
const IYZI_API_KEY = (0, params_1.defineSecret)("IYZI_API_KEY");
const IYZI_SECRET_KEY = (0, params_1.defineSecret)("IYZI_SECRET_KEY");
function getIyziBaseUrl() {
    return process.env.IYZI_BASE_URL || "https://sandbox-api.iyzipay.com";
}
function generateIyziAuthorization(apiKey, secretKey, uriPath, requestBody, randomKey) {
    const payloadToSign = randomKey + uriPath.trim() + requestBody;
    const signature = crypto
        .createHmac("sha256", secretKey.trim())
        .update(payloadToSign, "utf8")
        .digest("hex");
    const authorizationString = `apiKey:${apiKey.trim()}&randomKey:${randomKey}&signature:${signature}`;
    return `IYZWSv2 ${Buffer.from(authorizationString, "utf8").toString("base64")}`;
}
exports.evIyzicoCallback = (0, https_1.onRequest)({
    region: "europe-west1",
    timeoutSeconds: 60,
    secrets: [IYZI_API_KEY, IYZI_SECRET_KEY],
}, async (req, res) => {
    try {
        logger.info("🔥 evIyzicoCallback START", {
            method: req.method,
            body: req.body,
            query: req.query,
        });
        const token = (req.body?.token ?? req.query?.token ?? "")
            .toString()
            .trim();
        const callbackConversationId = (req.body?.conversationId ??
            req.query?.conversationId ??
            "")
            .toString()
            .trim();
        if (!token) {
            logger.error("❌ iyzico callback token yok", {
                body: req.body,
                query: req.query,
            });
            res.redirect(302, "https://sofrasofra.com/order-failed?reason=missing-token");
            return;
        }
        const snap = await db
            .collection("orders")
            .where("iyzicoToken", "==", token)
            .limit(1)
            .get();
        if (snap.empty) {
            logger.error("❌ Token ile Ev siparişi bulunamadı", {
                token,
                callbackConversationId,
            });
            res.redirect(302, "https://sofrasofra.com/order-failed?reason=order-not-found");
            return;
        }
        const orderDoc = snap.docs[0];
        const orderRef = orderDoc.ref;
        const orderData = orderDoc.data();
        const orderId = orderRef.id;
        const apiKey = IYZI_API_KEY.value();
        const secretKey = IYZI_SECRET_KEY.value();
        if (!apiKey || !secretKey) {
            logger.error("❌ iyzico secret bilgileri eksik");
            res.status(500).send("Iyzico secret bilgileri eksik");
            return;
        }
        const storedConversationId = (orderData.paymentConversationId ?? "")
            .toString()
            .trim();
        const retrievePayload = {
            locale: "tr",
            token,
        };
        if (storedConversationId) {
            retrievePayload.conversationId = storedConversationId;
        }
        const uriPath = "/payment/iyzipos/checkoutform/auth/ecom/detail";
        const requestBody = JSON.stringify(retrievePayload);
        const randomKey = crypto.randomBytes(8).toString("hex");
        const authorization = generateIyziAuthorization(apiKey, secretKey, uriPath, requestBody, randomKey);
        logger.info("🔎 iyzico retrieve request", {
            orderId,
            baseUrl: getIyziBaseUrl(),
            uriPath,
            hasStoredConversationId: !!storedConversationId,
        });
        const iyzicoRetrieveResponse = await axios_1.default.post(`${getIyziBaseUrl()}${uriPath}`, retrievePayload, {
            headers: {
                "Content-Type": "application/json",
                Authorization: authorization,
                "x-iyzi-rnd": randomKey,
            },
            timeout: 30000,
        });
        const retrieveData = iyzicoRetrieveResponse.data ?? {};
        const iyzicoStatus = (retrieveData.status ?? "")
            .toString()
            .trim()
            .toLowerCase();
        const iyzicoPaymentStatus = (retrieveData.paymentStatus ?? "")
            .toString()
            .trim()
            .toUpperCase();
        const fraudStatusRaw = retrieveData.fraudStatus;
        const fraudStatus = typeof fraudStatusRaw === "number"
            ? fraudStatusRaw
            : Number(fraudStatusRaw);
        const isPaymentSuccess = iyzicoStatus === "success" &&
            iyzicoPaymentStatus === "SUCCESS" &&
            (!Number.isFinite(fraudStatus) || fraudStatus === 1);
        const isFraudReview = iyzicoStatus === "success" &&
            iyzicoPaymentStatus === "SUCCESS" &&
            Number.isFinite(fraudStatus) &&
            fraudStatus === 0;
        let nextPaymentStatus = "failed";
        let nextOrderStatus = "payment_failed";
        let timelineStatus = "payment_failed";
        let timelineNote = "Ödeme iyzico retrieve sonucu başarısız.";
        if (isPaymentSuccess) {
            nextPaymentStatus = "paid";
            nextOrderStatus = "paid";
            timelineStatus = "paid";
            timelineNote = "Ödeme iyzico retrieve ile doğrulandı.";
        }
        else if (isFraudReview) {
            nextPaymentStatus = "payment_review";
            nextOrderStatus = "payment_review";
            timelineStatus = "payment_review";
            timelineNote = "Ödeme iyzico fraud kontrolünde incelemede.";
        }
        await orderRef.update({
            paymentStatus: nextPaymentStatus,
            status: nextOrderStatus,
            durum: nextOrderStatus,
            iyzicoCallbackToken: token,
            iyzicoCallbackConversationId: callbackConversationId,
            iyzicoCallbackRawBody: req.body ?? {},
            iyzicoCallbackRawQuery: req.query ?? {},
            iyzicoCallbackReceivedAt: firestore_1.FieldValue.serverTimestamp(),
            iyzicoRetrieveStatus: iyzicoStatus,
            iyzicoPaymentStatus,
            iyzicoFraudStatus: Number.isFinite(fraudStatus) ? fraudStatus : null,
            iyzicoPaymentId: retrieveData.paymentId ?? null,
            iyzicoBasketId: retrieveData.basketId ?? null,
            iyzicoPaidPrice: retrieveData.paidPrice ?? null,
            iyzicoPrice: retrieveData.price ?? null,
            iyzicoRetrieveRawResponse: retrieveData,
            paymentUpdatedAt: firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        await db.collection("orderTimeline").add({
            orderId,
            siparisNo: orderData.siparisNo ?? orderId,
            status: timelineStatus,
            actorType: "system",
            actorId: "iyzico",
            note: timelineNote,
            iyzicoStatus,
            iyzicoPaymentStatus,
            iyzicoFraudStatus: Number.isFinite(fraudStatus) ? fraudStatus : null,
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        logger.info("✅ Ev iyzico callback retrieve tamamlandı", {
            orderId,
            token,
            callbackConversationId,
            storedConversationId,
            iyzicoStatus,
            iyzicoPaymentStatus,
            fraudStatus,
            nextPaymentStatus,
        });
        if (isPaymentSuccess) {
            res.redirect(302, `https://sofrasofra.com/order-success?orderId=${encodeURIComponent(orderId)}`);
            return;
        }
        if (isFraudReview) {
            res.redirect(302, `https://sofrasofra.com/order-review?orderId=${encodeURIComponent(orderId)}`);
            return;
        }
        res.redirect(302, `https://sofrasofra.com/order-failed?orderId=${encodeURIComponent(orderId)}`);
    }
    catch (error) {
        logger.error("❌ evIyzicoCallback ERROR", {
            message: error?.message,
            stack: error?.stack,
            response: error?.response?.data,
        });
        res.redirect(302, "https://sofrasofra.com/order-failed?reason=callback-error");
    }
});
//# sourceMappingURL=ev_iyzico_callback.js.map