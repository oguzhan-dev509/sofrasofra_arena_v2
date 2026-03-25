const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

exports.siparisTeslimBildirim = onDocumentUpdated(
  "orders/{orderId}",
  async (event) => {

    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) {
      return;
    }

    // status değişmemişse çık
    if (before.status === after.status) {
      return;
    }

    // sadece delivered olduğunda çalış
    if (after.status !== "delivered") {
      return;
    }

    const userId = after.userId;

    if (!userId) {
      console.log("kullaniciId yok");
      return;
    }

    const userDoc = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();

    if (!userDoc.exists) {
      console.log("user bulunamadı");
      return;
    }

    const token = userDoc.data().fcmToken;

    if (!token) {
      console.log("FCM token yok");
      return;
    }

    const message = {
      token: token,
      notification: {
        title: "Siparişiniz teslim edildi",
        body: "Afiyet olsun. Sofrasofra'yı tercih ettiğiniz için teşekkür ederiz."
      }
    };

    await admin.messaging().send(message);

    console.log("Bildirim gönderildi");
  }
);