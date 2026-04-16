import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/admin/chef_profile_admin_page.dart';
import 'package:sofrasofra_arena_v2/admin/kurye_atama_motoru.dart';
import 'package:sofrasofra_arena_v2/admin/kurye_basvurulari.dart';
import 'package:sofrasofra_arena_v2/admin/kurye_harita_merkezi_sayfasi.dart';
import 'package:sofrasofra_arena_v2/admin/kurye_teslim_test_sayfasi.dart';
import 'package:sofrasofra_arena_v2/admin/usta_sef_admin_sayfasi.dart';
import 'package:sofrasofra_arena_v2/merchant/ev_orders_sayfasi.dart';
import 'package:sofrasofra_arena_v2/merchant/teslimat_ayarlar_sayfasi.dart';
import 'package:sofrasofra_arena_v2/merchant/uretici_yonetim_merkezi_sayfasi.dart';
import 'package:sofrasofra_arena_v2/merchant/urun_ekleme_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/chef_table_reservations_page.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_dersleri.dart';
import 'package:sofrasofra_arena_v2/modules/sef_itibar_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/akademi_merkezi.dart';
import 'package:sofrasofra_arena_v2/dev/academy_master_runner.dart';
import 'package:sofrasofra_arena_v2/admin/consulting_requests_admin_page.dart';
import 'package:sofrasofra_arena_v2/modules/sef_marka_kariyer_sayfasi.dart';

class GastronomiYonetimMerkezi extends StatelessWidget {
  final String? chefId;
  final String? chefName;
  final String? sellerId;
  final String? sellerName;

  const GastronomiYonetimMerkezi({
    super.key,
    this.chefId,
    this.chefName,
    this.sellerId,
    this.sellerName,
  });

  static const Color _bg = Color(0xFF090909);
  static const Color _panel = Color(0xFF111111);
  static const Color _panel2 = Color(0xFF171717);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _softText = Color(0xFFBDBDBD);
  static const Color _border = Color(0x22FFFFFF);

  bool _hasChefContext() => (chefId ?? '').trim().isNotEmpty;

  String get _currentChefId => (chefId ?? '').trim();

  String get _currentSellerId {
    final seller = (sellerId ?? '').trim();
    if (seller.isNotEmpty) return seller;
    return _currentChefId;
  }

  String get _heroName {
    final chef = (chefName ?? '').trim();
    if (chef.isNotEmpty) return chef;
    final seller = (sellerName ?? '').trim();
    if (seller.isNotEmpty) return seller;
    return 'Operasyon Merkezi';
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  void _showNeedChef(BuildContext context, String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$moduleName için önce chefId bağlamı ile bu merkeze girilmelidir.',
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNeedSeller(BuildContext context, String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$moduleName için sellerId bağlamı eksik. Bu alanı üretici veya satıcı panelinden aç.',
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openChefProfile(BuildContext context) {
    if (!_hasChefContext()) {
      _showNeedChef(context, 'Şef Profili');
      return;
    }

    _open(
      context,
      ChefProfileAdminPage(chefId: _currentChefId),
    );
  }

  void _openChefPrestige(BuildContext context) {
    if (!_hasChefContext()) {
      _showNeedChef(context, 'Şef İtibar Profili');
      return;
    }

    _open(
      context,
      SefItibarSayfasi(
        dukkanId: _currentChefId,
        isAdmin: true,
      ),
    );
  }

  void _openChefAcademy(BuildContext context) {
    if (!_hasChefContext()) {
      _showNeedChef(context, 'Şef Akademisi');
      return;
    }

    _open(
      context,
      SefAkademiDersleri(
        chefId: _currentChefId,
        chefName:
            (chefName ?? '').trim().isEmpty ? 'Usta Şef' : chefName!.trim(),
      ),
    );
  }

  void _openChefAdmin(BuildContext context) {
    if (!_hasChefContext()) {
      _showNeedChef(context, 'Şef Yönetim Paneli');
      return;
    }

    _open(
      context,
      UstaSefAdminSayfasi(chefId: _currentChefId),
    );
  }

  void _openChefReservations(BuildContext context) {
    _open(
      context,
      const ChefTableReservationsPage(),
    );
  }

  void _openIyzico(BuildContext context) {
    _open(
      context,
      const ChefTableReservationsPage(
        initialFilter: ReservationFilter.awaitingPayment,
      ),
    );
  }

  void _openSignatureKitchen(BuildContext context) {
    if (!_hasChefContext()) {
      _showNeedChef(context, 'İmza Mutfağı');
      return;
    }

    _open(
      context,
      SefItibarSayfasi(
        dukkanId: _currentChefId,
        isAdmin: true,
      ),
    );
  }

  void _openGalleryMedia(BuildContext context) {
    if (!_hasChefContext()) {
      _showNeedChef(context, 'Galeri / Medya');
      return;
    }

    _open(
      context,
      SefItibarSayfasi(
        dukkanId: _currentChefId,
        isAdmin: true,
      ),
    );
  }

  void _openProducerCenter(BuildContext context) {
    _open(context, const UreticiYonetimMerkeziSayfasi());
  }

  void _openEvOrders(BuildContext context) {
    final currentSellerId = _currentSellerId;
    if (currentSellerId.isEmpty) {
      _showNeedSeller(context, 'Ev Siparişleri');
      return;
    }

    _open(
      context,
      EvOrdersSayfasi(sellerId: currentSellerId),
    );
  }

  void _openProductAdd(BuildContext context) {
    _open(context, const UrunEklemeSayfasi());
  }

  void _openDeliverySettings(BuildContext context) {
    _open(context, const TeslimatAyarlariSayfasi());
  }

  void _openCourierApplications(BuildContext context) {
    _open(context, const KuryeBasvurulariSayfasi());
  }

  void _openCourierMap(BuildContext context) {
    _open(context, const KuryeHaritaMerkeziSayfasi());
  }

  void _openCourierAssignment(BuildContext context) {
    _open(context, const KuryeAtamaMotoru());
  }

  void _openCourierDeliveryTest(BuildContext context) {
    _open(context, const KuryeTeslimTestSayfasi());
  }

  void _openPlaceholder(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    _open(
      context,
      _PlaceholderPage(
        title: title,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chefCards = <_DashboardItem>[
      _DashboardItem(
        title: 'Şef Yönetim Paneli',
        subtitle:
            'Şef kayıtları, genel yönetim, içerik düzenleme ve temel operasyon akışları.',
        icon: Icons.dashboard_customize_rounded,
        onTap: () => _openChefAdmin(context),
      ),
      _DashboardItem(
        title: 'Şef Profili',
        subtitle:
            'Headline, uzmanlık alanları, premium görünüm ve profil görselleri.',
        icon: Icons.person_rounded,
        onTap: () => _openChefProfile(context),
      ),
      _DashboardItem(
        title: 'Şef İtibar Profili',
        subtitle:
            'İtibar, vitrin, kapak, profil fotoğrafı, metrik ve güven katmanı.',
        icon: Icons.workspace_premium_rounded,
        onTap: () => _openChefPrestige(context),
      ),
      _DashboardItem(
        title: 'Şef Marka & Kariyer',
        subtitle:
            'Kariyer zaman çizgisi, uzmanlık alanları, ödüller, iş birlikleri ve premium hizmet yüzeyleri.',
        icon: Icons.workspace_premium_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SefMarkaKariyerSayfasi(
                chefName: 'Ahmet Usta',
                isAdmin: true,
              ),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'Şef Akademisi',
        subtitle:
            'Dersler, videolar, kategori akışı ve eğitim mimarisini yönetin.',
        icon: Icons.play_lesson_rounded,
        onTap: () => _openChefAcademy(context),
      ),
      _DashboardItem(
        title: 'Akademi Master Runner',
        subtitle:
            'Akademi kategorilerini seed et, dersleri normalize et, şef profil patch uygula ve danışmanlık test kaydı oluştur.',
        icon: Icons.admin_panel_settings_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AcademyMasterRunnerPage(),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'İmza Mutfağı',
        subtitle:
            'İmza tabaklar, mutfak vitrini ve öne çıkan koleksiyon alanı.',
        icon: Icons.restaurant_menu_rounded,
        onTap: () => _openSignatureKitchen(context),
      ),
      _DashboardItem(
        title: 'Galeri / Medya',
        subtitle:
            'Kapak, galeri, etkinlik görselleri ve sunum materyallerini yönetin.',
        icon: Icons.photo_library_rounded,
        onTap: () => _openGalleryMedia(context),
      ),
      _DashboardItem(
        title: 'Şef Masası / Rezervasyonlar',
        subtitle: 'Rezervasyon onay, red, ödeme ve teyit akışlarını yönetin.',
        icon: Icons.event_seat_rounded,
        onTap: () => _openChefReservations(context),
      ),
      _DashboardItem(
        title: 'Siparişler / İyzico',
        subtitle:
            'Ödeme bekleyen rezervasyonlar, iyzico akışı ve timeout yönetimi.',
        icon: Icons.payments_rounded,
        onTap: () => _openIyzico(context),
      ),
      _DashboardItem(
        title: 'Danışmanlık Talepleri',
        subtitle: 'Gelen danışmanlık taleplerini görüntüle ve yönet.',
        icon: Icons.support_agent_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ConsultingRequestsAdminPage(
                chefId: 'gmRQ6eKx6WZ0fqDDFytHEgi88RH3',
                chefName: 'Ahmet Usta',
              ),
            ),
          );
        },
      ),
    ];

    final evCards = <_DashboardItem>[
      _DashboardItem(
        title: 'Üretici Yönetim Merkezi',
        subtitle:
            'Ev Lezzetleri operasyonunun ana kontrol paneli ve genel yönetim alanı.',
        icon: Icons.storefront_rounded,
        onTap: () => _openProducerCenter(context),
      ),
      _DashboardItem(
        title: 'Ürün Ekle / Düzenle',
        subtitle:
            'Yeni ev ürünü ekleme, fiyat ve içerik yönetimi için hızlı giriş.',
        icon: Icons.add_box_rounded,
        onTap: () => _openProductAdd(context),
      ),
      _DashboardItem(
        title: 'Ev Siparişleri',
        subtitle:
            'Mahalle Mutfağı sipariş akışı, durum takibi ve satış operasyonları.',
        icon: Icons.receipt_long_rounded,
        onTap: () => _openEvOrders(context),
      ),
      _DashboardItem(
        title: 'Teslimat Ayarları',
        subtitle:
            'Teslimat modeli, bölge, süre ve operasyon ayarlarını düzenleyin.',
        icon: Icons.local_shipping_rounded,
        onTap: () => _openDeliverySettings(context),
      ),
      _DashboardItem(
        title: 'Ev Lezzetleri Analitik',
        subtitle:
            'Sipariş hacmi, kategori verimi ve dönüşüm raporları için hazır alan.',
        icon: Icons.insights_rounded,
        onTap: () => _openPlaceholder(
          context,
          title: 'Ev Lezzetleri Analitik',
          description:
              'Bu modül bir sonraki aşamada metrik kartları ve satış içgörüleriyle açılacak.',
        ),
      ),
    ];

    final kuryeCards = <_DashboardItem>[
      _DashboardItem(
        title: 'Kurye Başvuruları',
        subtitle: 'Başvuru havuzu, inceleme, onay ve red süreçlerini yönetin.',
        icon: Icons.assignment_ind_rounded,
        onTap: () => _openCourierApplications(context),
      ),
      _DashboardItem(
        title: 'Kurye Harita Merkezi',
        subtitle:
            'Bölgesel kurye yoğunluğu, lokasyon ve canlı dağılım görünümü.',
        icon: Icons.map_rounded,
        onTap: () => _openCourierMap(context),
      ),
      _DashboardItem(
        title: 'Kurye Atama Motoru',
        subtitle:
            'Siparişe uygun kurye atama, öneri akışı ve operasyon kararı.',
        icon: Icons.route_rounded,
        onTap: () => _openCourierAssignment(context),
      ),
      _DashboardItem(
        title: 'Teslim Operasyon Testi',
        subtitle: 'Teslimat senaryolarını doğrulama ve uçtan uca test ekranı.',
        icon: Icons.fact_check_rounded,
        onTap: () => _openCourierDeliveryTest(context),
      ),
      _DashboardItem(
        title: 'Kurye Operasyon Notları',
        subtitle:
            'Saha prosedürleri, teslim kalite standardı ve süreç notları için hazır modül.',
        icon: Icons.sticky_note_2_rounded,
        onTap: () => _openPlaceholder(
          context,
          title: 'Kurye Operasyon Notları',
          description:
              'Bu alan daha sonra SOP, saha prosedürleri ve eğitim notları için açılacak.',
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Gastronomi Yönetim Merkezi',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final crossAxisCount = width >= 1320
              ? 3
              : width >= 760
                  ? 2
                  : 1;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroPanel(
                        title: 'Tek Merkezden Yönet',
                        subtitle:
                            'Şef, Ev Lezzetleri, sipariş, ödeme ve kurye operasyonlarını aynı merkezden yönet.',
                        badge: _heroName,
                        meta: _buildMetaText(),
                      ),
                      const SizedBox(height: 18),
                      _QuickStatsRow(
                        items: [
                          _StatItem(
                            label: 'Şef Modülü',
                            value: _hasChefContext() ? 'Bağlı' : 'Bekliyor',
                            icon: Icons.person_pin_rounded,
                          ),
                          _StatItem(
                            label: 'Ev Lezzetleri',
                            value:
                                _currentSellerId.isNotEmpty ? 'Bağlı' : 'Hazır',
                            icon: Icons.store_mall_directory_rounded,
                          ),
                          const _StatItem(
                            label: 'Kurye Operasyonu',
                            value: 'Aktif Alan',
                            icon: Icons.delivery_dining_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      _SectionHeader(
                        eyebrow: 'Chef OS',
                        title: 'Şef Operasyonları',
                        subtitle:
                            'Profil, akademi, itibar, rezervasyon ve ödeme süreçleri.',
                      ),
                    ],
                  ),
                ),
              ),
              _SectionGrid(
                items: chefCards,
                crossAxisCount: crossAxisCount,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
                  child: _SectionHeader(
                    eyebrow: 'Mahalle Mutfağı',
                    title: 'Ev Lezzetleri Operasyonları',
                    subtitle:
                        'Üretici paneli, ürün yönetimi, sipariş takibi ve teslimat ayarları.',
                  ),
                ),
              ),
              _SectionGrid(
                items: evCards,
                crossAxisCount: crossAxisCount,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 10),
                  child: _SectionHeader(
                    eyebrow: 'Lojistik Katmanı',
                    title: 'Kurye Operasyonları',
                    subtitle:
                        'Başvuru, harita, atama ve teslim kalite kontrol süreçleri.',
                  ),
                ),
              ),
              _SectionGrid(
                items: kuryeCards,
                crossAxisCount: crossAxisCount,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 26, 16, 28),
                  child: _BottomInfoCard(
                    title: 'Operasyon Mimarisi Doğru Kuruldu',
                    body:
                        'Müşteri vitrini ayrı, yönetim merkezi ayrı çalışır. Bu sayfa artık yönetim çekirdeği; ürünün arka ofisini tek bir merkeze toplar.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _buildMetaText() {
    final chef = _currentChefId;
    final seller = _currentSellerId;

    if (chef.isEmpty && seller.isEmpty) {
      return 'Henüz bağlam seçilmedi';
    }

    final parts = <String>[
      if (chef.isNotEmpty) 'chefId: $chef',
      if (seller.isNotEmpty) 'sellerId: $seller',
    ];

    return parts.join('  •  ');
  }
}

class _SectionGrid extends StatelessWidget {
  final List<_DashboardItem> items;
  final int crossAxisCount;

  const _SectionGrid({
    required this.items,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _DashboardCard(item: items[index]),
          childCount: items.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: crossAxisCount == 1 ? 1.55 : 1.18,
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final String meta;

  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.meta,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF171717),
            Color(0xFF111111),
            Color(0xFF1A1A1A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0x33FFB300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _gold.withValues(alpha: 0.32)),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: _gold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            meta,
            style: const TextStyle(
              color: Color(0xFFFFE0A3),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final List<_StatItem> items;

  const _QuickStatsRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => _MiniStatCard(item: item),
          )
          .toList(),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final _StatItem item;

  const _MiniStatCard({required this.item});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: _gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.eyebrow,
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
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFFBDBDBD),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _BottomInfoCard extends StatelessWidget {
  final String title;
  final String body;

  const _BottomInfoCard({
    required this.title,
    required this.body,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.hub_rounded, color: _gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.55,
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

class _DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;

  const _DashboardCard({required this.item});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x22FFFFFF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _gold.withValues(alpha: 0.20)),
                  ),
                  child: Icon(item.icon, color: _gold, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.8,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Text(
                      'Modülü Aç',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: _gold,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String description;

  const _PlaceholderPage({
    required this.title,
    required this.description,
  });

  static const Color _bg = Color(0xFF090909);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: Text(
          title,
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.auto_awesome, color: _gold, size: 32),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.55,
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
