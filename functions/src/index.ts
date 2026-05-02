import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import axios from "axios";
import * as crypto from "crypto";
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";

import {
  IYZI_API_KEY,
  IYZI_SECRET_KEY,
  getIyziBaseUrl,
} from "./config";

initializeApp();

const db = getFirestore();

export const iyzicoCallback = onRequest(
  { region: "europe-west1", secrets: [IYZI_API_KEY, IYZI_SECRET_KEY] },
  async (req, res) => {
    try {
      const body = req.body ?? {};

      logger.info("🔥 YENI VERIFY CALLBACK CALISTI", { body });

      const token = (body.token ?? "").toString().trim();
      const callbackConversationId = (
        body.conversationId ??
        body.conversation_id ??
        ""
      )
        .toString()
        .trim();

      if (!token) {
        logger.error("[CALLBACK] token yok", { body });
        res.status(400).send("Token yok");
        return;
      }

      const apiKey = IYZI_API_KEY.value();
      const secretKey = IYZI_SECRET_KEY.value();

      logger.info("[CALLBACK] token parsed", {
        token,
        callbackConversationId,
      });

      let reservationRef: FirebaseFirestore.DocumentReference | null = null;
      let reservationData: FirebaseFirestore.DocumentData | null = null;

      const tokenSnap = await db
        .collection("chef_table_reservations")
        .where("iyzicoToken", "==", token)
        .limit(1)
        .get();

      const firstTokenDoc = tokenSnap.docs[0];
      if (firstTokenDoc) {
        reservationRef = firstTokenDoc.ref;
        reservationData = firstTokenDoc.data();
      }

      if (!reservationRef || !reservationData) {
        logger.error("[CALLBACK] token ile rezervasyon bulunamadı", { token });
        res.status(404).send("Rezervasyon bulunamadı");
        return;
      }

      const detailPayload = {
        locale: "tr",
        conversationId:
          callbackConversationId ||
          (reservationData.paymentConversationId ?? "").toString(),
        token,
      };

      const uriPath =
        "/payment/iyzipos/checkoutform/auth/ecom/detail";
      const requestBody = JSON.stringify(detailPayload);
      const randomKey = crypto.randomBytes(8).toString("hex");

      const authorization = generateIyziAuthorization(
        apiKey,
        secretKey,
        uriPath,
        requestBody,
        randomKey
      );

      logger.info("[CALLBACK] verify request", {
        baseUrl: getIyziBaseUrl(),
        uriPath,
        token,
        conversationId: detailPayload.conversationId,
      });

      const verifyResponse = await axios.post(
        `${getIyziBaseUrl()}${uriPath}`,
        detailPayload,
        {
          headers: {
            "Content-Type": "application/json",
            Authorization: authorization,
            "x-iyzi-rnd": randomKey,
          },
          timeout: 30000,
        }
      );

      const verifyData = verifyResponse.data ?? {};

logger.info("[CALLBACK] verify response", verifyData);

const status = (verifyData.status ?? "").toString().trim().toLowerCase();
const paymentStatus = (verifyData.paymentStatus ?? "")
  .toString()
  .trim()
  .toUpperCase();

logger.info("🔥 FINAL VERIFY CHECK", {
  status,
  paymentStatus,
  raw: verifyData,
});
      const isPaid =
  status === "success" &&
  (
    paymentStatus === "SUCCESS" ||
    paymentStatus === "SUCCESSFUL" ||
    verifyData?.paymentStatus === undefined
  );
     if (isPaid) {
  await reservationRef.update({
    status: "completed",
    paymentStatus: "paid",
    reservationFlowStatus: "completed",
    iyzicoStatus: "success",
    iyzicoCallbackRawBody: body,
    iyzicoVerifyRawResponse: verifyData,
    iyzicoVerifiedAt: FieldValue.serverTimestamp(),
    paidAt: FieldValue.serverTimestamp(),
    paymentExpireAt: null,
    paymentUpdatedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  res
    .status(200)
    .send(
      "<html><body><h2>Ödeme doğrulandı</h2><p>Rezervasyonunuz kesinleşti.</p></body></html>"
    );
  return;
}

   await reservationRef.update({
  paymentStatus: "failed",
  reservationFlowStatus: "awaiting_payment",
  iyzicoStatus: "failed",
  iyzicoCallbackRawBody: body,
  iyzicoVerifyRawResponse: verifyData,
  iyzicoVerifiedAt: FieldValue.serverTimestamp(),
  paymentUpdatedAt: FieldValue.serverTimestamp(),
  updatedAt: FieldValue.serverTimestamp(),
});
      res
        .status(200)
        .send(
          "<html><body><h2>Ödeme doğrulanamadı</h2><p>İşlem tamamlanmadı veya doğrulama başarısız oldu.</p></body></html>"
        );
    } catch (error: any) {
      logger.error("❌ iyzicoCallback ERROR", {
        message: error?.message,
        stack: error?.stack,
        responseData: error?.response?.data,
      });

      res
        .status(500)
        .send(
          "<html><body><h2>Ödeme doğrulanamadı</h2><p>Sistem hatası oluştu.</p></body></html>"
        );
    }
  }
);
export const notifySellerOnNewOrder = onDocumentCreated(
  "siparisler/{siparisId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const order = snap.data();
    const siparisId = event.params.siparisId;

    if (order?.notification?.sellerNotified === true) {
      return;
    }

    const sellerId = (order.saticiId ?? "").toString().trim();
    if (!sellerId) {
      console.log("saticiId yok, bildirim atlanıyor.");
      return;
    }

    const sellerDoc = await db.collection("users").doc(sellerId).get();
    if (!sellerDoc.exists) {
      console.log("Satıcı bulunamadı:", sellerId);
      return;
    }

    const tokens = (sellerDoc.data()?.fcmTokens ?? []) as string[];
    if (tokens.length === 0) {
      console.log("Satıcı token yok:", sellerId);
      return;
    }

    const title = "Yeni sipariş geldi";
    const body = `${order.musteriAd ?? "Bir müşteri"} yeni sipariş oluşturdu.`;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title,
        body,
      },
      data: {
        type: "new_order",
        siparisId,
        musteriId: (order.musteriId ?? "").toString(),
        saticiId: sellerId,
      },
    });

    const invalidTokens: string[] = [];
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code ?? "";
        if (
          code.includes("registration-token-not-registered") ||
          code.includes("invalid-registration-token")
        ) {
        if (tokens[i]) invalidTokens.push(tokens[i]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await db.collection("users").doc(sellerId).update({
        fcmTokens: FieldValue.arrayRemove(...invalidTokens),
      });
    }

    await snap.ref.set(
      {
        notification: {
          sellerNotified: true,
          sellerNotifiedAt: FieldValue.serverTimestamp(),
        },
      },
      { merge: true }
    );
  }
);

export const notifyCustomerWhenCourierAssigned = onDocumentUpdated(
  "siparisler/{siparisId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const siparisId = event.params.siparisId;

    const beforeCourierId = (before.assignedCourierId ?? "").toString().trim();
    const afterCourierId = (after.assignedCourierId ?? "").toString().trim();

    const alreadyNotified =
      after?.notification?.customerCourierAssignedNotified === true;

    if (alreadyNotified) return;

    const hadCourierBefore = beforeCourierId.length > 0;
    const hasCourierNow = afterCourierId.length > 0;

    if (hadCourierBefore || !hasCourierNow) {
      return;
    }

    const customerId = (after.musteriId ?? "").toString().trim();
    if (!customerId) {
      console.log("musteriId yok, bildirim atlanıyor.");
      return;
    }

    const customerDoc = await db.collection("users").doc(customerId).get();
    if (!customerDoc.exists) {
      console.log("Müşteri bulunamadı:", customerId);
      return;
    }

    const courierDoc = await db.collection("couriers").doc(afterCourierId).get();
    const courierName = courierDoc.exists
      ? (courierDoc.data()?.adSoyad ?? "Kuryeniz").toString()
      : "Kuryeniz";

    const tokens = (customerDoc.data()?.fcmTokens ?? []) as string[];
    if (tokens.length === 0) {
      console.log("Müşteri token yok:", customerId);
      return;
    }

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Kurye atandı",
        body: `${courierName} siparişinizi teslim almak üzere atandı.`,
      },
      data: {
        type: "courier_assigned",
        siparisId,
        courierId: afterCourierId,
        musteriId: customerId,
      },
    });

    const invalidTokens: string[] = [];
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code ?? "";
        if (
          code.includes("registration-token-not-registered") ||
          code.includes("invalid-registration-token")
        ) {
         if (tokens[i]) invalidTokens.push(tokens[i]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await db.collection("users").doc(customerId).update({
        fcmTokens: FieldValue.arrayRemove(...invalidTokens),
      });
    }

    await event.data!.after.ref.set(
      {
        notification: {
          customerCourierAssignedNotified: true,
          customerCourierAssignedNotifiedAt: FieldValue.serverTimestamp(),
        },
      },
      { merge: true }
    );
  }
);

function generateIyziAuthorization(
  apiKey: string,
  secretKey: string,
  uriPath: string,
  requestBody: string,
  randomKey: string
): string {
  const cleanApiKey = apiKey.trim();
  const cleanSecretKey = secretKey.trim();
  const cleanUriPath = uriPath.trim();

  const payloadToSign = randomKey + cleanUriPath + requestBody;

  const signature = crypto
    .createHmac("sha256", cleanSecretKey)
    .update(payloadToSign, "utf8")
    .digest("hex");

  const authorizationString =
    `apiKey:${cleanApiKey}&randomKey:${randomKey}&signature:${signature}`;

  const encodedAuthorization = Buffer.from(
    authorizationString,
    "utf8"
  ).toString("base64");

  return `IYZWSv2 ${encodedAuthorization}`;
}

export const initializeChefTablePayment = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 60,
    secrets: [IYZI_API_KEY, IYZI_SECRET_KEY],
  },
  async (request) => {
    try {
      console.log("🔥 initializeChefTablePayment START");
      console.log("request.auth:", request.auth);
      console.log("request.data:", request.data);

      const uid = request.auth?.uid;
      if (!uid) {
        throw new HttpsError("unauthenticated", "Giriş gerekli.");
      }

      const reservationId = (request.data?.reservationId ?? "")
        .toString()
        .trim();

      if (!reservationId) {
        throw new HttpsError("invalid-argument", "reservationId gerekli.");
      }

      const ref = db.collection("chef_table_reservations").doc(reservationId);
      const snap = await ref.get();

      if (!snap.exists) {
        throw new HttpsError("not-found", "Rezervasyon bulunamadı.");
      }

      const data = snap.data() ?? {};

      const ownerUserId = (data.userId ?? "").toString().trim();
      const status = (data.status ?? "").toString().trim().toLowerCase();
      const paymentStatus = (data.paymentStatus ?? "")
        .toString()
        .trim()
        .toLowerCase();

      const totalPriceRaw = data.totalPrice ?? 0;
      const totalPrice =
        typeof totalPriceRaw === "number"
          ? totalPriceRaw
          : Number(totalPriceRaw);

    if (!ownerUserId) {
  throw new HttpsError(
    "failed-precondition",
    "Rezervasyonda kullanıcı bilgisi eksik."
  );
}

console.log("PAYMENT DEBUG owner check bypass active");

     if (status !== "approved") {
  throw new HttpsError(
    "failed-precondition",
    "TEST-STATUS-BLOCK"
  );
}

if (paymentStatus !== "awaiting_payment") {
  throw new HttpsError(
    "failed-precondition",
    "TEST-PAYMENTSTATUS-BLOCK"
  );
}
      if (!Number.isFinite(totalPrice) || totalPrice <= 0) {
        throw new HttpsError(
          "failed-precondition",
          "Geçersiz toplam tutar."
        );
      }

      const apiKey = IYZI_API_KEY.value();
      const secretKey = IYZI_SECRET_KEY.value();

      if (!apiKey || !secretKey) {
        throw new HttpsError("internal", "Iyzico secret bilgileri eksik.");
      }

      const paidPrice = totalPrice.toFixed(2);
      const conversationId = `chef_table_${reservationId}_${Date.now()}`;

      const safeAddress =
        (data.note ?? data.address ?? "").toString().trim() ||
        "Şef Masası Rezervasyonu";

      const ip =
        (request.rawRequest.headers["x-forwarded-for"] as string | undefined)
          ?.split(",")[0]
          ?.trim() ||
        request.rawRequest.ip ||
        "127.0.0.1";

      const payload: any = {
        locale: "tr",
        conversationId,
        price: paidPrice,
        paidPrice,
        currency: "TRY",
        basketId: reservationId,
        paymentGroup: "PRODUCT",
        callbackUrl: "https://iyzicocallback-huhcn5kuka-ew.a.run.app",
        enabledInstallments: [1],
        buyer: {
          id: uid,
          name: "Mehmet",
          surname: "Test",
          gsmNumber: "5555555555",
          email: "musteri@test.com",
          identityNumber: "11111111111",
          registrationAddress: "İstanbul",
          ip,
          city: "Istanbul",
          country: "Turkey",
          zipCode: "34000",
        },
        shippingAddress: {
          contactName: "Mehmet Test",
          city: "Istanbul",
          country: "Turkey",
          address: safeAddress,
          zipCode: "34000",
        },
        billingAddress: {
          contactName: "Mehmet Test",
          city: "Istanbul",
          country: "Turkey",
          address: safeAddress,
          zipCode: "34000",
        },
        basketItems: [
          {
            id: reservationId,
            name: (data.tableTitle ?? "Şef Masası Rezervasyonu")
              .toString()
              .trim(),
            category1: "ChefTable",
            itemType: "PHYSICAL",
            price: paidPrice,
          },
        ],
      };

      console.log("DEBUG PAYLOAD:", JSON.stringify(payload, null, 2));

      const uriPath =
  "/payment/iyzipos/checkoutform/initialize/auth/ecom";
const requestBody = JSON.stringify(payload);
const randomKey = crypto.randomBytes(8).toString("hex");

console.log("IYZI FINAL CHECK", {
  baseUrl: getIyziBaseUrl(),
  fullUrl: `${getIyziBaseUrl()}${uriPath}`,
  apiKeyPrefix: apiKey.slice(0, 8),
  secretKeyPrefix: secretKey.slice(0, 6),
});

const authorization = generateIyziAuthorization(
  apiKey,
  secretKey,
  uriPath,
  requestBody,
  randomKey
);

const iyzicoResponse = await axios.post(
  `${getIyziBaseUrl()}${uriPath}`,
  payload,
  {
    headers: {
      "Content-Type": "application/json",
      Authorization: authorization,
      "x-iyzi-rnd": randomKey,
    },
    timeout: 30000,
  }
);

      console.log(
        "iyzico response:",
        JSON.stringify(iyzicoResponse.data, null, 2)
      );

      const responseData = iyzicoResponse.data ?? {};
      const iyzicoStatus = (responseData.status ?? "").toString().trim();
      const token = (responseData.token ?? "").toString().trim();
      const checkoutUrl = (responseData.paymentPageUrl ?? "")
        .toString()
        .trim();

      if (iyzicoStatus !== "success" || !checkoutUrl) {
        throw new HttpsError(
          "internal",
          `Iyzico init hatası | code=${responseData.errorCode ?? "yok"} | message=${responseData.errorMessage ?? "yok"} | email=${payload.buyer.email} | gsm=${payload.buyer.gsmNumber} | callbackUrl=${payload.callbackUrl}`
        );
      }

      await ref.update({
        paymentConversationId: conversationId,
        iyzicoToken: token,
        iyzicoStatus,
        iyzicoCheckoutUrl: checkoutUrl,
        paymentInitRawResponse: responseData,
        paymentExpireAt: null,
        paymentUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        status: iyzicoStatus,
        token,
        checkoutUrl,
      };
    } catch (error: any) {
      console.error("❌ initializeChefTablePayment ERROR:", error);
      console.error("❌ error.message:", error?.message);
      console.error("❌ error.stack:", error?.stack);
      console.error("❌ error.response?.data:", error?.response?.data);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error?.message ?? "initializeChefTablePayment failed"
      );
    }
  }
);
export { initializeEvOrderPayment } from "./ev_order_payment";
export { evIyzicoCallback } from "./ev_iyzico_callback";
