import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChefTableReservationsPage extends StatelessWidget {
  ChefTableReservationsPage({super.key});

  final String chefId = 'RhkyTCD5TgWJFdEzP50mvCOrz5a2';

  Future<void> _updateReservationStatus(
    BuildContext context, {
    required String docId,
    required String newStatus,
  }) async {
    try {
      final now = DateTime.now();

      final Map<String, dynamic> updateData = <String, dynamic>{
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'approved') {
        updateData['paymentStatus'] = 'awaiting_payment';
        updateData['reservationFlowStatus'] = 'awaiting_payment';
        updateData['paymentProvider'] = 'iyzico';
        updateData['paymentExpireAt'] = Timestamp.fromDate(
          now.add(const Duration(minutes: 15)),
        );
      } else if (newStatus == 'rejected') {
        updateData['paymentStatus'] = 'not_required';
        updateData['reservationFlowStatus'] = 'rejected';
        updateData['paymentExpireAt'] = null;
      }

      await FirebaseFirestore.instance
          .collection('chef_table_reservations')
          .doc(docId)
          .update(updateData);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'approved'
                ? 'Rezervasyon onaylandı.'
                : 'Rezervasyon reddedildi.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellenemedi: $e'),
        ),
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

  String _formatPaymentStatus(String paymentStatus) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Şef Masası Rezervasyonları'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chef_table_reservations')
            .where('chefId', isEqualTo: chefId)
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
              final guestCount = data['guestCount'];
              final totalPrice = data['totalPrice'];
              final status = (data['status'] ?? '').toString();
              final paymentStatus = (data['paymentStatus'] ?? '').toString();
              final dateTs = data['date'] as Timestamp?;
              final createdAtTs = data['createdAt'] as Timestamp?;

              final isPending = status == 'pending';

              return Card(
                color: const Color(0xFF171717),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.08),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ödeme: ${_formatPaymentStatus(paymentStatus)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tarih: ${_formatDate(dateTs)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Oluşturulma: ${_formatDate(createdAtTs)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
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
                      if (isPending) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _updateReservationStatus(
                                    context,
                                    docId: doc.id,
                                    newStatus: 'approved',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Onayla'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  _updateReservationStatus(
                                    context,
                                    docId: doc.id,
                                    newStatus: 'rejected',
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                child: const Text('Reddet'),
                              ),
                            ),
                          ],
                        ),
                      ],
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
