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
exports.submitProfessionalApplication = exports.submitEvLezzetleriApplication = void 0;
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
    if (data.legalAccepted !== true) {
        throw new https_1.HttpsError("failed-precondition", "Başvuruyu göndermek için hukuki metinleri onaylamalısınız.");
    }
    const legalAcceptedTexts = Array.isArray(data.legalAcceptedTexts)
        ? data.legalAcceptedTexts.map((item) => cleanString(item)).filter(Boolean)
        : [];
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
        legalAccepted: true,
        legalAcceptedAt: now,
        legalAcceptedAtClient: cleanString(data.legalAcceptedAtClient),
        legalAcceptedVersion: cleanString(data.legalAcceptedVersion) || "v1.0",
        legalAcceptedTexts,
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
exports.submitProfessionalApplication = (0, https_1.onCall)({
    region: "europe-west1",
}, async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "Başvuru göndermek için oturum gerekli.");
    }
    const data = request.data;
    const isletmeTipi = cleanString(data.isletmeTipi) || "usta_sef";
    const professionalStatus = cleanString(data.professionalStatus) || "individual_chef";
    const requiresTaxCertificate = typeof data.requiresTaxCertificate === "boolean"
        ? data.requiresTaxCertificate
        : professionalStatus === "business_owner" ||
            professionalStatus === "corporate_catering";
    const isletmeAdi = cleanString(data.isletmeAdi);
    const yetkiliKisi = cleanString(data.yetkiliKisi);
    const telefon = cleanString(data.telefon);
    const email = cleanString(data.email);
    const sehir = cleanString(data.sehir);
    const ilce = cleanString(data.ilce);
    if (!isletmeAdi || !yetkiliKisi || !telefon || !sehir || !ilce) {
        throw new https_1.HttpsError("invalid-argument", "Zorunlu başvuru alanları eksik.");
    }
    const now = admin.firestore.FieldValue.serverTimestamp();
    const applicationRef = admin
        .firestore()
        .collection("producer_applications")
        .doc(uid);
    await applicationRef.set({
        userId: uid,
        type: "profesyonel_isletme",
        status: "submitted",
        aiReviewStatus: "not_started",
        riskLevel: "unknown",
        isletmeTipi,
        professionalStatus,
        requiresTaxCertificate,
        isletmeAdi,
        yetkiliKisi,
        telefon,
        email,
        sehir,
        ilce,
        vergiNotu: cleanString(data.vergiNotu),
        tcknVkn: cleanString(data.tcknVkn),
        iban: cleanString(data.iban).replace(/\s/g, "").toUpperCase(),
        aciklama: cleanString(data.aciklama),
        source: "profesyonel_isletme_basvuru_formu",
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
                sefKalan: 99,
                updatedAt: now,
            }, { merge: true });
            return;
        }
        const campaignData = campaignSnap.data() || {};
        const currentSefKalan = typeof campaignData.sefKalan === "number" ? campaignData.sefKalan : 0;
        const nextSefKalan = Math.max(currentSefKalan - 1, 0);
        transaction.set(campaignRef, {
            sefKalan: nextSefKalan,
            updatedAt: now,
        }, { merge: true });
    });
    return {
        success: true,
        applicationPath: `producer_applications/${uid}`,
    };
});
//# sourceMappingURL=producer_applications.js.map