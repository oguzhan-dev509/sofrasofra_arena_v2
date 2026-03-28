import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/chef_signature_dish_detail_page.dart';

class ChefSignatureKitchenPage extends StatelessWidget {
  final String chefId;

  const ChefSignatureKitchenPage({
    super.key,
    required this.chefId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          'ŞEFİN İMZA MUTFAĞI',
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Görsel Galeri'),
          _GallerySection(chefId: chefId),
          const SizedBox(height: 24),
          const _SectionTitle(title: 'İmza Tabaklar'),
          _SignatureDishesSection(chefId: chefId),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  final String chefId;

  const _GallerySection({required this.chefId});

  void _showGalleryPreview(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent),
            ),
            Center(
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 60,
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chef_gallery')
          .where('chefId', isEqualTo: chefId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD54F),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Galeri yüklenirken hata oluştu.\n${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Henüz galeri görseli yok.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final m = docs[index].data();
              final img = (m['imageUrl'] ?? '').toString();

              return Container(
                width: 120,
                margin: EdgeInsets.only(
                  left: index == 0 ? 16 : 12,
                  right: index == docs.length - 1 ? 16 : 0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x22FFD54F)),
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  onTap: img.isEmpty
                      ? null
                      : () => _showGalleryPreview(context, img),
                  child: img.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white54,
                          ),
                        )
                      : Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                              ),
                            );
                          },
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SignatureDishesSection extends StatelessWidget {
  final String chefId;

  const _SignatureDishesSection({required this.chefId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chef_signature_dishes')
          .where('chefId', isEqualTo: chefId)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD54F),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'İmza tabaklar yüklenirken hata oluştu.\n${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Henüz imza tabak eklenmemiş.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final m = docs[index].data();

            final title = (m['title'] ?? 'İsimsiz Tabak').toString();
            final desc = (m['description'] ?? '').toString();
            final img = (m['imageUrl'] ?? '').toString();

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChefSignatureDishDetailPage(
                      title: title,
                      description: desc,
                      imageUrl: img,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1B),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x33FFD54F)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: img.isEmpty
                          ? AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                width: double.infinity,
                                color: const Color(0xFF222222),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.white54,
                                  size: 34,
                                ),
                              ),
                            )
                          : AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Image.network(
                                img,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    width: double.infinity,
                                    color: const Color(0xFF222222),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.white54,
                                      size: 34,
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              desc,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
