import 'package:cloud_firestore/cloud_firestore.dart';

class AcademyDemoContentSeed {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    final now = Timestamp.now();

    // 🔥 DANIŞMANLIK MODÜLÜ
    await _createLesson(
      title: "Menü Danışmanlığı Temelleri",
      description: "Kârlı ve dengeli menü oluşturma teknikleri.",
      category: "danismanlik",
      subCategory: "Menü Danışmanlığı",
      duration: 60,
      videoCount: 3,
      isPremium: true,
      videos: [
        _video("Menü Kurgusu", 300, true),
        _video("Fiyatlandırma", 420, false),
        _video("Karlılık Analizi", 380, false),
      ],
      now: now,
    );

    await _createLesson(
      title: "Mutfak Kurulum Planı",
      description: "Sıfırdan profesyonel mutfak kurulum rehberi.",
      category: "danismanlik",
      subCategory: "Kurulum",
      duration: 75,
      videoCount: 3,
      isPremium: true,
      videos: [
        _video("Ekipman Seçimi", 400, true),
        _video("Yerleşim Planı", 450, false),
        _video("Operasyon Akışı", 420, false),
      ],
      now: now,
    );

    // 🔥 ŞEF MARKA MODÜLÜ
    await _createLesson(
      title: "Şef Kişisel Marka",
      description: "Şef olarak güçlü bir marka oluşturma.",
      category: "marka",
      subCategory: "Kişisel Marka",
      duration: 50,
      videoCount: 3,
      isPremium: false,
      videos: [
        _video("Marka Temelleri", 300, true),
        _video("Görünürlük", 280, true),
        _video("İtibar Yönetimi", 320, false),
      ],
      now: now,
    );

    await _createLesson(
      title: "Fiyatlandırma Psikolojisi",
      description: "Premium fiyatlandırma stratejileri.",
      category: "marka",
      subCategory: "Fiyatlandırma",
      duration: 55,
      videoCount: 3,
      isPremium: true,
      videos: [
        _video("Algı Yönetimi", 300, true),
        _video("Fiyat Katmanları", 360, false),
        _video("Upsell Teknikleri", 340, false),
      ],
      now: now,
    );

    print("🔥 DEMO CONTENT TAMAMLANDI");
  }

  static Future<void> _createLesson({
    required String title,
    required String description,
    required String category,
    required String subCategory,
    required int duration,
    required int videoCount,
    required bool isPremium,
    required List<Map<String, dynamic>> videos,
    required Timestamp now,
  }) async {
    final doc = await _db.collection('dersler').add({
      "title": title,
      "description": description,
      "category": category,
      "subCategory": subCategory,
      "duration": duration,
      "videoCount": videoCount,
      "isPremium": isPremium,
      "createdAt": now,
    });

    for (int i = 0; i < videos.length; i++) {
      await doc.collection('videos').add({
        ...videos[i],
        "order": i + 1,
      });
    }
  }

  static Map<String, dynamic> _video(String title, int duration, bool preview) {
    return {
      "title": title,
      "videoUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
      "durationSeconds": duration,
      "isPreview": preview,
    };
  }
}
