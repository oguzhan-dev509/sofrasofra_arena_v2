import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/foundation.dart';

class ChefAcademyBootstrapService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Future<void> backfillAllCourseVideos() async {
    final db = FirebaseFirestore.instance;

    debugPrint('🎬 Akademi video bootstrap başladı');

    final derslerSnap = await db.collection('dersler').get();

    if (derslerSnap.docs.isEmpty) {
      debugPrint('⚠️ dersler koleksiyonunda kayıt yok');
      return;
    }

    for (final dersDoc in derslerSnap.docs) {
      final data = dersDoc.data();
      debugPrint('🔎 Ders bulundu: ${dersDoc.id}');
      final String dersId = dersDoc.id;
      final String baslik =
          (data['title'] ?? data['baslik'] ?? 'Ders').toString();

      int videoCount = (data['videoCount'] is num)
          ? (data['videoCount'] as num).toInt()
          : int.tryParse((data['videoCount'] ?? '').toString()) ?? 0;

// Eğer videoCount yoksa veya 0 ise, varsayılan sayı ver.
      if (videoCount <= 0) {
        videoCount = 6;
        debugPrint(
            '🟡 videoCount yok/0 → varsayılan 6 verildi: $dersId ($baslik)');
      }

      final videosRef =
          db.collection('dersler').doc(dersId).collection('videos');

      final existingVideosSnap = await videosRef.get();
      if (existingVideosSnap.docs.isNotEmpty) {
        debugPrint('♻️ Güncelleniyor: $dersId ($baslik)');

        for (final doc in existingVideosSnap.docs) {
          await doc.reference.delete();
        }
      }

      final bool ucretsiz = data['ucretsiz'] == true ||
          data['isFree'] == true ||
          (data['price'] is num && (data['price'] as num).toDouble() <= 0);

      final batch = db.batch();

      for (int i = 1; i <= videoCount; i++) {
        final docRef = videosRef.doc('video-$i');

        batch.set(docRef, {
          'title': _buildVideoTitle(
            dersBasligi: baslik,
            index: i,
          ),
          'videoUrl': _buildDemoYoutubeUrl(i),
          'durationSeconds': _buildDurationSeconds(i),
          'order': i,
          'isPreview': ucretsiz ? i <= 2 : i == 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      batch.update(dersDoc.reference, {
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      debugPrint('🎉 Yazıldı: $dersId ($baslik) → $videoCount video');
    }

    debugPrint('🏁 Akademi video bootstrap tamamlandı');
  }

  static String _buildVideoTitle({
    required String dersBasligi,
    required int index,
  }) {
    const fallbackTitles = <String>[
      'Giriş ve Temel Hazırlık',
      'Malzeme Seçimi',
      'Ön Hazırlık Teknikleri',
      'Pişirme Aşaması',
      'Kontrol ve Denge',
      'Sunum ve Servis',
      'Püf Noktalar',
      'Profesyonel Uygulama',
      'Sık Yapılan Hatalar',
      'Final Uygulaması',
      'İleri Teknikler',
      'Şef Yorumu',
      'Ek Uygulama 1',
      'Ek Uygulama 2',
      'Ek Uygulama 3',
      'Ek Uygulama 4',
      'Ek Uygulama 5',
      'Ek Uygulama 6',
    ];

    final String suffix = index <= fallbackTitles.length
        ? fallbackTitles[index - 1]
        : 'Bölüm $index';

    return '$dersBasligi • $suffix';
  }

  static int _buildDurationSeconds(int index) {
    const durations = <int>[
      360,
      420,
      510,
      600,
      720,
      840,
      900,
      660,
      780,
      540,
      630,
      690,
    ];

    if (index <= durations.length) {
      return durations[index - 1];
    }

    return 480 + (index * 30);
  }

  static String _buildDemoYoutubeUrl(int index) {
    const urls = <String>[
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    ];

    return urls[(index - 1) % urls.length];
  }

  static Future<void> ensureAcademy({
    required String chefId,
  }) async {
    final coursesRef = _firestore.collection('courses');

    final existing =
        await coursesRef.where('chefId', isEqualTo: chefId).limit(1).get();

    if (existing.docs.isNotEmpty) {
      return;
    }

    final now = FieldValue.serverTimestamp();

    final List<Map<String, dynamic>> defaultCourses = [
      {
        'title': 'Genel Türk Mutfağı',
        'description': 'Temel teknikler ve reçete mantığı',
        'price': 299,
        'durationMinutes': 180,
        'videoCount': 12,
        'category': 'Türk Mutfağı',
      },
      {
        'title': 'Pişirme Teknikleri',
        'description': 'Profesyonel mutfak teknikleri',
        'price': 249,
        'durationMinutes': 150,
        'videoCount': 10,
        'category': 'Teknik',
      },
      {
        'title': 'Hijyen & Sağlık',
        'description': 'Gıda güvenliği ve hijyen kuralları',
        'price': 199,
        'durationMinutes': 120,
        'videoCount': 8,
        'category': 'Hijyen',
      },
      {
        'title': 'Tabak Sunumu',
        'description': 'Sunum ve plating teknikleri',
        'price': 279,
        'durationMinutes': 140,
        'videoCount': 9,
        'category': 'Sunum',
      },
    ];

    final batch = _firestore.batch();

    for (var course in defaultCourses) {
      final docRef = coursesRef.doc();

      batch.set(docRef, {
        'chefId': chefId,
        'title': course['title'],
        'description': course['description'],
        'price': course['price'],
        'durationMinutes': course['durationMinutes'],
        'videoCount': course['videoCount'],
        'category': course['category'],
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    await batch.commit();
  }
}
