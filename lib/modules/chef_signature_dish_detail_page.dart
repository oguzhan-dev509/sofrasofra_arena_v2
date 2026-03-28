import 'package:flutter/material.dart';

class ChefSignatureDishDetailPage extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;

  const ChefSignatureDishDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          'İMZA TABAK DETAYI',
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFD54F)),
      ),
      body: ListView(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: imageUrl.isEmpty
                ? Container(
                    height: 260,
                    color: const Color(0xFF222222),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white54,
                      size: 44,
                    ),
                  )
                : AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: const Color(0xFF222222),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white54,
                            size: 44,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x22FFD54F),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Şefin İmza Tabağı',
                    style: TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title.isEmpty ? 'İsimsiz Tabak' : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x22FFD54F)),
                  ),
                  child: Text(
                    description.isEmpty
                        ? 'Bu tabak için henüz açıklama eklenmemiş.'
                        : description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Şef Yorumu',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bu bölüm daha sonra şefin sunum yaklaşımı, servis önerisi ve tabağın karakterini anlatan özel metinlerle güçlendirilebilir.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.6,
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
