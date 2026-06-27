import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/controllers/favorite_controller.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/favorite_heart_button.dart';

class FavoriteProductButton extends StatefulWidget {
  final FavoriteController controller;

  final String productId;
  final String sellerId;
  final String sellerType;
  final String productName;
  final String imageUrl;
  final double price;
  final String category;
  final String sellerName;

  final double size;
  final ValueChanged<bool>? onChanged;
  final ValueChanged<Object>? onError;

  const FavoriteProductButton({
    super.key,
    required this.controller,
    required this.productId,
    required this.sellerId,
    required this.sellerType,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.category,
    this.sellerName = '',
    this.size = 42,
    this.onChanged,
    this.onError,
  });

  @override
  State<FavoriteProductButton> createState() => _FavoriteProductButtonState();
}

class _FavoriteProductButtonState extends State<FavoriteProductButton> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadFavorites();
    });
  }

  @override
  void didUpdateWidget(covariant FavoriteProductButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller.loadFavorites();
      });
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final isFavorite = await widget.controller.toggleFavorite(
        productId: widget.productId,
        sellerId: widget.sellerId,
        sellerType: widget.sellerType,
        productName: widget.productName,
        imageUrl: widget.imageUrl,
        price: widget.price,
        category: widget.category,
        sellerName: widget.sellerName,
      );

      widget.onChanged?.call(isFavorite);
    } catch (error) {
      widget.onError?.call(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final isFavorite = widget.controller.isFavorite(
          sellerType: widget.sellerType,
          productId: widget.productId,
        );

        final isLoading = widget.controller.isLoadingFavorites ||
            widget.controller.isLoading(
              sellerType: widget.sellerType,
              productId: widget.productId,
            );

        return FavoriteHeartButton(
          isFavorite: isFavorite,
          isLoading: isLoading,
          size: widget.size,
          onPressed: _toggleFavorite,
        );
      },
    );
  }
}
