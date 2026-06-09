import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/restoran_model.dart';
import 'restoran_detay_sayfasi.dart';
import 'restoran_siparis_yonetimi_sayfasi.dart';

class RestoranYonetimPaneli extends StatelessWidget {
  const RestoranYonetimPaneli({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF070707);
  static const Color _card = Color(0xFF141414);

  DocumentReference<Map<String, dynamic>> get _restaurantRef =>
      FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);

  Future<void> _updateOpenStatus({
    required BuildContext context,
    required bool isOpen,
  }) async {
    try {
      await _restaurantRef.update({
        'isOpen': isOpen,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOpen
                ? 'Restoran müşterilere açıldı.'
                : 'Restoran geçici olarak kapatıldı.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restoran durumu güncellenemedi: $error'),
        ),
      );
    }
  }

  Future<void> _restaurantCoverUpload({
    required BuildContext context,
  }) async {
    try {
      final picker = ImagePicker();

      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (file == null) return;

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
          'restaurants/$restaurantId/restaurant_cover/$fileName';

      debugPrint('RESTORAN ANA KAPAK UPLOAD START path=$storagePath');

      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('RESTORAN ANA KAPAK UPLOAD SUCCESS url=$downloadUrl');
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUid = currentUser?.uid ?? '';

      debugPrint('RESTORAN COVER AUTH uid=$currentUid');
      debugPrint(
        'RESTORAN COVER AUTH anonymous=${currentUser?.isAnonymous}',
      );

      final adminRef = FirebaseFirestore.instance
          .collection('platform_admins')
          .doc(currentUid);

      final adminDoc = await adminRef.get();

      debugPrint('RESTORAN COVER ADMIN PATH=platform_admins/$currentUid');
      debugPrint('RESTORAN COVER ADMIN EXISTS=${adminDoc.exists}');
      debugPrint('RESTORAN COVER ADMIN DATA=${adminDoc.data()}');
      await _restaurantRef.set(
        {
          'imageUrl': downloadUrl,
          'img': downloadUrl,
          'coverUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'coverUpdatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restoran kapak fotoğrafı güncellendi.'),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('RESTORAN ANA KAPAK UPLOAD ERROR => $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kapak fotoğrafı yüklenemedi: $error'),
        ),
      );
    }
  }

  Future<void> _restaurantCoverDelete({
    required BuildContext context,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Restoran kapağı silinsin mi?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Bu işlem yalnızca restoranın ana kapak görselini kaldırır. '
            'Menü ürünlerinin kapak ve galeri fotoğraflarına dokunulmaz.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Sil',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _restaurantRef.set(
        {
          'imageUrl': '',
          'img': '',
          'coverUpdatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'coverUpdatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        },
        SetOptions(merge: true),
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restoran kapak fotoğrafı kaldırıldı.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kapak fotoğrafı silinemedi: $error'),
        ),
      );
    }
  }

  void _openRestaurantDetail({
    required BuildContext context,
    required RestoranModel restaurant,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestoranDetaySayfasi(
          restaurant: restaurant,
          managementMode: true,
        ),
      ),
    );
  }

  void _openOrders(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestoranSiparisYonetimiSayfasi(
          restaurantId: restaurantId,
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _gold.withValues(alpha: 0.26),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: _gold,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _gold,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'RESTORAN YÖNETİM PANELİ',
          style: TextStyle(
            color: _gold,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _restaurantRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Restoran bilgisi alınamadı: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final document = snapshot.data!;

          if (!document.exists) {
            return const Center(
              child: Text(
                'Restoran kaydı bulunamadı.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = document.data() ?? const <String, dynamic>{};
          final restaurant = RestoranModel.fromMap(restaurantId, data);

          final restaurantName = restaurant.name.trim().isEmpty
              ? 'Restoran'
              : restaurant.name.trim();

          final imageUrl = restaurant.imageUrl.trim();
          final isOpen = data['isOpen'] == true;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                restaurantName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Kapak, menü, vitrin ve sipariş operasyonunuzu buradan yönetin.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.28),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 7,
                      child: imageUrl.isEmpty
                          ? Container(
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
                              child: const Center(
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  color: Colors.white24,
                                  size: 62,
                                ),
                              ),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white38,
                                    size: 54,
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _restaurantCoverUpload(
                                context: context,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: Colors.black,
                            ),
                            icon: Icon(
                              imageUrl.isEmpty
                                  ? Icons.add_photo_alternate_rounded
                                  : Icons.change_circle_rounded,
                            ),
                            label: Text(
                              imageUrl.isEmpty
                                  ? 'Kapak Fotoğrafı Ekle'
                                  : 'Kapak Fotoğrafını Değiştir',
                            ),
                          ),
                          if (imageUrl.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () async {
                                await _restaurantCoverDelete(
                                  context: context,
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text('Kapağı Sil'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.28),
                  ),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: isOpen,
                  activeColor: _gold,
                  title: Text(
                    isOpen ? 'Restoran Açık' : 'Restoran Kapalı',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    isOpen
                        ? 'Müşteriler restoranınızı açık olarak görebilir.'
                        : 'Restoran vitrinde görünür; fakat kapalı olarak işaretlenir.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  secondary: Icon(
                    isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isOpen ? _gold : Colors.white38,
                    size: 34,
                  ),
                  onChanged: (value) async {
                    await _updateOpenStatus(
                      context: context,
                      isOpen: value,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _actionCard(
                icon: Icons.auto_awesome_rounded,
                title: 'Restoranı Hazırla',
                subtitle:
                    'Restoran detayını açın; kapak, ürün ve galeri alanlarını yönetin.',
                onTap: () {
                  _openRestaurantDetail(
                    context: context,
                    restaurant: restaurant,
                  );
                },
              ),
              const SizedBox(height: 12),
              _actionCard(
                icon: Icons.add_circle_outline_rounded,
                title: 'Yeni Menü Ürünü Oluştur',
                subtitle:
                    'Mevcut çalışan Yeni Ürün alanına giderek ilk menü ürününü ekleyin.',
                onTap: () {
                  _openRestaurantDetail(
                    context: context,
                    restaurant: restaurant,
                  );
                },
              ),
              const SizedBox(height: 12),
              _actionCard(
                icon: Icons.storefront_rounded,
                title: 'Kendi Vitrinimi Gör',
                subtitle:
                    'Restoranın müşterilere görünen gerçek premium sayfasını açın.',
                onTap: () {
                  _openRestaurantDetail(
                    context: context,
                    restaurant: restaurant,
                  );
                },
              ),
              const SizedBox(height: 12),
              _actionCard(
                icon: Icons.receipt_long_rounded,
                title: 'Sipariş Yönetimi',
                subtitle:
                    'Restoran siparişlerini ve operasyon durumlarını görüntüleyin.',
                onTap: () {
                  _openOrders(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
