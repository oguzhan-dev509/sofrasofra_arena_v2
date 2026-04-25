import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/order_status_timeline.dart';

class UserReservationsPage extends StatelessWidget {
  UserReservationsPage({super.key});

  Future<void> _startPayment(
    BuildContext context,
    String reservationId,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ödeme ekranı hazırlanıyor...')),
      );

      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('initializeChefTablePayment');

      final result = await callable.call(<String, dynamic>{
        'reservationId': reservationId,
      });

      final data = Map<String, dynamic>.from(
        (result.data as Map?) ?? <String, dynamic>{},
      );

      final checkoutUrl = (data['checkoutUrl'] ?? '').toString().trim();

      if (checkoutUrl.isEmpty) {
        throw Exception('Ödeme linki alınamadı.');
      }

      final uri = Uri.tryParse(checkoutUrl);
      if (uri == null) {
        throw Exception('Geçersiz ödeme linki.');
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Ödeme sayfası açılamadı.');
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Ödeme sayfası açıldı. İşlem sonrası durum güncellenecek.'),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ödeme başlatılamadı: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ödeme hatası: $e')),
      );
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  String _formatPaymentStatus(String paymentStatus, bool isExpired) {
    if (isExpired) return 'Ödeme süresi doldu';

    switch (paymentStatus.toLowerCase()) {
      case 'awaiting_payment':
        return 'Ödeme bekleniyor';
      case 'paid':
        return 'Ödeme tamamlandı';
      case 'not_required':
        return 'Ödeme gerekmiyor';
      default:
        return paymentStatus.isEmpty ? '-' : paymentStatus;
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';

    final dt = ts.toDate();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day.$month.$year  $hour:$minute';
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '-';

    if (value is int) return '$value TL';
    if (value is double) return '${value.toStringAsFixed(0)} TL';

    final parsed = int.tryParse(value.toString());
    if (parsed != null) return '$parsed TL';

    return value.toString();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.redAccent;
      case 'pending':
        return Colors.orangeAccent;
      default:
        return Colors.white70;
    }
  }

  Color _paymentColor(String paymentStatus, bool isExpired) {
    if (isExpired) return Colors.redAccent;

    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.greenAccent;
      case 'awaiting_payment':
        return Colors.orangeAccent;
      case 'not_required':
        return Colors.white70;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('Rezervasyonlarım'),
        ),
        body: const Center(
          child: Text(
            'Kullanıcı oturumu bulunamadı.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Rezervasyonlarım'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chef_table_reservations')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Rezervasyon yok',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final tableTitle =
                  (data['tableTitle'] ?? 'Rezervasyon').toString();
              final concept = (data['concept'] ?? '').toString();
              final capacity = (data['capacity'] ?? '').toString();
              final guestCount = data['guestCount'];
              final totalPrice = data['totalPrice'];

              final status = (data['status'] ?? '').toString();
              final paymentStatus = (data['paymentStatus'] ?? '').toString();
              final reservationFlowStatus =
                  (data['reservationFlowStatus'] ?? '').toString();

              final dateTs = data['date'] as Timestamp?;
              final createdAtTs = data['createdAt'] as Timestamp?;
              final paymentExpireAtTs = data['paymentExpireAt'] as Timestamp?;

              final now = DateTime.now();
              final isExpired = paymentStatus == 'awaiting_payment' &&
                  paymentExpireAtTs != null &&
                  paymentExpireAtTs.toDate().isBefore(now);

              final showPaymentButton =
                  paymentStatus == 'awaiting_payment' && !isExpired;

              final isConfirmed = paymentStatus == 'paid' ||
                  reservationFlowStatus == 'confirmed';

              return Card(
                color: const Color(0xFF171717),
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tableTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OrderStatusTimeline(
                        orderStatus: data['reservationFlowStatus'] ?? '',
                        deliveryStatus: data['deliveryStatus'] ?? '',
                      ),
                      const SizedBox(height: 12),
                      if (concept.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          concept,
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Durum: ${_formatStatus(status)}',
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ödeme: ${_formatPaymentStatus(paymentStatus, isExpired)}',
                        style: TextStyle(
                          color: _paymentColor(paymentStatus, isExpired),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isConfirmed) ...[
                        const SizedBox(height: 4),
                        const Text(
                          'Rezervasyon kesinleşti',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Tarih: ${_formatDate(dateTs)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Oluşturulma: ${_formatDate(createdAtTs)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (capacity.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Kapasite: $capacity',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                      if (guestCount != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Kişi sayısı: $guestCount',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Toplam: ${_formatPrice(totalPrice)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      if (paymentExpireAtTs != null &&
                          paymentStatus == 'awaiting_payment') ...[
                        const SizedBox(height: 4),
                        Text(
                          'Ödeme son zamanı: ${_formatDate(paymentExpireAtTs)}',
                          style: TextStyle(
                            color:
                                isExpired ? Colors.redAccent : Colors.white70,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (showPaymentButton)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _startPayment(context, doc.id, doc);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Ödemeyi Tamamla'),
                          ),
                        ),
                      if (isExpired)
                        const Text(
                          'Bu rezervasyon için ödeme süresi dolmuş.',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (paymentStatus == 'paid')
                        const Text(
                          'Ödeme tamamlandı',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
