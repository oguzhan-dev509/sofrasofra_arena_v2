const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

if (!fs.existsSync(serviceAccountPath)) {
  console.error('HATA: scripts/serviceAccountKey.json bulunamadı.');
  process.exit(1);
}

const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

function toNumber(value, fallback = 0) {
  if (typeof value === 'number' && !Number.isNaN(value)) return value;
  if (typeof value === 'string') {
    const n = Number(value.trim());
    if (!Number.isNaN(n)) return n;
  }
  return fallback;
}

function toInt(value, fallback = 0) {
  const n = parseInt(String(value ?? fallback), 10);
  return Number.isNaN(n) ? fallback : n;
}

function deriveUygunluk(aktifSiparis, maxAktifSiparis) {
  if (aktifSiparis <= 0) return 'Müsait';
  if (aktifSiparis >= maxAktifSiparis) return 'Dolu';
  return 'Görevde';
}

async function fixCouriers() {
  const snapshot = await db.collection('couriers').get();

  if (snapshot.empty) {
    console.log('couriers koleksiyonunda kayıt bulunamadı.');
    return;
  }

  console.log(`Toplam ${snapshot.size} kurye bulundu.\n`);

  for (const doc of snapshot.docs) {
    const data = doc.data();

    const aktifSiparis = Math.max(0, toInt(data.aktifSiparis, 0));
    const maxAktifSiparis = Math.max(1, toInt(data.maxAktifSiparis, 1));

    const lat = toNumber(data.lat, 0);
    const lng = toNumber(data.lng, 0);

    const uygunluk = deriveUygunluk(aktifSiparis, maxAktifSiparis);

    const updatePayload = {
      aktifSiparis,
      maxAktifSiparis,
      lat,
      lng,
      uygunluk,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      assignmentStatus: admin.firestore.FieldValue.delete(),
    };

    await doc.ref.set(updatePayload, { merge: true });

    console.log(`Düzeltildi: ${doc.id}`);
    console.log({
      aktifSiparis,
      maxAktifSiparis,
      lat,
      lng,
      uygunluk,
    });
    console.log('-----------------------------');
  }

  console.log('\nTüm courier kayıtları standardize edildi.');
}

fixCouriers()
  .then(() => {
    console.log('İşlem tamam.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Script hata verdi:', error);
    process.exit(1);
  });