import { onRequest } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import * as crypto from "crypto";
import {
  PAYTR_MERCHANT_KEY,
  PAYTR_MERCHANT_SALT,
} from "./config";


function asString(value: unknown): string {
  return (value ?? "").toString().trim();
}

export const paytrCallback = onRequest(
  {
    region: "europe-west1",
    secrets: [PAYTR_MERCHANT_KEY, PAYTR_MERCHANT_SALT],
  },
  async (req, res) => {
    try {
      const db = getFirestore();
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

      const merchantKey = PAYTR_MERCHANT_KEY.value();
      const merchantSalt = PAYTR_MERCHANT_SALT.value();

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
        paytrCallbackReceivedAt: FieldValue.serverTimestamp(),
        paymentUpdatedAt: FieldValue.serverTimestamp(),
      };

      const batch = db.batch();

      batch.set(orderRef, updateData, { merge: true });

      const timelineRef = orderRef.collection("timeline").doc();
      batch.set(timelineRef, {
        status: timelineStatus,
        note: timelineNote,
        actorType: "system",
        actorId: "paytr",
        createdAt: FieldValue.serverTimestamp(),
      });

      const sellerOrdersSnap = await db
        .collection("sellerOrders")
        .where("orderId", "==", orderId)
        .get();

      sellerOrdersSnap.docs.forEach((sellerDoc) => {
        batch.set(
          sellerDoc.ref,
          {
            paymentProvider: "paytr",
            paymentStatus: nextPaymentStatus,
            status: nextOrderStatus,
            durum: nextOrderStatus,
            paytrStatus: status,
            paytrTotalAmount: totalAmount,
            paytrCallbackMerchantOid: merchantOid,
            paytrCallbackReceivedAt: FieldValue.serverTimestamp(),
            paymentUpdatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
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
    } catch (error: any) {
      logger.error("❌ paytrCallback ERROR", {
        message: error?.message,
        stack: error?.stack,
      });

      // Kritik: Hash doğrulanıp işlemde geçici DB hatası olursa PAYTR tekrar deneyebilsin.
      res.status(500).send("callback-error");
    }
  }
);

