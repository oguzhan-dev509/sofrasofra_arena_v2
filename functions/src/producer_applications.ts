import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

type EvApplicationPayload = {
  adSoyad?: string;
  telefon?: string;
  sehir?: string;
  ilce?: string;
  mutfakAdi?: string;
  urunBilgisi?: string;
  tcKimlikVergiNo?: string;
  vergiDairesi?: string;
  faturaAdresi?: string;
  faturaEposta?: string;
  iban?: string;
};

function cleanString(value: unknown): string {
  if (typeof value !== "string") return "";
  return value.trim();
}

export const submitEvLezzetleriApplication = onCall(
  {
    region: "europe-west1",
  },
  async (request) => {
    const uid = request.auth?.uid;

    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "Başvuru göndermek için oturum gerekli."
      );
    }

    const data = request.data as EvApplicationPayload;

    const adSoyad = cleanString(data.adSoyad);
    const telefon = cleanString(data.telefon);
    const sehir = cleanString(data.sehir);
    const ilce = cleanString(data.ilce);
    const mutfakAdi = cleanString(data.mutfakAdi);
    const urunBilgisi = cleanString(data.urunBilgisi);

    if (!adSoyad || !telefon || !sehir || !ilce || !mutfakAdi) {
      throw new HttpsError(
        "invalid-argument",
        "Zorunlu başvuru alanları eksik."
      );
    }

    const now = admin.firestore.FieldValue.serverTimestamp();

    const applicationRef = admin
      .firestore()
      .collection("producer_applications")
      .doc(uid);

    await applicationRef.set(
      {
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
      },
      { merge: true }
    );
    const campaignRef = admin
      .firestore()
      .collection("campaignSettings")
      .doc("main");

    await admin.firestore().runTransaction(async (transaction) => {
      const campaignSnap = await transaction.get(campaignRef);

      if (!campaignSnap.exists) {
        transaction.set(
          campaignRef,
          {
            evKalan: 99,
            updatedAt: now,
          },
          { merge: true }
        );
        return;
      }

      const campaignData = campaignSnap.data() || {};
      const currentEvKalan =
        typeof campaignData.evKalan === "number" ? campaignData.evKalan : 0;

      const nextEvKalan = Math.max(currentEvKalan - 1, 0);

      transaction.set(
        campaignRef,
        {
          evKalan: nextEvKalan,
          updatedAt: now,
        },
        { merge: true }
      );
    });
    return {
      success: true,
      applicationPath: `producer_applications/${uid}`,
    };
  }
);