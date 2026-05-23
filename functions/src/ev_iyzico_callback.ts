import * as admin from "firebase-admin";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import * as crypto from "crypto";
import axios from "axios";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = getFirestore();

const IYZI_API_KEY = defineSecret("IYZI_API_KEY");
const IYZI_SECRET_KEY = defineSecret("IYZI_SECRET_KEY");

function getIyziBaseUrl(): string {
  return process.env.IYZI_BASE_URL || "https://sandbox-api.iyzipay.com";
}

function generateIyziAuthorization(
  apiKey: string,
  secretKey: string,
  uriPath: string,
  requestBody: string,
  randomKey: string
): string {
  const payloadToSign = randomKey + uriPath.trim() + requestBody;

  const signature = crypto
    .createHmac("sha256", secretKey.trim())
    .update(payloadToSign, "utf8")
    .digest("hex");

  const authorizationString =
    `apiKey:${apiKey.trim()}&randomKey:${randomKey}&signature:${signature}`;

  return `IYZWSv2 ${Buffer.from(authorizationString, "utf8").toString("base64")}`;
}

export const evIyzicoCallback = onRequest(
  {
    region: "europe-west1",
    timeoutSeconds: 60,
    secrets: [IYZI_API_KEY, IYZI_SECRET_KEY],
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

      const callbackConversationId = (
        req.body?.conversationId ??
        req.query?.conversationId ??
        ""
      )
        .toString()
        .trim();

      if (!token) {
        logger.error("❌ iyzico callback token yok", {
          body: req.body,
          query: req.query,
        });

        res.redirect(
          302,
          "https://sofrasofra.com/order-failed?reason=missing-token"
        );
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

        res.redirect(
          302,
          "https://sofrasofra.com/order-failed?reason=order-not-found"
        );
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

      const retrievePayload: {
        locale: string;
        conversationId?: string;
        token: string;
      } = {
        locale: "tr",
        token,
      };

      if (storedConversationId) {
        retrievePayload.conversationId = storedConversationId;
      }

      const uriPath = "/payment/iyzipos/checkoutform/auth/ecom/detail";
      const requestBody = JSON.stringify(retrievePayload);
      const randomKey = crypto.randomBytes(8).toString("hex");

      const authorization = generateIyziAuthorization(
        apiKey,
        secretKey,
        uriPath,
        requestBody,
        randomKey
      );

      logger.info("🔎 iyzico retrieve request", {
        orderId,
        baseUrl: getIyziBaseUrl(),
        uriPath,
        hasStoredConversationId: !!storedConversationId,
      });

      const iyzicoRetrieveResponse = await axios.post(
        `${getIyziBaseUrl()}${uriPath}`,
        retrievePayload,
        {
          headers: {
            "Content-Type": "application/json",
            Authorization: authorization,
            "x-iyzi-rnd": randomKey,
          },
          timeout: 30000,
        }
      );

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
      const fraudStatus =
        typeof fraudStatusRaw === "number"
          ? fraudStatusRaw
          : Number(fraudStatusRaw);

      const isPaymentSuccess =
        iyzicoStatus === "success" &&
        iyzicoPaymentStatus === "SUCCESS" &&
        (!Number.isFinite(fraudStatus) || fraudStatus === 1);

      const isFraudReview =
        iyzicoStatus === "success" &&
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
      } else if (isFraudReview) {
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
        iyzicoCallbackReceivedAt: FieldValue.serverTimestamp(),

        iyzicoRetrieveStatus: iyzicoStatus,
        iyzicoPaymentStatus,
        iyzicoFraudStatus: Number.isFinite(fraudStatus) ? fraudStatus : null,
        iyzicoPaymentId: retrieveData.paymentId ?? null,
        iyzicoBasketId: retrieveData.basketId ?? null,
        iyzicoPaidPrice: retrieveData.paidPrice ?? null,
        iyzicoPrice: retrieveData.price ?? null,
        iyzicoRetrieveRawResponse: retrieveData,

        paymentUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      const sellerOrdersSnap = await db
        .collection("sellerOrders")
        .where("orderId", "==", orderId)
        .get();

      if (!sellerOrdersSnap.empty) {
        const sellerOrderBatch = db.batch();

        sellerOrdersSnap.docs.forEach((doc) => {
          sellerOrderBatch.update(doc.ref, {
            paymentStatus: nextPaymentStatus,
            status: nextOrderStatus,
            durum: nextOrderStatus,

            iyzicoCallbackToken: token,
            iyzicoCallbackConversationId: callbackConversationId,
            iyzicoPaymentStatus,
            iyzicoFraudStatus: Number.isFinite(fraudStatus)
              ? fraudStatus
              : null,
            iyzicoPaymentId: retrieveData.paymentId ?? null,
            iyzicoBasketId: retrieveData.basketId ?? null,
            iyzicoPaidPrice: retrieveData.paidPrice ?? null,
            iyzicoPrice: retrieveData.price ?? null,

            paymentUpdatedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          });
        });

        await sellerOrderBatch.commit();
      }
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
        createdAt: FieldValue.serverTimestamp(),
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
        res.redirect(
          302,
          `https://sofrasofra.com/order-success?orderId=${encodeURIComponent(
            orderId
          )}`
        );
        return;
      }

      if (isFraudReview) {
        res.redirect(
          302,
          `https://sofrasofra.com/order-review?orderId=${encodeURIComponent(
            orderId
          )}`
        );
        return;
      }

      res.redirect(
        302,
        `https://sofrasofra.com/order-failed?orderId=${encodeURIComponent(
          orderId
        )}`
      );
    } catch (error: any) {
      logger.error("❌ evIyzicoCallback ERROR", {
        message: error?.message,
        stack: error?.stack,
        response: error?.response?.data,
      });

      res.redirect(
        302,
        "https://sofrasofra.com/order-failed?reason=callback-error"
      );
    }
  }
);