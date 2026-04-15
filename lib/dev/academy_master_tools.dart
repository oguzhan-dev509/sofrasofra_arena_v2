import 'package:cloud_firestore/cloud_firestore.dart';

class AcademyMasterTools {
  AcademyMasterTools._();

  static const List<Map<String, dynamic>> academyCategoriesSeed = [
    {
      'id': 'osmanli',
      'title': 'Osmanlı & Türk Mutfağı',
      'shortTitle': 'Osmanlı',
      'icon': 'restaurant',
      'description':
          'Osmanlı saray mutfağı, klasik Türk mutfağı ve yöresel lezzetler.',
      'order': 1,
      'isActive': true,
      'isFeatured': true,
      'subCategories': [
        'Osmanlı Saray Mutfağı',
        'Klasik Türk Mutfağı',
        'Yöresel Mutfaklar',
      ],
    },
    {
      'id': 'dunya',
      'title': 'Dünya Mutfağı',
      'shortTitle': 'Dünya',
      'icon': 'public',
      'description': 'Avrupa, Asya ve modern mutfak yaklaşımları.',
      'order': 2,
      'isActive': true,
      'isFeatured': true,
      'subCategories': [
        'Avrupa Mutfağı',
        'Asya Mutfağı',
        'Modern Teknikler',
      ],
    },
    {
      'id': 'sunum',
      'title': 'Tabak Tasarımı & Sunum',
      'shortTitle': 'Sunum',
      'icon': 'style',
      'description': 'Fine dining plating, renk kullanımı ve sunum dili.',
      'order': 3,
      'isActive': true,
      'isFeatured': true,
      'subCategories': [
        'Fine Dining Plating',
        'Renk & Kompozisyon',
        'Sunum Dili',
      ],
    },
    {
      'id': 'teknik',
      'title': 'Teknik & Mutfak Temelleri',
      'shortTitle': 'Teknik',
      'icon': 'local_fire_department',
      'description': 'Pişirme teknikleri, hijyen ve temel mutfak disiplinleri.',
      'order': 4,
      'isActive': true,
      'isFeatured': true,
      'subCategories': [
        'Pişirme Teknikleri',
        'Hijyen & Sağlık',
        'Ürün İşleme',
      ],
    },
    {
      'id': 'pastacilik',
      'title': 'Pastacılık & Tatlı',
      'shortTitle': 'Pastacılık',
      'icon': 'cake',
      'description': 'Pasta, çikolata ve tatlı modülleri.',
      'order': 5,
      'isActive': true,
      'isFeatured': true,
      'subCategories': [
        'Pasta',
        'Çikolata',
        'Tatlılar',
      ],
    },
    {
      'id': 'maliyet',
      'title': 'Maliyet & İşletme',
      'shortTitle': 'Maliyet',
      'icon': 'payments',
      'description': 'Food cost, menü planlama ve karlılık yönetimi.',
      'order': 6,
      'isActive': true,
      'isFeatured': true,
      'subCategories': [
        'Food Cost',
        'Menü Planlama',
        'Karlılık',
      ],
    },
    {
      'id': 'danismanlik',
      'title': 'Danışmanlık & Kurulum',
      'shortTitle': 'Danışmanlık',
      'icon': 'support_agent',
      'description':
          'Menü danışmanlığı, mutfak kurulum ve operasyon sistemleri.',
      'order': 7,
      'isActive': true,
      'isFeatured': true,
      'subCategories': [
        'Menü Danışmanlığı',
        'Mutfak Kurulum',
        'Operasyon',
      ],
    },
    {
      'id': 'marka',
      'title': 'Şef Marka & Kariyer',
      'shortTitle': 'Marka',
      'icon': 'workspace_premium',
      'description': 'Kişisel marka, fiyatlandırma ve müşteri yönetimi.',
      'order': 8,
      'isActive': true,
      'isFeatured': true,
      'subCategories': [
        'Kişisel Marka',
        'Fiyatlandırma',
        'Müşteri Yönetimi',
      ],
    },
  ];

  static Future<void> seedAcademyCategories({
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final batch = db.batch();
    final now = Timestamp.now();

    for (final item in academyCategoriesSeed) {
      final String id = item['id'] as String;
      final ref = db.collection('academy_categories').doc(id);

      batch.set(
        ref,
        {
          ...item,
          'createdAt': now,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  static Map<String, dynamic> buildLessonPayload({
    required String chefId,
    required String chefName,
    required String title,
    required String description,
    required String category,
    required String categoryName,
    required String subCategory,
    required int durationMinutes,
    required int videoCount,
    required String level,
    required bool isPremium,
    required int order,
    String thumbnailUrl = '',
    String shortDescription = '',
  }) {
    final now = Timestamp.now();

    return {
      'title': title.trim(),
      'description': description.trim(),
      'shortDescription': shortDescription.trim().isEmpty
          ? description.trim()
          : shortDescription.trim(),
      'category': category.trim(),
      'categoryName': categoryName.trim(),
      'subCategory': subCategory.trim(),
      'chefId': chefId.trim(),
      'chefName': chefName.trim(),
      'durationMinutes': durationMinutes,
      'durationLabel': '$durationMinutes dk',
      'videoCount': videoCount,
      'level': level.trim(),
      'isPremium': isPremium,
      'isPublished': true,
      'thumbnailUrl': thumbnailUrl.trim(),
      'order': order,
      'createdAt': now,
      'updatedAt': now,

      // Geri uyum
      'baslik': title.trim(),
      'aciklama': description.trim(),
      'sure': '$durationMinutes dk',
      'ucretsiz': !isPremium,
    };
  }

  static Map<String, dynamic> buildLessonVideoPayload({
    required String title,
    required String videoUrl,
    required int durationSeconds,
    required int order,
    required bool isPreview,
    bool isLocked = false,
    String thumbnailUrl = '',
    String description = '',
  }) {
    final now = Timestamp.now();
    final minutes = (durationSeconds / 60).ceil();

    return {
      'title': title.trim(),
      'videoUrl': videoUrl.trim(),
      'durationSeconds': durationSeconds,
      'durationLabel': '$minutes dk',
      'order': order,
      'isPreview': isPreview,
      'isLocked': isLocked,
      'thumbnailUrl': thumbnailUrl.trim(),
      'description': description.trim(),
      'createdAt': now,
      'updatedAt': now,
    };
  }

  static Future<void> patchChefProfileForAcademy({
    required String chefId,
    required List<String> expertise,
    required List<String> academyCategories,
    required List<String> services,
    bool isAcademyActive = true,
    bool isConsultingActive = true,
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;

    await db.collection('chef_profiles').doc(chefId).set({
      'expertise': expertise,
      'academyCategories': academyCategories,
      'services': services,
      'isAcademyActive': isAcademyActive,
      'isConsultingActive': isConsultingActive,
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  static Map<String, dynamic> buildConsultingRequestPayload({
    required String chefId,
    required String chefName,
    required String userId,
    required String userName,
    required String type,
    required int budget,
    required String details,
    String phone = '',
    String city = '',
    String district = '',
  }) {
    final now = Timestamp.now();

    return {
      'chefId': chefId.trim(),
      'chefName': chefName.trim(),
      'userId': userId.trim(),
      'userName': userName.trim(),
      'type': type.trim(),
      'status': 'pending',
      'budget': budget,
      'details': details.trim(),
      'phone': phone.trim(),
      'city': city.trim(),
      'district': district.trim(),
      'createdAt': now,
      'updatedAt': now,
    };
  }

  static Future<void> createConsultingRequest({
    required Map<String, dynamic> payload,
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    await db.collection('consulting_requests').add(payload);
  }

  static Future<void> normalizeLessons({
    FirebaseFirestore? firestore,
    int batchSize = 250,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final snapshot = await db.collection('dersler').get();

    WriteBatch batch = db.batch();
    var opCount = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();

      final title = _safeText(data['title']).isNotEmpty
          ? _safeText(data['title'])
          : _safeText(data['baslik']).isNotEmpty
              ? _safeText(data['baslik'])
              : 'İsimsiz Eğitim';

      final description = _safeText(data['description']).isNotEmpty
          ? _safeText(data['description'])
          : _safeText(data['aciklama']).isNotEmpty
              ? _safeText(data['aciklama'])
              : 'Açıklama eklenmemiş';

      final categorySlug = _safeText(data['category']).isNotEmpty
          ? _safeText(data['category'])
          : _inferCategorySlug(data);

      final categoryName = _safeText(data['categoryName']).isNotEmpty
          ? _safeText(data['categoryName'])
          : _categoryTitleFromSlug(categorySlug);

      final subCategory = _safeText(data['subCategory']).isNotEmpty
          ? _safeText(data['subCategory'])
          : _safeText(data['kategori']).isNotEmpty
              ? _safeText(data['kategori'])
              : categoryName;

      final durationMinutes = _parseDurationMinutes(data);
      final videoCount = (data['videoCount'] as num?)?.toInt() ?? 0;
      final isPremium =
          data['isPremium'] == true ? true : !(data['ucretsiz'] == true);

      final chefName = _safeText(data['chefName']).isNotEmpty
          ? _safeText(data['chefName'])
          : 'Usta Şef';

      batch.set(
        doc.reference,
        {
          'title': title,
          'description': description,
          'shortDescription': description,
          'category': categorySlug,
          'categoryName': categoryName,
          'subCategory': subCategory,
          'durationMinutes': durationMinutes,
          'durationLabel':
              durationMinutes > 0 ? '$durationMinutes dk' : 'Süre belirtilmedi',
          'videoCount': videoCount,
          'level': _safeText(data['level']).isNotEmpty
              ? _safeText(data['level'])
              : 'beginner',
          'isPremium': isPremium,
          'isPublished': data['isPublished'] == false ? false : true,
          'chefName': chefName,
          'updatedAt': Timestamp.now(),

          // Geri uyum
          'baslik': title,
          'aciklama': description,
          'sure':
              durationMinutes > 0 ? '$durationMinutes dk' : 'Süre belirtilmedi',
          'ucretsiz': !isPremium,
        },
        SetOptions(merge: true),
      );

      opCount++;
      if (opCount >= batchSize) {
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }
  }

  static String lessonTitle(Map<String, dynamic> m) {
    return (m['title'] ?? m['baslik'] ?? 'İsimsiz Eğitim').toString();
  }

  static String lessonDescription(Map<String, dynamic> m) {
    return (m['description'] ?? m['aciklama'] ?? 'Açıklama eklenmemiş')
        .toString();
  }

  static String lessonDurationLabel(Map<String, dynamic> m) {
    return (m['durationLabel'] ?? m['sure'] ?? 'Süre belirtilmedi').toString();
  }

  static int lessonVideoCount(Map<String, dynamic> m) {
    return (m['videoCount'] as num?)?.toInt() ?? 0;
  }

  static bool lessonIsPremium(Map<String, dynamic> m) {
    if (m['isPremium'] == true) return true;
    if (m['ucretsiz'] == true) return false;
    return false;
  }

  static String lessonCategoryName(Map<String, dynamic> m) {
    return (m['categoryName'] ?? m['category'] ?? m['kategori'] ?? '')
        .toString()
        .trim();
  }

  static String _safeText(dynamic value) => (value ?? '').toString().trim();

  static String _normalizeText(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  static String _inferCategorySlug(Map<String, dynamic> data) {
    final raw = _normalizeText(
      [
        _safeText(data['category']),
        _safeText(data['categoryName']),
        _safeText(data['kategori']),
        _safeText(data['subCategory']),
        _safeText(data['title']),
        _safeText(data['baslik']),
      ].join(' '),
    );

    if (raw.contains('osmanli') ||
        raw.contains('turk') ||
        raw.contains('yoresel')) {
      return 'osmanli';
    }
    if (raw.contains('dunya') ||
        raw.contains('avrupa') ||
        raw.contains('asya') ||
        raw.contains('modern')) {
      return 'dunya';
    }
    if (raw.contains('sunum') ||
        raw.contains('tabak') ||
        raw.contains('plating') ||
        raw.contains('kompozisyon')) {
      return 'sunum';
    }
    if (raw.contains('teknik') ||
        raw.contains('pisirme') ||
        raw.contains('hijyen') ||
        raw.contains('urun isleme')) {
      return 'teknik';
    }
    if (raw.contains('pasta') ||
        raw.contains('cikolata') ||
        raw.contains('tatli') ||
        raw.contains('pastac')) {
      return 'pastacilik';
    }
    if (raw.contains('maliyet') ||
        raw.contains('food cost') ||
        raw.contains('kar') ||
        raw.contains('menu plan')) {
      return 'maliyet';
    }
    if (raw.contains('danisman') ||
        raw.contains('kurulum') ||
        raw.contains('operasyon')) {
      return 'danismanlik';
    }
    if (raw.contains('marka') ||
        raw.contains('kariyer') ||
        raw.contains('fiyatlandirma') ||
        raw.contains('musteri')) {
      return 'marka';
    }

    return 'teknik';
  }

  static String _categoryTitleFromSlug(String slug) {
    switch (slug) {
      case 'osmanli':
        return 'Osmanlı & Türk Mutfağı';
      case 'dunya':
        return 'Dünya Mutfağı';
      case 'sunum':
        return 'Tabak Tasarımı & Sunum';
      case 'teknik':
        return 'Teknik & Mutfak Temelleri';
      case 'pastacilik':
        return 'Pastacılık & Tatlı';
      case 'maliyet':
        return 'Maliyet & İşletme';
      case 'danismanlik':
        return 'Danışmanlık & Kurulum';
      case 'marka':
        return 'Şef Marka & Kariyer';
      default:
        return 'Teknik & Mutfak Temelleri';
    }
  }

  static int _parseDurationMinutes(Map<String, dynamic> data) {
    final rawNum = data['durationMinutes'];
    if (rawNum is num) return rawNum.toInt();

    final rawSure = _safeText(data['sure']);
    final rawDuration = _safeText(data['durationLabel']);
    final combined = '$rawSure $rawDuration';

    final match = RegExp(r'(\d+)').firstMatch(combined);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '') ?? 0;
    }

    return 0;
  }
}
