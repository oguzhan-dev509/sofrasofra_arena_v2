import 'package:flutter/material.dart';

import 'satici_onay_merkezi.dart';
import '../firestore_test_page.dart';

class AdminPaneliSayfasi extends StatelessWidget {
  const AdminPaneliSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          'ADMİN PANELİ',
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
          const SizedBox(height: 8),
          const Text(
            'Yönetim Modülleri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _adminKart(
            context: context,
            icon: Icons.verified_user,
            baslik: 'Satıcı Onay Merkezi',
            aciklama:
                'Ev Lezzetleri satıcılarını listele, onayla, reddet, aktif/pasif yönet.',
            hedef: const SaticiOnayMerkezi(),
          ),
          const SizedBox(height: 12),
          _adminKart(
            context: context,
            icon: Icons.science_outlined,
            baslik: 'Firestore Test',
            aciklama: 'Veri yapısını ve koleksiyon bağlantılarını kontrol et.',
            hedef: const FirestoreTestPage(),
          ),
          const SizedBox(height: 12),
          _yakindaKart(
            icon: Icons.receipt_long,
            baslik: 'Sipariş Yönetimi',
            aciklama: 'Sipariş akışları, durum yönetimi ve müdahale ekranı.',
          ),
          const SizedBox(height: 12),
          _yakindaKart(
            icon: Icons.delivery_dining,
            baslik: 'Kurye Yönetimi',
            aciklama: 'Teslimat modeli, bölge ve operasyon yönetimi.',
          ),
          const SizedBox(height: 12),
          _yakindaKart(
            icon: Icons.psychology_alt,
            baslik: 'AI Denetim Merkezi',
            aciklama: 'Risk skoru, otomatik kontrol ve moderasyon alanı.',
          ),
        ],
      ),
    );
  }

  Widget _adminKart({
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

  Widget _yakindaKart({
    required IconData icon,
    required String baslik,
    required String aciklama,
  }) {
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
