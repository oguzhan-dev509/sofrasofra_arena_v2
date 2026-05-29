import 'package:flutter/material.dart';

class BlogDetaySayfasi extends StatelessWidget {
  final String title;
  final String summary;
  final String content;
  final String kategoriLabel;
  final String? coverImage;

  const BlogDetaySayfasi({
    super.key,
    required this.title,
    required this.summary,
    required this.content,
    required this.kategoriLabel,
    this.coverImage,
  });

  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final hasImage = coverImage != null && coverImage!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Blog ve Rehberler',
          style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0x22FFB300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.network(
                      coverImage!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withAlpha(22),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _gold.withAlpha(90)),
                        ),
                        child: Text(
                          kategoriLabel,
                          style: const TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        summary,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        content,
                        style: const TextStyle(
                          color: Color(0xFFE6E6E6),
                          fontSize: 15.5,
                          height: 1.65,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
