import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/otomatik_kurye_atama_servisi.dart';

class SaticiSiparisPaneli extends StatefulWidget {
  const SaticiSiparisPaneli({super.key});

  @override
  State<SaticiSiparisPaneli> createState() => _SaticiSiparisPaneliState();
}

class _SaticiSiparisPaneliState extends State<SaticiSiparisPaneli> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _yenidenAta(
    BuildContext context,
    String orderId,
  ) async {
    try {
      final sonuc =
          await OtomatikKuryeAtamaServisi().siparisiYenidenAtamayiDene(orderId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sonuc
                ? 'Kurye atama tekrar denendi. Uygun kurye bulunduysa sipariş atandı.'
                : 'Şu anda uygun kurye bulunamadı. Sipariş beklemede kaldı.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yeniden atama sırasında hata oluştu: $e'),
        ),
      );
    }
  }

  Widget _buildAssignmentBadge(Map<String, dynamic> order) {
    final assignmentStatus =
        (order['assignmentStatus'] ?? '').toString().trim().toLowerCase();

    String text;
    Color color;

    switch (assignmentStatus) {
      case 'assigned':
        text = 'Kurye Atandı';
        color = Colors.green;
        break;

      case 'offer_sent':
        text = 'Kurye Teklifi Gönderildi';
        color = Colors.blue;
        break;

      case 'waiting_courier':
        text = 'Kurye Aranıyor';
        color = Colors.orange;
        break;

      case 'completed':
        text = 'Teslim Tamamlandı';
        color = Colors.green;
        break;

      case 'cancelled':
        text = 'Atama İptal';
        color = Colors.red;
        break;

      case 'no_courier_found':
        text = 'Uygun Kurye Bulunamadı';
        color = Colors.red;
        break;

      case 'invalid_order_location':
        text = 'Konum Hatası';
        color = Colors.red;
        break;

      case 'seller_assignment_required':
        text = 'Satıcı Kuryesi Gerekli';
        color = Colors.deepPurple;
        break;

      case 'not_required':
        text = 'Kurye Gerekmiyor';
        color = Colors.teal;
        break;

      default:
        text = 'Durum Bilinmiyor';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatMoney(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString();
    if (value is double) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(2);
    }
    return value.toString();
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _formatDistance(dynamic value) {
    if (value == null) return '-';
    if (value is int) return '${value.toString()} km';
    if (value is double) return '${value.toStringAsFixed(2)} km';

    final parsed = double.tryParse(value.toString());
    if (parsed == null) return '-';
    return '${parsed.toStringAsFixed(2)} km';
  }

  bool _showRetryButton(Map<String, dynamic> order) {
    final assignmentStatus =
        (order['assignmentStatus'] ?? '').toString().trim().toLowerCase();

    return assignmentStatus == 'waiting_courier' ||
        assignmentStatus == 'no_courier_found';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satıcı Sipariş Paneli'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ordersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Hata oluştu: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('Henüz sipariş bulunmuyor.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final orderId = doc.id;
              final data = doc.data();

              final siparisNo = _safeText(data['siparisNo'], fallback: orderId);
              final musteriAd = _safeText(data['musteriAd']);
              final saticiAd = _safeText(data['saticiAd']);
              final adres = _safeText(
                data['teslimatAdresi'] ?? data['adres'],
              );
              final toplam = _formatMoney(
                data['genelToplam'] ?? data['toplamTutar'] ?? data['araToplam'],
              );
              final status = _safeText(data['status']);
              final assignedCourierName =
                  _safeText(data['assignedCourierName'], fallback: 'Atanmadı');
              final courierAssignmentType =
                  _safeText(data['courierAssignmentType'], fallback: '-');
              final assignedCourierDistance =
                  _formatDistance(data['assignedCourierDistanceKm']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        runSpacing: 8,
                        spacing: 8,
                        children: [
                          Text(
                            'Sipariş No: $siparisNo',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _buildAssignmentBadge(data),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Müşteri: $musteriAd',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Satıcı: $saticiAd',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text('Adres: $adres'),
                      const SizedBox(height: 4),
                      Text('Sipariş Durumu: $status'),
                      const SizedBox(height: 4),
                      Text('Kurye: $assignedCourierName'),
                      const SizedBox(height: 4),
                      Text('Atama Tipi: $courierAssignmentType'),
                      const SizedBox(height: 4),
                      Text('Kurye Mesafesi: $assignedCourierDistance'),
                      const SizedBox(height: 4),
                      Text(
                        'Toplam: ₺$toplam',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (_showRetryButton(data))
                            ElevatedButton.icon(
                              onPressed: () => _yenidenAta(context, orderId),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Yeniden Ata'),
                            ),
                        ],
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
