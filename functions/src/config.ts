import { defineSecret } from "firebase-functions/params";

export const IYZI_API_KEY = defineSecret("IYZI_API_KEY") as any;
export const IYZI_SECRET_KEY = defineSecret("IYZI_SECRET_KEY") as any;

export const PAYTR_MERCHANT_ID = defineSecret("PAYTR_MERCHANT_ID") as any;
export const PAYTR_MERCHANT_KEY = defineSecret("PAYTR_MERCHANT_KEY") as any;
export const PAYTR_MERCHANT_SALT = defineSecret("PAYTR_MERCHANT_SALT") as any;

export function getIyziBaseUrl(): string {
  return "https://sandbox-api.iyzipay.com";
}

export function getIyziCallbackUrl(): string {
  const raw = process.env.IYZI_CALLBACK_URL ?? "";
  return raw.trim();
}

export function getPaytrBaseUrl(): string {
  return "https://www.paytr.com";
}

export function getPaytrCallbackUrl(): string {
  const raw = process.env.PAYTR_CALLBACK_URL ?? "";
  return raw.trim();
}

export function getPaytrOkUrl(): string {
  const raw = process.env.PAYTR_OK_URL ?? "";
  return raw.trim() || "https://sofrasofra.com/order-success";
}

export function getPaytrFailUrl(): string {
  const raw = process.env.PAYTR_FAIL_URL ?? "";
  return raw.trim() || "https://sofrasofra.com/order-failed";
}