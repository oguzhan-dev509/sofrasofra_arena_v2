import 'package:flutter/material.dart';

class SefImzaTabagiPremiumCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final dynamic price;
  final dynamic gelAlFiyat;
  final dynamic goturFiyat;
  final VoidCallback? onAddToCart;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SefImzaTabagiPremiumCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.price,
    this.gelAlFiyat,
    this.goturFiyat,
    required this.onEdit,
    required this.onDelete,
    required this.onAddToCart,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _dark = Color(0xFF101010);
  static const Color _panel = Color(0xFF171717);

  String _formatPrice(dynamic value) {
    if (value == null) return '—';
    final raw = value.toString().trim();
    if (raw.isEmpty || raw == '0' || raw == '0.0') return '—';
    return '$raw TL';
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;
    final hasDescription = description.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: _dark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _gold.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _emptyImage(),
                    )
                  else
                    _emptyImage(),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        if (onEdit != null)
                          _roundIconButton(
                            icon: Icons.edit_rounded,
                            onTap: onEdit!,
                          ),
                        if (onEdit != null && onDelete != null)
                          const SizedBox(width: 8),
                        if (onDelete != null)
                          _roundIconButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: onDelete!,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.trim().isEmpty ? 'Şefin İmza Tabağı' : title.trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'TEST: ÇİFT FİYAT KARTI AKTİF',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasDescription) ...[
                    const SizedBox(height: 8),
                    Text(
                      description.trim(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Satış Fiyatları',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _priceBox(
                                label: 'Gel-Al',
                                value: gelAlFiyat ?? price,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _priceBox(
                                label: 'Götür',
                                value: goturFiyat,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAddToCart,
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Sepete Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceBox({
    required String label,
    required dynamic value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.68),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _formatPrice(value),
            style: const TextStyle(
              color: _gold,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyImage() {
    return Container(
      color: const Color(0xFF222222),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: _gold,
          size: 46,
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.68),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
