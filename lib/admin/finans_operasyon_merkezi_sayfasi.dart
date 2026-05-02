import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FinansOperasyonMerkeziSayfasi extends StatelessWidget {
  const FinansOperasyonMerkeziSayfasi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _panel = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _textMuted = Color(0xFFBBBBBB);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Finans Operasyon Merkezi'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('createdAt', isGreaterThanOrEqualTo: startToday)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          double toplamCiro = 0;
          double platformGelir = 0;
          double ureticiToplam = 0;
          double kuryeToplam = 0;
          double islemUcretiToplam = 0;

          for (final d in docs) {
            final data = d.data();

            toplamCiro += (data['customerTotalPayment'] ?? 0).toDouble();
            platformGelir += (data['platformTotalRevenue'] ?? 0).toDouble();
            ureticiToplam += (data['producerNetAmount'] ?? 0).toDouble();
            kuryeToplam += (data['courierNetAmount'] ?? 0).toDouble();
            islemUcretiToplam += (data['paymentProcessingFee'] ?? 0).toDouble();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard('Bugünkü Ciro', toplamCiro),
              _buildCard('Platform Geliri', platformGelir),
              _buildCard('Üreticiye Giden', ureticiToplam),
              _buildCard('Kuryeye Giden', kuryeToplam),
              _buildCard('Ödeme İşlem Ücreti', islemUcretiToplam),
              _buildCard('Sipariş Sayısı', docs.length.toDouble()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(String title, double value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: _textMuted, fontSize: 14)),
          Text(
            _format(value),
            style: const TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _format(double value) {
    return '${value.toStringAsFixed(2)} ₺';
  }
}
