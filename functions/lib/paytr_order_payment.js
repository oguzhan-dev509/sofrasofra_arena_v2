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
exports.initializePaytrOrderPayment = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const axios_1 = __importDefault(require("axios"));
const crypto = __importStar(require("crypto"));
const config_1 = require("./config");
function asString(value) {
    return (value ?? "").toString().trim();
}
function asNumber(value) {
    if (typeof value === "number")
        return value;
    if (typeof value === "string") {
        return Number(value.replace(",", ".").trim()) || 0;
    }
    return 0;
}
function sanitizeMerchantOid(value) {
    return value.replace(/[^A-Za-z0-9_-]/g, "_").slice(0, 64);
}
exports.initializePaytrOrderPayment = (0, https_1.onCall)({
    region: "europe-west1",
    secrets: [
        config_1.PAYTR_MERCHANT_ID,
        config_1.PAYTR_MERCHANT_KEY,
        config_1.PAYTR_MERCHANT_SALT,
    ],
}, async (request) => {
    try {
        const db = (0, firestore_1.getFirestore)();
        const uid = request.auth?.uid;
        if (!uid) {
            throw new https_1.HttpsError("unauthenticated", "Oturum gerekli.");
        }
        const orderId = asString(request.data?.orderId);
        if (!orderId) {
            throw new https_1.HttpsError("invalid-argument", "orderId zorunlu.");
        }
        const orderRef = db.collection("orders").doc(orderId);
        const orderSnap = await orderRef.get();
        if (!orderSnap.exists) {
            throw new https_1.HttpsError("not-found", "Sipariş bulunamadı.");
        }
        const orderData = orderSnap.data() ?? {};
        const ownerUid = asString(orderData.userId ?? orderData.uid);
        if (ownerUid && ownerUid !== uid) {
            throw new https_1.HttpsError("permission-denied", "Bu sipariş için ödeme başlatılamaz.");
        }
        const paymentStatus = asString(orderData.paymentStatus);
        if (paymentStatus &&
            paymentStatus !== "pending" &&
            paymentStatus !== "awaiting_payment" &&
            paymentStatus !== "failed") {
            throw new https_1.HttpsError("failed-precondition", `Sipariş ödeme için uygun değil: ${paymentStatus}`);
        }
        const amountTl = asNumber(orderData.customerTotalPayment ??
            orderData.genelToplam ??
            orderData.totalPrice ??
            orderData.totalAmount);
        if (!Number.isFinite(amountTl) || amountTl <= 0) {
            throw new https_1.HttpsError("failed-precondition", "Geçersiz toplam tutar.");
        }
        const merchantId = config_1.PAYTR_MERCHANT_ID.value();
        const merchantKey = config_1.PAYTR_MERCHANT_KEY.value();
        const merchantSalt = config_1.PAYTR_MERCHANT_SALT.value();
        if (!merchantId || !merchantKey || !merchantSalt) {
            throw new https_1.HttpsError("failed-precondition", "PAYTR secret eksik.");
        }
        const merchantOid = sanitizeMerchantOid(`sf_${orderId}`);
        const paymentAmount = Math.round(amountTl * 100);
        const userEmail = asString(orderData.customerEmail ??
            orderData.email ??
            orderData.userEmail ??
            "musteri@sofrasofra.com");
        const userName = asString(orderData.customerName ??
            orderData.musteriAd ??
            orderData.buyerName ??
            "Sofrasofra Müşteri");
        const userPhone = asString(orderData.customerPhone ??
            orderData.musteriTelefon ??
            orderData.phone ??
            "05000000000");
        const userAddress = asString(orderData.address ??
            orderData.teslimatAdresi ??
            orderData.deliveryAddress ??
            "Sofrasofra");
        const userIp = asString(request.rawRequest.headers["x-forwarded-for"]).split(",")[0] || request.rawRequest.ip || "127.0.0.1";
        const basketTitle = asString(orderData.orderTitle ??
            orderData.dukkanAd ??
            orderData.saticiAdi ??
            "Sofrasofra Siparişi");
        const userBasket = Buffer.from(JSON.stringify([[basketTitle, amountTl.toFixed(2), 1]])).toString("base64");
        const okUrl = `${(0, config_1.getPaytrOkUrl)()}?orderId=${encodeURIComponent(orderId)}`;
        const failUrl = `${(0, config_1.getPaytrFailUrl)()}?orderId=${encodeURIComponent(orderId)}`;
        const callbackUrl = (0, config_1.getPaytrCallbackUrl)() ||
            "https://europe-west1-sofrasofra-a3344.cloudfunctions.net/paytrCallback";
        const noInstallment = "1";
        const maxInstallment = "0";
        const currency = "TL";
        const testMode = "1";
        const debugOn = "1";
        const timeoutLimit = "30";
        const lang = "tr";
        const tokenRaw = merchantId +
            userIp +
            merchantOid +
            userEmail +
            paymentAmount +
            userBasket +
            noInstallment +
            maxInstallment +
            currency +
            testMode +
            merchantSalt;
        const paytrToken = crypto
            .createHmac("sha256", merchantKey)
            .update(tokenRaw)
            .digest("base64");
        const payload = new URLSearchParams({
            merchant_id: merchantId,
            user_ip: userIp,
            merchant_oid: merchantOid,
            email: userEmail,
            payment_amount: paymentAmount.toString(),
            paytr_token: paytrToken,
            user_basket: userBasket,
            debug_on: debugOn,
            no_installment: noInstallment,
            max_installment: maxInstallment,
            user_name: userName,
            user_address: userAddress,
            user_phone: userPhone,
            merchant_ok_url: okUrl,
            merchant_fail_url: failUrl,
            callback_url: callbackUrl,
            timeout_limit: timeoutLimit,
            currency,
            test_mode: testMode,
            lang,
            iframe_v2: "1",
        });
        logger.info("🔥 initializePaytrOrderPayment START", {
            orderId,
            merchantOid,
            paymentAmount,
            paymentChannel: orderData.paymentChannel ?? null,
        });
        const response = await axios_1.default.post(`${(0, config_1.getPaytrBaseUrl)()}/odeme/api/get-token`, payload.toString(), {
            headers: {
                "Content-Type": "application/x-www-form-urlencoded",
            },
            timeout: 20000,
        });
        const responseData = response.data ?? {};
        const status = asString(responseData.status);
        const token = asString(responseData.token);
        if (status !== "success" || !token) {
            logger.error("❌ PAYTR get-token failed", {
                orderId,
                merchantOid,
                responseData,
            });
            throw new https_1.HttpsError("internal", `PAYTR token alınamadı: ${responseData.reason ?? status}`);
        }
        const iframeUrl = `${(0, config_1.getPaytrBaseUrl)()}/odeme/guvenli/${token}`;
        await orderRef.set({
            paymentProvider: "paytr",
            paymentStatus: "awaiting_payment",
            status: "awaiting_payment",
            durum: "awaiting_payment",
            paytrMerchantOid: merchantOid,
            paytrToken: token,
            paytrIframeUrl: iframeUrl,
            paytrInitRawResponse: responseData,
            paymentUpdatedAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        return {
            success: true,
            provider: "paytr",
            orderId,
            merchantOid,
            token,
            iframeUrl,
        };
    }
    catch (error) {
        logger.error("❌ initializePaytrOrderPayment ERROR", {
            message: error?.message,
            stack: error?.stack,
        });
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        throw new https_1.HttpsError("internal", error?.message ?? "initializePaytrOrderPayment failed");
    }
});
//# sourceMappingURL=paytr_order_payment.js.map