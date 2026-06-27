import 'package:flutter/foundation.dart';
import 'package:sofrasofra_arena_v2/services/favorite_service.dart';

class FavoriteController extends ChangeNotifier {
  final Set<String> _favoriteIds = <String>{};
  final Set<String> _loadingIds = <String>{};

  bool _isInitialized = false;
  bool _isLoadingFavorites = false;
  bool _isDisposed = false;

  bool get isInitialized => _isInitialized;

  bool get isLoadingFavorites => _isLoadingFavorites;

  Set<String> get favoriteIds => Set<String>.unmodifiable(_favoriteIds);

  bool isFavorite({
    required String sellerType,
    required String productId,
  }) {
    final favoriteId = FavoriteService.favoriteDocumentId(
      sellerType: sellerType,
      productId: productId,
    );

    return _favoriteIds.contains(favoriteId);
  }

  bool isLoading({
    required String sellerType,
    required String productId,
  }) {
    final favoriteId = FavoriteService.favoriteDocumentId(
      sellerType: sellerType,
      productId: productId,
    );

    return _loadingIds.contains(favoriteId);
  }

  Future<void> loadFavorites({
    bool forceRefresh = false,
  }) async {
    if (_isLoadingFavorites) {
      return;
    }

    if (_isInitialized && !forceRefresh) {
      return;
    }

    _isLoadingFavorites = true;
    _safeNotifyListeners();

    try {
      final loadedIds = await FavoriteService.loadFavoriteIds();

      _favoriteIds
        ..clear()
        ..addAll(loadedIds);

      _isInitialized = true;
    } finally {
      _isLoadingFavorites = false;
      _safeNotifyListeners();
    }
  }

  Future<bool> toggleFavorite({
    required String productId,
    required String sellerId,
    required String sellerType,
    required String productName,
    required String imageUrl,
    required double price,
    required String category,
    String sellerName = '',
  }) async {
    final favoriteId = FavoriteService.favoriteDocumentId(
      sellerType: sellerType,
      productId: productId,
    );

    if (_loadingIds.contains(favoriteId)) {
      return _favoriteIds.contains(favoriteId);
    }

    final wasFavorite = _favoriteIds.contains(favoriteId);
    final shouldBeFavorite = !wasFavorite;

    _loadingIds.add(favoriteId);

    if (shouldBeFavorite) {
      _favoriteIds.add(favoriteId);
    } else {
      _favoriteIds.remove(favoriteId);
    }

    _safeNotifyListeners();

    try {
      await FavoriteService.setFavorite(
        shouldBeFavorite: shouldBeFavorite,
        productId: productId,
        sellerId: sellerId,
        sellerType: sellerType,
        productName: productName,
        imageUrl: imageUrl,
        price: price,
        category: category,
        sellerName: sellerName,
      );

      return shouldBeFavorite;
    } catch (_) {
      if (wasFavorite) {
        _favoriteIds.add(favoriteId);
      } else {
        _favoriteIds.remove(favoriteId);
      }

      rethrow;
    } finally {
      _loadingIds.remove(favoriteId);
      _safeNotifyListeners();
    }
  }

  void clearLocalFavorites() {
    _favoriteIds.clear();
    _loadingIds.clear();
    _isInitialized = false;
    _isLoadingFavorites = false;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
