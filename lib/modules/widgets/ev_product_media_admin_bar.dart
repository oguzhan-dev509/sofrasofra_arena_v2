import 'package:flutter/material.dart';

class EvProductMediaAdminBar extends StatelessWidget {
  final VoidCallback onAddCoverPhoto;
  final VoidCallback onDeleteCoverPhoto;

  final VoidCallback onAddGalleryPhoto;
  final VoidCallback onDeleteCurrentGalleryPhoto;
  final VoidCallback onSetCurrentAsCover;

  final bool busy;

  const EvProductMediaAdminBar({
    super.key,
    required this.onAddCoverPhoto,
    required this.onDeleteCoverPhoto,
    required this.onAddGalleryPhoto,
    required this.onDeleteCurrentGalleryPhoto,
    required this.onSetCurrentAsCover,
    this.busy = false,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionBox(
          title: 'KAPAK YÖNETİMİ',
          children: [
            _actionButton(
              icon: Icons.photo_camera_back_outlined,
              label: 'Kapak Foto Ekle / Değiştir',
              onTap: busy ? null : onAddCoverPhoto,
            ),
            _actionButton(
              icon: Icons.delete_outline,
              label: 'Kapak Foto Sil',
              onTap: busy ? null : onDeleteCoverPhoto,
              isDanger: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionBox(
          title: 'GALERİ YÖNETİMİ',
          children: [
            _actionButton(
              icon: Icons.add_photo_alternate_outlined,
              label: 'Galeriye Ekle',
              onTap: busy ? null : onAddGalleryPhoto,
            ),
            _actionButton(
              icon: Icons.workspace_premium_outlined,
              label: 'Bu Görseli Kapak Yap',
              onTap: busy ? null : onSetCurrentAsCover,
            ),
            _actionButton(
              icon: Icons.delete_outline,
              label: 'Bu Görseli Sil',
              onTap: busy ? null : onDeleteCurrentGalleryPhoto,
              isDanger: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool isDanger = false,
  }) {
    final borderColor = isDanger
        ? Colors.redAccent.withValues(alpha: 0.35)
        : const Color(0x26FFB300);
    final iconColor = isDanger ? Colors.redAccent : _gold;
    final textColor = isDanger ? Colors.redAccent : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0D),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionBox extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionBox({
    required this.title,
    required this.children,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x26FFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: children,
          ),
        ],
      ),
    );
  }
}
