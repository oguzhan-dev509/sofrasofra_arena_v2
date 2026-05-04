import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PlatformOperasyonMerkeziSayfasi extends StatelessWidget {
  const PlatformOperasyonMerkeziSayfasi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _gold = Color(0xFFFFB300);

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final startToday = Timestamp.fromDate(_startOfToday());

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Platform Operasyon Merkezi',
          style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 6),
            const _SectionTitle(
              title: 'Genel Durum',
              subtitle: 'Platformun anlık operasyon verileri',
            ),
            const SizedBox(height: 16),

            // GRID
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _MetricCard(
                  title: 'Bugün Başvurular',
                  icon: Icons.assignment_rounded,
                  stream: FirebaseFirestore.instance
                      .collection('producer_applications')
                      .where('createdAt', isGreaterThanOrEqualTo: startToday)
                      .snapshots(),
                ),
                _MetricCard(
                  title: 'Onaylananlar',
                  icon: Icons.verified_rounded,
                  stream: FirebaseFirestore.instance
                      .collection('producer_applications')
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                ),
                _MetricCard(
                  title: 'Aktif Üreticiler',
                  icon: Icons.storefront_rounded,
                  stream: FirebaseFirestore.instance
                      .collection('producer_applications')
                      .where('status', isEqualTo: 'approved')
                      .where('type', isEqualTo: 'ev_lezzetleri')
                      .snapshots(),
                ),
                _MetricCard(
                  title: 'Şef / Restoran',
                  icon: Icons.restaurant_rounded,
                  stream: FirebaseFirestore.instance
                      .collection('producer_applications')
                      .where('status', isEqualTo: 'approved')
                      .where('type', isEqualTo: 'profesyonel_isletme')
                      .snapshots(),
                ),
                _MetricCard(
                  title: 'Bugün Sipariş',
                  icon: Icons.receipt_long_rounded,
                  stream: FirebaseFirestore.instance
                      .collection('orders') // yoksa 0 gösterecek
                      .where('createdAt', isGreaterThanOrEqualTo: startToday)
                      .snapshots(),
                ),
                _MetricCard(
                  title: 'Ödeme (İyzico)',
                  icon: Icons.payments_rounded,
                  stream: FirebaseFirestore.instance
                      .collection('chef_table_reservations')
                      .where('paymentStatus', isEqualTo: 'paid')
                      .snapshots(),
                ),
                _MetricCard(
                  title: 'Kurye Aktif',
                  icon: Icons.delivery_dining_rounded,
                  stream: FirebaseFirestore.instance
                      .collection('couriers')
                      .where('aktifMi', isEqualTo: true)
                      .snapshots(),
                ),
                _MetricCard(
                  title: 'Abonelikler',
                  icon: Icons.workspace_premium_rounded,
                  stream: FirebaseFirestore.instance
                      .collection('subscriptions') // yoksa 0
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const _SectionTitle(
              title: 'Son Başvurular',
              subtitle: 'En son gelen üretici / şef başvuruları',
            ),
            const SizedBox(height: 12),

            _LatestApplicationsList(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _gold,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Stream<QuerySnapshot<Map<String, dynamic>>> stream;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.stream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x33FFB300)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFB300), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LatestApplicationsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('producer_applications')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Text(
            'Henüz veri yok.',
            style: TextStyle(color: Colors.white60),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();

            final name = data['mutfakAdi'] ?? data['isletmeAdi'] ?? 'Başvuru';

            final status = data['status'] ?? 'submitted';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF151515),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    status,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
