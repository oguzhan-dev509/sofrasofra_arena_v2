import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sef_imza_tabagi_premium_card.dart';
import 'package:sofrasofra_arena_v2/services/sepet_service.dart';
import 'package:sofrasofra_arena_v2/cart/sepet_sayfasi.dart';

class SefImzaTabaklariSection extends StatefulWidget {
  final String chefId;

  const SefImzaTabaklariSection({
    super.key,
    required this.chefId,
  });

  @override
  State<SefImzaTabaklariSection> createState() =>
      _SefImzaTabaklariSectionState();
}

class _SefImzaTabaklariSectionState extends State<SefImzaTabaklariSection> {
  static const Color gold = Color(0xFFFFD54F);

  Future<void> _addDish() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance
          .ref()
          .child('chef_signature_dishes')
          .child(widget.chefId)
          .child(fileName);

      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();

      final urunRef =
          await FirebaseFirestore.instance.collection('urunler').add({
        'ad': 'Yeni İmza Tabağı',
        'urunAdi': 'Yeni İmza Tabağı',
        'title': 'Yeni İmza Tabağı',
        'img': url,
        'imageUrl': url,
        'images': [url],
        'aciklama': '',
        'description': '',
        'fiyat': 0,
        'price': 0,
        'gelAlFiyat': 0,
        'goturFiyat': 0,
        'kategori': 'Usta Şefler',
        'tip': 'Usta Şefler',
        'dukkanAdi': 'Şefin İmza Mutfağı',
        'dukkan': 'Şefin İmza Mutfağı',
        'dukkanId': widget.chefId,
        'sellerId': widget.chefId,
        'chefId': widget.chefId,
        'isActive': true,
        'aktifMi': true,
        'onayDurumu': 'onaylandi',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('chef_signature_dishes').add({
        'chefId': widget.chefId,
        'urunDocId': urunRef.id,
        'imageUrl': url,
        'title': 'Yeni İmza Tabağı',
        'description': '',
        'price': 0,
        'gelAlFiyat': 0,
        'goturFiyat': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İmza tabağı eklendi')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _deleteDish(String docId) async {
    final dishRef = FirebaseFirestore.instance
        .collection('chef_signature_dishes')
        .doc(docId);

    final snap = await dishRef.get();
    final data = snap.data() ?? {};
    final urunDocId = (data['urunDocId'] ?? '').toString();

    await dishRef.delete();

    if (urunDocId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('urunler')
          .doc(urunDocId)
          .delete();
    }
  }

  Future<void> _addSignatureDishToCart(
    String docId,
    Map<String, dynamic> data,
  ) async {
    final priceRaw = data['price'] ?? data['fiyat'] ?? 0;

    final double price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw.toString().replaceAll(',', '.')) ?? 0;

    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu imza tabağı için fiyat eklenmemiş.'),
        ),
      );
      return;
    }

    final imageUrl = (data['imageUrl'] ?? data['img'] ?? '').toString();

    final title =
        (data['title'] ?? data['name'] ?? data['ad'] ?? 'Şefin İmza Tabağı')
            .toString();

    final gelAlFinalPrice = _asDouble(
      data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'],
    );

    final goturRawPrice = _asDouble(data['goturFiyat']);
    final goturFinalPrice = goturRawPrice > 0 ? goturRawPrice : null;

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: const Color(0xFF151515),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teslimat tercihi seçin',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Gel-Al',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${gelAlFinalPrice.toStringAsFixed(0)} ₺',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext, {
                      'tip': 'gel_al',
                      'fiyat': gelAlFinalPrice,
                    });
                  },
                ),
                if (goturFinalPrice != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Götür',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${goturFinalPrice.toStringAsFixed(0)} ₺',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext, {
                        'tip': 'gotur',
                        'fiyat': goturFinalPrice,
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null) return;

    final selectedTip = selected['tip'].toString();
    final selectedPrice = selected['fiyat'] as double;
    final baseProductId = (data['urunDocId'] ?? docId).toString();

    await SepetService.sepeteEkle(
      urunId: '${baseProductId}_$selectedTip',
      urunAdi: title,
      dukkanAdi: 'Şefin İmza Mutfağı',
      kategori: 'Usta Şefler',
      img: imageUrl,
      fiyat: selectedPrice,
      gelAlFiyat: gelAlFinalPrice,
      goturFiyat: goturFinalPrice,
      teslimatTipi: selectedTip,
      saticiId: widget.chefId,
      dukkanId: widget.chefId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İmza tabağı sepete eklendi.')),
    );
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SepetSayfasi(),
      ),
    );
  }

  Future<void> _editDishInfo(
    String docId,
    dynamic currentPrice,
    String currentDescription,
    Map<String, dynamic> data,
  ) async {
    final gelAlController = TextEditingController(
      text: (data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'] ?? '')
          .toString(),
    );

    final goturController = TextEditingController(
      text: (data['goturFiyat'] ?? '').toString(),
    );

    final descController = TextEditingController(text: currentDescription);

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('İmza Tabağı Bilgileri'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gelAlController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Gel-Al Fiyatı (₺)',
                  hintText: 'Örn: 1500',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: goturController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Götür Fiyatı (₺)',
                  hintText: 'Örn: 1600',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Tarif / Açıklama',
                  hintText: 'Yemeğin kısa tarifini yazın',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                final gelAlPrice = double.tryParse(
                      gelAlController.text.trim().replaceAll(',', '.'),
                    ) ??
                    0;

                final goturPrice = double.tryParse(
                      goturController.text.trim().replaceAll(',', '.'),
                    ) ??
                    0;

                final description = descController.text.trim();

                await FirebaseFirestore.instance
                    .collection('chef_signature_dishes')
                    .doc(docId)
                    .update({
                  'price': gelAlPrice,
                  'fiyat': gelAlPrice,
                  'gelAlFiyat': gelAlPrice,
                  'goturFiyat': goturPrice,
                  'description': description,
                  'aciklama': description,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                final urunDocId = (data['urunDocId'] ?? '').toString();

                if (urunDocId.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('urunler')
                      .doc(urunDocId)
                      .update({
                    'price': gelAlPrice,
                    'fiyat': gelAlPrice,
                    'gelAlFiyat': gelAlPrice,
                    'goturFiyat': goturPrice,
                    'description': description,
                    'aciklama': description,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                }

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'ŞEFİN İMZA TABAKLARI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            InkWell(
              onTap: _addDish,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: gold,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.add_a_photo_rounded,
                      size: 16,
                      color: Colors.black,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Ekle',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chef_signature_dishes')
              .where('chefId', isEqualTo: widget.chefId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Text('Henüz imza tabağı yok.');
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final imageUrl =
                    (data['imageUrl'] ?? data['img'] ?? '').toString();

                final title = (data['title'] ??
                        data['name'] ??
                        data['ad'] ??
                        'Şefin İmza Tabağı')
                    .toString();

                final description = (data['description'] ??
                        data['tarif'] ??
                        data['aciklama'] ??
                        '')
                    .toString();

                return SefImzaTabagiPremiumCard(
                  imageUrl: imageUrl,
                  title: title,
                  description: description,
                  price: data['price'] ?? data['fiyat'],
                  gelAlFiyat:
                      data['gelAlFiyat'] ?? data['price'] ?? data['fiyat'],
                  goturFiyat: data['goturFiyat'],
                  onEdit: () => _editDishInfo(
                    doc.id,
                    data['price'] ?? data['fiyat'],
                    description,
                    data,
                  ),
                  onDelete: () => _deleteDish(doc.id),
                  onAddToCart: () => _addSignatureDishToCart(doc.id, data),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

double _asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
}
