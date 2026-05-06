import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/ev_product_media_admin_bar.dart';

class UrunDetayMediaAdminPanel extends StatelessWidget {
  final bool busy;
  final VoidCallback onAddCoverPhoto;
  final VoidCallback onDeleteCoverPhoto;
  final VoidCallback onAddGalleryPhoto;
  final VoidCallback onDeleteCurrentGalleryPhoto;
  final VoidCallback onSetCurrentAsCover;

  const UrunDetayMediaAdminPanel({
    super.key,
    required this.busy,
    required this.onAddCoverPhoto,
    required this.onDeleteCoverPhoto,
    required this.onAddGalleryPhoto,
    required this.onDeleteCurrentGalleryPhoto,
    required this.onSetCurrentAsCover,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF12351F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _gold.withValues(alpha: 0.35),
            ),
          ),
          child: const Text(
            'DEBUG: ÜRETİCİ / ADMIN MODU - yönetim araçları açık',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        EvProductMediaAdminBar(
          busy: busy,
          onAddCoverPhoto: onAddCoverPhoto,
          onDeleteCoverPhoto: onDeleteCoverPhoto,
          onAddGalleryPhoto: onAddGalleryPhoto,
          onDeleteCurrentGalleryPhoto: onDeleteCurrentGalleryPhoto,
          onSetCurrentAsCover: onSetCurrentAsCover,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
