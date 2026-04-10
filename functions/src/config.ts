import { defineSecret } from "firebase-functions/params";

export const IYZI_API_KEY = defineSecret("IYZI_API_KEY") as any;
export const IYZI_SECRET_KEY = defineSecret("IYZI_SECRET_KEY") as any;

export function getIyziBaseUrl(): string {
  return "https://sandbox-api.iyzipay.com";
}

export function getIyziCallbackUrl(): string {
  const raw = process.env.IYZI_CALLBACK_URL ?? "";
  return raw.trim();
}