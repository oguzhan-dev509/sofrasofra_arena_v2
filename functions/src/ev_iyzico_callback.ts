import * as admin from "firebase-admin";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = getFirestore();

export const evIyzicoCallback = onRequest(
  {
    region: "europe-west1",
    timeoutSeconds: 60,
  },
  async (req, res) => {
    try {
      logger.info("🔥 evIyzicoCallback START", {
        method: req.method,
        body: req.body,
        query: req.query,
      });

      const token = (req.body?.token ?? req.query?.token ?? "")
        .toString()
        .trim();

      const conversationId = (
        req.body?.conversationId ??
        req.query?.conversationId ??
        ""
      )
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

      const orderDoc = snap.docs[0];
      const orderRef = orderDoc.ref;
      const orderData = orderDoc.data();

      await orderRef.update({
        paymentStatus: "paid",
        iyzicoCallbackToken: token,
        iyzicoCallbackConversationId: conversationId,
        iyzicoCallbackRawBody: req.body ?? {},
        iyzicoCallbackRawQuery: req.query ?? {},
        iyzicoCallbackReceivedAt: FieldValue.serverTimestamp(),

        status: "paid",
        durum: "paid",

        updatedAt: FieldValue.serverTimestamp(),
      });

      await db.collection("orderTimeline").add({
        orderId: orderRef.id,
        siparisNo: orderData.siparisNo ?? orderRef.id,
        status: "paid",
        actorType: "system",
        actorId: "iyzico",
        note: "Ödeme iyzico callback ile alındı",
        createdAt: FieldValue.serverTimestamp(),
      });

      logger.info("✅ Ev ödeme callback başarılı", {
        orderId: orderRef.id,
        token,
        conversationId,
      });

      res.status(200).send("Ev ödeme başarılı");
    } catch (error: any) {
      logger.error("❌ evIyzicoCallback ERROR", {
        message: error?.message,
        stack: error?.stack,
      });

      res.status(500).send("Ev iyzico callback hata");
    }
  }
);