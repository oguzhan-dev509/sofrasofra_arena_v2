import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class _BrandLessonSeed {
  final String docId;
  final String baslik;
  final String aciklama;
  final int sure;
  final bool ucretsiz;
  final String category;
  final List<_BrandVideoSeed> videos;

  const _BrandLessonSeed({
    required this.docId,
    required this.baslik,
    required this.aciklama,
    required this.sure,
    required this.ucretsiz,
    required this.category,
    required this.videos,
  });
}

class _BrandVideoSeed {
  final String docId;
  final String title;
  final String videoUrl;
  final int durationSeconds;
  final int order;
  final bool isPreview;

  const _BrandVideoSeed({
    required this.docId,
    required this.title,
    required this.videoUrl,
    required this.durationSeconds,
    required this.order,
    required this.isPreview,
  });
}

Future<void> runAcademyBrandCareerBootstrapOnce({
  String chefId = 'demo_chef_ahmet_usta',
  String chefName = 'Ahmet Usta',
}) async {
  try {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final now = FieldValue.serverTimestamp();

    const lessons = <_BrandLessonSeed>[
      _BrandLessonSeed(
        docId: 'marka_001',
        baslik: 'Şefler İçin Kişisel Marka Temelleri',
        aciklama:
            'Şef kimliğini netleştirme, güven oluşturan vitrin dili ve ilk premium algı inşası.',
        sure: 22,
        ucretsiz: true,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'Kişisel marka neden gelir üretir?',
            videoUrl: 'https://example.com/videos/marka_001_1.mp4',
            durationSeconds: 420,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: 'Şef kimliği nasıl netleştirilir?',
            videoUrl: 'https://example.com/videos/marka_001_2.mp4',
            durationSeconds: 510,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      _BrandLessonSeed(
        docId: 'marka_002',
        baslik: 'Premium Konumlandırma ve Farklılaşma',
        aciklama:
            'Rakiplerden ayrışma, yüksek algı üretme ve şef profilini premium seviyeye taşıma.',
        sure: 28,
        ucretsiz: false,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'Premium şef algısı nasıl kurulur?',
            videoUrl: 'https://example.com/videos/marka_002_1.mp4',
            durationSeconds: 560,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: 'Doğru müşteri için doğru konum',
            videoUrl: 'https://example.com/videos/marka_002_2.mp4',
            durationSeconds: 610,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      _BrandLessonSeed(
        docId: 'marka_003',
        baslik: 'Premium Fiyatlandırma Stratejileri',
        aciklama:
            'Ucuz görünmeden satış yapma, hizmet seviyesine göre fiyat yükseltme ve paketleme mantığı.',
        sure: 25,
        ucretsiz: false,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'Fiyat değil değer satmak',
            videoUrl: 'https://example.com/videos/marka_003_1.mp4',
            durationSeconds: 530,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: 'Paket, menü ve deneyim fiyatlaması',
            videoUrl: 'https://example.com/videos/marka_003_2.mp4',
            durationSeconds: 660,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      _BrandLessonSeed(
        docId: 'marka_004',
        baslik: 'Müşteri Yönetimi ve Sadakat Tasarımı',
        aciklama:
            'Doğru müşteriyle çalışma, tekrar satın alma ve premium deneyim akışı kurma.',
        sure: 24,
        ucretsiz: false,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'Zor müşteri değil doğru müşteri',
            videoUrl: 'https://example.com/videos/marka_004_1.mp4',
            durationSeconds: 470,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: 'Sadakat üreten deneyim tasarımı',
            videoUrl: 'https://example.com/videos/marka_004_2.mp4',
            durationSeconds: 590,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      _BrandLessonSeed(
        docId: 'marka_005',
        baslik: 'Instagram’dan Müşteriye Dönüşüm Sistemi',
        aciklama:
            'Sosyal medya görünürlüğünü gerçek sipariş, rezervasyon ve danışmanlığa dönüştürme.',
        sure: 21,
        ucretsiz: true,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'Profil dili ve içerik omurgası',
            videoUrl: 'https://example.com/videos/marka_005_1.mp4',
            durationSeconds: 390,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: 'DM’den satışa geçiş akışı',
            videoUrl: 'https://example.com/videos/marka_005_2.mp4',
            durationSeconds: 520,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      _BrandLessonSeed(
        docId: 'marka_006',
        baslik: 'Şef Hikâyesi Yazımı ve Güven Dili',
        aciklama:
            'Bio, tanıtım metni, uzmanlık anlatısı ve güven veren profil mesajları oluşturma.',
        sure: 19,
        ucretsiz: true,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'İyi bio neden satış yapar?',
            videoUrl: 'https://example.com/videos/marka_006_1.mp4',
            durationSeconds: 360,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: 'Güçlü uzmanlık cümleleri kurmak',
            videoUrl: 'https://example.com/videos/marka_006_2.mp4',
            durationSeconds: 480,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      _BrandLessonSeed(
        docId: 'marka_007',
        baslik: 'Kurumsal Müşteri ve Davet Pozisyonlaması',
        aciklama:
            'Bireysel işlerden kurumsal davet ve premium etkinlik gelirine geçiş stratejisi.',
        sure: 27,
        ucretsiz: false,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'Kurumsal müşteri senden ne bekler?',
            videoUrl: 'https://example.com/videos/marka_007_1.mp4',
            durationSeconds: 530,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: 'Teklif dili ve premium sunum',
            videoUrl: 'https://example.com/videos/marka_007_2.mp4',
            durationSeconds: 640,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      _BrandLessonSeed(
        docId: 'marka_008',
        baslik: 'Şefler İçin Teklif Paketleri Tasarlama',
        aciklama:
            'Danışmanlık, catering, workshop ve özel davetler için paket mantığı oluşturma.',
        sure: 23,
        ucretsiz: false,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'Paket mantığı neden kazandırır?',
            videoUrl: 'https://example.com/videos/marka_008_1.mp4',
            durationSeconds: 450,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: 'Standart, premium ve VIP paket kurgusu',
            videoUrl: 'https://example.com/videos/marka_008_2.mp4',
            durationSeconds: 610,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      _BrandLessonSeed(
        docId: 'marka_009',
        baslik: 'Premium İletişim ve İkna Dili',
        aciklama:
            'Mesajlaşma, teklif dönüşü, takip ve kapanış dilinde premium etki kurma.',
        sure: 20,
        ucretsiz: true,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'Mesaj dilinde güven üretmek',
            videoUrl: 'https://example.com/videos/marka_009_1.mp4',
            durationSeconds: 400,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: 'Takip ve kapanış akışı',
            videoUrl: 'https://example.com/videos/marka_009_2.mp4',
            durationSeconds: 520,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
      _BrandLessonSeed(
        docId: 'marka_010',
        baslik: 'Şef Kariyer Haritası ve Gelir Katmanları',
        aciklama:
            'Atölye, danışmanlık, özel masa, etkinlik ve dijital eğitim ile çoklu gelir yapısı kurma.',
        sure: 30,
        ucretsiz: false,
        category: 'Marka & Kariyer',
        videos: [
          _BrandVideoSeed(
            docId: 'video_001',
            title: 'Tek gelirden çoklu gelire geçiş',
            videoUrl: 'https://example.com/videos/marka_010_1.mp4',
            durationSeconds: 590,
            order: 1,
            isPreview: true,
          ),
          _BrandVideoSeed(
            docId: 'video_002',
            title: '12 aylık kariyer büyüme planı',
            videoUrl: 'https://example.com/videos/marka_010_2.mp4',
            durationSeconds: 720,
            order: 2,
            isPreview: false,
          ),
        ],
      ),
    ];

    for (final lesson in lessons) {
      final lessonRef = firestore.collection('dersler').doc(lesson.docId);

      batch.set(
          lessonRef,
          {
            'chefId': chefId,
            'chefName': chefName,
            'baslik': lesson.baslik,
            'aciklama': lesson.aciklama,
            'sure': lesson.sure,
            'ucretsiz': lesson.ucretsiz,
            'videoCount': lesson.videos.length,
            'category': lesson.category,
            'aktifMi': true,
            'isActive': true,
            'createdAt': now,
            'updatedAt': now,
          },
          SetOptions(merge: true));

      for (final video in lesson.videos) {
        final videoRef = lessonRef.collection('videos').doc(video.docId);

        batch.set(
            videoRef,
            {
              'title': video.title,
              'videoUrl': video.videoUrl,
              'durationSeconds': video.durationSeconds,
              'order': video.order,
              'isPreview': video.isPreview,
              'createdAt': now,
              'updatedAt': now,
            },
            SetOptions(merge: true));
      }
    }

    await batch.commit();
    debugPrint(
      '✅ Marka & Kariyer seed tamamlandı: ${lessons.length} ders eklendi.',
    );
  } catch (e, st) {
    debugPrint('❌ Marka & Kariyer seed hatası: $e');
    debugPrint('$st');
    rethrow;
  }
}
