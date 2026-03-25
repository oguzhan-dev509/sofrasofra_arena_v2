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

async function fixOrdersSchema() {
  const snapshot = await db.collection('orders').get();

  if (snapshot.empty) {
    console.log('orders koleksiyonunda kayıt bulunamadı.');
    return;
  }

  console.log(`Toplam ${snapshot.size} sipariş bulundu.\n`);

  for (const doc of snapshot.docs) {
    const data = doc.data();

    const status = (data.status ?? '').toString().trim().toLowerCase();
    const assignmentStatus = (data.assignmentStatus ?? '')
        .toString()
        .trim()
        .toLowerCase();

    const updatePayload = {};
    let touched = false;

    // durum alanını kaldır
    if (Object.prototype.hasOwnProperty.call(data, 'durum')) {
      updatePayload.durum = FieldValue.delete();
      touched = true;
    }

    // delivered -> completed
    if (status == 'delivered' && assignmentStatus != 'completed') {
      updatePayload.assignmentStatus = 'completed';
      touched = true;
    }

    // on_the_way -> assigned (eksikse)
    if (status == 'on_the_way' && assignmentStatus.isEmpty) {
      updatePayload.assignmentStatus = 'assigned';
      touched = true;
    }

    // ready + no_courier_found artık waiting_courier olmalı
    if (status == 'ready' && assignmentStatus == 'no_courier_found') {
      updatePayload.status = 'waiting_courier';
      touched = true;
    }

    if (touched) {
      updatePayload.updatedAt = FieldValue.serverTimestamp();

      await doc.ref.set(updatePayload, { merge: true });

      console.log(`Düzeltildi: ${doc.id}`);
      console.log(updatePayload);
      console.log('-----------------------------');
    }
  }

  console.log('\nOrders schema cleanup tamamlandı.');
}

fixOrdersSchema()
  .then(() => {
    console.log('İşlem tamam.');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Script hata verdi:', error);
    process.exit(1);
  });