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
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sofrasofra_arena_v2/modules/restoranlar/restoran_siparis_yonetimi_sayfasi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/restaurant_product_stock.dart';

class RestoranDetaySayfasi extends StatelessWidget {
  const RestoranDetaySayfasi({
    super.key,
    required this.restaurant,
    this.managementMode = false,
  });

  final RestoranModel restaurant;
  final bool managementMode;

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
                  builder: (_) => RestoranSiparisYonetimiSayfasi(
                    restaurantId: restaurant.id,
                    restaurantName: restaurant.name,
                  ),
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
          const SizedBox(height: 12),
          _RestaurantTitleStrip(restaurant: restaurant),
          const SizedBox(height: 14),
          FutureBuilder<bool>(
            future: PlatformAdminService.isCurrentUserPlatformAdmin(),
            builder: (context, snapshot) {
              final canManage = managementMode || snapshot.data == true;

              return _MenuPreviewSection(
                restaurant: restaurant,
                isAdmin: canManage,
              );
            },
          ),
          const SizedBox(height: 18),
          _InfoSection(restaurant: restaurant),
          const SizedBox(height: 18),
          _LaunchNotice(restaurant: restaurant),
          const SizedBox(height: 18),
          _RestaurantReviewsPlaceholder(restaurantId: restaurant.id),
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
      height: 155,
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
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF05080D),
                    Color(0xFF071018),
                    Color(0xFF101820),
                  ],
                ),
              ),
            ),
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

class _RestaurantTitleStrip extends StatelessWidget {
  const _RestaurantTitleStrip({required this.restaurant});

  final RestoranModel restaurant;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: 0.20),
        ),
      ),
      child: Text(
        restaurant.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          height: 1.10,
          fontWeight: FontWeight.w900,
        ),
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

class _RestaurantReviewsPlaceholder extends StatefulWidget {
  const _RestaurantReviewsPlaceholder({
    required this.restaurantId,
  });

  final String restaurantId;

  @override
  State<_RestaurantReviewsPlaceholder> createState() =>
      _RestaurantReviewsPlaceholderState();
}

class _RestaurantReviewsPlaceholderState
    extends State<_RestaurantReviewsPlaceholder> {
  static const Color _gold = Color(0xFFFFB300);

  final TextEditingController _commentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen yorumunuzu yazın.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .collection('reviews')
          .add({
        'comment': comment,
        'status': 'pending',
        'source': 'restaurant_detail_page',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorumunuz alındı. İnceleme sonrası yayınlanacaktır.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yorum kaydedilemedi: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.20),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 6,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          iconColor: _gold,
          collapsedIconColor: _gold,
          initiallyExpanded: false,
          leading: const Icon(
            Icons.reviews_outlined,
            color: _gold,
            size: 22,
          ),
          title: const Text(
            'Restoran Yorumları',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Yorum yazmak ve yorumları görmek için tıklayın.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            const Text(
              'Müşteri yorumları bu alanda görünecek. İlk fazda restoran deneyimi ve ürün memnuniyeti yorumları burada yayınlanacaktır.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13.8,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Bu restoran hakkındaki yorumunuzu yazın...',
                hintStyle: const TextStyle(
                  color: Colors.white38,
                  fontSize: 13.5,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.045),
                contentPadding: const EdgeInsets.all(14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _gold,
                    width: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSaving ? null : _saveReview,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _gold,
                        ),
                      )
                    : const Icon(
                        Icons.send_outlined,
                        size: 18,
                        color: _gold,
                      ),
                label: Text(
                  _isSaving ? 'Kaydediliyor...' : 'Yorumu Gönder',
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _gold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              child: const Text(
                'Henüz yayınlanmış yorum yok. İlk müşteri yorumları inceleme sonrası burada görünecek.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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

  Future<bool> _showSingleSellerCartDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Sepetinde başka bir mutfak var',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Aynı anda yalnızca tek mutfaktan sipariş verebilirsin. '
            'Devam etmek için mevcut sepeti temizleyelim mi?',
            style: TextStyle(
              color: Colors.white70,
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'Temizle ve Ekle',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  Future<void> _clearCurrentUserCart() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    final sepetRef =
        FirebaseFirestore.instance.collection('sepetler').doc(user.uid);

    final itemsSnap = await sepetRef.collection('items').get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in itemsSnap.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(sepetRef);

    await batch.commit();
  }

  Future<void> _sepeteRestoranUrunuEkle({
    required BuildContext context,
    required RestoranMenuItemModel item,
    required String teslimatTipi,
    String? imageUrl,
  }) async {
    final restaurantSnapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurant.id)
        .get();

    final latestRestaurant = restaurantSnapshot.exists
        ? RestoranModel.fromMap(
            restaurantSnapshot.id,
            restaurantSnapshot.data() ?? const <String, dynamic>{},
          )
        : restaurant;

    if (!latestRestaurant.isEffectivelyOpen) {
      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Bu restoran şu anda sipariş almıyor: '
            '${latestRestaurant.effectiveStatusText}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

      return;
    }
    final itemSnapshot = await FirebaseFirestore.instance
        .collection('restaurants')
        .doc(restaurant.id)
        .collection('menu_items')
        .doc(item.id)
        .get();

    final latestItem = itemSnapshot.exists
        ? RestoranMenuItemModel.fromMap(
            itemSnapshot.id,
            itemSnapshot.data() ?? const <String, dynamic>{},
          )
        : item;

    if (!latestItem.canOrder) {
      if (!context.mounted) return;

      final messenger = ScaffoldMessenger.of(context);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            '${latestItem.name} şu anda siparişe açık değil: '
            '${latestItem.availabilityText}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

      return;
    }

    final isGotur = teslimatTipi == 'gotur';
    final effectiveImageUrl = imageUrl?.trim().isNotEmpty == true
        ? imageUrl!.trim()
        : latestItem.imageForUi;

    final effectiveGelAlFiyat = effectiveImageUrl.isNotEmpty
        ? latestItem.gelAlFiyatForImage(effectiveImageUrl)
        : latestItem.gelAlFiyat;

    final effectiveGoturFiyat = effectiveImageUrl.isNotEmpty
        ? latestItem.goturFiyatForImage(effectiveImageUrl)
        : latestItem.goturFiyat;

    final selectedPrice = isGotur ? effectiveGoturFiyat : effectiveGelAlFiyat;
    final teslimatLabel = isGotur ? 'Götür' : 'Gel-Al';

    try {
      await SepetService.sepeteEkle(
        urunId:
            'restaurant_${restaurant.id}_${item.id}_${RestoranMenuItemModel.galleryImageKey(effectiveImageUrl)}_$teslimatTipi',
        urunAdi: latestItem.name,
        dukkanAdi: restaurant.name,
        kategori: latestItem.category,
        img: effectiveImageUrl,
        fiyat: selectedPrice,
        gelAlFiyat: effectiveGelAlFiyat,
        goturFiyat: effectiveGoturFiyat,
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
          content: Text(
            '${latestItem.name} sepete eklendi. ($teslimatLabel)',
          ),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SepetSayfasi(),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('RESTORAN SEPET EKLE ERROR => $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      final errorText = error.toString();

      if (errorText.contains('tek satıcıdan')) {
        final shouldClearCart = await _showSingleSellerCartDialog(context);

        if (!context.mounted) return;

        if (shouldClearCart) {
          try {
            await _clearCurrentUserCart();

            if (!context.mounted) return;

            await _sepeteRestoranUrunuEkle(
              context: context,
              item: item,
              teslimatTipi: teslimatTipi,
              imageUrl: imageUrl,
            );
          } catch (clearError) {
            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sepet temizlenemedi: $clearError'),
              ),
            );
          }
        }

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ürün sepete eklenemedi: $error'),
        ),
      );
    }
  }

  Future<void> _menuFotografiEkle({
    required BuildContext context,
    required RestoranMenuItemModel item,
  }) async {
    try {
      final picker = ImagePicker();

      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seçilen kapak fotoğrafı okunamadı.'),
          ),
        );
        return;
      }

      final safeFileName = file.name.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

      final storagePath =
          'restaurants/${restaurant.id}/menu_items/${item.id}/cover/$fileName';

      debugPrint('RESTORAN KAPAK UPLOAD START path=$storagePath');

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('RESTORAN KAPAK UPLOAD SUCCESS url=$downloadUrl');

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('menu_items')
          .doc(item.id)
          .set(
        {
          'img': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kapak fotoğrafı güncellendi.'),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('RESTORAN KAPAK EKLE ERROR => $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kapak fotoğrafı güncellenemedi: $error'),
        ),
      );
    }
  }

  Future<void> _menuProfilFotografiEkle({
    required BuildContext context,
    required RestoranMenuItemModel item,
  }) async {
    try {
      final picker = ImagePicker();

      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seçilen profil fotoğrafı okunamadı.'),
          ),
        );
        return;
      }

      final safeFileName = file.name.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

      final storagePath =
          'restaurants/${restaurant.id}/menu_items/${item.id}/profile/$fileName';

      debugPrint('RESTORAN PROFIL UPLOAD START path=$storagePath');

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('RESTORAN PROFIL UPLOAD SUCCESS url=$downloadUrl');

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('menu_items')
          .doc(item.id)
          .set(
        {
          'profileImg': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil fotoğrafı güncellendi.'),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('RESTORAN PROFIL EKLE ERROR => $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil fotoğrafı güncellenemedi: $error'),
        ),
      );
    }
  }

  Future<void> _menuProfilFotografiSil({
    required BuildContext context,
    required RestoranMenuItemModel item,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Profil fotoğrafı silinsin mi?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Bu işlem yalnızca küçük yuvarlak profil / logo fotoğrafını kaldırır. Kapak ve galeri fotoğraflarına dokunulmaz.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
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
          'profileImg': '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil fotoğrafı silindi.'),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('RESTORAN PROFIL SIL ERROR => $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil fotoğrafı silinemedi: $error'),
        ),
      );
    }
  }

  Future<void> _menuGaleriFotografiEkle({
    required BuildContext context,
    required RestoranMenuItemModel item,
  }) async {
    try {
      final galleryLimit = restaurant.galleryPhotoLimit;

      final itemRef = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('menu_items')
          .doc(item.id);

      final itemDoc = await itemRef.get();
      final currentImages = ((itemDoc.data()?['images'] as List?) ?? [])
          .map((url) => url.toString().trim())
          .where((url) => url.isNotEmpty)
          .toList();

      if (currentImages.length >= galleryLimit) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${restaurant.membershipLabel} galeri limiti doldu. '
              'Bu paket için en fazla $galleryLimit fotoğraf eklenebilir.',
            ),
          ),
        );
        return;
      }

      final picker = ImagePicker();

      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seçilen fotoğraf okunamadı.'),
          ),
        );
        return;
      }

      final safeFileName =
          file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$safeFileName';

      final storagePath =
          'restaurants/${restaurant.id}/menu_items/${item.id}/gallery/$fileName';

      debugPrint('RESTORAN GALERI UPLOAD START path=$storagePath');

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('RESTORAN GALERI UPLOAD SUCCESS url=$downloadUrl');

      await itemRef.set(
        {
          'images': FieldValue.arrayUnion([downloadUrl]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Galeriye fotoğraf eklendi.'),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('RESTORAN GALERI EKLE ERROR => $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Galeri fotoğrafı eklenemedi: $error'),
        ),
      );
    }
  }

  Future<void> _menuGaleriFotografiSil({
    required BuildContext context,
    required RestoranMenuItemModel item,
    required String imageUrl,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Galeri fotoğrafı silinsin mi?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Bu işlem sadece galeri fotoğrafını kaldırır. Kapak fotoğrafına dokunulmaz.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final itemRef = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id)
          .collection('menu_items')
          .doc(item.id);

      debugPrint('RESTORAN GALERI SIL restaurantId=${restaurant.id}');
      debugPrint('RESTORAN GALERI SIL itemId=${item.id}');
      debugPrint('RESTORAN GALERI SIL imageUrl=$imageUrl');

      final doc = await itemRef.get();
      final data = doc.data();

      final currentImages = ((data?['images'] as List?) ?? [])
          .map((url) => url.toString().trim())
          .where((url) => url.isNotEmpty)
          .toList();

      debugPrint('RESTORAN GALERI SIL before=$currentImages');

      final cleanedImages =
          currentImages.where((url) => url != imageUrl.trim()).toList();

      await itemRef.set(
        {
          'images': cleanedImages,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      final afterDoc = await itemRef.get();
      debugPrint('RESTORAN GALERI SIL after=${afterDoc.data()?['images']}');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Galeri fotoğrafı silindi.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Galeri fotoğrafı silinemedi: $error'),
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

  Future<void> _yeniMenuUrunuDialogAc({
    required BuildContext context,
  }) async {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    final gelAlController = TextEditingController();
    final goturController = TextEditingController();
    final descriptionController = TextEditingController();
    final preparationController = TextEditingController(text: '20');

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool saving = false;
          bool isFeatured = false;
          String stockStatus = RestaurantProductStockStatus.inStock;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> urunuOlustur() async {
                final name = nameController.text.trim();
                final category = categoryController.text.trim();
                final description = descriptionController.text.trim();

                final gelAlText =
                    gelAlController.text.trim().replaceAll(',', '.');
                final goturText =
                    goturController.text.trim().replaceAll(',', '.');

                final gelAlFiyat = double.tryParse(gelAlText) ?? 0;
                final goturFiyat = double.tryParse(goturText) ?? 0;
                final preparationMinutes =
                    int.tryParse(preparationController.text.trim()) ?? 20;

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ürün adı zorunludur.'),
                    ),
                  );
                  return;
                }

                if (category.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kategori zorunludur.'),
                    ),
                  );
                  return;
                }

                if (gelAlFiyat <= 0 && goturFiyat <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('En az bir fiyat girilmelidir.'),
                    ),
                  );
                  return;
                }

                setDialogState(() {
                  saving = true;
                });

                try {
                  final itemRef = FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurant.id)
                      .collection('menu_items')
                      .doc();

                  final itemId = itemRef.id;

                  debugPrint(
                    'RESTORAN YENI URUN CREATE '
                    'restaurantId=${restaurant.id} itemId=$itemId name=$name',
                  );

                  await itemRef.set({
                    'id': itemId,
                    'restaurantId': restaurant.id,
                    'sellerId': restaurant.id,
                    'name': name,
                    'title': name,
                    'description': description,
                    'category': category,
                    'img': '',
                    'profileImg': '',
                    'images': <String>[],
                    'galleryMeta': <String, dynamic>{},
                    'gelAlFiyat': gelAlFiyat,
                    'goturFiyat': goturFiyat,
                    'isActive': true,
                    'isAvailable':
                        stockStatus == RestaurantProductStockStatus.inStock,
                    'stockStatus': stockStatus,
                    'stockUpdatedAt': FieldValue.serverTimestamp(),
                    'isFeatured': isFeatured,
                    'preparationMinutes': preparationMinutes,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
                  });

                  debugPrint(
                    'RESTORAN YENI URUN CREATE SUCCESS itemId=$itemId',
                  );

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$name oluşturuldu. Şimdi kapak ve galeri fotoğraflarını ekleyebilirsiniz.',
                      ),
                    ),
                  );
                } catch (error, stackTrace) {
                  debugPrint('RESTORAN YENI URUN CREATE ERROR => $error');
                  debugPrintStack(stackTrace: stackTrace);

                  setDialogState(() {
                    saving = false;
                  });

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ürün oluşturulamadı: $error'),
                    ),
                  );
                }
              }

              InputDecoration inputDecoration({
                required String label,
                String? hint,
              }) {
                return InputDecoration(
                  labelText: label,
                  hintText: hint,
                  labelStyle: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w800,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.22),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _gold,
                      width: 1.3,
                    ),
                  ),
                );
              }

              return AlertDialog(
                backgroundColor: const Color(0xFF151515),
                title: const Text(
                  'Yeni Menü Ürünü',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: SizedBox(
                  width: 560,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          enabled: !saving,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: inputDecoration(
                            label: 'Ürün adı',
                            hint: 'Günün Menüsü',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: categoryController,
                          enabled: !saving,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: inputDecoration(
                            label: 'Kategori',
                            hint: 'Sulu Yemekler',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: gelAlController,
                                enabled: !saving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: inputDecoration(
                                  label: 'Gel-Al fiyatı',
                                  hint: '180',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: goturController,
                                enabled: !saving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: inputDecoration(
                                  label: 'Götür fiyatı',
                                  hint: '200',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: preparationController,
                          enabled: !saving,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: inputDecoration(
                            label: 'Hazırlama süresi',
                            hint: '20 dakika',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descriptionController,
                          enabled: !saving,
                          maxLines: 3,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: inputDecoration(
                            label: 'Açıklama',
                            hint: 'Günlük hazırlanan sıcak ev yemekleri.',
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: stockStatus,
                          dropdownColor: const Color(0xFF1B1B1B),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: inputDecoration(
                            label: 'Ürün stok durumu',
                            hint: 'Stok durumunu seçin',
                          ),
                          items:
                              RestaurantProductStockStatus.values.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(
                                RestaurantProductStockStatus.label(status),
                              ),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  if (value == null) return;

                                  setDialogState(() {
                                    stockStatus = value;
                                  });
                                },
                        ),
                        const SizedBox(height: 6),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeColor: _gold,
                          value: isFeatured,
                          title: const Text(
                            'Öne çıkan ürün',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    isFeatured = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        saving ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: saving ? null : urunuOlustur,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                    ),
                    icon: saving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.add_circle_outline_rounded),
                    label: Text(
                      saving ? 'Oluşturuluyor...' : 'Ürünü Oluştur',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      categoryController.dispose();
      gelAlController.dispose();
      goturController.dispose();
      descriptionController.dispose();
      preparationController.dispose();
    }
  }

  Future<void> _menuUrunuDuzenleDialogAc({
    required BuildContext context,
    required RestoranMenuItemModel item,
    required String imageUrl,
  }) async {
    final meta = item.galleryMetaFor(imageUrl);

    final currentGelAlFiyat = meta?.gelAlFiyat ?? item.gelAlFiyat;
    final currentGoturFiyat = meta?.goturFiyat ?? item.goturFiyat;
    final currentDescription = meta?.description.trim().isNotEmpty == true
        ? meta!.description
        : item.description;

    final gelAlController = TextEditingController(
      text: currentGelAlFiyat > 0 ? currentGelAlFiyat.toStringAsFixed(0) : '',
    );

    final goturController = TextEditingController(
      text: currentGoturFiyat > 0 ? currentGoturFiyat.toStringAsFixed(0) : '',
    );

    final descriptionController = TextEditingController(
      text: currentDescription,
    );

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool saving = false;
          String stockStatus = item.stockStatus;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> kaydet() async {
                final gelAlText =
                    gelAlController.text.trim().replaceAll(',', '.');
                final goturText =
                    goturController.text.trim().replaceAll(',', '.');
                final description = descriptionController.text.trim();

                final gelAlFiyat = double.tryParse(gelAlText) ?? 0;
                final goturFiyat = double.tryParse(goturText) ?? 0;

                if (gelAlFiyat <= 0 && goturFiyat <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('En az bir fiyat alanı girilmelidir.'),
                    ),
                  );
                  return;
                }

                setDialogState(() {
                  saving = true;
                });

                try {
                  final imageKey =
                      RestoranMenuItemModel.galleryImageKey(imageUrl);

                  final itemRef = FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(restaurant.id)
                      .collection('menu_items')
                      .doc(item.id);

                  debugPrint(
                    'RESTORAN GALERI META UPDATE '
                    'restaurantId=${restaurant.id} '
                    'itemId=${item.id} '
                    'imageKey=$imageKey',
                  );

                  await itemRef.update({
                    'galleryMeta.$imageKey.gelAlFiyat': gelAlFiyat,
                    'galleryMeta.$imageKey.goturFiyat': goturFiyat,
                    'galleryMeta.$imageKey.description': description,
                    'stockStatus': stockStatus,
                    'isAvailable':
                        stockStatus == RestaurantProductStockStatus.inStock,
                    'stockUpdatedAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (!dialogContext.mounted) return;

                  Navigator.of(dialogContext).pop();

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Fiyat, açıklama ve stok durumu güncellendi.',
                      ),
                    ),
                  );
                } catch (error, stackTrace) {
                  debugPrint(
                    'RESTORAN GALERI META UPDATE ERROR => $error',
                  );
                  debugPrintStack(stackTrace: stackTrace);

                  setDialogState(() {
                    saving = false;
                  });

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Fiyat, açıklama ve stok güncellenemedi: $error',
                      ),
                    ),
                  );
                }
              }

              InputDecoration inputDecoration({
                required String label,
                String? hint,
              }) {
                return InputDecoration(
                  labelText: label,
                  hintText: hint,
                  labelStyle: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w800,
                  ),
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.22),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: _gold,
                      width: 1.3,
                    ),
                  ),
                );
              }

              return AlertDialog(
                backgroundColor: const Color(0xFF151515),
                title: const Text(
                  'Fiyat, Açıklama ve Stok Düzenle',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: gelAlController,
                                enabled: !saving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: inputDecoration(
                                  label: 'Gel-Al fiyatı',
                                  hint: '180',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: goturController,
                                enabled: !saving,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: inputDecoration(
                                  label: 'Götür fiyatı',
                                  hint: '200',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descriptionController,
                          enabled: !saving,
                          maxLines: 3,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: inputDecoration(
                            label: 'Açıklama',
                            hint: 'Fotoğrafa özel kısa açıklama',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: stockStatus,
                          dropdownColor: const Color(0xFF1B1B1B),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: inputDecoration(
                            label: 'Ürün stok durumu',
                            hint: 'Stok durumunu seçin',
                          ),
                          items:
                              RestaurantProductStockStatus.values.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(
                                RestaurantProductStockStatus.label(status),
                              ),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  if (value == null) return;

                                  setDialogState(() {
                                    stockStatus = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        saving ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: saving ? null : kaydet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                    ),
                    icon: saving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      saving ? 'Kaydediliyor...' : 'Kaydet',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      gelAlController.dispose();
      goturController.dispose();
      descriptionController.dispose();
    }
  }

  Widget _buildFirstProductGuide(BuildContext context) {
    Widget step({
      required String number,
      required String title,
      required String description,
      required IconData icon,
    }) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.09),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.42),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                number,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: _gold,
                        size: 18,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: _gold,
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Restoranını 4 adımda hazırla',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'İlk ürününü oluşturduktan sonra kapak ve galeri fotoğrafı düğmeleri otomatik açılır.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          step(
            number: '1',
            title: 'İlk ürününü oluştur',
            description:
                'Ürün adı, kategori, Gel-Al ve Götür fiyatı ile açıklamayı gir.',
            icon: Icons.add_circle_outline_rounded,
          ),
          const SizedBox(height: 10),
          step(
            number: '2',
            title: 'Kapak fotoğrafını ekle',
            description:
                'Bu fotoğraf ürün kartında ve müşterilerin gördüğü vitrinde yer alır.',
            icon: Icons.add_photo_alternate_outlined,
          ),
          const SizedBox(height: 10),
          step(
            number: '3',
            title: 'Galeri fotoğraflarını ekle',
            description:
                'Ürününü gerçek fotoğraflarla zenginleştir; web görünümünde üçlü düzen oluşur.',
            icon: Icons.photo_library_outlined,
          ),
          const SizedBox(height: 10),
          step(
            number: '4',
            title: 'Fiyatları kontrol et ve yayına al',
            description:
                'Gel-Al ve Götür fiyatlarını kontrol ederek ürünü satışa hazırla.',
            icon: Icons.verified_outlined,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _yeniMenuUrunuDialogAc(
                  context: context,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(
                Icons.add_business_rounded,
              ),
              label: const Text(
                'İlk Ürünümü Oluştur',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bool iyzicoReviewMode = true;
    final canSeeMenu = isAdmin || iyzicoReviewMode;

    if (!canSeeMenu) {
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
        final items = snapshot.data ?? const <RestoranMenuItemModel>[];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: _gold,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.45),
              ),
            ),
            child: Text(
              'Menü ürünleri alınamadı: ${snapshot.error}',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        if (items.isEmpty) {
          if (!isAdmin) {
            return const SizedBox.shrink();
          }

          return _buildFirstProductGuide(context);
        }
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
              if (isAdmin) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await _yeniMenuUrunuDialogAc(context: context);
                      },
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: _gold,
                        size: 18,
                      ),
                      label: const Text(
                        'Yeni Ürün',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RestoranSiparisYonetimiSayfasi(
                              restaurantId: restaurant.id,
                              restaurantName: restaurant.name,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.receipt_long_outlined,
                        color: _gold,
                        size: 18,
                      ),
                      label: const Text(
                        'Restoran Siparişleri',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
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
                  onAddGalleryPhotoTap: () async {
                    await _menuGaleriFotografiEkle(
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
                  onAddProfilePhotoTap: () async {
                    await _menuProfilFotografiEkle(
                      context: context,
                      item: item,
                    );
                  },
                  onDeleteGalleryPhotoTap: (imageUrl) async {
                    await _menuGaleriFotografiSil(
                      context: context,
                      item: item,
                      imageUrl: imageUrl,
                    );
                  },
                  onEditMenuItemTap: (imageUrl) async {
                    await _menuUrunuDuzenleDialogAc(
                      context: context,
                      item: item,
                      imageUrl: imageUrl,
                    );
                  },
                  onGelAlTap: (imageUrl) async {
                    await _sepeteRestoranUrunuEkle(
                      context: context,
                      item: item,
                      teslimatTipi: 'gel_al',
                      imageUrl: imageUrl,
                    );
                  },
                  onGoturTap: (imageUrl) async {
                    await _sepeteRestoranUrunuEkle(
                      context: context,
                      item: item,
                      teslimatTipi: 'gotur',
                      imageUrl: imageUrl,
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
