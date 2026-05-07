import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/ev_product_gallery.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/ev_gallery_manager.dart';

import 'package:sofrasofra_arena_v2/modules/widgets/ev_product_status_note_card.dart';
import 'package:sofrasofra_arena_v2/services/sepet_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sofrasofra_arena_v2/cart/sepet_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/product_reviews_section.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/ev_gallery_sales_bridge.dart';
import 'package:sofrasofra_arena_v2/modules/fullscreen_gallery.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/urun_detay_media_admin_panel.dart';
import 'package:sofrasofra_arena_v2/services/platform_admin_service.dart';

class UrunDetaySayfasi extends StatefulWidget {
  final String urunAdi;
  final String urunFiyat;
  final String urunGorsel;
  final String aciklama;
  final String dukkanAdi;
  final String konum;
  final String youtubeUrl;
  final List<String>? urunGorseller;

  final String? productId;
  final String? sellerId;
  final bool isAdmin;

  final String kategori;

  final num? gelAlFiyat;
  final num? goturFiyat;

  const UrunDetaySayfasi({
    super.key,
    required this.urunAdi,
    required this.urunFiyat,
    required this.urunGorsel,
    required this.aciklama,
    required this.dukkanAdi,
    required this.konum,
    required this.youtubeUrl,
    this.urunGorseller,
    this.productId,
    this.sellerId,
    this.isAdmin = false,
    this.kategori = 'Ev Lezzetleri',
    this.gelAlFiyat,
    this.goturFiyat,
  });

  @override
  State<UrunDetaySayfasi> createState() => _UrunDetaySayfasiState();
}

bool _liveBugunHazirlandi = false;
bool _liveSinirliAdet = false;

String _liveKalanAdet = '';
String _liveChefNote = '';

class _UrunDetaySayfasiState extends State<UrunDetaySayfasi> {
  bool _isPlatformAdmin = false;

  int adet = 1;
  int _selectedGalleryIndex = 0;
  bool _mediaBusy = false;

  List<String> _liveImages = <String>[];
  String _liveFallbackImage = '';

  num? _liveGelAlFiyat;
  num? _liveGoturFiyat;

  int _hoveredIndex = -1;
  String _selectedDeliveryType = 'gel_al';
  Widget _priceMiniBox({
    required String title,
    required String price,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _gold.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.70),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            price,
            style: const TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  static const Color _bg = Color(0xFF070707);
  static const Color _surface = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _textPrimary = Colors.white;
  static const Color _textMuted = Color(0xFFB8B8B8);
  static const Color _border = Color(0x26FFB300);
  static const Color _chipBg = Color(0xFF151515);

  String get _coverImageUrl {
    final fallback = _liveFallbackImage.trim();
    if (fallback.isNotEmpty && isHttpUrl(fallback)) return fallback;

    final widgetCover = widget.urunGorsel.trim();
    if (widgetCover.isNotEmpty && isHttpUrl(widgetCover)) return widgetCover;

    if (_galleryImageUrls.isNotEmpty) {
      return _galleryImageUrls.first;
    }

    return '';
  }

  Future<void> _openStatusNoteDialog() async {
    final productId = (widget.productId ?? '').trim();

    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün ID bulunamadı.')),
      );
      return;
    }

    bool bugunHazirlandi = false;
    bool sinirliAdet = false;

    final kalanAdetController = TextEditingController();
    final chefNoteController = TextEditingController();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('urunler')
          .doc(productId)
          .get();

      final data = doc.data() ?? <String, dynamic>{};

      bugunHazirlandi = data['bugunHazirlandi'] == true;
      sinirliAdet = data['sinirliAdet'] == true;
      kalanAdetController.text = (data['kalanAdet'] ?? '').toString();
      chefNoteController.text = (data['chefNote'] ?? '').toString();
    } catch (_) {}

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111111),
              title: const Text(
                'Günlük Durum / Üretici Notu',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      value: bugunHazirlandi,
                      activeColor: _gold,
                      title: const Text(
                        'Bugün hazırlandı',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onChanged: (v) {
                        setDialog(() {
                          bugunHazirlandi = v;
                        });
                      },
                    ),
                    SwitchListTile(
                      value: sinirliAdet,
                      activeColor: _gold,
                      title: const Text(
                        'Sınırlı adet',
                        style: TextStyle(color: Colors.white70),
                      ),
                      onChanged: (v) {
                        setDialog(() {
                          sinirliAdet = v;
                        });
                      },
                    ),
                    if (sinirliAdet) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: kalanAdetController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Kalan Adet',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: chefNoteController,
                      minLines: 2,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Üreticiden Not',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('urunler')
                        .doc(productId)
                        .update({
                      'bugunHazirlandi': bugunHazirlandi,
                      'sinirliAdet': sinirliAdet,
                      'kalanAdet': kalanAdetController.text.trim(),
                      'chefNote': chefNoteController.text.trim(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Günlük durum güncellendi.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _gold),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                      color: Colors.black,
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

    kalanAdetController.dispose();
    chefNoteController.dispose();
  }

  List<String> get _galleryImageUrls {
    return _liveImages
        .map((e) => e.toString().trim())
        .where((e) =>
            e.isNotEmpty &&
            isHttpUrl(e) &&
            !e.contains('/cover/') &&
            !e.contains('%2Fcover%2F'))
        .toSet()
        .toList();
  }

  List<String> get _heroSliderImages {
    final cover = _coverImageUrl;

    final List<String> result = [];

    if (cover.isNotEmpty) {
      result.add(cover);
    }

    if (_effectiveImages.isNotEmpty) {
      result.addAll(
        _effectiveImages.where((e) => e != cover),
      );
    }

    return result;
  }

  Future<void> _openPriceEditDialog() async {
    final productId = (widget.productId ?? '').trim();

    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün ID bulunamadı.')),
      );
      return;
    }

    final gelAlController = TextEditingController(
      text: _effectiveGelAlPrice?.toStringAsFixed(0) ?? '',
    );

    final goturController = TextEditingController(
      text: _effectiveGoturPrice?.toStringAsFixed(0) ?? '',
    );
    final aciklamaController = TextEditingController(
      text: '',
    );
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Fiyat Yönetimi',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: gelAlController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Gel-Al Fiyatı',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: goturController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Götür Fiyatı',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aciklamaController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tarif / Açıklama',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () async {
                final gelAlText = gelAlController.text.trim();
                final goturText = goturController.text.trim();

                if (gelAlText.isEmpty && goturText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('En az bir fiyat girilmeli.')),
                  );
                  return;
                }

                final gelAlNum =
                    num.tryParse(gelAlText.replaceAll(',', '.')) ?? 0;

                await FirebaseFirestore.instance
                    .collection('urunler')
                    .doc(productId)
                    .update({
                  'gelAlFiyat': gelAlText,
                  'goturFiyat': goturText,
                  'fiyat': gelAlNum,
                  'priceUpdatedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;

                setState(() {
                  _liveGelAlFiyat = _parsePrice(gelAlText);
                  _liveGoturFiyat = _parsePrice(goturText);
                });

                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fiyat güncellendi.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: _gold),
              child: const Text(
                'Kaydet',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    gelAlController.dispose();
    goturController.dispose();
  }

  String _priceText(num? value) {
    if (value == null) return '';
    if (value == value.roundToDouble()) {
      return '${value.toInt()} ₺';
    }
    return '${value.toStringAsFixed(2)} ₺';
  }

  num? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;

    final raw = value
        .toString()
        .replaceAll('₺', '')
        .replaceAll('TL', '')
        .replaceAll(',', '.')
        .trim();

    if (raw.isEmpty) return null;
    return num.tryParse(raw);
  }

  num? get _effectiveGelAlPrice {
    return _liveGelAlFiyat ??
        widget.gelAlFiyat ??
        _parsePrice(widget.urunFiyat);
  }

  num? get _effectiveGoturPrice {
    return _liveGoturFiyat ?? widget.goturFiyat;
  }

  bool get _hasGelAlPrice => _effectiveGelAlPrice != null;
  bool get _hasGoturPrice => _effectiveGoturPrice != null;

  num? get _selectedUnitPrice {
    if (_selectedDeliveryType == 'gotur') {
      return _effectiveGoturPrice ?? _effectiveGelAlPrice;
    }
    return _effectiveGelAlPrice ?? _effectiveGoturPrice;
  }

  String get _selectedUnitPriceText => _priceText(_selectedUnitPrice);

  String get _selectedDeliveryLabel {
    return _selectedDeliveryType == 'gotur' ? 'Götür' : 'Gel-Al';
  }

  num get _selectedTotalPrice {
    final unit = _selectedUnitPrice ?? 0;
    return unit * adet;
  }

  static bool isHttpUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool get _canManageMedia {
    final uid = (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
    final sellerId = (widget.sellerId ?? '').trim();
    final productId = (widget.productId ?? '').trim();

    if (uid.isEmpty || productId.isEmpty) {
      return false;
    }

    final isOwner = sellerId.isNotEmpty && uid == sellerId;

    return isOwner || _isPlatformAdmin;
  }

  List<String> get _effectiveImages {
    return _liveImages;
  }

  List<String> get _galleryOnlyImages {
    return _effectiveImages
        .map((e) => e.toString().trim())
        .where((e) =>
            e.isNotEmpty &&
            isHttpUrl(e) &&
            !e.contains('/cover/') &&
            !e.contains('%2Fcover%2F'))
        .toSet()
        .toList();
  }

  String get _currentImageUrl {
    final images = _galleryImageUrls;
    if (images.isEmpty) return '';
    final safeIndex = _selectedGalleryIndex.clamp(0, images.length - 1);
    return images[safeIndex];
  }

  @override
  void initState() {
    super.initState();

    _loadPlatformAdminRole();

    _liveImages = EvGalleryManager.normalizeImages(
      images: widget.urunGorseller,
      fallbackImage: widget.urunGorsel,
    ).toSet().toList();
    _liveFallbackImage = widget.urunGorsel.trim();

    if (!_hasGelAlPrice && _hasGoturPrice) {
      _selectedDeliveryType = 'gotur';
    }
  }

  Future<void> _youtubeAc() async {
    final url = widget.youtubeUrl.trim();
    if (url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw 'Açılamadı';
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('YouTube linki açılamadı'),
        ),
      );
    }
  }

  Future<void> _replaceCoverPhoto() async {
    if (_mediaBusy) return;

    final productId = (widget.productId ?? '').trim();
    final sellerId = (widget.sellerId ?? '').trim().isNotEmpty
        ? (widget.sellerId ?? '').trim()
        : (FirebaseAuth.instance.currentUser?.uid ?? 'guest');

    if (productId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('productId eksik.')),
      );
      return;
    }

    setState(() => _mediaBusy = true);

    try {
      final bytes = await EvGalleryManager.pickSingleImage();
      if (bytes == null) return;

      final url = await EvGalleryManager.uploadCoverImage(
        sellerId: sellerId,
        productId: productId,
        bytes: bytes,
      );

      await FirebaseFirestore.instance
          .collection('urunler')
          .doc(productId)
          .set({
        'img': url.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() {
        _liveFallbackImage = url.trim();
        _selectedGalleryIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kapak görseli güncellendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kapak güncellenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _mediaBusy = false);
      }
    }
  }

  Future<void> _deleteCoverPhoto() async {
    if (_mediaBusy) return;

    final productId = (widget.productId ?? '').trim();

    if (productId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('productId eksik.')),
      );
      return;
    }

    setState(() => _mediaBusy = true);

    try {
      final oldCoverUrl = _liveFallbackImage.trim();

      await FirebaseFirestore.instance
          .collection('urunler')
          .doc(productId)
          .set({
        'img': '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await EvGalleryManager.deleteStorageByUrl(oldCoverUrl);

      if (!mounted) return;

      setState(() {
        _liveFallbackImage = '';
        _selectedGalleryIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kapak görseli silindi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kapak silinemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _mediaBusy = false);
      }
    }
  }

  Future<void> _loadPlatformAdminRole() async {
    final isAdmin = await PlatformAdminService.isCurrentUserPlatformAdmin();

    if (!mounted) return;

    setState(() {
      _isPlatformAdmin = isAdmin;
    });
  }

  Future<void> _addPhotoToGallery() async {
    if (!_canManageMedia || _mediaBusy) return;

    final productId = (widget.productId ?? '').trim();
    final sellerId = (widget.sellerId ?? '').trim();

    if (productId.isEmpty || sellerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('productId / sellerId eksik.')),
      );
      return;
    }

    setState(() => _mediaBusy = true);

    try {
      final bytes = await EvGalleryManager.pickSingleImage();
      if (bytes == null) return;

      final url = await EvGalleryManager.uploadImage(
        sellerId: sellerId,
        productId: productId,
        bytes: bytes,
      );

      await EvGalleryManager.addGalleryImages(
        productId: productId,
        sellerId: sellerId,
        existingImages: _effectiveImages,
        newUrls: [url],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galeriye fotoğraf eklendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fotoğraf eklenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _mediaBusy = false);
      }
    }
  }

  Future<void> _deleteCurrentPhoto() async {
    if (!_canManageMedia || _mediaBusy) return;

    final productId = (widget.productId ?? '').trim();
    final sellerId = (widget.sellerId ?? '').trim();

    if (productId.isEmpty || sellerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('productId / sellerId eksik.')),
      );
      return;
    }

    final currentUrl = _currentImageUrl;
    if (currentUrl.trim().isEmpty) return;

    setState(() => _mediaBusy = true);

    try {
      await EvGalleryManager.removeGalleryImage(
        productId: productId,
        sellerId: sellerId,
        existingImages: _effectiveImages,
        imageUrl: currentUrl,
      );

      await EvGalleryManager.deleteStorageByUrl(currentUrl);

      if (!mounted) return;

      setState(() {
        _selectedGalleryIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görsel silindi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel silinemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _mediaBusy = false);
      }
    }
  }

  Future<void> _setCurrentAsCover() async {
    if (!_canManageMedia || _mediaBusy) return;

    final productId = (widget.productId ?? '').trim();
    final sellerId = (widget.sellerId ?? '').trim();

    if (productId.isEmpty || sellerId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('productId / sellerId eksik.')),
      );
      return;
    }

    final currentUrl = _currentImageUrl;
    if (currentUrl.trim().isEmpty) return;

    setState(() => _mediaBusy = true);

    try {
      await EvGalleryManager.setAsCoverImage(
        productId: productId,
        sellerId: sellerId,
        existingImages: _effectiveImages,
        imageUrl: currentUrl,
      );

      if (!mounted) return;

      setState(() {
        _selectedGalleryIndex = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kapak görseli güncellendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kapak güncellenemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _mediaBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productId = (widget.productId ?? '').trim();

    return Scaffold(
      backgroundColor: _bg,
      body: productId.isEmpty
          ? _buildScaffoldBody()
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('urunler')
                  .doc(productId)
                  .snapshots(),
              builder: (context, snapshot) {
                final liveData = snapshot.data?.data() ?? <String, dynamic>{};
                _liveBugunHazirlandi = liveData['bugunHazirlandi'] == true;
                _liveSinirliAdet = liveData['sinirliAdet'] == true;
                _liveKalanAdet = (liveData['kalanAdet'] ?? '').toString();
                _liveChefNote = (liveData['note'] ?? '').toString();
                final rawImages = ((liveData['images'] as List?) ?? [])
                    .map((e) => e.toString().trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                final liveFallback =
                    (liveData['img'] ?? widget.urunGorsel).toString().trim();

                _liveImages = EvGalleryManager.normalizeImages(
                  images:
                      rawImages.isNotEmpty ? rawImages : widget.urunGorseller,
                  fallbackImage: liveFallback.isNotEmpty
                      ? liveFallback
                      : widget.urunGorsel,
                );

                _liveFallbackImage = liveFallback;
                _liveGelAlFiyat =
                    _parsePrice(liveData['gelAlFiyat'] ?? liveData['fiyat']);
                _liveGoturFiyat = _parsePrice(liveData['goturFiyat']);

                if (_effectiveImages.isEmpty) {
                  _selectedGalleryIndex = 0;
                } else if (_selectedGalleryIndex >= _galleryImageUrls.length &&
                    _galleryImageUrls.isNotEmpty) {
                  _selectedGalleryIndex = 0;
                }

                return _buildScaffoldBody();
              },
            ),
      bottomSheet: _buildBottomBar(),
    );
  }

  Widget _sellerPackagePrompt() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF111111),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.42),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ev Lezzetleri Paketleri',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ücretsiz\n• Aylık: 0 TL\n• Komisyon: %10\n• 3 fotoğraf\n• Temel görünürlük',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Pro\n• Aylık: 149 TL\n• Komisyon: %5\n• 8 fotoğraf\n• 1 video linki\n• Daha güçlü görünürlük',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Premium\n• Aylık: 299 TL\n• Komisyon: %2\n• 24 fotoğraf\n• 3 video linki\n• Mahalle vitrin önceliği',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _gold.withValues(alpha: 0.34),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.20),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.trending_up_rounded,
              color: _gold,
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRO’ya yükselt',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '8 fotoğraf + 1 video linki + daha güçlü görünürlük',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: _gold,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showSingleSellerDialog() async {
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
            'Aynı anda yalnızca tek mutfaktan sipariş verebilirsin.\n\n'
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
                'Sepeti Temizle',
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

  Future<bool> _showSingleSellerCartDialog() async {
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

  Widget _buildScaffoldBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 420,
          pinned: true,
          elevation: 0,
          backgroundColor: _bg,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: _textPrimary),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.black,
                  child: _buildHeroImage(),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.72, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_canManageMedia) ...[
                    _sellerPackagePrompt(),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openPriceEditDialog,
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Fiyat Değiştir / Ekle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _gold,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openStatusNoteDialog,
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Günlük Durum / Üretici Notu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _gold,
                          side: const BorderSide(color: _border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildPriceAndChipsCard(),
                  const SizedBox(height: 14),
                  EvProductStatusNoteCard(
                    bugunHazirlandi: _liveBugunHazirlandi,
                    sinirliAdet: _liveSinirliAdet,
                    kalanAdet: _liveKalanAdet,
                    chefNote: _liveChefNote,
                  ),
                  const SizedBox(height: 14),
                  _buildMetaCard(),
                  const SizedBox(height: 14),
                  _buildDescriptionCard(),
                  const SizedBox(height: 18),
                  ProductReviewsSection(
                    productId: (widget.productId ?? '').trim(),
                  ),
                  const SizedBox(height: 14),
                  if (_galleryImageUrls.isNotEmpty) ...[
                    if (_canManageMedia) ...[
                      UrunDetayMediaAdminPanel(
                        busy: _mediaBusy,
                        onAddCoverPhoto: _replaceCoverPhoto,
                        onDeleteCoverPhoto: _deleteCoverPhoto,
                        onAddGalleryPhoto: _addPhotoToGallery,
                        onDeleteCurrentGalleryPhoto: _deleteCurrentPhoto,
                        onSetCurrentAsCover: _setCurrentAsCover,
                      ),
                    ],
                    _buildGalleryStripCard(),
                    const SizedBox(height: 14),
                  ],
                  _buildQuantityCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage() {
    return EvProductGallery(
      images: _heroSliderImages,
      fallbackImage: '',
      height: 420,
      borderRadius: BorderRadius.circular(0),
      showThumbnails: false,
      isOwner: true,
      onAddPhoto: () {
        debugPrint('GALERI FOTO EKLE TEST');
      },
      onDeletePhoto: (index) {
        debugPrint('GALERI FOTO SIL TEST: $index');
      },
      onSetCoverPhoto: (index) {
        debugPrint('KAPAK YAP TEST: $index');
      },
      onIndexChanged: (index) {
        if (_selectedGalleryIndex == index) return;
        setState(() {
          _selectedGalleryIndex = index;
        });
      },
    );
  }

  Widget _buildGalleryStripCard() {
    final images = _galleryImageUrls;

    if (images.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final itemWidth = isMobile
        ? (screenWidth * 0.38).clamp(118.0, 152.0).toDouble()
        : ((screenWidth - 36.0 - 36.0 - 28.0) / 3)
            .clamp(140.0, 220.0)
            .toDouble();

    final safeSelectedIndex = _selectedGalleryIndex < 0
        ? 0
        : (_selectedGalleryIndex >= images.length
            ? images.length - 1
            : _selectedGalleryIndex);

    final selectedGalleryImage = images[safeSelectedIndex];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÜRÜN GALERİSİ',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),

          // Mobil güvenli: küçük kartlarda sadece görsel gösterilir.
          SizedBox(
            height: itemWidth + 10,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final imageUrl = images[index];
                final isSelected = index == safeSelectedIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGalleryIndex = index;
                    });
                  },
                  child: SizedBox(
                    width: itemWidth,
                    height: itemWidth,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? _gold : _border,
                          width: isSelected ? 3 : 1.2,
                        ),
                        color: const Color(0xFF111111),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                            : const [],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.medium,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;

                                  return Container(
                                    color: const Color(0xFF111111),
                                    alignment: Alignment.center,
                                    child: const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _gold,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF151515),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: _textMuted,
                                    size: 22,
                                  ),
                                ),
                              ),
                              if (_canManageMedia)
                                Positioned(
                                  left: 8,
                                  top: 8,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: () async {
                                      setState(() {
                                        _selectedGalleryIndex = index;
                                      });

                                      final ownerProductId =
                                          (widget.productId ?? '').trim();
                                      final sellerId =
                                          (widget.sellerId ?? '').trim();

                                      if (ownerProductId.isEmpty ||
                                          sellerId.isEmpty ||
                                          imageUrl.trim().isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Galeri ürünü için eksik bilgi var.'),
                                            backgroundColor: Colors.redAccent,
                                          ),
                                        );
                                        return;
                                      }

                                      final ref = await EvGallerySalesBridge
                                          .ensureGalleryProduct(
                                        ownerProductId: ownerProductId,
                                        sellerId: sellerId,
                                        dukkanAdi: widget.dukkanAdi,
                                        imageUrl: imageUrl,
                                      );

                                      if (!mounted) return;

                                      await EvGallerySalesBridge
                                          .editGalleryProductInfo(
                                        context: context,
                                        ref: ref,
                                        current: 0,
                                      );
                                    },
                                    child: Container(
                                      width: 31,
                                      height: 31,
                                      decoration: BoxDecoration(
                                        color: _gold.withValues(alpha: 0.96),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.black
                                              .withValues(alpha: 0.22),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.edit_rounded,
                                        color: Colors.black,
                                        size: 17,
                                      ),
                                    ),
                                  ),
                                ),
                              if (isSelected)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.65),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _gold.withValues(alpha: 0.75),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: _gold,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${index + 1}/${images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FullScreenGallery(
                                          images: images,
                                          initialIndex: index,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.65),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.visibility_rounded,
                                      color: Colors.white,
                                      size: 17,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Satış/fiyat/sepet paneli artık küçük kartın içinde değil,
          // seçili görselin altında tam genişlikte durur.
          EvGallerySalesActions(
            ownerProductId: (widget.productId ?? '').trim(),
            sellerId: (widget.sellerId ?? '').trim(),
            dukkanAdi: widget.dukkanAdi,
            imageUrl: selectedGalleryImage,
            isAdmin: _canManageMedia,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceAndChipsCard() {
    final goturDisplayPrice = _effectiveGoturPrice ?? _effectiveGelAlPrice;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.urunAdi.trim().isEmpty ? 'İsimsiz ürün' : widget.urunAdi,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          if (widget.aciklama.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.aciklama,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'FİYAT',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x14FFB300),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  _selectedUnitPriceText.isEmpty
                      ? (widget.urunFiyat.trim().isEmpty
                          ? 'Fiyat yok'
                          : widget.urunFiyat)
                      : _selectedUnitPriceText,
                  style: const TextStyle(
                    color: _gold,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if (_hasGelAlPrice ||
              goturDisplayPrice != null ||
              widget.urunFiyat.trim().isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _deliveryChip(
                  title: 'Gel-Al',
                  price: _hasGelAlPrice
                      ? _priceText(_effectiveGelAlPrice)
                      : widget.urunFiyat,
                  selected: _selectedDeliveryType == 'gel_al',
                  onTap: () {
                    setState(() {
                      _selectedDeliveryType = 'gel_al';
                    });
                  },
                ),
                _deliveryChip(
                  title: 'Götür',
                  price: goturDisplayPrice == null
                      ? '—'
                      : _priceText(goturDisplayPrice),
                  selected: _selectedDeliveryType == 'gotur',
                  onTap: () {
                    setState(() {
                      _selectedDeliveryType = 'gotur';
                    });
                  },
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniChip(Icons.schedule_outlined, 'Bugün hazırlandı'),
              _miniChip(Icons.home_work_outlined, 'Mahalle mutfağı'),
              _miniChip(Icons.local_fire_department_outlined, 'Sınırlı adet'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          if (widget.dukkanAdi.trim().isNotEmpty)
            _infoRow(Icons.storefront_outlined, 'Mutfak', widget.dukkanAdi),
          if (widget.dukkanAdi.trim().isNotEmpty &&
              widget.konum.trim().isNotEmpty)
            const SizedBox(height: 14),
          if (widget.konum.trim().isNotEmpty)
            _infoRow(Icons.location_on_outlined, 'Konum', widget.konum),
          if (widget.dukkanAdi.trim().isNotEmpty ||
              widget.konum.trim().isNotEmpty)
            const SizedBox(height: 14),
          _infoRow(Icons.star_rounded, 'Puan', '4.9 • 120+ değerlendirme'),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÜRÜN AÇIKLAMASI',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.15,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.aciklama.trim().isEmpty
                ? 'Bu ürün için henüz açıklama girilmedi.'
                : widget.aciklama,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 15,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.youtubeUrl.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _youtubeAc,
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: const Text("YouTube'da İzle"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: const BorderSide(color: _border),
                  backgroundColor: _gold.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'ADET',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _adetButon(Icons.remove, () {
            if (adet > 1) {
              setState(() {
                adet--;
              });
            }
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              adet.toString(),
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _adetButon(Icons.add, () {
            setState(() {
              adet++;
            });
          }),
        ],
      ),
    );
  }

  Widget _adetButon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _chipBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Icon(
          icon,
          color: _gold,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: _border),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 22,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: _canManageMedia
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$adet adet seçildi • $_selectedDeliveryLabel',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _priceText(_selectedTotalPrice),
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_selectedUnitPrice == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Bu ürün için fiyat tanımlı değil.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final productId = (widget.productId ?? '').trim();

                        if (productId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Ürün ID bulunamadı. Sepete eklenemedi.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        try {
                          await SepetService.sepeteEkle(
                            urunId: productId,
                            urunAdi: widget.urunAdi,
                            dukkanAdi: widget.dukkanAdi,
                            kategori: widget.kategori,
                            img: _coverImageUrl,
                            fiyat: _selectedUnitPrice!.toDouble(),
                            gelAlFiyat: widget.kategori == 'Ev Lezzetleri'
                                ? _effectiveGelAlPrice?.toDouble()
                                : null,
                            goturFiyat: widget.kategori == 'Ev Lezzetleri'
                                ? (_effectiveGoturPrice ?? _effectiveGelAlPrice)
                                    ?.toDouble()
                                : null,
                            teslimatTipi: widget.kategori == 'Ev Lezzetleri'
                                ? _selectedDeliveryType
                                : 'gel_al',
                            saticiId: (widget.sellerId ?? '').trim(),
                            dukkanId: (widget.sellerId ?? '').trim(),
                          );

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: _gold,
                              content: Text(
                                '${widget.urunAdi} • $_selectedDeliveryLabel • ${_priceText(_selectedTotalPrice)} sepete eklendi!',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          );
                          await Future<void>.delayed(
                              const Duration(milliseconds: 650));

                          if (!mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SepetSayfasi(),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          final errorText = e.toString();

                          if (errorText.contains('tek satıcıdan')) {
                            final shouldClear = await _showSingleSellerDialog();

                            if (!mounted) return;

                            if (shouldClear) {
                              try {
                                await _clearCurrentUserCart();

                                await SepetService.sepeteEkle(
                                  urunId: productId,
                                  urunAdi: widget.urunAdi,
                                  dukkanAdi: widget.dukkanAdi,
                                  kategori: widget.kategori,
                                  img: _coverImageUrl,
                                  fiyat: _selectedUnitPrice!.toDouble(),
                                  gelAlFiyat: widget.kategori == 'Ev Lezzetleri'
                                      ? _effectiveGelAlPrice?.toDouble()
                                      : null,
                                  goturFiyat: widget.kategori == 'Ev Lezzetleri'
                                      ? (_effectiveGoturPrice ??
                                              _effectiveGelAlPrice)
                                          ?.toDouble()
                                      : null,
                                  teslimatTipi:
                                      widget.kategori == 'Ev Lezzetleri'
                                          ? _selectedDeliveryType
                                          : 'gel_al',
                                  saticiId: (widget.sellerId ?? '').trim(),
                                  dukkanId: (widget.sellerId ?? '').trim(),
                                );

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: _gold,
                                    content: Text(
                                      'Sepet temizlendi ve ${widget.urunAdi} sepete eklendi!',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                );
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SepetSayfasi(),
                                  ),
                                );
                              } catch (err) {
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Sepet temizlenemedi: $err'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }

                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sepete eklenemedi: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text(
                        'SEPETE EKLE',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _deliveryChip({
    required String title,
    required String price,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0x14FFB300) : _chipBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _gold : _border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _gold.withOpacity(0.22),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: selected ? _gold : _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _gold),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _chipBg,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _border),
          ),
          child: Icon(
            icon,
            color: _gold,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ],
    );
  }
}
