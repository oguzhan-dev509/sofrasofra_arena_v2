import 'package:flutter/material.dart';

String _safeHttpUrlOrEmpty(String? url) {
  final value = (url ?? '').trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  return '';
}

class AdminCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const AdminCircleButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 19),
      ),
    );
  }
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
        GestureDetector(
          onTap: onOpenCover,
          child: safeCover.isEmpty
              ? Container(
                  color: const Color(0xFF111111),
                  child: const Center(
                    child: Icon(
                      Icons.landscape,
                      color: Colors.white24,
                      size: 42,
                    ),
                  ),
                )
              : Image.network(
                  safeCover,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.15),
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFF111111),
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: Colors.white24,
                        size: 42,
                      ),
                    ),
                  ),
                ),
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x00000000),
                Color(0x12000000),
                Color(0x30000000),
                Color(0x5C050505),
              ],
              stops: [0.0, 0.38, 0.76, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 20,
          top: 18,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(125),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Text(
                  'SOFRASOFRA ELİT GASTRONOMİ ARENA',
                  style: TextStyle(
                    color: Color(0xFFFFD166),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0x3300C853)
                      : const Color(0x33FF5252),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isActive
                        ? const Color(0x6600E676)
                        : const Color(0x66FF6E6E),
                  ),
                ),
                child: Text(
                  isActive ? 'AKTİF' : 'PASİF',
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFFB9F6CA)
                        : const Color(0xFFFFCDD2),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(125),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x33FFB300)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFFB300),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'ÖNE ÇIKAN ŞEF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isAdmin)
          Positioned(
            top: 20,
            right: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'KAPAK',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdminCircleButton(
                        icon: Icons.delete_outline,
                        color: Colors.redAccent,
                        onTap: onDeleteCover,
                      ),
                      const SizedBox(width: 10),
                      AdminCircleButton(
                        icon: Icons.photo,
                        color: const Color(0xFFFFB300),
                        onTap: onEditCover,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'PROFİL',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdminCircleButton(
                        icon: Icons.person_remove_alt_1,
                        color: Colors.redAccent,
                        onTap: onDeleteProfile,
                      ),
                      const SizedBox(width: 10),
                      AdminCircleButton(
                        icon: Icons.add_a_photo,
                        color: const Color(0xFFFFB300),
                        onTap: onEditProfile,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          left: 22,
          right: 22,
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(30),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onOpenProfile,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x55FFFFFF),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(60),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: safeProfile.isEmpty
                          ? Container(
                              color: const Color(0xFF1C1C1C),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white38,
                                size: 34,
                              ),
                            )
                          : Image.network(
                              safeProfile,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF1C1C1C),
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white38,
                                  size: 34,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.04,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (bio.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          bio,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
