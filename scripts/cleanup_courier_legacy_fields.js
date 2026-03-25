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
const FieldValue = admin.firestore.FieldValue;

async function cleanupCourierLegacyFields() {
  const snapshot = await db.collection('couriers').get();

  if (snapshot.empty) {
    console.log('couriers koleksiyonunda kayıt bulunamadı.');
    return;
  }

  console.log(`Toplam ${snapshot.size} kurye bulundu.\n`);

  for (const doc of snapshot.docs) {
    await doc.ref.set({
      assignmentStatus: FieldValue.delete(),
      availability: FieldValue.delete(),
      assignedCourierId: FieldValue.delete(),
      assignedCourierName: FieldValue.delete(),
      currentOrderId: FieldValue.delete(),
      status: FieldValue.delete(),
      uygunlukDurumu: FieldValue.delete(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(`Legacy alanlar temizlendi: ${doc.id}`);
  }

  console.log('\nCourier legacy field temizliği tamamlandı.');
}

cleanupCourierLegacyFields()
  .then(() => {
    console.log('İşlem tamam.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Script hata verdi:', error);
    process.exit(1);
  });