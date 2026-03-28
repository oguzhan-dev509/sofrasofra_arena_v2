import 'package:cloud_firestore/cloud_firestore.dart';

class CoursePurchaseResult {
  final bool success;
  final String? orderId;
  final String message;

  const CoursePurchaseResult({
    required this.success,
    required this.message,
    this.orderId,
  });
}

class CoursePurchaseService {
  static const double platformCommissionRate = 0.20;

  static Future<CoursePurchaseResult> purchaseCourse({
    required String userId,
    required String courseId,
    required String courseTitle,
    required String chefId,
    required String chefName,
    required num price,
  }) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final existingAccess = await firestore
          .collection('user_courses')
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (existingAccess.docs.isNotEmpty) {
        return const CoursePurchaseResult(
          success: true,
          message: 'Bu kurs zaten satın alınmış.',
        );
      }

      final double grossAmount = price.toDouble();
      final double platformCommissionAmount =
          grossAmount * platformCommissionRate;
      final double chefNetIncome = grossAmount - platformCommissionAmount;

      final orderRef = firestore.collection('course_orders').doc();
      final userCourseRef = firestore.collection('user_courses').doc();
      final chefEarningRef = firestore.collection('chef_earnings').doc();

      await firestore.runTransaction((transaction) async {
        transaction.set(orderRef, {
          'userId': userId,
          'courseId': courseId,
          'courseTitle': courseTitle,
          'chefId': chefId,
          'chefName': chefName,
          'price': grossAmount,
          'currency': 'TRY',
          'paymentStatus': 'paid',
          'accessStatus': 'unlocked',
          'platformCommissionRate': platformCommissionRate,
          'platformCommissionAmount': platformCommissionAmount,
          'chefNetIncome': chefNetIncome,
          'createdAt': FieldValue.serverTimestamp(),
          'paidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(userCourseRef, {
          'userId': userId,
          'courseId': courseId,
          'chefId': chefId,
          'orderId': orderRef.id,
          'isActive': true,
          'purchasedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(chefEarningRef, {
          'chefId': chefId,
          'courseId': courseId,
          'orderId': orderRef.id,
          'userId': userId,
          'grossAmount': grossAmount,
          'platformCommissionRate': platformCommissionRate,
          'platformCommissionAmount': platformCommissionAmount,
          'netAmount': chefNetIncome,
          'status': 'accrued',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      return CoursePurchaseResult(
        success: true,
        orderId: orderRef.id,
        message: 'Kurs satın alma tamamlandı.',
      );
    } catch (e) {
      return CoursePurchaseResult(
        success: false,
        message: 'Satın alma hatası: $e',
      );
    }
  }
}