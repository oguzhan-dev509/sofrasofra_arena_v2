class RestoranModel {
  const RestoranModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.cuisine,
    required this.city,
    required this.district,
    required this.preparationText,
    required this.ratingText,
    this.membershipType = 'free',
    this.isFounder = true,
    this.isOpen = false,
    this.isLaunchReady = false,
    this.supportsGelAl = true,
    this.supportsGotur = true,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String cuisine;
  final String city;
  final String district;
  final String preparationText;
  final String ratingText;
  final String membershipType;
  final bool isFounder;
  final bool isOpen;
  final bool isLaunchReady;
  final bool supportsGelAl;
  final bool supportsGotur;

  String get locationText {
    if (city.trim().isEmpty) return district;
    return '$district / $city';
  }

  String get serviceText {
    final services = <String>[];

    if (supportsGelAl) {
      services.add('Gel-Al');
    }

    if (supportsGotur) {
      services.add('Götür');
    }

    if (services.isEmpty) {
      return 'Servis hazırlanıyor';
    }

    return services.join(' • ');
  }

  String get launchStatusText {
    if (isOpen) {
      return 'Açık';
    }

    if (isLaunchReady) {
      return 'Lansmana Hazır';
    }

    return 'Lansmana Hazırlanıyor';
  }

  int get galleryPhotoLimit {
    final type = membershipType.toLowerCase().trim();

    if (type == 'pro' ||
        type == 'kurumsal' ||
        type == 'corporate' ||
        type == 'enterprise') {
      return 24;
    }

    if (type == 'premium') {
      return 12;
    }

    return 6;
  }

  String get membershipLabel {
    final type = membershipType.toLowerCase().trim();

    if (type == 'pro' ||
        type == 'kurumsal' ||
        type == 'corporate' ||
        type == 'enterprise') {
      return 'Pro / Kurumsal Restoran';
    }

    if (type == 'premium') {
      return 'Premium Restoran';
    }

    return 'Free Restoran';
  }

  static RestoranModel fromMap(String id, Map<String, dynamic> data) {
    return RestoranModel(
      id: id,
      name: (data['name'] ?? data['restaurantName'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? data['img'] ?? '').toString(),
      cuisine: (data['cuisine'] ?? data['cuisineType'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      district: (data['district'] ?? '').toString(),
      preparationText:
          (data['preparationText'] ?? data['averagePreparationText'] ?? '')
              .toString(),
      ratingText: (data['ratingText'] ?? data['rating'] ?? '').toString(),
      membershipType: (data['membershipType'] ??
              data['packageType'] ??
              data['plan'] ??
              data['subscriptionTier'] ??
              'free')
          .toString()
          .toLowerCase()
          .trim(),
      isFounder: data['isFounder'] == true,
      isOpen: data['isOpen'] == true,
      isLaunchReady: data['isLaunchReady'] == true,
      supportsGelAl: data['supportsGelAl'] != false,
      supportsGotur: data['supportsGotur'] != false,
    );
  }
}
