import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/fullscreen_gallery.dart';

class EvProductGallery extends StatefulWidget {
  final List<String>? images;
  final String fallbackImage;
  final double height;
  final BorderRadius borderRadius;
  final ValueChanged<int>? onIndexChanged;
  final bool showThumbnails;

  // Admin opsiyonları
  final bool isOwner;
  final VoidCallback? onAddPhoto;
  final ValueChanged<int>? onDeletePhoto;
  final ValueChanged<int>? onSetCoverPhoto;

  const EvProductGallery({
    super.key,
    this.images,
    required this.fallbackImage,
    this.height = 420,
    required this.borderRadius,
    this.onIndexChanged,
    this.showThumbnails = true,
    this.isOwner = false,
    this.onAddPhoto,
    this.onDeletePhoto,
    this.onSetCoverPhoto,
  });

  @override
  State<EvProductGallery> createState() => _EvProductGalleryState();
}

class _EvProductGalleryState extends State<EvProductGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const Color _gold = Color(0xFFFFB300);

  List<String> get _images {
    final raw = widget.images ?? [];

    final gallery = raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    return List.unmodifiable(gallery);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant EvProductGallery oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newImages = _images;
    final safeIndex =
        newImages.isEmpty ? 0 : _currentIndex.clamp(0, newImages.length - 1);

    if (_currentIndex != safeIndex) {
      setState(() {
        _currentIndex = safeIndex;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || newImages.isEmpty) return;
      _pageController.jumpToPage(safeIndex);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    final images = _images;
    if (!_pageController.hasClients) return;
    if (images.length <= 1) return;

    final safeIndex = index.clamp(0, images.length - 1);

    _pageController.animateToPage(
      safeIndex,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );

    widget.onIndexChanged?.call(safeIndex);
  }

  Widget _buildArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildOwnerButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ),
    );
  }

  Widget _buildThumb({
    required String imageUrl,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 74,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? _gold : Colors.white24,
            width: isActive ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyGallery() {
    return Container(
      height: widget.height,
      width: double.infinity,
      color: const Color(0xFF151515),
      alignment: Alignment.center,
      child: widget.isOwner && widget.onAddPhoto != null
          ? GestureDetector(
              onTap: widget.onAddPhoto,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x55FFB300)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: _gold),
                    SizedBox(width: 8),
                    Text(
                      'Fotoğraf ekle',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const Icon(
              Icons.image_not_supported_outlined,
              size: 42,
              color: Colors.white38,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;

    if (images.isEmpty) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: _buildEmptyGallery(),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        children: [
          SizedBox(
            height: widget.height,
            width: double.infinity,
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                if (_currentIndex == index) return;
                setState(() {
                  _currentIndex = index;
                });
                widget.onIndexChanged?.call(index);
              },
              itemBuilder: (context, index) {
                final imageUrl = images[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenGallery(
                          images: images,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.black,
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: widget.height,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: _gold),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF151515),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 42,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (images.length > 1)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildArrow(
                  icon: Icons.chevron_left,
                  onTap: () => _goToPage(_currentIndex - 1),
                ),
              ),
            ),
          if (images.length > 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildArrow(
                  icon: Icons.chevron_right,
                  onTap: () => _goToPage(_currentIndex + 1),
                ),
              ),
            ),
          if (widget.isOwner)
            Positioned(
              top: 12,
              left: 12,
              child: Row(
                children: [
                  if (widget.onAddPhoto != null)
                    _buildOwnerButton(
                      icon: Icons.add_photo_alternate_outlined,
                      iconColor: _gold,
                      onTap: widget.onAddPhoto!,
                    ),
                  if (widget.onAddPhoto != null &&
                      widget.onSetCoverPhoto != null)
                    const SizedBox(width: 8),
                  if (widget.onSetCoverPhoto != null)
                    _buildOwnerButton(
                      icon: Icons.star_rounded,
                      iconColor: _gold,
                      onTap: () => widget.onSetCoverPhoto!(_currentIndex),
                    ),
                ],
              ),
            ),
          if (widget.isOwner && widget.onDeletePhoto != null)
            Positioned(
              top: 12,
              right: images.length > 1 ? 64 : 12,
              child: _buildOwnerButton(
                icon: Icons.close_rounded,
                iconColor: Colors.white,
                onTap: () => widget.onDeletePhoto!(_currentIndex),
              ),
            ),
          if (images.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (widget.showThumbnails && images.length > 1)
            Positioned(
              left: 12,
              right: 12,
              bottom: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return _buildThumb(
                          imageUrl: images[index],
                          isActive: index == _currentIndex,
                          onTap: () => _goToPage(index),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
