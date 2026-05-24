class RestoranMenuItemModel {
  const RestoranMenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.category,
    required this.img,
    this.profileImg = '',
    required this.gelAlFiyat,
    required this.goturFiyat,
    this.images = const [],
    this.isActive = true,
    this.isAvailable = true,
    this.isFeatured = false,
    this.preparationMinutes = 20,
    this.allergenNote = '',
  });

  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final String category;

  /// Sofrasofra medya standardı:
  /// Kapak fotoğrafı: img
  /// Küçük profil/logo/baş foto: profileImg
  /// Galeri: images[]
  /// UI önceliği: img → images
  final String img;
  final String profileImg;
  final List<String> images;

  final double gelAlFiyat;
  final double goturFiyat;

  final bool isActive;
  final bool isAvailable;
  final bool isFeatured;
  final int preparationMinutes;
  final String allergenNote;

  bool get canOrder => isActive && isAvailable;

  String get priceText {
    if (gelAlFiyat > 0 && goturFiyat > 0) {
      return 'Gel-Al ₺${gelAlFiyat.toStringAsFixed(0)} • Götür ₺${goturFiyat.toStringAsFixed(0)}';
    }

    if (gelAlFiyat > 0) {
      return 'Gel-Al ₺${gelAlFiyat.toStringAsFixed(0)}';
    }

    if (goturFiyat > 0) {
      return 'Götür ₺${goturFiyat.toStringAsFixed(0)}';
    }

    return 'Fiyat hazırlanıyor';
  }

  String get availabilityText {
    if (!isActive) {
      return 'Menüde pasif';
    }

    if (!isAvailable) {
      return 'Stokta yok';
    }

    return 'Siparişe hazır';
  }

  String get imageForUi {
    if (img.trim().isNotEmpty) {
      return img;
    }

    if (images.isNotEmpty) {
      return images.first;
    }

    return '';
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }

    return 0;
  }

  static int _readInt(dynamic value, {int fallback = 20}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  static List<String> _readImages(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    return const [];
  }

  static RestoranMenuItemModel fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    return RestoranMenuItemModel(
      id: id,
      restaurantId: (data['restaurantId'] ?? '').toString(),
      name: (data['name'] ?? data['productName'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      category: (data['category'] ?? 'Menü').toString(),
      img: (data['img'] ?? data['imageUrl'] ?? '').toString(),
      profileImg:
          (data['profileImg'] ?? data['avatarUrl'] ?? data['logoUrl'] ?? '')
              .toString(),
      images: _readImages(data['images']),
      gelAlFiyat: _readDouble(data['gelAlFiyat'] ?? data['price']),
      goturFiyat: _readDouble(data['goturFiyat']),
      isActive: data['isActive'] != false,
      isAvailable: data['isAvailable'] != false,
      isFeatured: data['isFeatured'] == true,
      preparationMinutes: _readInt(
        data['preparationMinutes'],
        fallback: 20,
      ),
      allergenNote: (data['allergenNote'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toCartSnapshot({
    required String restaurantName,
    required String deliveryMode,
  }) {
    final selectedPrice = deliveryMode == 'gotur' ? goturFiyat : gelAlFiyat;

    return {
      'sellerType': 'restaurant',
      'sellerId': restaurantId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'productId': id,
      'productName': name,
      'category': category,
      'price': selectedPrice,
      'gelAlFiyat': gelAlFiyat,
      'goturFiyat': goturFiyat,
      'deliveryMode': deliveryMode,
      'imageUrl': imageForUi,
      'quantity': 1,
      'feeIncludedInPrice': true,
      'deliveryIncludedInPrice': true,
      'isRestaurantLaunchPreview': true,
    };
  }
}
