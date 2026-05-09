import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/ev_lezzetleri_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/sef_vitrini_v2.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/restoranlar_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/radyo/radyo_merkezi_sayfasi.dart';
import 'package:sofrasofra_arena_v2/onboarding/kurye_basvuru_sayfasi.dart';
import 'package:sofrasofra_arena_v2/onboarding/ev_lezzetleri_basvuru_sayfasi.dart';
import 'package:sofrasofra_arena_v2/onboarding/profesyonel_isletme_basvuru_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/kurumsal/sofrasofra_hukuki_index_sayfasi.dart';

class KurumsalFooterLinks extends StatelessWidget {
  const KurumsalFooterLinks({super.key});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _panel = Color(0xFF151515);
  static const Color _muted = Color(0xFFBDBDBD);

  void _showSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kurumsal bağlantılar çok yakında yayında olacak.'),
      ),
    );
  }

  void _openPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sofrasofra',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Evde pişen emek, mahallede değer bulur.',
            style: TextStyle(
              color: _gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          _FooterGroup(
            title: 'Platform',
            items: const [
              'Ev Lezzetleri',
              'Usta Şefler',
              'Restoranlar',
              'Kurye Ağı',
              'Mahalle Mutfak Ağı',
              'Sofrasofra Radyo',
              'Blog ve Rehberler',
              'Kurumsal Site',
            ],
            onTap: () => _showSoon(context),
            itemActions: {
              'Ev Lezzetleri': () => _openPage(
                    context,
                    const EvLezzetleriVitrini(
                      city: 'İstanbul',
                      district: 'Tümü',
                    ),
                  ),
              'Usta Şefler': () => _openPage(
                    context,
                    const SefVitriniV2(),
                  ),
              'Restoranlar': () => _openPage(
                    context,
                    const RestoranlarVitrini(),
                  ),
              'Sofrasofra Radyo': () => _openPage(
                    context,
                    const RadyoMerkeziSayfasi(),
                  ),
            },
          ),
          const SizedBox(height: 14),
          _FooterGroup(
            title: 'İş Ortağımız Olun',
            items: const [
              'Ev Lezzetleri Üreticisi Ol',
              'Usta Şef Olarak Katıl',
              'Restoran / İşletme Başvurusu',
              'Kurye Ağına Katıl',
              'Mahalle Mutfak Koçu Ol',
            ],
            onTap: () => _showSoon(context),
            itemActions: {
              'Ev Lezzetleri Üreticisi Ol': () => _openPage(
                    context,
                    const EvLezzetleriBasvuruSayfasi(),
                  ),
              'Usta Şef Olarak Katıl': () => _openPage(
                    context,
                    const ProfesyonelIsletmeBasvuruSayfasi(),
                  ),
              'Restoran / İşletme Başvurusu': () => _openPage(
                    context,
                    const ProfesyonelIsletmeBasvuruSayfasi(),
                  ),
              'Kurye Ağına Katıl': () => _openPage(
                    context,
                    const KuryeBasvuruSayfasi(),
                  ),
            },
          ),
          const SizedBox(height: 14),
          _FooterGroup(
            title: 'Yardım',
            items: const [
              'Sık Sorulan Sorular',
              'Sipariş ve Teslimat',
              'Üretici Destek',
              'Kurye Destek',
            ],
            onTap: () => _showSoon(context),
          ),
          const SizedBox(height: 14),
          _FooterGroup(
            title: 'Hukuki',
            items: const [
              'Tüm Hukuki Metinler',
              'KVKK Aydınlatma Metni',
              'Gizlilik Politikası',
              'Kullanım Koşulları',
              'Mesafeli Satış Sözleşmesi',
              'İptal ve İade Politikası',
            ],
            onTap: () => _openPage(
              context,
              const SofrasofraHukukiIndexSayfasi(),
            ),
            itemActions: {
              'Tüm Hukuki Metinler': () => _openPage(
                    context,
                    const SofrasofraHukukiIndexSayfasi(),
                  ),
              'KVKK Aydınlatma Metni': () => _openPage(
                    context,
                    const SofrasofraHukukiIndexSayfasi(),
                  ),
              'Gizlilik Politikası': () => _openPage(
                    context,
                    const SofrasofraHukukiIndexSayfasi(),
                  ),
              'Kullanım Koşulları': () => _openPage(
                    context,
                    const SofrasofraHukukiIndexSayfasi(),
                  ),
              'Mesafeli Satış Sözleşmesi': () => _openPage(
                    context,
                    const SofrasofraHukukiIndexSayfasi(),
                  ),
              'İptal ve İade Politikası': () => _openPage(
                    context,
                    const SofrasofraHukukiIndexSayfasi(),
                  ),
            },
          ),
          const SizedBox(height: 16),
          const _ContactInfoBlock(),
          const SizedBox(height: 18),
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
          ),
          const SizedBox(height: 14),
          const Text(
            '© Sofrasofra.com',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterGroup extends StatelessWidget {
  final String title;
  final List<String> items;
  final VoidCallback onTap;
  final Map<String, VoidCallback>? itemActions;

  const _FooterGroup({
    required this.title,
    required this.items,
    required this.onTap,
    this.itemActions,
  });

  static const Color _gold = Color(0xFFFFB300);
  // ignore: unused_field
  static const Color _muted = Color(0xFFCCCCCC);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: _gold,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            return InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: itemActions?[item] ?? onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.045),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Text(
                  item,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ContactInfoBlock extends StatelessWidget {
  const _ContactInfoBlock();

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İLETİŞİM VE KURUMSAL BİLGİLER',
            style: TextStyle(
              color: _gold,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 10),
          _ContactLine(
            label: 'Şirket Unvanı',
            value: 'UYBAT TEKNOLOJİ YAZILIM VE TİCARET LİMİTED ŞİRKETİ',
          ),
          SizedBox(height: 7),
          _ContactLine(
            label: 'Ticaret Sicil No',
            value: '1096741',
          ),
          SizedBox(height: 7),
          _ContactLine(
            label: 'MERSİS No',
            value: '0898132285200001',
          ),
          SizedBox(height: 7),
          _ContactLine(
            label: 'Adres',
            value:
                'Abdurrahman Nafiz Gürman Mahallesi, Kınalıtepe Sokak, Simitaş 8 Blok, No: 1, İç Kapı No: 311, Güngören / İstanbul',
          ),
          SizedBox(height: 7),
          _ContactLine(
            label: 'E-posta',
            value: 'info@sofrasofra.com',
          ),
          SizedBox(height: 7),
          _ContactLine(
            label: 'WhatsApp Hattı',
            value: '+90 533 322 13 24',
          ),
          SizedBox(height: 7),
          _ContactLine(
            label: 'Destek Hattı',
            value: 'Yayın öncesi ayrıca duyurulacaktır.',
          ),
          SizedBox(height: 7),
          _ContactLine(
            label: 'Web',
            value: 'www.sofrasofra.com',
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final String label;
  final String value;

  const _ContactLine({
    required this.label,
    required this.value,
  });

  static const Color _muted = Color(0xFFCCCCCC);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
