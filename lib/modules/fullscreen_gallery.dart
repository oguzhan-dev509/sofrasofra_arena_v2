import 'package:flutter/material.dart';

class FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _controller;
  late int currentIndex;

  // Zoom kontrolü için
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();

    // Güvenli index (out of range crash önler)
    currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);

    _controller = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final isZoomed = _transformationController.value != Matrix4.identity();

    _transformationController.value =
        isZoomed ? Matrix4.identity() : Matrix4.identity()
          ..scale(2.5);
  }

  @override
  Widget build(BuildContext context) {
    // Güvenlik: boş liste
    if (widget.images.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Görsel bulunamadı",
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 🔥 Ana galeri
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) {
              setState(() {
                currentIndex = i;
                _transformationController.value = Matrix4.identity();
              });
            },
            itemBuilder: (_, i) {
              final img = widget.images[i];

              return GestureDetector(
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: Image.network(
                      img,
                      fit: BoxFit.contain,

                      // 🔄 loading indicator
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFB300),
                          ),
                        );
                      },

                      // ❌ hata fallback
                      errorBuilder: (_, __, ___) {
                        return const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 60,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),

          // 🔢 sayaç
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${currentIndex + 1}/${widget.images.length}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // ❌ kapatma
          Positioned(
            top: 50,
            left: 10,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
