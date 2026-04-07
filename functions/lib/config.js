"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.IYZI_SECRET_KEY = exports.IYZI_API_KEY = void 0;
exports.getIyziBaseUrl = getIyziBaseUrl;
exports.getIyziCallbackUrl = getIyziCallbackUrl;
const params_1 = require("firebase-functions/params");
exports.IYZI_API_KEY = (0, params_1.defineSecret)("IYZI_API_KEY");
exports.IYZI_SECRET_KEY = (0, params_1.defineSecret)("IYZI_SECRET_KEY");
function getIyziBaseUrl() {
    const raw = process.env.IYZI_BASE_URL ?? "https://sandbox-api.iyzipay.com";
    return raw.trim().replace(/\/+$/, "");
}
function getIyziCallbackUrl() {
    const raw = process.env.IYZI_CALLBACK_URL ?? "";
    return raw.trim();
}
//# sourceMappingURL=config.js.map