import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/create_reservation_page.dart';

class SefCateringSection extends StatelessWidget {
  const SefCateringSection({
    super.key,
    required this.chefId,
    required this.chefName,
  });

  final String chefId;
  final String chefName;

  static const Color gold = Color(0xFFFFB300);
  static const Color card = Color(0xFF121212);

  Widget _sectionTitle(String text) {
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

  Widget _pill(
    BuildContext context,
    String text, {
    IconData? icon,
    String? tableTitle,
    String? concept,
    String? capacity,
    int? unitPrice,
  }) {
    final isInteractive = tableTitle != null &&
        concept != null &&
        capacity != null &&
        unitPrice != null;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: !isInteractive
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateReservationPage(
                    chefId: chefId,
                    chefName: chefName,
                    tableTitle: tableTitle,
                    concept: concept,
                    capacity: capacity,
                    unitPrice: unitPrice,
                  ),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(isInteractive ? 10 : 6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isInteractive ? const Color(0x33FFB300) : Colors.white10,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: gold),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                color: isInteractive ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String body,
  }) {
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

  Widget _ctaButton(
    BuildContext context,
    String text, {
    bool filled = false,
    String? tableTitle,
    String? concept,
    String? capacity,
    int? unitPrice,
  }) {
    final isInteractive = tableTitle != null &&
        concept != null &&
        capacity != null &&
        unitPrice != null;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: !isInteractive
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateReservationPage(
                    chefId: chefId,
                    chefName: chefName,
                    tableTitle: tableTitle,
                    concept: concept,
                    capacity: capacity,
                    unitPrice: unitPrice,
                  ),
                ),
              );
            },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: filled ? 18 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: filled ? gold : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: filled ? gold : Colors.white12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: filled ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('KURUMSAL DAVETLER / CATERING'),
          const SizedBox(height: 10),
          const Text(
            'Marka etkinlikleri, VIP davetler ve özel organizasyonlar için '
            'şef imzası taşıyan, uçtan uca planlanmış premium gastronomi deneyimleri sunulur.',
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
              _pill(
                context,
                'Kurumsal Etkinlik',
                icon: Icons.apartment_rounded,
                tableTitle: 'Kurumsal Etkinlik',
                concept: 'Kurumsal Menü',
                capacity: '20+ Kişi',
                unitPrice: 2000,
              ),
              _pill(
                context,
                'Özel Davet',
                icon: Icons.celebration_rounded,
                tableTitle: 'Özel Davet',
                concept: 'Kişiye Özel Menü',
                capacity: '2-10 Kişi',
                unitPrice: 1800,
              ),
              _pill(
                context,
                'Butik Catering',
                icon: Icons.room_service_rounded,
                tableTitle: 'Butik Catering',
                concept: 'Catering Hizmeti',
                capacity: '10-100 Kişi',
                unitPrice: 1500,
              ),
              _pill(
                context,
                "Chef's Table",
                icon: Icons.table_restaurant_rounded,
                tableTitle: "Chef's Table",
                concept: 'Özel Şef Deneyimi',
                capacity: '2-8 Kişi',
                unitPrice: 2200,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoCard(
                icon: Icons.menu_book_rounded,
                title: 'Menü Kurgusu',
                body:
                    'Etkinliğin ruhuna ve davetli profiline göre özel menü akışı tasarlanır.',
              ),
              const SizedBox(width: 12),
              _infoCard(
                icon: Icons.groups_rounded,
                title: 'Servis & Ekip',
                body:
                    'Profesyonel servis standardı ile sahada güçlü operasyon yönetimi sağlanır.',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoCard(
                icon: Icons.palette_rounded,
                title: 'Sunum Dili',
                body:
                    'Marka kimliğine uygun tabak, servis ve masa üstü deneyim dili oluşturulur.',
              ),
              const SizedBox(width: 12),
              _infoCard(
                icon: Icons.location_on_rounded,
                title: 'Lokasyon Esnekliği',
                body:
                    'Mekân bağımsız kurgularla villa, ofis, bahçe ve özel alan organizasyonları yönetilir.',
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            '• Marka lansmanları ve basın davetleri\n'
            '• Yönetici yemekleri ve VIP ağırlama\n'
            '• Kişiye özel menü planlama ve akış tasarımı\n'
            '• Profesyonel ekip, servis standardı ve şef dokunuşu',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ctaButton(
                context,
                'Teklif Planla',
                filled: true,
                tableTitle: 'Kurumsal Etkinlik',
                concept: 'Kurumsal Menü',
                capacity: '20+ Kişi',
                unitPrice: 2000,
              ),
              _ctaButton(
                context,
                'Detayları Gör',
                tableTitle: 'Özel Davet',
                concept: 'Kişiye Özel Menü',
                capacity: '2-10 Kişi',
                unitPrice: 1800,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
