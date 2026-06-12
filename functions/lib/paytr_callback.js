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
Object.defineProperty(exports, "__esModule", { value: true });
exports.paytrCallback = void 0;
const https_1 = require("firebase-functions/v2/https");
const firestore_1 = require("firebase-admin/firestore");
const logger = __importStar(require("firebase-functions/logger"));
const crypto = __importStar(require("crypto"));
const config_1 = require("./config");
const db = (0, firestore_1.getFirestore)();
function asString(value) {
    return (value ?? "").toString().trim();
}
exports.paytrCallback = (0, https_1.onRequest)({
    region: "europe-west1",
    secrets: [config_1.PAYTR_MERCHANT_KEY, config_1.PAYTR_MERCHANT_SALT],
}, async (req, res) => {
    try {
        if (req.method !== "POST") {
            res.status(405).send("Method Not Allowed");
            return;
        }
        const body = req.body ?? {};
        const merchantOid = asString(body.merchant_oid);
        const status = asString(body.status);
        const totalAmount = asString(body.total_amount);
        const receivedHash = asString(body.hash);
        logger.info("🔥 paytrCallback START", {
            merchantOid,
            status,
            totalAmount,
            hasHash: receivedHash.length > 0,
            body,
        });
        if (!merchantOid || !status || !totalAmount || !receivedHash) {
            logger.error("❌ PAYTR callback eksik alan", {
                merchantOid,
                status,
                totalAmount,
                hasHash: receivedHash.length > 0,
                body,
            });
            res.status(400).send("missing-fields");
            return;
        }
        const merchantKey = config_1.PAYTR_MERCHANT_KEY.value();
        const merchantSalt = config_1.PAYTR_MERCHANT_SALT.value();
        if (!merchantKey || !merchantSalt) {
            logger.error("❌ PAYTR secret eksik");
            res.status(500).send("secret-missing");
            return;
        }
        const tokenRaw = merchantOid + merchantSalt + status + totalAmount;
        const expectedHash = crypto
            .createHmac("sha256", merchantKey)
            .update(tokenRaw)
            .digest("base64");
        if (expectedHash !== receivedHash) {
            logger.error("❌ PAYTR callback hash geçersiz", {
                merchantOid,
                status,
                totalAmount,
            });
            res.status(400).send("bad-hash");
            return;
        }
        const orderSnap = await db
            .collection("orders")
            .where("paytrMerchantOid", "==", merchantOid)
            .limit(1)
            .get();
        const orderDoc = orderSnap.docs[0];
        if (!orderDoc) {
            logger.error("❌ PAYTR callback sipariş bulunamadı", {
                merchantOid,
                status,
            });
            // PAYTR tekrar tekrar denemesin diye hash doğruysa OK döneriz,
            // ama kaydı loglarda yakalarız.
            res.status(200).send("OK");
            return;
        }
        const orderId = orderDoc.id;
        const orderRef = orderDoc.ref;
        const isSuccess = status === "success";
        const nextPaymentStatus = isSuccess ? "paid" : "failed";
        const nextOrderStatus = isSuccess ? "paid" : "payment_failed";
        const timelineStatus = isSuccess ? "paid" : "payment_failed";
        const timelineNote = isSuccess
            ? "Ödeme PAYTR callback ile doğrulandı."
            : `PAYTR ödeme başarısız: ${asString(body.failed_reason_msg ?? body.failed_reason_code)}`;
        const updateData = {
            paymentProvider: "paytr",
            paymentStatus: nextPaymentStatus,
            status: nextOrderStatus,
            durum: nextOrderStatus,
            paytrStatus: status,
            paytrTotalAmount: totalAmount,
            paytrCallbackMerchantOid: merchantOid,
            paytrCallbackRawBody: body,
            paytrCallbackReceivedAt: firestore_1.FieldValue.serverTimestamp(),
            paymentUpdatedAt: firestore_1.FieldValue.serverTimestamp(),
        };
        const batch = db.batch();
        batch.set(orderRef, updateData, { merge: true });
        const timelineRef = orderRef.collection("timeline").doc();
        batch.set(timelineRef, {
            status: timelineStatus,
            note: timelineNote,
            actorType: "system",
            actorId: "paytr",
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        const sellerOrdersSnap = await db
            .collection("sellerOrders")
            .where("orderId", "==", orderId)
            .get();
        sellerOrdersSnap.docs.forEach((sellerDoc) => {
            batch.set(sellerDoc.ref, {
                paymentProvider: "paytr",
                paymentStatus: nextPaymentStatus,
                status: nextOrderStatus,
                durum: nextOrderStatus,
                paytrStatus: status,
                paytrTotalAmount: totalAmount,
                paytrCallbackMerchantOid: merchantOid,
                paytrCallbackReceivedAt: firestore_1.FieldValue.serverTimestamp(),
                paymentUpdatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
        });
        await batch.commit();
        logger.info("✅ PAYTR callback tamamlandı", {
            orderId,
            merchantOid,
            status,
            nextPaymentStatus,
            sellerOrderCount: sellerOrdersSnap.size,
        });
        res.status(200).send("OK");
    }
    catch (error) {
        logger.error("❌ paytrCallback ERROR", {
            message: error?.message,
            stack: error?.stack,
        });
        // Kritik: Hash doğrulanıp işlemde geçici DB hatası olursa PAYTR tekrar deneyebilsin.
        res.status(500).send("callback-error");
    }
});
//# sourceMappingURL=paytr_callback.js.map