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

      logger.info("🔥 YENI VERIFY CALLBACK CALISTI", {
        body,
      });

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

      logger.info("[CALLBACK] token parsed", {
        token,
        callbackConversationId,
      });

      let reservationRef: FirebaseFirestore.DocumentReference | null = null;

      const tokenSnap = await db
        .collection("chef_table_reservations")
        .where("iyzicoToken", "==", token)
        .limit(1)
        .get();

     const firstTokenDoc = tokenSnap.docs[0];
if (firstTokenDoc) {
  reservationRef = firstTokenDoc.ref;
}

      if (!reservationRef && callbackConversationId) {
        const convSnap = await db
          .collection("chef_table_reservations")
          .where("paymentConversationId", "==", callbackConversationId)
          .limit(1)
          .get();

        const firstConvDoc = convSnap.docs[0];
if (firstConvDoc) {
  reservationRef = firstConvDoc.ref;
}
      }

      if (!reservationRef) {
        logger.error("[CALLBACK] reservation bulunamadı", {
          token,
          callbackConversationId,
        });
        res.status(404).send("Reservation not found");
        return;
      }

      const reservationSnap = await reservationRef.get();
      if (!reservationSnap.exists) {
        logger.error("[CALLBACK] reservation doc bulunamadı", {
          token,
          callbackConversationId,
        });
        res.status(404).send("Reservation doc not found");
        return;
      }

      const reservation = reservationSnap.data() ?? {};
      const storedConversationId = (
        reservation.paymentConversationId ?? ""
      ).toString().trim();

      logger.info("[CALLBACK] reservation found", {
        reservationId: reservationRef.id,
        storedConversationId,
        paymentStatus: reservation.paymentStatus ?? null,
      });

      const apiKey = IYZI_API_KEY.value();
      const secretKey = IYZI_SECRET_KEY.value();

      if (!apiKey || !secretKey) {
        logger.error("[CALLBACK] Iyzico secret bilgileri eksik");
        res.status(500).send("Iyzico config missing");
        return;
      }

      const uriPath = "/payment/iyzipos/checkoutform/auth/ecom/detail";
      const retrievePayload = {
        locale: "tr",
        conversationId: storedConversationId || callbackConversationId,
        token,
      };

      const requestBody = JSON.stringify(retrievePayload);
      const randomKey = crypto.randomBytes(8).toString("hex");

      const authorization = generateIyziAuthorization(
        apiKey,
        secretKey,
        uriPath,
        requestBody,
        randomKey
      );

      logger.info("[CALLBACK] retrieve start", {
        reservationId: reservationRef.id,
        token,
        conversationId: retrievePayload.conversationId,
      });

      const retrieveResponse = await axios.post(
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

      const result = retrieveResponse.data ?? {};

      logger.info("[CALLBACK] retrieve response", result);

      const resultStatus = (result.status ?? "")
        .toString()
        .trim()
        .toLowerCase();

      const paymentStatus = (result.paymentStatus ?? "")
        .toString()
        .trim()
        .toUpperCase();

      const resultConversationId = (result.conversationId ?? "")
        .toString()
        .trim();

      const resultToken = (result.token ?? "").toString().trim();

      const fraudStatusRaw = result.fraudStatus;
      const fraudStatus =
        typeof fraudStatusRaw === "number"
          ? fraudStatusRaw
          : Number(fraudStatusRaw);

      if (storedConversationId && resultConversationId !== storedConversationId) {
        logger.error("[CALLBACK] conversation mismatch", {
          storedConversationId,
          resultConversationId,
          token,
        });

        await reservationRef.set(
          {
            paymentError: "Conversation mismatch",
            iyzicoVerifyVersion: "v2",
            iyzicoRetrieveSummary: {
              status: resultStatus || null,
              paymentStatus: paymentStatus || null,
              conversationId: resultConversationId || null,
              token: resultToken || token || null,
              fraudStatus: Number.isNaN(fraudStatus) ? null : fraudStatus,
              paymentId: (result.paymentId ?? "").toString() || null,
              basketId: (result.basketId ?? "").toString() || null,
              paidPrice: result.paidPrice ?? null,
              price: result.price ?? null,
              currency: (result.currency ?? "").toString() || null,
            },
            paymentUpdatedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        res.status(400).send("Conversation mismatch");
        return;
      }

      if (resultToken && resultToken !== token) {
        logger.error("[CALLBACK] token mismatch", {
          callbackToken: token,
          resultToken,
        });

        await reservationRef.set(
          {
            paymentError: "Token mismatch",
            iyzicoVerifyVersion: "v2",
            iyzicoRetrieveSummary: {
              status: resultStatus || null,
              paymentStatus: paymentStatus || null,
              conversationId: resultConversationId || null,
              token: resultToken || token || null,
              fraudStatus: Number.isNaN(fraudStatus) ? null : fraudStatus,
              paymentId: (result.paymentId ?? "").toString() || null,
              basketId: (result.basketId ?? "").toString() || null,
              paidPrice: result.paidPrice ?? null,
              price: result.price ?? null,
              currency: (result.currency ?? "").toString() || null,
            },
            paymentUpdatedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        res.status(400).send("Token mismatch");
        return;
      }

      const retrieveSummary = {
        status: resultStatus || null,
        paymentStatus: paymentStatus || null,
        conversationId: resultConversationId || null,
        token: resultToken || token || null,
        fraudStatus: Number.isNaN(fraudStatus) ? null : fraudStatus,
        paymentId: (result.paymentId ?? "").toString() || null,
        basketId: (result.basketId ?? "").toString() || null,
        paidPrice: result.paidPrice ?? null,
        price: result.price ?? null,
        currency: (result.currency ?? "").toString() || null,
      };

      const isApprovedPayment =
        resultStatus === "success" &&
        paymentStatus === "SUCCESS" &&
        (Number.isNaN(fraudStatus) || fraudStatus === 1);

      if (!isApprovedPayment) {
        logger.error("[CALLBACK] verify failed", {
          reservationId: reservationRef.id,
          retrieveSummary,
        });

        await reservationRef.set(
          {
            paymentStatus: "failed",
            reservationFlowStatus: "payment_failed",
            paymentProvider: "iyzico",
            paymentError:
              (result.errorMessage ?? "").toString().trim() ||
              (result.errorCode ?? "").toString().trim() ||
              `Verify failed: status=${resultStatus}, paymentStatus=${paymentStatus}, fraudStatus=${Number.isNaN(fraudStatus) ? "NaN" : fraudStatus}`,
            iyzicoStatus: resultStatus,
            iyzicoVerifyVersion: "v2",
            iyzicoRetrieveSummary: retrieveSummary,
            paymentUpdatedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        res.status(400).send("Odeme dogrulanamadi");
        return;
      }

      logger.info("[CALLBACK] success update applying", {
        reservationId: reservationRef.id,
        retrieveSummary,
      });

      await reservationRef.set(
        {
          paymentStatus: "paid",
          reservationFlowStatus: "confirmed",
          paymentProvider: "iyzico",
          paidAt: FieldValue.serverTimestamp(),
          paymentUpdatedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
          paymentExpireAt: null,
          paymentError: null,
          iyzicoStatus: resultStatus,
          iyzicoVerifyVersion: "v2",
          iyzicoRetrieveSummary: retrieveSummary,
        },
        { merge: true }
      );

      logger.info("[CALLBACK] success update applied", {
        reservationId: reservationRef.id,
      });

      res.status(200).send("Odeme alindi. Rezervasyon kesinlestirildi.");
    } catch (e: any) {
      logger.error("[CALLBACK] error", e);
      logger.error("[CALLBACK] error response", e?.response?.data ?? null);
      res.status(500).send("error");
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

      if (!ownerUserId || ownerUserId !== uid) {
        throw new HttpsError(
          "permission-denied",
          "Bu rezervasyon için ödeme başlatamazsınız."
        );
      }

      if (status !== "approved") {
        throw new HttpsError(
          "failed-precondition",
          "Rezervasyon henüz ödeme için uygun değil."
        );
      }

      if (paymentStatus !== "awaiting_payment") {
        throw new HttpsError(
          "failed-precondition",
          "Bu rezervasyon ödeme beklemiyor."
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
  callbackUrl: "https://europe-west1-sofrasofra-a3344.cloudfunctions.net/iyzicoCallback",
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
