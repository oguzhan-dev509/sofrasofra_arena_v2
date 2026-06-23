import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../admin/admin_paneli_sayfasi.dart';

import '../modules/akademi_merkezi.dart';
import '../modules/kurye_basvuru_merkezi.dart';

import 'ev_orders_sayfasi.dart';
import 'package:sofrasofra_arena_v2/merchant/urun_ekleme_sayfasi_v2.dart';
import 'satici_siparis_paneli.dart';
import 'sef_yonetim_paneli.dart';
import 'teslimat_ayarlar_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/ev_membership_card.dart';
import 'package:sofrasofra_arena_v2/courier/kurye_mobil_paneli.dart';
import 'package:sofrasofra_arena_v2/modules/restoranlar/restoran_yonetim_paneli.dart';
import 'package:sofrasofra_arena_v2/modules/restoranlar/restoranlarim_sayfasi.dart';
import 'ev_fisler_sayfasi.dart';

class UreticiYonetimMerkeziSayfasi extends StatelessWidget {
  const UreticiYonetimMerkeziSayfasi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _panel = Color(0xFF151515);

  static const Color _gold = Color(0xFFFFD54F);
  static const Color _muted = Color(0xFFB9B2A6);
// ignore: unused_field
  static const String _chefId = 'RhkyTCD5TgWJFdEzP50mvCOrz5a2';
  static const String _chefName = 'Feride Lokman';
  // ignore: unused_field
  static const String _demoOrderId = 'demo-order-id';
  // ignore: unused_field
  static const String _sellerId = 'zeynep_ev_lezzetleri';
  Future<String> _resolveOperationalSellerId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';

    if (uid.isEmpty) {
      return _sellerId;
    }

    try {
      final sellerDoc =
          await FirebaseFirestore.instance.collection('sellers').doc(uid).get();

      final data = sellerDoc.data() ?? <String, dynamic>{};

      final resolvedSellerId = (data['dukkanId'] ??
              data['operationalSellerId'] ??
              data['sellerId'] ??
              '')
          .toString()
          .trim();

      if (resolvedSellerId.isNotEmpty) {
        return resolvedSellerId;
      }
    } catch (error) {
      debugPrint(
        'ÜRETİCİ SELLER ID ÇÖZÜMLEME HATASI uid=$uid error=$error',
      );
    }

    return _sellerId;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 1280
        ? 3
        : width >= 820
            ? 2
            : 1;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'ÜRETİCİ YÖNETİM MERKEZİ',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _panel,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: _gold.withValues(alpha: 0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SOFRASOFRA OPERASYON OMURGASI',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tüm üretici, sipariş, kurye, arşiv ve admin akışları için tek merkez.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'İlk sürümde doğrulanmış paneller güvenle bağlanır. Yeni modüller bu omurgaya sırayla eklenir.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SefYonetimPaneli(
                                dukkanAdi: _chefName,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.dashboard_customize_rounded),
                        label: const Text(
                          'Şef Panelini Aç',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Bu merkez modüler olarak büyütülecek.',
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _gold,
                          side:
                              BorderSide(color: _gold.withValues(alpha: 0.30)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.hub_rounded),
                        label: const Text('Kazanımları Koru'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const EvMembershipCard(),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: width >= 820 ? 1.22 : 0.98,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _HubCard(
                  title: 'Üretici Panelleri',
                  badge: 'AKTİF',
                  icon: Icons.storefront_rounded,
                  description:
                      'Şef, itibar ve restoran panellerini tek yerde toplayan ana üretici alanı.',
                  items: const [
                    'Şef Yönetim Paneli',
                    'Şef İtibar Profili',
                    'Restoran Yönetimi',
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UreticiPanelleriSayfasi(
                          chefId: _chefId,
                          chefName: _chefName,
                        ),
                      ),
                    );
                  },
                ),
                _HubCard(
                  title: 'Sipariş & Teslimat',
                  badge: 'AKTİF',
                  icon: Icons.local_shipping_rounded,
                  description:
                      'Satıcı sipariş paneli, ev siparişleri ve teslimat ayarlarının operasyon merkezi.',
                  items: const [
                    'Satıcı Siparişleri',
                    'Ev Siparişleri',
                    'Teslimat Ayarları',
                  ],
                  onTap: () async {
                    final resolvedSellerId =
                        await _resolveOperationalSellerId();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SiparisTeslimatMerkeziSayfasi(
                          sellerId: resolvedSellerId,
                        ),
                      ),
                    );
                  },
                ),
                _HubCard(
                  title: 'Kurye & Saha',
                  badge: 'AKTİF',
                  icon: Icons.delivery_dining_rounded,
                  description:
                      'Kurye paneli ve başvuru merkezi ile teslimat sahasını tek noktadan yönet.',
                  items: const [
                    'Kurye Paneli',
                    'Kurye Başvuru Merkezi',
                    'Saha operasyonu',
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KuryeSahaMerkeziSayfasi(),
                      ),
                    );
                  },
                ),
                _HubCard(
                  title: 'Üye & Kurye Arşivi',
                  badge: 'HAZIRLIK',
                  icon: Icons.inventory_2_rounded,
                  description:
                      'Arşiv, belge, statü, denetim izi ve geçmiş kayıtlar için omurga alanı.',
                  items: const [
                    'Üye geçmişi',
                    'Kurye kayıtları',
                    'Denetim izi',
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UyeKuryeArsivMerkeziSayfasi(),
                      ),
                    );
                  },
                ),
                _HubCard(
                  title: 'Admin & İçerik',
                  badge: 'AKTİF',
                  icon: Icons.admin_panel_settings_rounded,
                  description:
                      'Admin paneli, usta şef admin akışı ve üst düzey içerik yönetim alanı.',
                  items: const [
                    'Admin Paneli',
                    'Usta Şef Admin',
                    'İçerik yönetimi',
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminMerkeziSayfasi(),
                      ),
                    );
                  },
                ),
                _HubCard(
                  title: 'Akademi & AI Görev',
                  badge: 'GENİŞLEYECEK',
                  icon: Icons.memory_rounded,
                  description:
                      'Akademi merkezi bugün, AI görev merkezi ise yarının operasyon katmanı.',
                  items: const [
                    'Akademi Merkezi',
                    'AI görev omurgası',
                    'Log & öneriler',
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AkademiAIMerkeziSayfasi(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UreticiPanelleriSayfasi extends StatelessWidget {
  final String chefId;
  final String chefName;

  const UreticiPanelleriSayfasi({
    super.key,
    required this.chefId,
    required this.chefName,
  });

  @override
  Widget build(BuildContext context) {
    return const _PanelShell(
      title: 'ÜRETİCİ PANELLERİ',
      subtitle: 'Güvenli çalışan üretici panelleri',
      cards: [
        _PanelItemData(
          title: 'Şef Yönetim Paneli',
          subtitle: 'Profil, kapak, galeri ve üretici yönetimi.',
          icon: Icons.badge_rounded,
          pageType: _PanelPageType.sefYonetim,
        ),
        _PanelItemData(
          title: 'Şef İtibar Profili',
          subtitle: 'Vitrin, güven, itibar ve hızlı erişim alanları.',
          icon: Icons.workspace_premium_rounded,
          pageType: _PanelPageType.sefItibar,
        ),
        _PanelItemData(
          title: 'Restoran Yönetim Paneli',
          subtitle: 'Restoran operasyonu ve yönetim akışı.',
          icon: Icons.restaurant_menu_rounded,
          pageType: _PanelPageType.restoran,
        ),
        _PanelItemData(
          title: 'Mahalle Mutfağı Vitrini',
          subtitle: 'Ürün ekle, fotoğraf yükle, vitrini düzenle',
          icon: Icons.storefront_rounded,
          pageType: _PanelPageType.vitrinDuzenle,
        ),
      ],
    );
  }
}

class SiparisTeslimatMerkeziSayfasi extends StatelessWidget {
  final String sellerId;

  const SiparisTeslimatMerkeziSayfasi({
    super.key,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    return _PanelShell(
      sellerId: sellerId,
      title: 'SİPARİŞ & TESLİMAT',
      subtitle: 'Sipariş ve teslimat operasyonu',
      cards: const [
        _PanelItemData(
          title: 'Satıcı Sipariş Paneli',
          subtitle: 'Onay, red, hazırlık ve sipariş yönetimi.',
          icon: Icons.receipt_long_rounded,
          pageType: _PanelPageType.saticiSiparis,
        ),
        _PanelItemData(
          title: 'Ev Siparişleri',
          subtitle: 'Ev lezzetleri sipariş akışı ve ekranı.',
          icon: Icons.home_work_rounded,
          pageType: _PanelPageType.evOrders,
        ),
        _PanelItemData(
          title: 'Teslimat Ayarları',
          subtitle: 'Teslimat yapılandırması ve operasyon tercihi.',
          icon: Icons.tune_rounded,
          pageType: _PanelPageType.teslimatAyarlari,
        ),
      ],
    );
  }
}

class KuryeSahaMerkeziSayfasi extends StatelessWidget {
  const KuryeSahaMerkeziSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PanelShell(
      title: 'KURYE & SAHA',
      subtitle: 'Kurye operasyonu ve saha yönetimi',
      cards: [
        _PanelItemData(
          title: 'Kurye Paneli',
          subtitle: 'Kurye tarafı operasyon ve görev akışı.',
          icon: Icons.delivery_dining_rounded,
          pageType: _PanelPageType.kuryePaneli,
        ),
        _PanelItemData(
          title: 'Kurye Başvuru Merkezi',
          subtitle: 'Kurye başvuru ve değerlendirme alanı.',
          icon: Icons.assignment_ind_rounded,
          pageType: _PanelPageType.kuryeBasvuru,
        ),
        _PanelItemData(
          title: 'Kurye Arşivi',
          subtitle: 'İleride belge, statü ve geçmiş kayıt merkezi.',
          icon: Icons.inventory_rounded,
          pageType: _PanelPageType.placeholder,
        ),
      ],
    );
  }
}

class UyeKuryeArsivMerkeziSayfasi extends StatelessWidget {
  const UyeKuryeArsivMerkeziSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderShell(
      title: 'ÜYE & KURYE ARŞİV MERKEZİ',
      description:
          'Üye geçmişi, kurye kayıtları, belge yönetimi, statü arşivi ve denetim izi burada toplanacak.',
    );
  }
}

class AdminMerkeziSayfasi extends StatelessWidget {
  const AdminMerkeziSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PanelShell(
      title: 'ADMIN & İÇERİK',
      subtitle: 'Üst düzey yönetim panelleri',
      cards: [
        _PanelItemData(
          title: 'Admin Paneli',
          subtitle: 'Genel yönetim ve içerik kontrol alanı.',
          icon: Icons.admin_panel_settings_rounded,
          pageType: _PanelPageType.adminPaneli,
        ),
        _PanelItemData(
          title: 'Usta Şef Admin',
          subtitle: 'Bu modül kendi iç hatası giderilince yeniden bağlanacak.',
          icon: Icons.stars_rounded,
          pageType: _PanelPageType.placeholder,
        ),
      ],
    );
  }
}

class AkademiAIMerkeziSayfasi extends StatelessWidget {
  const AkademiAIMerkeziSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return const _PanelShell(
      title: 'AKADEMİ & AI GÖREV',
      subtitle: 'Bugünün akademisi, yarının AI omurgası',
      cards: [
        _PanelItemData(
          title: 'Akademi Merkezi',
          subtitle: 'Dersler, içerikler ve eğitim akışı.',
          icon: Icons.school_rounded,
          pageType: _PanelPageType.akademi,
        ),
        _PanelItemData(
          title: 'AI Görev Merkezi',
          subtitle: 'Ajan görevleri, log ve karar akışı için hazırlık alanı.',
          icon: Icons.memory_rounded,
          pageType: _PanelPageType.placeholder,
        ),
      ],
    );
  }
}

enum _PanelPageType {
  sefYonetim,
  sefItibar,
  restoran,
  saticiSiparis,
  evOrders,
  teslimatAyarlari,
  kuryePaneli,
  kuryeBasvuru,
  adminPaneli,
  akademi,
  placeholder,

  vitrinDuzenle, // 🔥 BURAYA EKLE
}

class _PanelItemData {
  final String title;
  final String subtitle;
  final IconData icon;
  final _PanelPageType pageType;

  const _PanelItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.pageType,
  });
}

class _PanelShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_PanelItemData> cards;
  final String sellerId;

  const _PanelShell({
    required this.title,
    required this.subtitle,
    required this.cards,
    this.sellerId = '',
  });

  static const Color _bg = Color(0xFF090909);

  static const Color _gold = Color(0xFFFFD54F);
  static const Color _muted = Color(0xFFB9B2A6);
  // ignore: unused_field
  static const String _chefId = 'RhkyTCD5TgWJFdEzP50mvCOrz5a2';
  static const String _chefName = 'Feride Lokman';
  static const String _sellerId = 'zeynep_ev_lezzetleri';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: Text(
          title,
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: _muted,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 24),
          ...cards.map(
            (item) => _MiniPanelCard(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.icon,
              onTap: () {
                switch (item.pageType) {
                  case _PanelPageType.sefYonetim:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SefYonetimPaneli(
                          dukkanAdi: _chefName,
                        ),
                      ),
                    );
                    break;
                  case _PanelPageType.sefItibar:
                    break;
                  case _PanelPageType.restoran:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RestoranlarimSayfasi(),
                      ),
                    );
                    break;
                  case _PanelPageType.saticiSiparis:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SaticiSiparisPaneli(
                          sellerId: 'RhkyTCD5TgWJFdEzP50mvCOrz5a2',
                        ),
                      ),
                    );
                    break;

                  case _PanelPageType.evOrders:
                    final effectiveSellerId = sellerId.trim().isNotEmpty
                        ? sellerId.trim()
                        : _sellerId;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EvFislerSayfasi(
                          sellerId: effectiveSellerId,
                          sellerName: 'Zeynep Ev Lezzetleri',
                        ),
                      ),
                    );
                    break;
                  case _PanelPageType.teslimatAyarlari:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeslimatAyarlariSayfasi(),
                      ),
                    );
                    break;
                  case _PanelPageType.kuryePaneli:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KuryeMobilPaneli(),
                      ),
                    );
                    break;
                  case _PanelPageType.kuryeBasvuru:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KuryeBasvuruMerkeziSayfasi(),
                      ),
                    );
                    break;
                  case _PanelPageType.adminPaneli:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPaneliSayfasi(),
                      ),
                    );
                    break;
                  case _PanelPageType.vitrinDuzenle:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UrunEklemeSayfasiV2(),
                      ),
                    );
                    break;
                  case _PanelPageType.akademi:
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AkademiMerkeziSayfasi(),
                      ),
                    );
                    break;
                  case _PanelPageType.placeholder:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${item.title} bu merkez altında sırayla açılacak.'),
                      ),
                    );
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderShell extends StatelessWidget {
  final String title;
  final String description;

  const _PlaceholderShell({
    required this.title,
    required this.description,
  });

  static const Color _bg = Color(0xFF090909);
  static const Color _panel = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _muted = Color(0xFFB9B2A6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: Text(
          title,
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 760),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _gold.withValues(alpha: 0.18)),
          ),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 18,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final String title;
  final String badge;
  final IconData icon;
  final String description;
  final List<String> items;
  final VoidCallback onTap;

  const _HubCard({
    required this.title,
    required this.badge,
    required this.icon,
    required this.description,
    required this.items,
    required this.onTap,
  });

  static const Color _panel = Color(0xFF151515);
  static const Color _panelSoft = Color(0xFF1D1D1D);
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _muted = Color(0xFFB9B2A6);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _gold.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _panelSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: _gold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _gold.withValues(alpha: 0.22)),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                color: _muted,
                fontSize: 14,
                height: 1.55,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: const [
                Text(
                  'Modülü Aç',
                  style: TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, color: _gold, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPanelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniPanelCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  static const Color _panel = Color(0xFF161616);
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _muted = Color(0xFFB9B2A6);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _gold.withValues(alpha: 0.16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: _gold),
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
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: _muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _gold,
                    size: 28,
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
