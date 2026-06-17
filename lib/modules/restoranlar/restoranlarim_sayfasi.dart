import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/restoran_service.dart';
import 'models/restoran_model.dart';
import 'restoran_detay_sayfasi.dart';
import 'restoran_yonetim_paneli.dart';
import 'restoran_yan_urun_yonetimi_sayfasi.dart';
import '../../services/platform_admin_service.dart';

class RestoranlarimSayfasi extends StatelessWidget {
  const RestoranlarimSayfasi({super.key});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF070707);
  static const Color _card = Color(0xFF141414);

  Future<void> _yeniRestoranOlustur(
    BuildContext context,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null || currentUser.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Restoran oluşturmak için kalıcı satıcı veya yönetici hesabıyla giriş yapmalısınız.',
          ),
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final cityController = TextEditingController(text: 'İstanbul');
    final districtController = TextEditingController();
    final addressController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    final phoneController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          bool saving = false;
          bool supportsGelAl = true;
          bool supportsGotur = true;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> kaydet() async {
                final name = nameController.text.trim();
                final city = cityController.text.trim();
                final district = districtController.text.trim();
                final address = addressController.text.trim();
                final category = categoryController.text.trim();
                final description = descriptionController.text.trim();
                final phone = phoneController.text.trim();

                if (name.isEmpty ||
                    city.isEmpty ||
                    district.isEmpty ||
                    category.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Restoran adı, şehir, ilçe ve kategori zorunludur.',
                      ),
                    ),
                  );
                  return;
                }

                setDialogState(() {
                  saving = true;
                });

                try {
                  final uid = currentUser.uid;

                  final restaurantRef = FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc();

                  final restaurantId = restaurantRef.id;

                  await restaurantRef.set({
                    'restaurantId': restaurantId,
                    'sellerId': restaurantId,
                    'ownerUid': uid,
                    'applicationId': uid,
                    'name': name,
                    'restaurantName': name,
                    'title': name,
                    'city': city,
                    'district': district,
                    'address': address,
                    'category': category,
                    'cuisine': category,
                    'cuisineType': category,
                    'description': description,
                    'phone': phone,
                    'imageUrl': '',
                    'img': '',
                    'preparationText': '20-30 dk',
                    'ratingText': 'Yeni',
                    'rating': 'Yeni',
                    'isOpen': false,
                    'isActive': true,
                    'isLaunchReady': false,
                    'isFounder': true,
                    'supportsGelAl': supportsGelAl,
                    'supportsGotur': supportsGotur,
                    'deliverySupported': supportsGotur,
                    'membershipType': 'free',
                    'packageType': 'free',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'createdBy': uid,
                  });

                  if (!context.mounted) return;

                  Navigator.of(dialogContext).pop();

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RestoranYonetimPaneli(
                        restaurantId: restaurantId,
                      ),
                    ),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$name oluşturuldu. Şimdi kapağı ve ilk menü ürününü ekleyebilirsiniz.',
                      ),
                    ),
                  );
                } catch (error) {
                  setDialogState(() {
                    saving = false;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Restoran oluşturulamadı: $error',
                      ),
                    ),
                  );
                }
              }

              return AlertDialog(
                backgroundColor: const Color(0xFF151515),
                title: const Text(
                  'Yeni Restoran Oluştur',
                  style: TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                content: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _field(
                          controller: nameController,
                          label: 'Restoran adı',
                          hint: 'Adana Kebapçısı',
                        ),
                        _field(
                          controller: cityController,
                          label: 'Şehir',
                        ),
                        _field(
                          controller: districtController,
                          label: 'İlçe',
                        ),
                        _field(
                          controller: addressController,
                          label: 'Adres',
                        ),
                        _field(
                          controller: categoryController,
                          label: 'Kategori',
                          hint: 'Kebap & Izgara',
                        ),
                        _field(
                          controller: descriptionController,
                          label: 'Açıklama',
                          maxLines: 3,
                        ),
                        _field(
                          controller: phoneController,
                          label: 'Telefon',
                          keyboardType: TextInputType.phone,
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeColor: _gold,
                          value: supportsGelAl,
                          title: const Text(
                            'Gel-Al destekleniyor',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    supportsGelAl = value;
                                  });
                                },
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeColor: _gold,
                          value: supportsGotur,
                          title: const Text(
                            'Götür destekleniyor',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    supportsGotur = value;
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
                    child: const Text('Vazgeç'),
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
                        : const Icon(Icons.add_business_rounded),
                    label: Text(
                      saving ? 'Oluşturuluyor...' : 'Restoranı Oluştur',
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
      cityController.dispose();
      districtController.dispose();
      addressController.dispose();
      categoryController.dispose();
      descriptionController.dispose();
      phoneController.dispose();
    }
  }

  static Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white60),
          hintStyle: const TextStyle(color: Colors.white30),
          filled: true,
          fillColor: Colors.black26,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _gold.withValues(alpha: 0.22),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: _gold,
            ),
          ),
        ),
      ),
    );
  }

  void _yonet(
    BuildContext context,
    RestoranModel restaurant,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestoranYonetimPaneli(
          restaurantId: restaurant.id,
        ),
      ),
    );
  }

  void _vitriniGor(
    BuildContext context,
    RestoranModel restaurant,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestoranDetaySayfasi(
          restaurant: restaurant,
        ),
      ),
    );
  }

  Future<void> _restoranSil({
    required BuildContext context,
    required RestoranModel restaurant,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          title: const Text(
            'Restoran silinsin mi?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '${restaurant.name} restoranı ve menü ürünleri silinecek. '
            'Bu işlem geri alınamaz.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Evet, Sil'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUid = currentUser?.uid ?? '';

      debugPrint('RESTORAN SIL AUTH uid=$currentUid');
      debugPrint('RESTORAN SIL AUTH anonymous=${currentUser?.isAnonymous}');
      debugPrint('RESTORAN SIL restaurantId=${restaurant.id}');
      debugPrint('RESTORAN SIL restaurantName=${restaurant.name}');

      final adminDoc = await FirebaseFirestore.instance
          .collection('platform_admins')
          .doc(currentUid)
          .get();

      debugPrint('RESTORAN SIL ADMIN PATH=platform_admins/$currentUid');
      debugPrint('RESTORAN SIL ADMIN EXISTS=${adminDoc.exists}');
      debugPrint('RESTORAN SIL ADMIN DATA=${adminDoc.data()}');
      final restaurantRef = FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurant.id);

      final menuItems = await restaurantRef.collection('menu_items').get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in menuItems.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(restaurantRef);

      await batch.commit();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${restaurant.name} silindi.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restoran silinemedi: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'RESTORANLARIM',
          style: TextStyle(
            color: _gold,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () async {
                await _yeniRestoranOlustur(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Yeni Restoran'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<bool>(
        future: PlatformAdminService.isCurrentUserPlatformAdmin(),
        builder: (context, adminSnapshot) {
          if (adminSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _gold,
              ),
            );
          }

          final currentUser = FirebaseAuth.instance.currentUser;
          final currentUid = currentUser?.uid ?? '';
          final isAnonymous = currentUser?.isAnonymous != false;
          final isPlatformAdmin = adminSnapshot.data == true;

          if (isAnonymous) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Restoran yönetimi için kalıcı satıcı veya yönetici hesabıyla giriş yapmalısınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }

          return StreamBuilder<List<RestoranModel>>(
            stream: RestoranService.streamRestaurantsForManagement(
              currentUid: currentUid,
              isPlatformAdmin: isPlatformAdmin,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Restoranlar alınamadı: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _gold),
                );
              }

              final restaurants = snapshot.data!;

              if (restaurants.isEmpty) {
                return Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await _yeniRestoranOlustur(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                    ),
                    icon: const Icon(Icons.add_business_rounded),
                    label: Text(
                      isPlatformAdmin
                          ? 'İlk Restoranı Oluştur'
                          : 'Restoran Oluştur',
                    ),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;

                  final crossAxisCount = width >= 1180
                      ? 3
                      : width >= 720
                          ? 2
                          : 1;

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: width >= 720 ? 1.15 : 1.05,
                    ),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = restaurants[index];

                      final imageUrl = restaurant.imageUrl.trim().isNotEmpty
                          ? restaurant.imageUrl.trim()
                          : '';

                      return Container(
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.25),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
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
                                      child: const Icon(
                                        Icons.restaurant_rounded,
                                        color: Colors.white24,
                                        size: 58,
                                      ),
                                    )
                                  : Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Center(
                                          child: Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.white38,
                                            size: 48,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurant.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    restaurant.locationText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                _yonet(context, restaurant);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _gold,
                                                foregroundColor: Colors.black,
                                              ),
                                              child: const Text('Yönet'),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                _vitriniGor(
                                                  context,
                                                  restaurant,
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: _gold,
                                                side: BorderSide(
                                                  color: _gold.withValues(
                                                    alpha: 0.65,
                                                  ),
                                                ),
                                              ),
                                              child: const Text('Vitrini Gör'),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    RestoranYanUrunYonetimiSayfasi(
                                                  restaurantId: restaurant.id,
                                                ),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            side: BorderSide(
                                              color: _gold.withValues(
                                                alpha: 0.45,
                                              ),
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.local_drink_rounded,
                                          ),
                                          label: const Text('Yan Ürünler'),
                                        ),
                                      ),
                                      if (isPlatformAdmin) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            onPressed: () async {
                                              await _restoranSil(
                                                context: context,
                                                restaurant: restaurant,
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.redAccent,
                                              side: const BorderSide(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                            ),
                                            label: const Text('Restoranı Sil'),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
