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
          const SizedBox(height: 12),
          _RestaurantTitleStrip(restaurant: restaurant),
          const SizedBox(height: 14),
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
    final isGotur = teslimatTipi == 'gotur';
    final effectiveImageUrl = imageUrl?.trim().isNotEmpty == true
        ? imageUrl!.trim()
        : item.imageForUi;

    final effectiveGelAlFiyat = effectiveImageUrl.isNotEmpty
        ? item.gelAlFiyatForImage(effectiveImageUrl)
        : item.gelAlFiyat;

    final effectiveGoturFiyat = effectiveImageUrl.isNotEmpty
        ? item.goturFiyatForImage(effectiveImageUrl)
        : item.goturFiyat;

    final selectedPrice = isGotur ? effectiveGoturFiyat : effectiveGelAlFiyat;
    final teslimatLabel = isGotur ? 'Götür' : 'Gel-Al';

    try {
      await SepetService.sepeteEkle(
        urunId:
            'restaurant_${restaurant.id}_${item.id}_${RestoranMenuItemModel.galleryImageKey(effectiveImageUrl)}_$teslimatTipi',
        urunAdi: item.name,
        dukkanAdi: restaurant.name,
        kategori: item.category,
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
          content: Text('${item.name} sepete eklendi. ($teslimatLabel)'),
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
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Yeni menü ürünü',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Gel-Al fiyatı',
                            hintText: '80',
                            labelStyle: const TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.w800,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
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
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Götür fiyatı',
                            hintText: '95',
                            labelStyle: const TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.w800,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    maxLines: 3,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Açıklama',
                      hintText: 'Kısa ürün açıklaması',
                      labelStyle: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Kapat',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
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
        builder: (dialogContext) {
          bool saving = false;

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

                  debugPrint('RESTORAN GALERI META UPDATE imageKey=$imageKey');
                  debugPrint('RESTORAN GALERI META UPDATE imageUrl=$imageUrl');
                  debugPrint(
                    'RESTORAN GALERI META UPDATE gelAl=$gelAlFiyat gotur=$goturFiyat',
                  );

                  await itemRef.update({
                    'galleryMeta.$imageKey.gelAlFiyat': gelAlFiyat,
                    'galleryMeta.$imageKey.goturFiyat': goturFiyat,
                    'galleryMeta.$imageKey.description': description,
                    'galleryMeta.$imageKey.updatedAt':
                        FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (!context.mounted) return;

                  Navigator.of(dialogContext).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} güncellendi.'),
                    ),
                  );
                } catch (e) {
                  setDialogState(() {
                    saving = false;
                  });

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Menü ürünü güncellenemedi: $e'),
                    ),
                  );
                }
              }

              return AlertDialog(
                backgroundColor: const Color(0xFF151515),
                title: Text(
                  '${item.name} düzenle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: gelAlController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Gel-Al fiyatı',
                                  hintText: '80',
                                  labelStyle: const TextStyle(
                                    color: _gold,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: _gold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: goturController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Götür fiyatı',
                                  hintText: '95',
                                  labelStyle: const TextStyle(
                                    color: _gold,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.18),
                                    ),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: _gold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: descriptionController,
                          maxLines: 4,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Açıklama',
                            hintText: 'Kısa ürün açıklaması',
                            labelStyle: const TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.w800,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.35),
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
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        saving ? null : () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: saving ? null : kaydet,
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(saving ? 'Kaydediliyor...' : 'Kaydet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
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
                            builder: (_) =>
                                const RestoranSiparisYonetimiSayfasi(),
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
