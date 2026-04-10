import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AcademyCategoryBootstrapService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const List<Map<String, dynamic>> _seedCategories = [
    {
      'slug': 'genel-turk-mutfagi',
      'title': 'Genel Türk Mutfağı',
      'description':
          'Temel Türk mutfağı teknikleri, klasik reçeteler ve mutfak disiplini.',
      'icon': 'restaurant',
      'order': 1,
      'isActive': true,
      'colorHex': '#FFB300',
    },
    {
      'slug': 'osmanli-mutfagi',
      'title': 'Osmanlı Mutfağı',
      'description':
          'Saray mutfağı, tarihsel reçeteler ve geleneksel pişirme yaklaşımı.',
      'icon': 'auto_awesome',
      'order': 2,
      'isActive': true,
      'colorHex': '#D4AF37',
    },
    {
      'slug': 'dunya-mutfagi',
      'title': 'Dünya Mutfağı',
      'description':
          'Farklı ülkelerden mutfak teknikleri ve uluslararası tarif yaklaşımı.',
      'icon': 'public',
      'order': 3,
      'isActive': true,
      'colorHex': '#FFC107',
    },
    {
      'slug': 'tabak-tasarim',
      'title': 'Tabak Tasarım',
      'description':
          'Sunum estetiği, porsiyon dengesi ve profesyonel plating teknikleri.',
      'icon': 'palette',
      'order': 4,
      'isActive': true,
      'colorHex': '#FFD54F',
    },
    {
      'slug': 'pastacilik',
      'title': 'Pastacılık',
      'description':
          'Tatlı, hamur işi, krema ve temel pastacılık eğitim modülleri.',
      'icon': 'cake',
      'order': 5,
      'isActive': true,
      'colorHex': '#FFCA28',
    },
    {
      'slug': 'maliyet-isletme',
      'title': 'Maliyet & İşletme',
      'description':
          'Reçete maliyeti, ekip yönetimi, menü planlama ve işletme mantığı.',
      'icon': 'payments',
      'order': 6,
      'isActive': true,
      'colorHex': '#FFECB3',
    },
  ];

  static Future<void> bootstrapAcademyCategories({
    bool overwriteExisting = false,
  }) async {
    debugPrint('🗂️ Academy category bootstrap başladı');

    final colRef = _db.collection('academy_categories');
    final allSnap = await colRef.get();

    if (allSnap.docs.isNotEmpty && !overwriteExisting) {
      debugPrint(
        '✅ academy_categories zaten dolu: ${allSnap.docs.length} kayıt var, işlem yapılmadı.',
      );
      return;
    }

    if (allSnap.docs.isNotEmpty && overwriteExisting) {
      debugPrint('♻️ Var olan academy_categories kayıtları siliniyor...');
      for (final doc in allSnap.docs) {
        await doc.reference.delete();
      }
    }

    final batch = _db.batch();

    for (final item in _seedCategories) {
      final slug = item['slug'].toString();
      final docRef = colRef.doc(slug);

      batch.set(docRef, {
        'slug': item['slug'],
        'title': item['title'],
        'description': item['description'],
        'icon': item['icon'],
        'order': item['order'],
        'isActive': item['isActive'],
        'colorHex': item['colorHex'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('📁 Hazırlandı: ${item['title']}');
    }

    await batch.commit();

    debugPrint('🏁 Academy category bootstrap tamamlandı');
  }
}
