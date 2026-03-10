import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../firestore_test_page.dart';
import 'kurye_yonetimi.dart';
import 'satici_onay_merkezi.dart';
import 'siparis_yonetimi.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          'ADMIN DASHBOARD',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Platform Özeti',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          const _OzetKartlari(),
          const SizedBox(height: 22),
          const Text(
            'Hızlı Yönetim',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _yonetimKart(
            context: context,
            icon: Icons.verified_user,
            baslik: 'Satıcı Onay Merkezi',
            aciklama:
                'Ev Lezzetleri satıcılarını incele, onayla, reddet ve aktif/pasif yönet.',
            hedef: const SaticiOnayMerkezi(),
          ),
          const SizedBox(height: 12),
          _yonetimKart(
            context: context,
            icon: Icons.science_outlined,
            baslik: 'Firestore Test',
            aciklama: 'Koleksiyon ve örnek veri bağlantılarını kontrol et.',
            hedef: const FirestoreTestPage(),
          ),
          const SizedBox(height: 12),
          _yonetimKart(
            context: context,
            icon: Icons.receipt_long,
            baslik: 'Sipariş Yönetimi',
            aciklama:
                'Aktif siparişler, geciken siparişler ve admin müdahale ekranı.',
            hedef: const SiparisYonetimi(),
          ),
          const SizedBox(height: 12),
          _yonetimKart(
            context: context,
            icon: Icons.delivery_dining,
            baslik: 'Kurye Yönetimi',
            aciklama:
                'Teslimat modeli, bölge bazlı operasyon ve kurye izleme alanı.',
            hedef: const KuryeYonetimi(),
          ),
          const SizedBox(height: 12),
          const _YakindaKart(
            icon: Icons.psychology_alt,
            baslik: 'AI Denetim Merkezi',
            aciklama:
                'Risk skoru, otomatik denetim ve içerik moderasyon akışı.',
          ),
        ],
      ),
    );
  }

  Widget _yonetimKart({
    required BuildContext context,
    required IconData icon,
    required String baslik,
    required String aciklama,
    required Widget hedef,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => hedef),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x33FFB300)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0x22FFB300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFFFB300)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: const TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    aciklama,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _OzetKartlari extends StatelessWidget {
  const _OzetKartlari();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _CountCard(
                title: 'Toplam Satıcı',
                icon: Icons.storefront,
                collection: 'ev_lezzetleri',
                iconBg: Color(0x22FFB300),
                borderColor: Color(0x33FFB300),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _PendingSellerCard(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _ActiveOrdersCard(),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _TodayRevenueCard(),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String collection;
  final Color iconBg;
  final Color borderColor;

  const _CountCard({
    required this.title,
    required this.icon,
    required this.collection,
    required this.iconBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        final count = snapshot.data?.docs.length ?? 0;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return _istatistikKarti(
          title: title,
          value: hasError ? '!' : (loading ? '...' : count.toString()),
          icon: icon,
          iconBg: iconBg,
          borderColor: borderColor,
        );
      },
    );
  }
}

class _PendingSellerCard extends StatelessWidget {
  const _PendingSellerCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ev_lezzetleri')
          .where('onayDurumu', isEqualTo: 'beklemede')
          .snapshots(),
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        final count = snapshot.data?.docs.length ?? 0;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return _istatistikKarti(
          title: 'Bekleyen Onay',
          value: hasError ? '!' : (loading ? '...' : count.toString()),
          icon: Icons.pending_actions,
          iconBg: const Color(0x22FFA000),
          borderColor: const Color(0x33FFA000),
        );
      },
    );
  }
}

class _ActiveOrdersCard extends StatelessWidget {
  const _ActiveOrdersCard();

  bool _aktifSiparisMi(String durum) {
    const aktifDurumlar = {
      'pending',
      'preparing',
      'on_the_way',
      'hazirlaniyor',
      'yolda',
      'beklemede',
      'onay_bekliyor',
    };
    return aktifDurumlar.contains(durum);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        int aktifSiparisSayisi = 0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data();
            final durum = (data['status'] ?? data['durum'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

            if (_aktifSiparisMi(durum)) {
              aktifSiparisSayisi++;
            }
          }
        }

        return _istatistikKarti(
          title: 'Aktif Sipariş',
          value: hasError
              ? '!'
              : (loading ? '...' : aktifSiparisSayisi.toString()),
          icon: Icons.receipt_long,
          iconBg: const Color(0x2200C853),
          borderColor: const Color(0x3300C853),
        );
      },
    );
  }
}

class _TodayRevenueCard extends StatelessWidget {
  const _TodayRevenueCard();

  DateTime _baslangicBugun() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _bugunMu(Timestamp? ts) {
    if (ts == null) return false;
    final date = ts.toDate();
    final start = _baslangicBugun();
    final end = start.add(const Duration(days: 1));
    return !date.isBefore(start) && date.isBefore(end);
  }

  double _parseTutar(Map<String, dynamic> data) {
    final adaylar = [
      data['totalAmount'],
      data['toplamTutar'],
      data['tutar'],
      data['genelToplam'],
      data['total'],
    ];

    for (final item in adaylar) {
      if (item is num) return item.toDouble();
      if (item is String) {
        final temiz = item.replaceAll(',', '.').trim();
        final val = double.tryParse(temiz);
        if (val != null) return val;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        final hasError = snapshot.hasError;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        double bugunCiro = 0;

        if (snapshot.hasData) {
          for (final doc in snapshot.data!.docs) {
            final data = doc.data();

            Timestamp? ts;
            final rawTs = data['createdAt'] ?? data['siparisTarihi'];
            if (rawTs is Timestamp) {
              ts = rawTs;
            }

            if (_bugunMu(ts)) {
              bugunCiro += _parseTutar(data);
            }
          }
        }

        return _istatistikKarti(
          title: 'Bugünkü Ciro',
          value: hasError
              ? '!'
              : (loading ? '...' : '₺${bugunCiro.toStringAsFixed(0)}'),
          icon: Icons.payments,
          iconBg: const Color(0x223296FF),
          borderColor: const Color(0x333296FF),
        );
      },
    );
  }
}

class _YakindaKart extends StatelessWidget {
  final IconData icon;
  final String baslik;
  final String aciklama;

  const _YakindaKart({
    required this.icon,
    required this.baslik,
    required this.aciklama,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E0E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white54),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$baslik (Yakında)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  aciklama,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _istatistikKarti({
  required String title,
  required String value,
  required IconData icon,
  required Color iconBg,
  required Color borderColor,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFFFFB300)),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
