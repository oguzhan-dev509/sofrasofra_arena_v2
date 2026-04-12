import 'package:flutter/material.dart';

String _safeHttpUrlOrEmpty(String? url) {
  final value = (url ?? '').trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  return '';
}

class HeroHeader extends StatelessWidget {
  final String coverImageUrl;
  final String profileImageUrl;
  final String title;
  final String subtitle;
  final String bio;
  final bool isAdmin;
  final bool isActive;
  final VoidCallback onEditCover;
  final VoidCallback onDeleteCover;
  final VoidCallback onEditProfile;
  final VoidCallback onDeleteProfile;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenCover;

  const HeroHeader({
    super.key,
    required this.coverImageUrl,
    required this.profileImageUrl,
    required this.title,
    required this.subtitle,
    required this.bio,
    required this.isAdmin,
    required this.isActive,
    required this.onEditCover,
    required this.onDeleteCover,
    required this.onEditProfile,
    required this.onDeleteProfile,
    this.onOpenProfile,
    this.onOpenCover,
  });

  @override
  Widget build(BuildContext context) {
    final safeCover = _safeHttpUrlOrEmpty(coverImageUrl);
    final safeProfile = _safeHttpUrlOrEmpty(profileImageUrl);

    return Stack(
      fit: StackFit.expand,
      children: [
        safeCover.isEmpty
            ? Container(color: Colors.black)
            : Image.network(safeCover, fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.4)),
        Center(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ],
    );
  }
}
