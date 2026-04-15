import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AcademyCategoryBootstrap {
  AcademyCategoryBootstrap._();

  static const List<Map<String, dynamic>> _categories = [
    {
      'id': 'osmanli_turk',
      'title': 'Osmanlı & Türk Mutfağı',
      'subtitle':
          'Kök teknikler, saray mirası ve geleneksel lezzet bilgisini taşıyan ana omurga.',
      'icon': 'restaurant',
      'order': 1,
      'colorKey': 'gold',
      'isActive': true,
      'tags': [
        'Osmanlı',
        'Türk Mutfağı',
        'Yöresel',
        'Saray Mutfağı',
      ],
      'subCategories': [
        'Osmanlı Saray Mutfağı',
        'Klasik Türk Mutfağı',
        'Yöresel Mutfaklar',
        'Geleneksel Pişirme Kültürü',
      ],
    },
    {
      'id': 'dunya_mutfagi',
      'title': 'Dünya Mutfağı',
      'subtitle':
          'Avrupa, Asya ve modern gastronomi yaklaşımlarıyla küresel vizyon kazandıran alan.',
      'icon': 'public',
      'order': 2,
      'colorKey': 'gold',
      'isActive': true,
      'tags': [
        'Dünya Mutfağı',
        'Avrupa',
        'Asya',
        'Global',
      ],
      'subCategories': [
        'Avrupa Mutfağı',
        'Asya Mutfağı',
        'Akdeniz Mutfağı',
        'Modern Dünya Teknikleri',
      ],
    },
    {
      'id': 'tabak_tasarimi',
      'title': 'Tabak Tasarımı & Sunum',
      'subtitle':
          'Premium algıyı yükselten plating, kompozisyon ve sunum dili eğitimi.',
      'icon': 'palette',
      'order': 3,
      'colorKey': 'gold',
      'isActive': true,
      'tags': [
        'Tabak Tasarımı',
        'Sunum',
        'Plating',
        'Fine Dining',
      ],
      'subCategories': [
        'Fine Dining Plating',
        'Renk & Kompozisyon',
        'Sunum Dili',
        'Masa Üstü Deneyimi',
      ],
    },
    {
      'id': 'mutfak_teknikleri',
      'title': 'Mutfak Teknikleri',
      'subtitle':
          'Pişirme teknikleri, hijyen, disiplin ve ürün işleme temelleri.',
      'icon': 'local_fire_department',
      'order': 4,
      'colorKey': 'gold',
      'isActive': true,
      'tags': [
        'Teknik',
        'Pişirme',
        'Hijyen',
        'Temel Mutfak',
      ],
      'subCategories': [
        'Pişirme Teknikleri',
        'Hijyen & Sağlık',
        'Ürün İşleme',
        'Mutfak Disiplini',
      ],
    },
    {
      'id': 'pastacilik_tatli',
      'title': 'Pastacılık & Tatlı',
      'subtitle':
          'Pasta, çikolata, tatlı ve fırın ürünleriyle dikey uzmanlık alanı.',
      'icon': 'cake',
      'order': 5,
      'colorKey': 'gold',
      'isActive': true,
      'tags': [
        'Pastacılık',
        'Tatlı',
        'Çikolata',
        'Fırın',
      ],
      'subCategories': [
        'Pasta Teknikleri',
        'Çikolata Yapımı',
        'Kek & Kurabiye',
        'Sütlü Tatlılar',
        'Börek Çeşitleri',
      ],
    },
    {
      'id': 'maliyet_isletme',
      'title': 'Maliyet & İşletme',
      'subtitle':
          'Food cost, menü planlama, ekipman ve kârlılık yönetimini öğreten işletme katmanı.',
      'icon': 'calculate',
      'order': 6,
      'colorKey': 'gold',
      'isActive': true,
      'tags': [
        'Maliyet',
        'İşletme',
        'Food Cost',
        'Karlılık',
      ],
      'subCategories': [
        'İşletme Maliyeti Hesaplama',
        'Food Cost Yönetimi',
        'Menü & Reçete',
        'Ekipmanlar',
        'Satış & İş Akışı Takibi',
      ],
    },
    {
      'id': 'danismanlik_kurulum',
      'title': 'Danışmanlık & Kurulum',
      'subtitle':
          'Menü danışmanlığı, mutfak kurulumu ve profesyonel operasyon sistemleri.',
      'icon': 'business_center',
      'order': 7,
      'colorKey': 'gold',
      'isActive': true,
      'tags': [
        'Danışmanlık',
        'Kurulum',
        'Operasyon',
        'Menü Danışmanlığı',
      ],
      'subCategories': [
        'Menü Danışmanlığı',
        'Konsept Geliştirme',
        'Mutfak Kurulum',
        'Operasyon Sistemi',
        'Personel Eğitimi',
      ],
    },
    {
      'id': 'sef_marka_kariyer',
      'title': 'Şef Marka & Kariyer',
      'subtitle':
          'Marka kimliği, sahne, vitrin, uzmanlık ve prestij inşasını destekleyen katman.',
      'icon': 'workspace_premium',
      'order': 8,
      'colorKey': 'gold',
      'isActive': true,
      'tags': [
        'Usta Şef',
        'Marka',
        'Prestij',
        'Kariyer',
      ],
      'subCategories': [
        'Marka Kimliği',
        'Vitrin / Sahne',
        'Uzmanlık & Prestij',
        'Müşteri Yönetimi',
        'Fiyatlandırma',
      ],
    },
  ];

  static Future<void> runOnce() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final now = FieldValue.serverTimestamp();

    final collection = firestore.collection('academy_categories');

    for (final item in _categories) {
      final docId = item['id'] as String;
      final docRef = collection.doc(docId);

      batch.set(
        docRef,
        {
          'id': item['id'],
          'title': item['title'],
          'subtitle': item['subtitle'],
          'icon': item['icon'],
          'order': item['order'],
          'colorKey': item['colorKey'],
          'isActive': item['isActive'],
          'tags': item['tags'],
          'subCategories': item['subCategories'],
          'updatedAt': now,
          'createdAt': now,
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    if (kDebugMode) {
      debugPrint(
        'AcademyCategoryBootstrap tamamlandı: ${_categories.length} kategori yüklendi/güncellendi.',
      );
    }
  }
}
