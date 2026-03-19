import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'otomatik_kurye_atama_servisi.dart';

class OrderRetryEngine {
  OrderRetryEngine._();
  static final OrderRetryEngine instance = OrderRetryEngine._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OtomatikKuryeAtamaServisi _assignmentService =
      OtomatikKuryeAtamaServisi();

  static const int retryDelaySeconds = 10;
  static const int defaultMaxRetryCount = 5;

  bool _isProcessing = false;

  Future<void> scheduleRetry({
    required String orderId,
    required String reason,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final snap = await orderRef.get();

      if (!snap.exists) return;

      final data = snap.data() ?? {};

      final int retryCount = _asInt(data['retryCount'], fallback: 0);
      final int maxRetryCount =
          _asInt(data['maxRetryCount'], fallback: defaultMaxRetryCount);

      if (retryCount >= maxRetryCount) {
        await orderRef.update({
          'assignmentStatus': 'manual_review_required',
          'retryStatus': 'exhausted',
          'lastRetryReason': 'max_retry_exceeded',
          'retryScheduledAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
          'assignmentLogs': FieldValue.arrayUnion([
            {
              'type': 'retry_exhausted',
              'reason': 'max_retry_exceeded',
              'at': DateTime.now().toIso8601String(),
            }
          ]),
        });
        return;
      }

      final scheduledAt =
          DateTime.now().add(const Duration(seconds: retryDelaySeconds));

      await orderRef.update({
        'assignmentStatus': 'retry_scheduled',
        'retryStatus': 'scheduled',
        'retryScheduledAt': Timestamp.fromDate(scheduledAt),
        'lastRetryReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
        'assignmentLogs': FieldValue.arrayUnion([
          {
            'type': 'retry_scheduled',
            'reason': reason,
            'retryCount': retryCount,
            'scheduledFor': scheduledAt.toIso8601String(),
            'at': DateTime.now().toIso8601String(),
          }
        ]),
      });

      debugPrint(
        '[OrderRetryEngine] Retry scheduled | orderId=$orderId | reason=$reason',
      );
    } catch (e, st) {
      debugPrint('[OrderRetryEngine] scheduleRetry error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> processDueRetries() async {
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      final now = Timestamp.now();

      final query = await _firestore
          .collection('orders')
          .where('assignmentStatus', isEqualTo: 'retry_scheduled')
          .where('retryStatus', isEqualTo: 'scheduled')
          .where('retryScheduledAt', isLessThanOrEqualTo: now)
          .limit(20)
          .get();

      if (query.docs.isEmpty) {
        return;
      }

      for (final doc in query.docs) {
        await _retrySingleOrder(doc.id, doc.data());
      }
    } catch (e, st) {
      debugPrint('[OrderRetryEngine] processDueRetries error: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _retrySingleOrder(
    String orderId,
    Map<String, dynamic> data,
  ) async {
    final orderRef = _firestore.collection('orders').doc(orderId);

    try {
      final String currentAssignmentStatus =
          (data['assignmentStatus'] ?? '').toString().trim();
      final String currentStatus = (data['status'] ?? '').toString().trim();

      if (currentAssignmentStatus == 'assigned') {
        await orderRef.update({
          'retryStatus': 'idle',
          'retryScheduledAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      if (currentStatus == 'delivered' ||
          currentStatus == 'cancelled' ||
          currentStatus == 'completed') {
        await orderRef.update({
          'retryStatus': 'idle',
          'retryScheduledAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      await orderRef.update({
        'assignmentStatus': 'retrying',
        'retryStatus': 'retrying',
        'lastRetryAt': FieldValue.serverTimestamp(),
        'retryCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
        'assignmentLogs': FieldValue.arrayUnion([
          {
            'type': 'retry_started',
            'at': DateTime.now().toIso8601String(),
          }
        ]),
      });

      await _assignmentService.sipariseOtomatikKuryeAta(orderId);

      final refreshed = await orderRef.get();
      final newData = refreshed.data() ?? {};

      final assignedCourierId =
          (newData['assignedCourierId'] ?? '').toString().trim();
      final assignmentStatus =
          (newData['assignmentStatus'] ?? '').toString().trim();

      if (assignedCourierId.isNotEmpty && assignmentStatus == 'assigned') {
        await orderRef.update({
          'retryStatus': 'idle',
          'retryScheduledAt': null,
          'updatedAt': FieldValue.serverTimestamp(),
          'assignmentLogs': FieldValue.arrayUnion([
            {
              'type': 'retry_success',
              'courierId': assignedCourierId,
              'at': DateTime.now().toIso8601String(),
            }
          ]),
        });

        debugPrint(
          '[OrderRetryEngine] Retry success | orderId=$orderId | courier=$assignedCourierId',
        );
        return;
      }

      await scheduleRetry(
        orderId: orderId,
        reason: 'retry_failed_no_courier',
      );
    } catch (e, st) {
      debugPrint('[OrderRetryEngine] _retrySingleOrder error: $e');
      debugPrintStack(stackTrace: st);

      await scheduleRetry(
        orderId: orderId,
        reason: 'retry_exception',
      );
    }
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
