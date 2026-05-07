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
