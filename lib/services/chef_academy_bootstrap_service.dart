import 'package:cloud_firestore/cloud_firestore.dart';

class ChefAcademyBootstrapService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> ensureAcademy({
    required String chefId,
  }) async {
    final coursesRef = _firestore.collection('courses');

    final existing = await coursesRef
        .where('chefId', isEqualTo: chefId)
        .limit(1)
        .get();

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