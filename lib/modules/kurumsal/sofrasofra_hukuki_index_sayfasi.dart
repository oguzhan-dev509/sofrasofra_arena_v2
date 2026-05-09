import 'package:flutter/material.dart';

import 'sofrasofra_hukuki_detay_sayfasi.dart';
import 'sofrasofra_hukuki_metinler.dart';

class SofrasofraHukukiIndexSayfasi extends StatelessWidget {
  const SofrasofraHukukiIndexSayfasi({super.key});

  static const Color _bg = Color(0xFF0E0E0E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Hukuki Metinler',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            _HeaderBlock(),
            const SizedBox(height: 18),
            ...sofrasofraHukukiMetinler.map(
              (metin) => _LegalCard(metin: metin),
            ),
            const SizedBox(height: 24),
            const _CompanyInfoBlock(),
          ],
        ),
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  static const Color _gold = Color(0xFFFFB300);
  static const Color _textMuted = Color(0xFFB8B8B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: _gold,
            size: 30,
          ),
          SizedBox(height: 12),
          Text(
            'Sofrasofra Hukuki Merkezi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gizlilik, KVKK, kullanım koşulları, satış sözleşmeleri, başvuru ve iş ortaklığı metinleri bu alanda yer alır.',
            style: TextStyle(
              color: _textMuted,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalCard extends StatelessWidget {
  final SofrasofraHukukiMetin metin;

  const _LegalCard({
    required this.metin,
  });

  static const Color _card = Color(0xFF171717);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _textMuted = Color(0xFFB8B8B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SofrasofraHukukiDetaySayfasi(
                  metin: metin,
                ),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: _gold,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metin.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          metin.summary,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: 25,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanyInfoBlock extends StatelessWidget {
  const _CompanyInfoBlock();

  static const Color _textMuted = Color(0xFFB8B8B8);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: 0.25),
        ),
      ),
      child: const Text(
        'UYBAT TEKNOLOJİ YAZILIM VE TİCARET LİMİTED ŞİRKETİ\n'
        'Web: www.sofrasofra.com\n'
        'E-posta: info@sofrasofra.com\n'
        'WhatsApp: +90 533 322 13 24\n'
        'Adres: Abdurrahman Nafiz Gürman Mahallesi, Kınalıtepe Sokak, '
        'Simitaş 8 Blok No: 1, İç Kapı No: 311, Güngören / İstanbul',
        style: TextStyle(
          color: _textMuted,
          fontSize: 12.2,
          height: 1.55,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
