class ChefModel {
  final String id;
  final String name;
  final String city;
  final String district;
  final String bio;
  final String title;
  final String subtitle;
  final List<String> tags;

  final double rating;
  final int reviewCount;
  final int experienceYears;
  final int studentCount;
  final int videoCount;
  final int consultingCount;

  final String img;
  final List<String> gallery;

  final int consultingPrice;
  final int coursePrice;
  final String currency;

  final bool verified;
  final bool premium;
  final bool featured;
  final bool isActive;

  const ChefModel({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.bio,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    required this.studentCount,
    required this.videoCount,
    required this.consultingCount,
    required this.img,
    required this.gallery,
    required this.consultingPrice,
    required this.coursePrice,
    required this.currency,
    required this.verified,
    required this.premium,
    required this.featured,
    required this.isActive,
  });

  factory ChefModel.fromMap(String id, Map<String, dynamic> data) {
    final stats = (data['stats'] as Map<String, dynamic>?) ?? {};
    final pricing = (data['pricing'] as Map<String, dynamic>?) ?? {};
    final status = (data['status'] as Map<String, dynamic>?) ?? {};

    return ChefModel(
      id: id,
      name: (data['name'] ?? data['dukkan'] ?? 'Usta Şef').toString(),
      city: (data['city'] ?? data['sehir'] ?? '').toString(),
      district: (data['district'] ?? data['ilce'] ?? '').toString(),
      bio: (data['bio'] ?? data['hikaye'] ?? '').toString(),
      title: (data['title'] ?? data['uzmanlik'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      tags: ((data['tags'] as List?) ?? []).map((e) => e.toString()).toList(),
      rating: (stats['rating'] as num?)?.toDouble() ??
          (data['itibar_puani'] as num?)?.toDouble() ??
          0,
      reviewCount: (stats['reviewCount'] as num?)?.toInt() ?? 0,
      experienceYears: (stats['experienceYears'] as num?)?.toInt() ?? 0,
      studentCount: (stats['studentCount'] as num?)?.toInt() ??
          (data['mezun_sayisi'] as num?)?.toInt() ??
          0,
      videoCount: (stats['videoCount'] as num?)?.toInt() ?? 0,
      consultingCount: (stats['consultingCount'] as num?)?.toInt() ?? 0,
      img: (data['img'] ?? '').toString(),
      gallery:
          ((data['gallery'] as List?) ?? []).map((e) => e.toString()).toList(),
      consultingPrice: (pricing['consultingPrice'] as num?)?.toInt() ?? 0,
      coursePrice: (pricing['coursePrice'] as num?)?.toInt() ?? 0,
      currency: (pricing['currency'] ?? 'TRY').toString(),
      verified: status['verified'] == true,
      premium: status['premium'] == true,
      featured: status['featured'] == true,
      isActive: status['isActive'] == true || data['isActive'] == true,
    );
  }
}
