"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyCustomerWhenCourierAssigned = exports.notifySellerOnNewOrder = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
(0, app_1.initializeApp)();
const db = (0, firestore_2.getFirestore)();
exports.notifySellerOnNewOrder = (0, firestore_1.onDocumentCreated)("siparisler/{siparisId}", async (event) => {
    const snap = event.data;
    if (!snap)
        return;
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
    const tokens = (sellerDoc.data()?.fcmTokens ?? []);
    if (tokens.length === 0) {
        console.log("Satıcı token yok:", sellerId);
        return;
    }
    const title = "Yeni sipariş geldi";
    const body = `${order.musteriAd ?? "Bir müşteri"} yeni sipariş oluşturdu.`;
    const response = await (0, messaging_1.getMessaging)().sendEachForMulticast({
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
    const invalidTokens = [];
    response.responses.forEach((r, i) => {
        if (!r.success) {
            const code = r.error?.code ?? "";
            if (code.includes("registration-token-not-registered") ||
                code.includes("invalid-registration-token")) {
                invalidTokens.push(tokens[i]);
            }
        }
    });
    if (invalidTokens.length > 0) {
        await db.collection("users").doc(sellerId).update({
            fcmTokens: firestore_2.FieldValue.arrayRemove(...invalidTokens),
        });
    }
    await snap.ref.set({
        notification: {
            sellerNotified: true,
            sellerNotifiedAt: firestore_2.FieldValue.serverTimestamp(),
        },
    }, { merge: true });
});
exports.notifyCustomerWhenCourierAssigned = (0, firestore_1.onDocumentUpdated)("siparisler/{siparisId}", async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after)
        return;
    const siparisId = event.params.siparisId;
    const beforeCourierId = (before.assignedCourierId ?? "").toString().trim();
    const afterCourierId = (after.assignedCourierId ?? "").toString().trim();
    const alreadyNotified = after?.notification?.customerCourierAssignedNotified === true;
    if (alreadyNotified)
        return;
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
    const tokens = (customerDoc.data()?.fcmTokens ?? []);
    if (tokens.length === 0) {
        console.log("Müşteri token yok:", customerId);
        return;
    }
    const response = await (0, messaging_1.getMessaging)().sendEachForMulticast({
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
    const invalidTokens = [];
    response.responses.forEach((r, i) => {
        if (!r.success) {
            const code = r.error?.code ?? "";
            if (code.includes("registration-token-not-registered") ||
                code.includes("invalid-registration-token")) {
                invalidTokens.push(tokens[i]);
            }
        }
    });
    if (invalidTokens.length > 0) {
        await db.collection("users").doc(customerId).update({
            fcmTokens: firestore_2.FieldValue.arrayRemove(...invalidTokens),
        });
    }
    await event.data.after.ref.set({
        notification: {
            customerCourierAssignedNotified: true,
            customerCourierAssignedNotifiedAt: firestore_2.FieldValue.serverTimestamp(),
        },
    }, { merge: true });
});
