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
const FOUNDER_CAMPAIGN_VERSION = "founder_100_2026_v1";
const FOUNDER_LIMIT = 100;
const PAYTR_PAYMENT_FEE_RATE = 0.0199;
function cleanString(value) {
    if (typeof value !== "string")
        return "";
    return value.trim();
}
function founderExpiryFrom(grantedAt) {
    const expiryDate = grantedAt.toDate();
    expiryDate.setUTCFullYear(expiryDate.getUTCFullYear() + 1);
    return admin.firestore.Timestamp.fromDate(expiryDate);
}
function isExistingFounderAllocation(applicationData, founderCategory) {
    if (!applicationData)
        return false;
    return (applicationData.isFounder === true &&
        applicationData.founderCategory === founderCategory &&
        applicationData.founderCampaignVersion === FOUNDER_CAMPAIGN_VERSION);
}
function founderFields({ founderCategory, sequence, grantedAt, expiresAt, }) {
    return {
        isFounder: true,
        founderCategory,
        founderSequence: sequence,
        founderGrantedAt: grantedAt,
        founderExpiresAt: expiresAt,
        founderCampaignVersion: FOUNDER_CAMPAIGN_VERSION,
        plan: "founding",
        planType: "founding",
        membershipType: "founding",
        packageType: "founding",
        membershipStatus: "active",
        membershipFeeExempt: true,
        membershipFeeExemptUntil: expiresAt,
        commissionExempt: true,
        commissionExemptUntil: expiresAt,
        sofrasofraCommissionRate: 0,
        sofrasofraCommissionLabel: "%0 — Kurucu Üye Avantajı",
        paymentProvider: "paytr",
        paymentFeeRate: PAYTR_PAYMENT_FEE_RATE,
        paymentFeeLabel: "%1,99 PAYTR İşlem Maliyeti",
        founderBenefitStatus: "active",
    };
}
function nonFounderFields(founderCategory) {
    return {
        isFounder: false,
        founderCategory,
        founderSequence: null,
        founderGrantedAt: null,
        founderExpiresAt: null,
        founderCampaignVersion: FOUNDER_CAMPAIGN_VERSION,
        plan: "free",
        planType: "free",
        membershipType: "free",
        packageType: "free",
        membershipStatus: "active",
        membershipFeeExempt: false,
        membershipFeeExemptUntil: null,
        commissionExempt: false,
        commissionExemptUntil: null,
        sofrasofraCommissionRate: null,
        sofrasofraCommissionLabel: null,
        paymentProvider: "paytr",
        paymentFeeRate: PAYTR_PAYMENT_FEE_RATE,
        paymentFeeLabel: "%1,99 PAYTR İşlem Maliyeti",
        founderBenefitStatus: "not_eligible",
    };
}
async function saveApplicationWithFounderAllocation({ applicationRef, campaignRef, remainingField, founderCategory, applicationData, }) {
    return admin.firestore().runTransaction(async (transaction) => {
        const applicationSnap = await transaction.get(applicationRef);
        const campaignSnap = await transaction.get(campaignRef);
        const existingApplicationData = applicationSnap.data();
        const alreadyAllocated = isExistingFounderAllocation(existingApplicationData, founderCategory);
        const campaignData = campaignSnap.data() || {};
        const rawRemaining = campaignData[remainingField];
        const currentRemaining = typeof rawRemaining === "number"
            ? Math.max(Math.min(Math.floor(rawRemaining), FOUNDER_LIMIT), 0)
            : FOUNDER_LIMIT;
        const now = admin.firestore.Timestamp.now();
        if (alreadyAllocated) {
            const existingSequence = typeof existingApplicationData?.founderSequence === "number"
                ? existingApplicationData.founderSequence
                : null;
            const existingExpiryValue = existingApplicationData?.founderExpiresAt;
            const existingExpiry = existingExpiryValue instanceof admin.firestore.Timestamp
                ? existingExpiryValue
                : null;
            transaction.set(applicationRef, {
                ...applicationData,
                updatedAt: now,
            }, { merge: true });
            return {
                isFounder: true,
                founderCategory,
                founderSequence: existingSequence,
                founderExpiresAt: existingExpiry,
                remaining: currentRemaining,
            };
        }
        if (currentRemaining > 0) {
            const sequence = FOUNDER_LIMIT - currentRemaining + 1;
            const expiresAt = founderExpiryFrom(now);
            const nextRemaining = Math.max(currentRemaining - 1, 0);
            transaction.set(applicationRef, {
                ...applicationData,
                ...founderFields({
                    founderCategory,
                    sequence,
                    grantedAt: now,
                    expiresAt,
                }),
                createdAt: applicationSnap.exists
                    ? existingApplicationData?.createdAt ?? now
                    : now,
                updatedAt: now,
            }, { merge: true });
            transaction.set(campaignRef, {
                [remainingField]: nextRemaining,
                [`${remainingField}LastAllocatedSequence`]: sequence,
                founderCampaignVersion: FOUNDER_CAMPAIGN_VERSION,
                updatedAt: now,
            }, { merge: true });
            return {
                isFounder: true,
                founderCategory,
                founderSequence: sequence,
                founderExpiresAt: expiresAt,
                remaining: nextRemaining,
            };
        }
        transaction.set(applicationRef, {
            ...applicationData,
            ...nonFounderFields(founderCategory),
            createdAt: applicationSnap.exists
                ? existingApplicationData?.createdAt ?? now
                : now,
            updatedAt: now,
        }, { merge: true });
        if (!campaignSnap.exists) {
            transaction.set(campaignRef, {
                [remainingField]: 0,
                founderCampaignVersion: FOUNDER_CAMPAIGN_VERSION,
                updatedAt: now,
            }, { merge: true });
        }
        return {
            isFounder: false,
            founderCategory,
            founderSequence: null,
            founderExpiresAt: null,
            remaining: 0,
        };
    });
}
async function saveApplicationWithoutFounderAllocation({ applicationRef, applicationData, founderCategory, }) {
    return admin.firestore().runTransaction(async (transaction) => {
        const applicationSnap = await transaction.get(applicationRef);
        const existingApplicationData = applicationSnap.data();
        const now = admin.firestore.Timestamp.now();
        transaction.set(applicationRef, {
            ...applicationData,
            ...nonFounderFields(founderCategory),
            createdAt: applicationSnap.exists
                ? existingApplicationData?.createdAt ?? now
                : now,
            updatedAt: now,
        }, { merge: true });
        return {
            isFounder: false,
            founderCategory: null,
            founderSequence: null,
            founderExpiresAt: null,
            remaining: 0,
        };
    });
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
        ? data.legalAcceptedTexts
            .map((item) => cleanString(item))
            .filter(Boolean)
        : [];
    const applicationRef = admin
        .firestore()
        .collection("producer_applications")
        .doc(uid);
    const campaignRef = admin
        .firestore()
        .collection("campaignSettings")
        .doc("main");
    const allocation = await saveApplicationWithFounderAllocation({
        applicationRef,
        campaignRef,
        remainingField: "evKalan",
        founderCategory: "ev_lezzetleri",
        applicationData: {
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
            iban: cleanString(data.iban).replace(/\s/g, "").toUpperCase(),
            legalAccepted: true,
            legalAcceptedAt: admin.firestore.Timestamp.now(),
            legalAcceptedAtClient: cleanString(data.legalAcceptedAtClient),
            legalAcceptedVersion: cleanString(data.legalAcceptedVersion) || "v1.0",
            legalAcceptedTexts,
            source: "ev_lezzetleri_basvuru_formu",
        },
    });
    return {
        success: true,
        applicationPath: `producer_applications/${uid}`,
        founderBenefit: {
            isFounder: allocation.isFounder,
            founderCategory: allocation.founderCategory,
            founderSequence: allocation.founderSequence,
            founderExpiresAt: allocation.founderExpiresAt?.toDate().toISOString() ?? null,
            remaining: allocation.remaining,
            sofrasofraCommissionRate: allocation.isFounder ? 0 : null,
            paytrPaymentFeeRate: PAYTR_PAYMENT_FEE_RATE,
        },
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
    if (data.legalAccepted !== true) {
        throw new https_1.HttpsError("failed-precondition", "Başvuruyu göndermek için hukuki metinleri onaylamalısınız.");
    }
    const legalAcceptedTexts = Array.isArray(data.legalAcceptedTexts)
        ? data.legalAcceptedTexts
            .map((item) => cleanString(item))
            .filter(Boolean)
        : [];
    const applicationRef = admin
        .firestore()
        .collection("producer_applications")
        .doc(uid);
    const campaignRef = admin
        .firestore()
        .collection("campaignSettings")
        .doc("main");
    const professionalApplicationData = {
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
        legalAccepted: true,
        legalAcceptedAt: admin.firestore.Timestamp.now(),
        legalAcceptedAtClient: cleanString(data.legalAcceptedAtClient),
        legalAcceptedVersion: cleanString(data.legalAcceptedVersion) || "v1.0",
        legalAcceptedTexts,
        source: "profesyonel_isletme_basvuru_formu",
    };
    let allocation;
    if (isletmeTipi === "restoran") {
        allocation = await saveApplicationWithFounderAllocation({
            applicationRef,
            campaignRef,
            remainingField: "restoranKalan",
            founderCategory: "restoran",
            applicationData: professionalApplicationData,
        });
    }
    else if (isletmeTipi === "usta_sef") {
        allocation = await saveApplicationWithFounderAllocation({
            applicationRef,
            campaignRef,
            remainingField: "sefKalan",
            founderCategory: "usta_sef",
            applicationData: professionalApplicationData,
        });
    }
    else {
        allocation = await saveApplicationWithoutFounderAllocation({
            applicationRef,
            applicationData: professionalApplicationData,
            founderCategory: isletmeTipi || "profesyonel_isletme",
        });
    }
    return {
        success: true,
        applicationPath: `producer_applications/${uid}`,
        founderBenefit: {
            isFounder: allocation.isFounder,
            founderCategory: allocation.founderCategory,
            founderSequence: allocation.founderSequence,
            founderExpiresAt: allocation.founderExpiresAt?.toDate().toISOString() ?? null,
            remaining: allocation.remaining,
            sofrasofraCommissionRate: allocation.isFounder ? 0 : null,
            paytrPaymentFeeRate: PAYTR_PAYMENT_FEE_RATE,
        },
    };
});
//# sourceMappingURL=producer_applications.js.map