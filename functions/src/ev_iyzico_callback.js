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
exports.evIyzicoCallback = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const logger = __importStar(require("firebase-functions/logger"));
if (!admin.apps.length) {
    admin.initializeApp();
}
const db = (0, firestore_1.getFirestore)();
exports.evIyzicoCallback = (0, https_1.onRequest)({
    region: "europe-west1",
    timeoutSeconds: 60,
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
        const conversationId = (req.body?.conversationId ??
            req.query?.conversationId ??
            "")
            .toString()
            .trim();
        if (!token) {
            logger.error("❌ token yok", { body: req.body, query: req.query });
            res.status(400).send("Token yok");
            return;
        }
        const snap = await db
            .collection("orders")
            .where("iyzicoToken", "==", token)
            .limit(1)
            .get();
        if (snap.empty) {
            logger.error("❌ Ev siparişi bulunamadı", { token, conversationId });
            res.status(404).send("Ev siparişi bulunamadı");
            return;
        }
        const orderDoc = snap.docs.first;
        const orderRef = orderDoc.ref;
        const orderData = orderDoc.data();
        await orderRef.update({
            paymentStatus: "paid",
            iyzicoCallbackToken: token,
            iyzicoCallbackConversationId: conversationId,
            iyzicoCallbackRawBody: req.body ?? {},
            iyzicoCallbackRawQuery: req.query ?? {},
            iyzicoCallbackReceivedAt: firestore_1.FieldValue.serverTimestamp(),
            status: "paid",
            durum: "paid",
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        await db.collection("orderTimeline").add({
            orderId: orderRef.id,
            siparisNo: orderData.siparisNo ?? orderRef.id,
            status: "paid",
            actorType: "system",
            actorId: "iyzico",
            note: "Ödeme iyzico callback ile alındı",
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        });
        logger.info("✅ Ev ödeme callback başarılı", {
            orderId: orderRef.id,
            token,
            conversationId,
        });
        res.status(200).send("Ev ödeme başarılı");
    }
    catch (error) {
        logger.error("❌ evIyzicoCallback ERROR", {
            message: error?.message,
            stack: error?.stack,
        });
        res.status(500).send("Ev iyzico callback hata");
    }
});
