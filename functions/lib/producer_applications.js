"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.submitEvLezzetleriApplication = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
function cleanString(value) {
    if (typeof value !== "string")
        return "";
    return value.trim();
}
exports.submitEvLezzetleriApplication = (0, https_1.onCall)({
    region: "europe-west1",
}, async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "Başvuru göndermek için oturum gerekli.");
    }
    const data = request.data;
    const adSoyad = cleanString(data.adSoyad);
    const telefon = cleanString(data.telefon);
    const sehir = cleanString(data.sehir);
    const ilce = cleanString(data.ilce);
    const mutfakAdi = cleanString(data.mutfakAdi);
    const urunBilgisi = cleanString(data.urunBilgisi);
    if (!adSoyad || !telefon || !sehir || !ilce || !mutfakAdi) {
        throw new https_1.HttpsError("invalid-argument", "Zorunlu başvuru alanları eksik.");
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    const applicationRef = admin
        .firestore()
        .collection("producer_applications")
        .doc(uid);
    await applicationRef.set({
        userId: uid,
        type: "ev_lezzetleri",
        status: "submitted",
        adSoyad,
        telefon,
        sehir,
        ilce,
        mutfakAdi,
        urunBilgisi,
        tcKimlikVergiNo: cleanString(data.tcKimlikVergiNo),
        vergiDairesi: cleanString(data.vergiDairesi),
        faturaAdresi: cleanString(data.faturaAdresi),
        faturaEposta: cleanString(data.faturaEposta),
        iban: cleanString(data.iban),
        source: "ev_lezzetleri_basvuru_formu",
        updatedAt: now,
        createdAt: now,
    }, { merge: true });
    const campaignRef = admin
        .firestore()
        .collection("campaignSettings")
        .doc("main");
    await admin.firestore().runTransaction(async (transaction) => {
        const campaignSnap = await transaction.get(campaignRef);
        if (!campaignSnap.exists) {
            transaction.set(campaignRef, {
                evKalan: 99,
                updatedAt: now,
            }, { merge: true });
            return;
        }
        const campaignData = campaignSnap.data() || {};
        const currentEvKalan = typeof campaignData.evKalan === "number" ? campaignData.evKalan : 0;
        const nextEvKalan = Math.max(currentEvKalan - 1, 0);
        transaction.set(campaignRef, {
            evKalan: nextEvKalan,
            updatedAt: now,
        }, { merge: true });
    });
    return {
        success: true,
        applicationPath: `producer_applications/${uid}`,
    };
});
//# sourceMappingURL=producer_applications.js.map