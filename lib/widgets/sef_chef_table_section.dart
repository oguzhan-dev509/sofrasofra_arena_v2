import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/create_reservation_page.dart';

class SefChefTableSection extends StatelessWidget {
  const SefChefTableSection({super.key});

  static const Color gold = Color(0xFFFFB300);
  static const Color card = Color(0xFF121212);

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: gold,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.6,
      ),
    );
  }

  Widget _pill(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: gold),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String body) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(6),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: gold, size: 20),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _button(String text, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: filled ? gold : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? gold : Colors.white12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? Colors.black : Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('ŞEFİN MASASI'),
          const SizedBox(height: 10),
          const Text(
            'Sınırlı kontenjanlı, şef ile birebir etkileşim sunan '
            'özel gastronomi deneyimi.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill('VIP Deneyim', Icons.workspace_premium_rounded),
              _pill('Sınırlı Katılım', Icons.group),
              _pill('Şef Sunumu', Icons.restaurant_menu),
              _pill('Tadım Menüsü', Icons.menu_book),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _infoCard(
                Icons.restaurant,
                'Deneyim',
                'Şef anlatımıyla ilerleyen tadım menüsü.',
              ),
              const SizedBox(width: 12),
              _infoCard(
                Icons.people,
                'Katılım',
                'Az sayıda misafir ile özel ortam.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoCard(
                Icons.wine_bar,
                'Eşleşme',
                'İçecek ve lezzet uyumları.',
              ),
              const SizedBox(width: 12),
              _infoCard(
                Icons.schedule,
                'Rezervasyon',
                'Ön planlı özel tarihli deneyim.',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '• Şef ile birebir iletişim\n'
            '• Premium masa deneyimi\n'
            '• Özel günler için ideal konsept\n'
            '• Seçkin katılımcı yapısı',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateReservationPage(),
                    ),
                  );
                },
                child: _button('Rezervasyon Planla', filled: true),
              ),
              const SizedBox(width: 10),
              _button('Detayları Gör'),
            ],
          ),
        ],
      ),
    );
  }
}
