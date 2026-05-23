import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/cart/sepet_sayfasi.dart';
import 'package:sofrasofra_arena_v2/services/platform_admin_service.dart';
import 'package:sofrasofra_arena_v2/services/restoran_service.dart';
import 'package:sofrasofra_arena_v2/services/sepet_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/restoran_menu_item_model.dart';
import 'models/restoran_model.dart';
import 'widgets/restoran_menu_item_card.dart';
import 'widgets/restoran_status_badge.dart';

class RestoranDetaySayfasi extends StatelessWidget {
  const RestoranDetaySayfasi({
    super.key,
    required this.restaurant,
  });

  final RestoranModel restaurant;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF050505);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'RESTORAN DETAYI',
          style: TextStyle(
            color: _gold,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sepetim',
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: _gold,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SepetSayfasi(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
        children: [
          _CoverSection(restaurant: restaurant),
          const SizedBox(height: 18),
          _InfoSection(restaurant: restaurant),
          const SizedBox(height: 18),
          _LaunchNotice(restaurant: restaurant),
          const SizedBox(height: 18),
          FutureBuilder<bool>(
            future: PlatformAdminService.isCurrentUserPlatformAdmin(),
            builder: (context, snapshot) {
              final isAdmin = snapshot.data == true;

              return _MenuPreviewSection(
                restaurant: restaurant,
                isAdmin: isAdmin,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CoverSection extends StatelessWidget {
  const _CoverSection({required this.restaurant});

  final RestoranModel restaurant;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _gold.withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            restaurant.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF202020),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Colors.white38,
                  size: 54,
                ),
              );
            },
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.80),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const RestoranStatusBadge(
                  label: 'Kurucu Restoran',
                  icon: Icons.workspace_premium,
                  isGold: true,
                ),
                RestoranStatusBadge(
                  label: restaurant.launchStatusText,
                  icon: Icons.lock_clock,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.restaurant});

  final RestoranModel restaurant;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            restaurant.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RestoranStatusBadge(
                label: restaurant.cuisine,
                icon: Icons.local_dining,
              ),
              RestoranStatusBadge(
                label: restaurant.locationText,
                icon: Icons.location_on_outlined,
              ),
              RestoranStatusBadge(
                label: restaurant.serviceText,
                icon: Icons.shopping_bag_outlined,
                isGold: true,
              ),
              RestoranStatusBadge(
                label: restaurant.preparationText,
                icon: Icons.timer_outlined,
              ),
              RestoranStatusBadge(
                label: restaurant.ratingText,
                icon: Icons.star_rounded,
                isGold: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaunchNotice extends StatelessWidget {
  const _LaunchNotice({required this.restaurant});

  final RestoranModel restaurant;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: _gold,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${restaurant.name} için siparişler lansman döneminde aktif edilecek. '
              'Bu sayfa restoran menüsü, servis modeli ve müşteri deneyimi için hazırlık ekranıdır.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.8,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuPreviewSection extends StatelessWidget {
  const _MenuPreviewSection({
    required this.restaurant,
    required this.isAdmin,
  });

  final RestoranModel restaurant;
  final bool isAdmin;

  static const Color _gold = Color(0xFFFFB300);

  List<RestoranMenuItemModel> get _demoItems {
    return [
      RestoranMenuItemModel(
        id: '${restaurant.id}_gunun_corbasi',
        restaurantId: restaurant.id,
        name: 'Günün Çorbası',
        description: 'Restoranın günlük hazırladığı sıcak başlangıç lezzeti.',
        category: 'Çorbalar',
        img: 'https://images.unsplash.com/photo-1547592166-23ac45744acd',
        gelAlFiyat: 80,
        goturFiyat: 95,
        isFeatured: true,
        preparationMinutes: 12,
      ),
      RestoranMenuItemModel(
        id: '${restaurant.id}_izgara_kofte',
        restaurantId: restaurant.id,
        name: 'Izgara Köfte',
        description:
            'Pilav, salata ve günlük garnitür eşliğinde restoran usulü köfte.',
        category: 'Ana Yemekler',
        img: 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba',
        gelAlFiyat: 220,
        goturFiyat: 250,
        preparationMinutes: 25,
      ),
      RestoranMenuItemModel(
        id: '${restaurant.id}_lahmacun',
        restaurantId: restaurant.id,
        name: 'Taş Fırın Lahmacun',
        description:
            'İnce hamur, taze harç ve fırından sıcak çıkan mahalle lezzeti.',
        category: 'Fırın',
        img: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38',
        gelAlFiyat: 90,
        goturFiyat: 110,
        preparationMinutes: 18,
      ),
    ];
  }

  Future<void> _sepeteRestoranUrunuEkle({
    required BuildContext context,
    required RestoranMenuItemModel item,
    required String teslimatTipi,
  }) async {
    final isGotur = teslimatTipi == 'gotur';
    final selectedPrice = isGotur ? item.goturFiyat : item.gelAlFiyat;
    final teslimatLabel = isGotur ? 'Götür' : 'Gel-Al';

    try {
      await SepetService.sepeteEkle(
        urunId: 'restaurant_${restaurant.id}_${item.id}_$teslimatTipi',
        urunAdi: item.name,
        dukkanAdi: restaurant.name,
        kategori: item.category,
        img: item.imageForUi,
        fiyat: selectedPrice,
        gelAlFiyat: item.gelAlFiyat,
        goturFiyat: item.goturFiyat,
        teslimatTipi: teslimatTipi,
        deliveryIncludedInPrice: true,
        feeIncludedInPrice: true,
        saticiId: restaurant.id,
        dukkanId: restaurant.id,
        sellerTypeOverride: 'restaurant',
      );

      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          content: Text(
            '${item.name} $teslimatLabel olarak sepete eklendi.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sepete eklenemedi: $e',
          ),
        ),
      );
    }
  }

  Future<void> _menuFotografiEkle({
    required BuildContext context,
    required RestoranMenuItemModel item,
  }) async {
    final controller = TextEditingController(text: item.imageForUi);

    final imageUrl = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Menü fotoğrafı ekle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Fotoğraf URL adresi',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: _gold),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, controller.text.trim());
              },
              child: const Text(
                'Kaydet',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (imageUrl == null) return;

    final cleanUrl = imageUrl.trim();

    if (cleanUrl.isEmpty) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf URL boş olamaz.'),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('menu_items')
          .doc(item.id)
          .set(
        {
          'img': cleanUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} fotoğrafı güncellendi.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf güncellenemedi: $e'),
        ),
      );
    }
  }

  Future<void> _menuFotografiSil({
    required BuildContext context,
    required RestoranMenuItemModel item,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Fotoğraf silinsin mi?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '${item.name} için kapak fotoğrafı kaldırılacak.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Sil',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('menu_items')
          .doc(item.id)
          .set(
        {
          'img': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} fotoğrafı silindi.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf silinemedi: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isAdmin) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: const Text(
          'Restoran menüsü yakında Sofrasofra’da yayında olacak.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.5,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return StreamBuilder<List<RestoranMenuItemModel>>(
      stream: RestoranService.streamMenuItems(
        restaurantId: restaurant.id,
      ),
      builder: (context, snapshot) {
        final firestoreItems = snapshot.data ?? const <RestoranMenuItemModel>[];
        final items = firestoreItems.isNotEmpty ? firestoreItems : _demoItems;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _gold.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Menü Önizlemesi',
                style: TextStyle(
                  color: _gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bu alan yalnızca platform adminleri tarafından görülür. Restoran menüsü, ürün fiyatları ve lansman öncesi sipariş altyapısı burada test edilecek.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (item) => RestoranMenuItemCard(
                  item: item,
                  canManageMedia: isAdmin,
                  onAddPhotoTap: () async {
                    await _menuFotografiEkle(
                      context: context,
                      item: item,
                    );
                  },
                  onDeletePhotoTap: () async {
                    await _menuFotografiSil(
                      context: context,
                      item: item,
                    );
                  },
                  onGelAlTap: () async {
                    await _sepeteRestoranUrunuEkle(
                      context: context,
                      item: item,
                      teslimatTipi: 'gel_al',
                    );
                  },
                  onGoturTap: () async {
                    await _sepeteRestoranUrunuEkle(
                      context: context,
                      item: item,
                      teslimatTipi: 'gotur',
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
