import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AcademyCategoryNormalizeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Map<String, Map<String, String>> _categoryMap = {
    'genel-turk-mutfagi': {
      'title': 'Genel Türk Mutfağı',
      'slug': 'genel-turk-mutfagi',
    },
    'osmanli-mutfagi': {
      'title': 'Osmanlı Mutfağı',
      'slug': 'osmanli-mutfagi',
    },
    'dunya-mutfagi': {
      'title': 'Dünya Mutfağı',
      'slug': 'dunya-mutfagi',
    },
    'tabak-tasarim': {
      'title': 'Tabak Tasarım',
      'slug': 'tabak-tasarim',
    },
    'pastacilik': {
      'title': 'Pastacılık',
      'slug': 'pastacilik',
    },
    'maliyet-isletme': {
      'title': 'Maliyet & İşletme',
      'slug': 'maliyet-isletme',
    },
  };

  static String _normalizeToSlug(dynamic rawValue) {
    final raw = (rawValue ?? '').toString().trim().toLowerCase();

    switch (raw) {
      case 'genel türk mutfağı':
      case 'genel turk mutfagi':
      case 'genel-turk-mutfagi':
      case 'turk mutfagi':
      case 'türk mutfağı':
        return 'genel-turk-mutfagi';

      case 'osmanlı':
      case 'osmanli':
      case 'osmanlı mutfağı':
      case 'osmanli mutfagi':
      case 'osmanli-mutfagi':
        return 'osmanli-mutfagi';

      case 'dünya':
      case 'dunya':
      case 'dünya mutfağı':
      case 'dunya mutfagi':
      case 'dunya-mutfagi':
        return 'dunya-mutfagi';

      case 'tabak tasarım':
      case 'tabak tasarim':
      case 'tabak-tasarim':
      case 'sunum':
      case 'plating':
        return 'tabak-tasarim';

      case 'pastacılık':
      case 'pastacilik':
      case 'tatli':
      case 'tatlı':
      case 'hamur işi':
      case 'hamur isi':
        return 'pastacilik';

      case 'maliyet':
      case 'işletme':
      case 'isletme':
      case 'maliyet & işletme':
      case 'maliyet & isletme':
      case 'maliyet-isletme':
        return 'maliyet-isletme';

      default:
        return '';
    }
  }

  static String _guessSlugFromLesson(Map<String, dynamic> data) {
    final fromCategory = _normalizeToSlug(
        data['categorySlug'] ?? data['category'] ?? data['kategori']);
    if (fromCategory.isNotEmpty) return fromCategory;

    final title =
        (data['baslik'] ?? data['title'] ?? '').toString().toLowerCase();
    final description = (data['aciklama'] ?? data['description'] ?? '')
        .toString()
        .toLowerCase();
    final combined = '$title $description';

    if (combined.contains('osmanlı') || combined.contains('osmanli')) {
      return 'osmanli-mutfagi';
    }
    if (combined.contains('dünya') ||
        combined.contains('dunya') ||
        combined.contains('italyan')) {
      return 'dunya-mutfagi';
    }
    if (combined.contains('tabak') ||
        combined.contains('sunum') ||
        combined.contains('plating')) {
      return 'tabak-tasarim';
    }
    if (combined.contains('pasta') ||
        combined.contains('tatlı') ||
        combined.contains('tatli') ||
        combined.contains('hamur')) {
      return 'pastacilik';
    }
    if (combined.contains('maliyet') ||
        combined.contains('işletme') ||
        combined.contains('isletme')) {
      return 'maliyet-isletme';
    }

    return 'genel-turk-mutfagi';
  }

  static Future<void> normalizeLessonCategories() async {
    debugPrint('🧭 Ders kategori normalize başladı');

    final snap = await _db.collection('dersler').get();

    if (snap.docs.isEmpty) {
      debugPrint('⚠️ dersler koleksiyonunda kayıt yok');
      return;
    }

    for (final doc in snap.docs) {
      final data = doc.data();

      final slug = _guessSlugFromLesson(data);
      final mapped = _categoryMap[slug];

      if (mapped == null) {
        debugPrint('⚠️ Eşleşme bulunamadı: ${doc.id}');
        continue;
      }

      await doc.reference.set({
        'categorySlug': mapped['slug'],
        'category': mapped['title'],
        'kategori': mapped['title'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        '✅ Normalize edildi: ${doc.id} → ${mapped['title']} (${mapped['slug']})',
      );
    }

    debugPrint('🏁 Ders kategori normalize tamamlandı');
  }
}
