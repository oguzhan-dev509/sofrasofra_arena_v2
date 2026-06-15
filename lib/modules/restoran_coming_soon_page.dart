import 'package:flutter/material.dart';

class RestoranComingSoonPage extends StatelessWidget {
  const RestoranComingSoonPage({super.key});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🔥 RESTORAN LANSMAN ZEMİNİ
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Color(0xFF16110A),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),

          /// 🔥 PREMIUM OVERLAY (karanlık + derinlik)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          /// 🔥 ALT BLOK (mesajlar)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 48,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// 🔥 BAŞLIK
                  const Text(
                    'RESTORANLAR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 ALT METİN (senin seçtiğin premium versiyon)
                  const Text(
                    'Ürün sizin. Emek sizin. Kazanç sizin.\n\n'
                    'Tahsilat aynı gün hesabınızda.\n'
                    'Asıl farkı ise ilk açılışta göreceksiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// 🔥 CTA BUTON
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      'İlk Açılıştan Haberdar Ol',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
