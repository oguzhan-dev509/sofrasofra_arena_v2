import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MahalleMutfaklariSingleVitrinSection extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  final String selectedCategory;
  final bool isMobile;
  final int crossAxisCount;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)
      onOpenDetail;
  final void Function(QueryDocumentSnapshot<Map<String, dynamic>> doc)?
      onAddToCart;

  const MahalleMutfaklariSingleVitrinSection({
    super.key,
    required this.docs,
    required this.selectedCategory,
    required this.isMobile,
    required this.crossAxisCount,
    required this.onOpenDetail,
    this.onAddToCart,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF171717);
  static const Color _border = Color(0x22FFB300);

  static String _normalizeText(dynamic value) {
    return (value ?? '')
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  static String _safeText(dynamic value) {
    return (value ?? '').toString().trim();
  }

  static bool isMainCatalogDoc(Map<String, dynamic> data) {
    final source = _safeText(data['source']);
    final orderSource = _safeText(data['orderSource']);
    final sourceType = _safeText(data['sourceType']);
    final urunTipi = _safeText(data['urunTipi']);

    final isGalleryProduct = data['isGalleryProduct'] == true;
    final hiddenFromCatalog = data['hiddenFromCatalog'] == true;

    final ad = _safeText(data['ad'] ?? data['urunAdi']);

    if (source == 'ev_gallery' ||
        orderSource == 'ev_gallery' ||
        sourceType == 'ev_gallery' ||
        urunTipi == 'ev_gallery' ||
        isGalleryProduct ||
        hiddenFromCatalog ||
        ad == 'Ev Galeri Ürünü') {
      return false;
    }

    return true;
  }

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> uniqueSellerDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> unique = {};

    for (final doc in docs) {
      final data = doc.data();

      if (!isMainCatalogDoc(data)) {
        continue;
      }

      final kitchenName = _normalizeText(
        data['dukkan'] ??
            data['dukkanAdi'] ??
            data['mutfakAdi'] ??
            data['satici'] ??
            '',
      );

      final district = _normalizeText(
        data['ilce'] ?? data['ilçe'] ?? '',
      );

      final city = _normalizeText(
        data['sehir'] ?? data['şehir'] ?? '',
      );

      final ownerKey = _normalizeText(
        data['sellerId'] ??
            data['saticiId'] ??
            data['dukkanId'] ??
            data['ownerId'] ??
            data['userId'] ??
            '',
      );

      final sellerKey = kitchenName.isNotEmpty
          ? '$kitchenName|$district|$city'
          : ownerKey.isNotEmpty
              ? ownerKey
              : '';

      if (sellerKey.isEmpty) continue;

      unique.putIfAbsent(sellerKey, () => doc);
    }

    return unique.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final sellerDocs = uniqueSellerDocs(docs);

    if (sellerDocs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 80),
        child: _EmptySingleVitrin(),
      );
    }

    final title = selectedCategory == 'Tümü'
        ? 'Mahalle Mutfakları'
        : '$selectedCategory Mutfakları';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: title,
          subtitle:
              'Her üretici tek vitrin olarak listelenir. Ürünler ve galeri vitrine girince açılır.',
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sellerDocs.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            childAspectRatio: isMobile ? 0.78 : 0.76,
          ),
          itemBuilder: (context, index) {
            final doc = sellerDocs[index];
            final data = doc.data();

            return _SingleKitchenCard(
              data: data,
              onTap: () => onOpenDetail(doc),
              onAddToCart: onAddToCart == null ? null : () => onAddToCart!(doc),
            );
          },
        ),
      ],
    );
  }
}

class _SingleKitchenCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  const _SingleKitchenCard({
    required this.data,
    required this.onTap,
    this.onAddToCart,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF171717);

  String _safeText(dynamic value) {
    return (value ?? '').toString().trim();
  }

  String _imageUrl() {
    final direct = _safeText(
      data['producerImg'] ??
          data['ownerImg'] ??
          data['profilFoto'] ??
          data['img'] ??
          data['imageUrl'] ??
          data['imgUrl'] ??
          data['resim'],
    );

    if (direct.isNotEmpty) return direct;

    final images = data['images'];
    if (images is List && images.isNotEmpty) {
      return _safeText(images.first);
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final name = _safeText(
      data['dukkan'] ??
          data['dukkanAdi'] ??
          data['mutfakAdi'] ??
          data['satici'] ??
          'Mahalle Mutfağı',
    );

    final category = _safeText(
      data['kategori'] ?? data['category'] ?? 'Ev Lezzetleri',
    );

    final district = _safeText(data['ilce'] ?? data['ilçe']);
    final city = _safeText(data['sehir'] ?? data['şehir']);
    final location = [
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
    ].join(' / ');

    final img = _imageUrl();

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x22FFB300)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: img.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.storefront_outlined,
                        color: Colors.white38,
                        size: 42,
                      ),
                    )
                  : Image.network(
                      img,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const Center(
                          child: Icon(
                            Icons.storefront_outlined,
                            color: Colors.white38,
                            size: 42,
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Mahalle Mutfağı' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    location.isEmpty ? 'Mahalle Mutfağı' : location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            category.isEmpty ? 'Ev Lezzetleri' : category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _gold,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
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
          title,
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EmptySingleVitrin extends StatelessWidget {
  const _EmptySingleVitrin();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(
          Icons.search_off_rounded,
          color: Colors.white38,
          size: 42,
        ),
        SizedBox(height: 12),
        Text(
          'Bu kategoride mutfak bulunamadı.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
