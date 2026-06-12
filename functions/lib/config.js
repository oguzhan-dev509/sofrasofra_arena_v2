"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PAYTR_MERCHANT_SALT = exports.PAYTR_MERCHANT_KEY = exports.PAYTR_MERCHANT_ID = exports.IYZI_SECRET_KEY = exports.IYZI_API_KEY = void 0;
exports.getIyziBaseUrl = getIyziBaseUrl;
exports.getIyziCallbackUrl = getIyziCallbackUrl;
exports.getPaytrBaseUrl = getPaytrBaseUrl;
exports.getPaytrCallbackUrl = getPaytrCallbackUrl;
exports.getPaytrOkUrl = getPaytrOkUrl;
exports.getPaytrFailUrl = getPaytrFailUrl;
const params_1 = require("firebase-functions/params");
exports.IYZI_API_KEY = (0, params_1.defineSecret)("IYZI_API_KEY");
exports.IYZI_SECRET_KEY = (0, params_1.defineSecret)("IYZI_SECRET_KEY");
exports.PAYTR_MERCHANT_ID = (0, params_1.defineSecret)("PAYTR_MERCHANT_ID");
exports.PAYTR_MERCHANT_KEY = (0, params_1.defineSecret)("PAYTR_MERCHANT_KEY");
exports.PAYTR_MERCHANT_SALT = (0, params_1.defineSecret)("PAYTR_MERCHANT_SALT");
function getIyziBaseUrl() {
    return "https://sandbox-api.iyzipay.com";
}
function getIyziCallbackUrl() {
    const raw = process.env.IYZI_CALLBACK_URL ?? "";
    return raw.trim();
}
function getPaytrBaseUrl() {
    return "https://www.paytr.com";
}
function getPaytrCallbackUrl() {
    const raw = process.env.PAYTR_CALLBACK_URL ?? "";
    return raw.trim();
}
function getPaytrOkUrl() {
    const raw = process.env.PAYTR_OK_URL ?? "";
    return raw.trim() || "https://sofrasofra.com/order-success";
}
function getPaytrFailUrl() {
    const raw = process.env.PAYTR_FAIL_URL ?? "";
    return raw.trim() || "https://sofrasofra.com/order-failed";
}
//# sourceMappingURL=config.js.map