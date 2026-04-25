export declare const iyzicoCallback: import("firebase-functions/v2/https").HttpsFunction;
export declare const notifySellerOnNewOrder: import("firebase-functions/v2/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").QueryDocumentSnapshot | undefined, {
    siparisId: string;
}>>;
export declare const notifyCustomerWhenCourierAssigned: import("firebase-functions/v2/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2/firestore").Change<import("firebase-functions/v2/firestore").QueryDocumentSnapshot> | undefined, {
    siparisId: string;
}>>;
export declare const initializeChefTablePayment: import("firebase-functions/v2/https").CallableFunction<any, Promise<{
    success: boolean;
    status: any;
    token: any;
    checkoutUrl: any;
}>>;
export { initializeEvOrderPayment } from "./ev_order_payment";
export { evIyzicoCallback } from "./ev_iyzico_callback";
//# sourceMappingURL=index.d.ts.map