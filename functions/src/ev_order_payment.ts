import * as admin from "firebase-admin";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
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

export const initializeEvOrderPayment = onCall(
  {
    region: "europe-west1",
    timeoutSeconds: 60,
    secrets: [IYZI_API_KEY, IYZI_SECRET_KEY],
  },
  async (request) => {
    try {
      logger.info("🔥 initializeEvOrderPayment START", {
        auth: request.auth?.uid,
        data: request.data,
      });

      const uid = request.auth?.uid;
      if (!uid) {
        throw new HttpsError("unauthenticated", "Giriş gerekli.");
      }

      const orderId = (request.data?.orderId ?? "").toString().trim();
      if (!orderId) {
        throw new HttpsError("invalid-argument", "orderId gerekli.");
      }

      const ref = db.collection("orders").doc(orderId);
      const snap = await ref.get();

      if (!snap.exists) {
        throw new HttpsError("not-found", "Sipariş bulunamadı.");
      }

      const data = snap.data() ?? {};

      const ownerUserId = (data.userId ?? "").toString().trim();
      if (ownerUserId && ownerUserId !== uid) {
        throw new HttpsError("permission-denied", "Bu sipariş size ait değil.");
      }

      const paymentStatus = (data.paymentStatus ?? "")
        .toString()
        .trim()
        .toLowerCase();

      if (
        paymentStatus &&
        paymentStatus !== "pending" &&
        paymentStatus !== "awaiting_payment"
      ) {
        throw new HttpsError(
          "failed-precondition",
          `Sipariş ödeme için uygun değil: ${paymentStatus}`
        );
      }

      const totalPriceRaw = data.genelToplam ?? data.totalPrice ?? 0;
      const totalPrice =
        typeof totalPriceRaw === "number"
          ? totalPriceRaw
          : Number(totalPriceRaw);

      if (!Number.isFinite(totalPrice) || totalPrice <= 0) {
        throw new HttpsError("failed-precondition", "Geçersiz toplam tutar.");
      }

      const apiKey = IYZI_API_KEY.value();
      const secretKey = IYZI_SECRET_KEY.value();

      if (!apiKey || !secretKey) {
        throw new HttpsError("internal", "Iyzico secret bilgileri eksik.");
      }

      const paidPrice = totalPrice.toFixed(2);
      const conversationId = `ev_order_${orderId}_${Date.now()}`;

      const ip =
        (request.rawRequest.headers["x-forwarded-for"] as string | undefined)
          ?.split(",")[0]
          ?.trim() ||
        request.rawRequest.ip ||
        "127.0.0.1";

      const safeAddress =
        (data.teslimatAdresi ?? data.adres ?? "Ev Lezzetleri Siparişi")
          .toString()
          .trim();

      const customerName =
        (data.musteriAd ?? "Mehmet").toString().trim() || "Mehmet";

      const phoneRaw =
        (data.musteriTelefon ?? "05555555555").toString().replace(/\D/g, "");

      const gsmNumber = phoneRaw.length >= 10 ? phoneRaw : "5555555555";

      const payload: any = {
        locale: "tr",
        conversationId,
        price: paidPrice,
        paidPrice,
        currency: "TRY",
        basketId: orderId,
        paymentGroup: "PRODUCT",
        callbackUrl: "https://eviyzicocallback-huhcn5kuka-ew.a.run.app",
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

      const responseData = iyzicoResponse.data ?? {};
      const iyzicoStatus = (responseData.status ?? "").toString().trim();
      const token = (responseData.token ?? "").toString().trim();
      const checkoutUrl = (responseData.paymentPageUrl ?? "").toString().trim();

      if (iyzicoStatus !== "success" || !checkoutUrl) {
        throw new HttpsError(
          "internal",
          `Iyzico init hatası | code=${responseData.errorCode ?? "yok"} | message=${responseData.errorMessage ?? "yok"}`
        );
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
      logger.error("❌ initializeEvOrderPayment ERROR", {
        message: error?.message,
        stack: error?.stack,
        response: error?.response?.data,
      });

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error?.message ?? "initializeEvOrderPayment failed"
      );
    }
  }
);