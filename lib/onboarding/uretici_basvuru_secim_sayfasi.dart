import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'ev_lezzetleri_basvuru_sayfasi.dart';
import 'profesyonel_isletme_basvuru_sayfasi.dart';

class UreticiBasvuruSecimSayfasi extends StatelessWidget {
  const UreticiBasvuruSecimSayfasi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _gold = Color(0xFFFFB300);

  Future<void> _openIfQuotaAvailable({
    required BuildContext context,
    required String field,
    required String fullMessage,
    required Widget page,
  }) async {
    final doc = await FirebaseFirestore.instance
        .collection('campaignSettings')
        .doc('main')
        .get();

    final data = doc.data() ?? {};
    final kalan = data[field] ?? 0;

    if (kalan <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fullMessage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Üretici Başvurusu',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Sofrasofra’da nasıl yer almak istiyorsunuz?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Başvuru tipinizi seçin. Belgeleriniz ve paneliniz buna göre hazırlanacak.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 26),
                _ChoiceCard(
                  icon: Icons.home_work_rounded,
                  title: 'Ev Lezzetleri Üreticisi',
                  subtitle:
                      'Evde üreten, ikametgah ve gerekli belge kontrolüyle doğrulanan bireysel üreticiler.',
                  bullets: const [
                    'E-devlet imzalı ikametgah ve gerekli başvuru belgeleri',
                    'Şehir / ilçe / mutfak adı',
                    'Onay sonrası Ürün Ekle sayfasına geçiş',
                  ],
                  onTap: () => _openIfQuotaAvailable(
                    context: context,
                    field: 'evKalan',
                    fullMessage: 'Ev Lezzetleri kontenjanı doldu.',
                    page: const EvLezzetleriBasvuruSayfasi(),
                  ),
                ),
                const SizedBox(height: 16),
                _ChoiceCard(
                  icon: Icons.storefront_rounded,
                  title: 'Usta Şef / Restoran',
                  subtitle:
                      'Vergi levhası, IBAN ve işletme bilgileriyle profesyonel kayıt.',
                  bullets: const [
                    'İşletme adı, yetkili kişi, e-posta, WhatsApp',
                    'Vergi levhası ve IBAN',
                    'Onay sonrası şef/restoran yönetim paneli',
                  ],
                  onTap: () => _openIfQuotaAvailable(
                    context: context,
                    field: 'sefKalan',
                    fullMessage: 'Usta Şef kontenjanı doldu.',
                    page: const ProfesyonelIsletmeBasvuruSayfasi(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.onTap,
  });

  static const Color _card = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _border = Color(0x44FFB300);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: Icon(icon, color: _gold, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...bullets.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: _gold,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              b,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: _gold,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
