import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import axios from "axios";
import * as crypto from "crypto";
import {
  PAYTR_MERCHANT_ID,
  PAYTR_MERCHANT_KEY,
  PAYTR_MERCHANT_SALT,
  getPaytrBaseUrl,
  getPaytrCallbackUrl,
  getPaytrFailUrl,
  getPaytrOkUrl,
} from "./config";


function asString(value: unknown): string {
  return (value ?? "").toString().trim();
}

function asNumber(value: unknown): number {
  if (typeof value === "number") return value;
  if (typeof value === "string") {
    return Number(value.replace(",", ".").trim()) || 0;
  }
  return 0;
}

function sanitizeMerchantOid(value: string): string {
  return value.replace(/[^A-Za-z0-9]/g, "").slice(0, 64);
}

export const initializePaytrOrderPayment = onCall(
  {
    region: "europe-west1",
    secrets: [
      PAYTR_MERCHANT_ID,
      PAYTR_MERCHANT_KEY,
      PAYTR_MERCHANT_SALT,
    ],
  },
  async (request) => {
    try {
      const db = getFirestore();
      const uid = request.auth?.uid;
      if (!uid) {
        throw new HttpsError("unauthenticated", "Oturum gerekli.");
      }

      const orderId = asString(request.data?.orderId);
      if (!orderId) {
        throw new HttpsError("invalid-argument", "orderId zorunlu.");
      }

      const orderRef = db.collection("orders").doc(orderId);
      const orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        throw new HttpsError("not-found", "Sipariş bulunamadı.");
      }

      const orderData = orderSnap.data() ?? {};

      const ownerUid = asString(orderData.userId ?? orderData.uid);
      if (ownerUid && ownerUid !== uid) {
        throw new HttpsError(
          "permission-denied",
          "Bu sipariş için ödeme başlatılamaz."
        );
      }

      const paymentStatus = asString(orderData.paymentStatus);
      if (
        paymentStatus &&
        paymentStatus !== "pending" &&
        paymentStatus !== "awaiting_payment" &&
        paymentStatus !== "failed"
      ) {
        throw new HttpsError(
          "failed-precondition",
          `Sipariş ödeme için uygun değil: ${paymentStatus}`
        );
      }

      const amountTl = asNumber(
        orderData.customerTotalPayment ??
          orderData.genelToplam ??
          orderData.totalPrice ??
          orderData.totalAmount
      );

      if (!Number.isFinite(amountTl) || amountTl <= 0) {
        throw new HttpsError("failed-precondition", "Geçersiz toplam tutar.");
      }

      const merchantId = PAYTR_MERCHANT_ID.value().trim();
      const merchantKey = PAYTR_MERCHANT_KEY.value().trim();
      const merchantSalt = PAYTR_MERCHANT_SALT.value().trim();

      if (!merchantId || !merchantKey || !merchantSalt) {
        throw new HttpsError("failed-precondition", "PAYTR secret eksik.");
      }

      const merchantOid = sanitizeMerchantOid(`sf_${orderId}`);
      const paymentAmount = Math.round(amountTl * 100);

      const userEmail = asString(
        orderData.customerEmail ??
          orderData.email ??
          orderData.userEmail ??
          "musteri@sofrasofra.com"
      );

      const userName = asString(
        orderData.customerName ??
          orderData.musteriAd ??
          orderData.buyerName ??
          "Sofrasofra Müşteri"
      );

      const userPhone = asString(
        orderData.customerPhone ??
          orderData.musteriTelefon ??
          orderData.phone ??
          "05000000000"
      );

      const userAddress = asString(
        orderData.address ??
          orderData.teslimatAdresi ??
          orderData.deliveryAddress ??
          "Sofrasofra"
      );

      const userIp = asString(
        request.rawRequest.headers["x-forwarded-for"]
      ).split(",")[0] || request.rawRequest.ip || "127.0.0.1";

      const basketTitle = asString(
        orderData.orderTitle ??
          orderData.dukkanAd ??
          orderData.saticiAdi ??
          "Sofrasofra Siparişi"
      );

      const userBasket = Buffer.from(
        JSON.stringify([[basketTitle, amountTl.toFixed(2), 1]])
      ).toString("base64");

      const okUrl = `${getPaytrOkUrl()}?orderId=${encodeURIComponent(orderId)}`;
      const failUrl = `${getPaytrFailUrl()}?orderId=${encodeURIComponent(
        orderId
      )}`;
      const callbackUrl =
        getPaytrCallbackUrl() ||
        "https://europe-west1-sofrasofra-a3344.cloudfunctions.net/paytrCallback";

      const noInstallment = "1";
      const maxInstallment = "0";
      const currency = "TL";
      const testMode = "0";
      const debugOn = "1";
      const timeoutLimit = "30";
      const lang = "tr";

      const tokenRaw =
        merchantId +
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
        paytrDebug: {
          merchantIdLength: merchantId.length,
          merchantKeyLength: merchantKey.length,
          merchantSaltLength: merchantSalt.length,
          userIp,
          userEmail,
          userBasket,
          noInstallment,
          maxInstallment,
          currency,
          testMode,
          callbackUrl,
          okUrl,
          failUrl,
          hasPaytrToken: paytrToken.length > 0,
        },
      });

      const response = await axios.post(
        `${getPaytrBaseUrl()}/odeme/api/get-token`,
        payload.toString(),
        {
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
          },
          timeout: 20000,
        }
      );

      const responseData = response.data ?? {};
      const status = asString(responseData.status);
      const token = asString(responseData.token);

      if (status !== "success" || !token) {
        logger.error("❌ PAYTR get-token failed", {
          orderId,
          merchantOid,
          responseData,
        });
        throw new HttpsError(
          "internal",
          `PAYTR token alınamadı: ${responseData.reason ?? status}`
        );
      }

      const iframeUrl = `${getPaytrBaseUrl()}/odeme/guvenli/${token}`;

      await orderRef.set(
        {
          paymentProvider: "paytr",
          paymentStatus: "awaiting_payment",
          status: "awaiting_payment",
          durum: "awaiting_payment",
          paytrMerchantOid: merchantOid,
          paytrToken: token,
          paytrIframeUrl: iframeUrl,
          paytrInitRawResponse: responseData,
          paymentUpdatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return {
        success: true,
        provider: "paytr",
        orderId,
        merchantOid,
        token,
        iframeUrl,
      };
    } catch (error: any) {
      logger.error("❌ initializePaytrOrderPayment ERROR", {
        message: error?.message,
        stack: error?.stack,
      });

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        error?.message ?? "initializePaytrOrderPayment failed"
      );
    }
  }
);



