import 'package:flutter/material.dart';

class FavoriteHeartButton extends StatelessWidget {
  final bool isFavorite;
  final bool isLoading;
  final VoidCallback? onPressed;
  final double size;

  const FavoriteHeartButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.isLoading = false,
    this.size = 42,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _favoriteRed = Color(0xFFFF3B5C);
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isFavorite ? 'Favorilerden çıkar' : 'Favorilere ekle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFavorite
                  ? _favoriteRed.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.68),
              border: Border.all(
                color: isFavorite
                    ? _favoriteRed.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.18),
                width: isFavorite ? 1.6 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: size * 0.42,
                      height: size * 0.42,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _gold,
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        key: ValueKey<bool>(isFavorite),
                        size: size * 0.55,
                        color: isFavorite ? _favoriteRed : Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
