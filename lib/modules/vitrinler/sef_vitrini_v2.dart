import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/sef_itibar_sayfasi.dart';
import 'package:sofrasofra_arena_v2/merchant/gastronomi_yonetim_merkezi.dart';

class SefVitriniV2 extends StatelessWidget {
  const SefVitriniV2({super.key});

  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _gold = Color(0xFFFFB300);

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('urunler')
        .where('isActive', isEqualTo: true)
        .where('onayDurumu', isEqualTo: 'onaylandi')
        .where('tip', isEqualTo: 'Usta Sefler');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _bg,
        iconTheme: const IconThemeData(color: _gold),
        actions: const [],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Şef vitrini yüklenirken hata oluştu:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz onaylı şef bulunmuyor.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final items = docs
              .map((doc) {
                final data = doc.data();

                final String docId = doc.id;
                final String dukkanId =
                    (data['dukkanId'] ?? '').toString().trim();
                final String ownerId =
                    (data['ownerId'] ?? '').toString().trim();

                if (ownerId.isEmpty) {
                  return null;
                }

                final String ad = (data['dukkan'] ??
                        data['ad'] ??
                        data['satici'] ??
                        'Usta Şef')
                    .toString()
                    .trim();

                final String uzman = (data['uzmanlik'] ??
                        data['kategori'] ??
                        'Gastronomi Uzmanı')
                    .toString()
                    .trim();

                final String img = _safeUrl((data['img'] ?? '').toString());
                final String puan = (data['itibar_puani'] ?? '4.9').toString();

                final List<String> gallery = List<String>.from(
                  data['gallery'] ?? const [],
                ).map(_safeUrl).where((e) => e.isNotEmpty).toList();

                return _ChefV2Item(
                  docId: docId,
                  dukkanId: dukkanId,
                  ownerId: ownerId,
                  ad: ad.isEmpty ? 'Usta Şef' : ad,
                  uzman: uzman.isEmpty ? 'Gastronomi Uzmanı' : uzman,
                  img: img,
                  puan: puan,
                  gallery: gallery,
                  isSample: data['isSample'] == true,
                );
              })
              .whereType<_ChefV2Item>()
              .toList();

          items.sort((a, b) {
            final aFeatured = a.gallery.isNotEmpty ? 1 : 0;
            final bFeatured = b.gallery.isNotEmpty ? 1 : 0;
            return bFeatured.compareTo(aFeatured);
          });

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 1;
              if (width >= 700) crossAxisCount = 2;
              if (width >= 1100) crossAxisCount = 3;

              return GridView.builder(
                padding: const EdgeInsets.all(18),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  mainAxisExtent: width >= 1100 ? 465 : 465,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ChefPremiumCard(
                    item: item,
                    isFeatured: index == 0 && item.gallery.isNotEmpty,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static String _safeUrl(String url) {
    final u = url.replaceAll(RegExp(r'\s+'), '').trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    return '';
  }
}

class _ChefV2Item {
  final String docId;
  final String dukkanId;
  final String ownerId;
  final String ad;
  final String uzman;
  final String img;
  final String puan;
  final List<String> gallery;
  final bool isSample;
  const _ChefV2Item({
    required this.docId,
    required this.dukkanId,
    required this.ownerId,
    required this.ad,
    required this.uzman,
    required this.img,
    required this.puan,
    required this.gallery,
    required this.isSample,
  });
}

class _ChefPremiumCard extends StatefulWidget {
  final _ChefV2Item item;
  final bool isFeatured;

  const _ChefPremiumCard({
    required this.item,
    required this.isFeatured,
  });

  @override
  State<_ChefPremiumCard> createState() => _ChefPremiumCardState();
}

class _ChefPremiumCardState extends State<_ChefPremiumCard> {
  bool _hover = false;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF151515);

  String _resolvedChefId(_ChefV2Item item) {
    if (item.ownerId.isNotEmpty) return item.ownerId;
    if (item.dukkanId.isNotEmpty) return item.dukkanId;
    return item.docId;
  }

  Future<void> _openCenterWithPin(_ChefV2Item item) async {
    final controller = TextEditingController();
    final chefId = _resolvedChefId(item);

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Merkez Girişi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Devam etmek için şifre girin.',
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'PIN / Şifre',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _gold),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim() == '1234') {
                  Navigator.pop(dialogContext, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Şifre yanlış'),
                      backgroundColor: Colors.black,
                    ),
                  );
                }
              },
              child: const Text(
                'Giriş',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (ok == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GastronomiYonetimMerkezi(
            chefId: chefId,
            chefName: item.ad,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final previewImages = <String>[
      if (item.img.isNotEmpty) item.img,
      ...item.gallery,
    ].toSet().take(3).toList();

    return MouseRegion(
      onEnter: (_) {
        if (!kIsWeb) return;
        setState(() => _hover = true);
      },
      onExit: (_) {
        if (!kIsWeb) return;
        setState(() => _hover = false);
      },
      child: AnimatedScale(
        scale: _hover ? 1.015 : 1,
        duration: const Duration(milliseconds: 180),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {
            final chefId = _resolvedChefId(item);

            debugPrint('--- CARD DEBUG ---');
            debugPrint('ad       = ${item.ad}');
            debugPrint('docId    = ${item.docId}');
            debugPrint('dukkanId = ${item.dukkanId}');
            debugPrint('ownerId  = ${item.ownerId}');
            debugPrint('chefId   = $chefId');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SefItibarSayfasi(
                  dukkanId: chefId,
                  isAdmin: false,
                ),
              ),
            );
          },
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: widget.isFeatured
                        ? const Color(0x66FFB300)
                        : const Color(0x22FFB300),
                    width: widget.isFeatured ? 1.4 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: _hover ? 0.42 : 0.26),
                      blurRadius: _hover ? 28 : 18,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroImage(
                      imageUrl: item.img,
                      isFeatured: widget.isFeatured,
                      isSample: item.isSample,
                      ad: item.ad,
                      puan: item.puan,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.ad.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.uzman,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _MiniBadge(
                                icon: Icons.workspace_premium,
                                text: widget.isFeatured
                                    ? 'Öne Çıkan'
                                    : 'Usta Şef',
                              ),
                              const SizedBox(width: 8),
                              _MiniBadge(
                                icon: Icons.restaurant_menu,
                                text: item.gallery.isEmpty
                                    ? 'Profil'
                                    : '${item.gallery.length} galeri',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (previewImages.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                        child: _PreviewStrip(images: previewImages),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.fromLTRB(18, 8, 18, 18),
                        child: _EmptyPreview(),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: GestureDetector(
                  onTap: () {
                    _openCenterWithPin(item);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .72),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x33FFFFFF)),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final String imageUrl;
  final bool isFeatured;
  final bool isSample;
  final String ad;
  final String puan;

  const _HeroImage({
    required this.imageUrl,
    required this.isFeatured,
    required this.ad,
    required this.puan,
    required this.isSample,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            )
          else
            _fallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .12),
                  Colors.black.withValues(alpha: .20),
                  Colors.black.withValues(alpha: .78),
                ],
              ),
            ),
          ),
          if (isFeatured)
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .72),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x66FFB300)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: _gold, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Öne Çıkan Şef',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isSample)
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'ÖRNEK ŞEF',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0x33FFFFFF)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: _gold, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    puan,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black.withValues(alpha: .40),
                  backgroundImage:
                      imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ad,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _gold,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.black,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFF1B1B1B),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          color: Colors.white24,
          size: 56,
        ),
      ),
    );
  }
}

class _PreviewStrip extends StatelessWidget {
  final List<String> images;

  const _PreviewStrip({required this.images});

  @override
  Widget build(BuildContext context) {
    final preview = images.take(3).toList();

    return Row(
      children: List.generate(preview.length, (index) {
        final url = preview[index];
        return Expanded(
          child: Container(
            height: 78,
            margin: EdgeInsets.only(right: index == preview.length - 1 ? 0 : 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white30),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      alignment: Alignment.center,
      child: const Text(
        'Galeri henüz eklenmedi',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniBadge({
    required this.icon,
    required this.text,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _gold, size: 13),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
