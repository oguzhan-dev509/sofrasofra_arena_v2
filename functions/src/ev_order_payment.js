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
exports.initializeEvOrderPayment = void 0;
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
exports.initializeEvOrderPayment = (0, https_1.onCall)({
    region: "europe-west1",
    timeoutSeconds: 60,
    secrets: [IYZI_API_KEY, IYZI_SECRET_KEY],
}, async (request) => {
    try {
        logger.info("🔥 initializeEvOrderPayment START", {
            auth: request.auth?.uid,
            data: request.data,
        });
        const uid = request.auth?.uid;
        if (!uid) {
            throw new https_1.HttpsError("unauthenticated", "Giriş gerekli.");
        }
        const orderId = (request.data?.orderId ?? "").toString().trim();
        if (!orderId) {
            throw new https_1.HttpsError("invalid-argument", "orderId gerekli.");
        }
        const ref = db.collection("orders").doc(orderId);
        const snap = await ref.get();
        if (!snap.exists) {
            throw new https_1.HttpsError("not-found", "Sipariş bulunamadı.");
        }
        const data = snap.data() ?? {};
        const ownerUserId = (data.userId ?? "").toString().trim();
        if (ownerUserId && ownerUserId !== uid) {
            throw new https_1.HttpsError("permission-denied", "Bu sipariş size ait değil.");
        }
        const paymentStatus = (data.paymentStatus ?? "")
            .toString()
            .trim()
            .toLowerCase();
        if (paymentStatus &&
            paymentStatus !== "pending" &&
            paymentStatus !== "awaiting_payment") {
            throw new https_1.HttpsError("failed-precondition", `Sipariş ödeme için uygun değil: ${paymentStatus}`);
        }
        const totalPriceRaw = data.genelToplam ?? data.totalPrice ?? 0;
        const totalPrice = typeof totalPriceRaw === "number"
            ? totalPriceRaw
            : Number(totalPriceRaw);
        if (!Number.isFinite(totalPrice) || totalPrice <= 0) {
            throw new https_1.HttpsError("failed-precondition", "Geçersiz toplam tutar.");
        }
        const apiKey = IYZI_API_KEY.value();
        const secretKey = IYZI_SECRET_KEY.value();
        if (!apiKey || !secretKey) {
            throw new https_1.HttpsError("internal", "Iyzico secret bilgileri eksik.");
        }
        const paidPrice = totalPrice.toFixed(2);
        const conversationId = `ev_order_${orderId}_${Date.now()}`;
        const ip = request.rawRequest.headers["x-forwarded-for"]
            ?.split(",")[0]
            ?.trim() ||
            request.rawRequest.ip ||
            "127.0.0.1";
        const safeAddress = (data.teslimatAdresi ?? data.adres ?? "Ev Lezzetleri Siparişi")
            .toString()
            .trim();
        const customerName = (data.musteriAd ?? "Mehmet").toString().trim() || "Mehmet";
        const phoneRaw = (data.musteriTelefon ?? "05555555555").toString().replace(/\D/g, "");
        const gsmNumber = phoneRaw.length >= 10 ? phoneRaw : "5555555555";
        const payload = {
            locale: "tr",
            conversationId,
            price: paidPrice,
            paidPrice,
            currency: "TRY",
            basketId: orderId,
            paymentGroup: "PRODUCT",
            callbackUrl: "https://europe-west1-sofrasofra-a3344.cloudfunctions.net/evIyzicoCallback",
            enabledInstallments: [1],
            buyer: {
                id: uid,
                name: customerName,
                surname: "Test",
                gsmNumber,
                email: "musteri@test.com",
                identityNumber: "11111111111",
                registrationAddress: safeAddress,
                ip,
                city: "Istanbul",
                country: "Turkey",
                zipCode: "34000",
            },
            shippingAddress: {
                contactName: `${customerName} Test`,
                city: "Istanbul",
                country: "Turkey",
                address: safeAddress,
                zipCode: "34000",
            },
            billingAddress: {
                contactName: `${customerName} Test`,
                city: "Istanbul",
                country: "Turkey",
                address: safeAddress,
                zipCode: "34000",
            },
            basketItems: [
                {
                    id: orderId,
                    name: (data.saticiAdi ?? data.dukkanAdi ?? "Ev Lezzetleri Siparişi")
                        .toString()
                        .trim(),
                    category1: "EvLezzetleri",
                    itemType: "PHYSICAL",
                    price: paidPrice,
                },
            ],
        };
        const uriPath = "/payment/iyzipos/checkoutform/initialize/auth/ecom";
        const requestBody = JSON.stringify(payload);
        const randomKey = crypto.randomBytes(8).toString("hex");
        const authorization = generateIyziAuthorization(apiKey, secretKey, uriPath, requestBody, randomKey);
        const iyzicoResponse = await axios_1.default.post(`${getIyziBaseUrl()}${uriPath}`, payload, {
            headers: {
                "Content-Type": "application/json",
                Authorization: authorization,
                "x-iyzi-rnd": randomKey,
            },
            timeout: 30000,
        });
        const responseData = iyzicoResponse.data ?? {};
        const iyzicoStatus = (responseData.status ?? "").toString().trim();
        const token = (responseData.token ?? "").toString().trim();
        const checkoutUrl = (responseData.paymentPageUrl ?? "").toString().trim();
        if (iyzicoStatus !== "success" || !checkoutUrl) {
            throw new https_1.HttpsError("internal", `Iyzico init hatası | code=${responseData.errorCode ?? "yok"} | message=${responseData.errorMessage ?? "yok"}`);
        }
        await ref.update({
            paymentStatus: "awaiting_payment",
            paymentProvider: "iyzico",
            paymentConversationId: conversationId,
            iyzicoToken: token,
            iyzicoStatus,
            iyzicoCheckoutUrl: checkoutUrl,
            paymentInitRawResponse: responseData,
            paymentExpireAt: null,
            paymentUpdatedAt: firestore_1.FieldValue.serverTimestamp(),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        return {
            success: true,
            status: iyzicoStatus,
            token,
            checkoutUrl,
        };
    }
    catch (error) {
        logger.error("❌ initializeEvOrderPayment ERROR", {
            message: error?.message,
            stack: error?.stack,
            response: error?.response?.data,
        });
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        throw new https_1.HttpsError("internal", error?.message ?? "initializeEvOrderPayment failed");
    }
});
