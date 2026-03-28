import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

const db = getFirestore();

export const notifySellerOnNewOrder = onDocumentCreated(
  "siparisler/{siparisId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const order = snap.data();
    const siparisId = event.params.siparisId;

    if (order?.notification?.sellerNotified === true) {
      return;
    }

    const sellerId = (order.saticiId ?? "").toString().trim();
    if (!sellerId) {
      console.log("saticiId yok, bildirim atlanıyor.");
      return;
    }

    const sellerDoc = await db.collection("users").doc(sellerId).get();
    if (!sellerDoc.exists) {
      console.log("Satıcı bulunamadı:", sellerId);
      return;
    }

    const tokens = (sellerDoc.data()?.fcmTokens ?? []) as string[];
    if (tokens.length === 0) {
      console.log("Satıcı token yok:", sellerId);
      return;
    }

    const title = "Yeni sipariş geldi";
    const body = `${order.musteriAd ?? "Bir müşteri"} yeni sipariş oluşturdu.`;

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title,
        body,
      },
      data: {
        type: "new_order",
        siparisId,
        musteriId: (order.musteriId ?? "").toString(),
        saticiId: sellerId,
      },
    });

    const invalidTokens: string[] = [];
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code ?? "";
        if (
          code.includes("registration-token-not-registered") ||
          code.includes("invalid-registration-token")
        ) {
          invalidTokens.push(tokens[i]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await db.collection("users").doc(sellerId).update({
        fcmTokens: FieldValue.arrayRemove(...invalidTokens),
      });
    }

    await snap.ref.set({
      notification: {
        sellerNotified: true,
        sellerNotifiedAt: FieldValue.serverTimestamp(),
      },
    }, { merge: true });
  }
);

export const notifyCustomerWhenCourierAssigned = onDocumentUpdated(
  "siparisler/{siparisId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const siparisId = event.params.siparisId;

    const beforeCourierId = (before.assignedCourierId ?? "").toString().trim();
    const afterCourierId = (after.assignedCourierId ?? "").toString().trim();

    const alreadyNotified = after?.notification?.customerCourierAssignedNotified === true;

    if (alreadyNotified) return;

    // sadece gerçekten yeni kurye atandıysa çalış
    if (beforeCourierId.isNotEmpty || afterCourierId.isEmpty) {
      return;
    }

    const customerId = (after.musteriId ?? "").toString().trim();
    if (!customerId) {
      console.log("musteriId yok, bildirim atlanıyor.");
      return;
    }

    const customerDoc = await db.collection("users").doc(customerId).get();
    if (!customerDoc.exists) {
      console.log("Müşteri bulunamadı:", customerId);
      return;
    }

    const courierDoc = await db.collection("couriers").doc(afterCourierId).get();
    const courierName = courierDoc.exists
      ? (courierDoc.data()?.adSoyad ?? "Kuryeniz").toString()
      : "Kuryeniz";

    const tokens = (customerDoc.data()?.fcmTokens ?? []) as string[];
    if (tokens.length === 0) {
      console.log("Müşteri token yok:", customerId);
      return;
    }

    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Kurye atandı",
        body: `${courierName} siparişinizi teslim almak üzere atandı.`,
      },
      data: {
        type: "courier_assigned",
        siparisId,
        courierId: afterCourierId,
        musteriId: customerId,
      },
    });

    const invalidTokens: string[] = [];
    response.responses.forEach((r, i) => {
      if (!r.success) {
        const code = r.error?.code ?? "";
        if (
          code.includes("registration-token-not-registered") ||
          code.includes("invalid-registration-token")
        ) {
          invalidTokens.push(tokens[i]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await db.collection("users").doc(customerId).update({
        fcmTokens: FieldValue.arrayRemove(...invalidTokens),
      });
    }

    await event.data!.after.ref.set({
      notification: {
        customerCourierAssignedNotified: true,
        customerCourierAssignedNotifiedAt: FieldValue.serverTimestamp(),
      },
    }, { merge: true });
  }
);