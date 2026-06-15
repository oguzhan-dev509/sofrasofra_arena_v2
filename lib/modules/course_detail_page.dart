import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;
  final Map<String, dynamic> courseData;

  const CourseDetailPage({
    super.key,
    required this.courseId,
    required this.courseData,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  static const Color _bg = Color(0xFF111111);
  static const Color _panel = Color(0xFF1A1A1A);
  static const Color _gold = Color(0xFFFFB300);

  bool _isPurchasing = false;

  String _safeText(dynamic value) {
    return (value ?? '').toString().trim();
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  double _safeDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString().replaceAll(',', '.')) ?? 0;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  String _categoryText() {
    final raw = _normalize(_safeText(widget.courseData['category']));

    if (raw.contains('osmanli')) return 'Osmanlı';
    if (raw.contains('turk')) return 'Türk Mutfağı';
    if (raw.contains('dunya')) return 'Dünya Mutfağı';
    if (raw.contains('pastac')) return 'Pastacılık';
    if (raw.contains('tatli') || raw.contains('cikolata')) return 'Tatlı';
    if (raw.contains('tabak') || raw.contains('sunum')) return 'Tabak Tasarım';
    if (raw.contains('hijyen') || raw.contains('saglik')) return 'Hijyen';
    if (raw.contains('maliyet') || raw.contains('cost')) return 'Maliyet';
    if (raw.contains('kafe') ||
        raw.contains('isletme') ||
        raw.contains('menu')) {
      return 'Kafe & İşletme';
    }

    final fallback = _safeText(widget.courseData['category']);
    return fallback.isEmpty ? 'Genel' : fallback;
  }

  String _priceText() {
    final price = _safeDouble(widget.courseData['price']);
    if (price <= 0) return 'Yakında';
    return '${price.toStringAsFixed(0)} ₺';
  }

  String _durationText() {
    final durationMinutes = _safeInt(widget.courseData['durationMinutes']);
    if (durationMinutes <= 0) return 'Süre yakında';
    return '$durationMinutes dakika';
  }

  String _videoCountText() {
    final videoCount = _safeInt(widget.courseData['videoCount']);
    if (videoCount <= 0) return 'Video bilgisi yakında';
    return '$videoCount video';
  }

  Future<void> _openVideo(BuildContext context, String videoUrl) async {
    final uri = Uri.tryParse(videoUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video bağlantısı geçersiz.')),
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video açılamadı.')),
      );
    }
  }

  Stream<bool> _hasPurchasedStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Stream<bool>.value(false);
    }

    return FirebaseFirestore.instance
        .collection('user_courses')
        .where('userId', isEqualTo: uid)
        .where('courseId', isEqualTo: widget.courseId)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isNotEmpty);
  }

  Future<void> _purchaseCourseDemo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı oturumu bulunamadı.')),
      );
      return;
    }

    try {
      setState(() => _isPurchasing = true);

      final uid = user.uid;
      final chefId = _safeText(widget.courseData['chefId']);

      final existing = await FirebaseFirestore.instance
          .collection('user_courses')
          .where('userId', isEqualTo: uid)
          .where('courseId', isEqualTo: widget.courseId)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('user_courses').add({
          'userId': uid,
          'courseId': widget.courseId,
          'chefId': chefId,
          'purchasedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders satın alındı.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satın alma sırasında hata oluştu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _safeText(widget.courseData['title']).isEmpty
        ? 'Başlıksız Ders'
        : _safeText(widget.courseData['title']);

    final description = _safeText(widget.courseData['description']).isEmpty
        ? 'Bu ders için henüz açıklama eklenmemiş.'
        : _safeText(widget.courseData['description']);

    final chefId = _safeText(widget.courseData['chefId']);
    final category = _categoryText();
    final priceText = _priceText();
    final durationText = _durationText();
    final videoCountText = _videoCountText();
    final previewUrl = _safeText(
      widget.courseData['previewVideoUrl'] ?? widget.courseData['videoUrl'],
    );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Ders Detayı',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<bool>(
        stream: _hasPurchasedStream(),
        builder: (context, purchaseSnap) {
          final hasPurchased = purchaseSnap.data ?? false;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1A1A1A),
                        Color(0xFF222222),
                        Color(0xFF151515),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: _gold.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniBadge(text: category),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14.5,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StatChip(
                            icon: Icons.ondemand_video,
                            text: videoCountText,
                          ),
                          _StatChip(
                            icon: Icons.schedule,
                            text: durationText,
                          ),
                          _StatChip(
                            icon: Icons.sell_outlined,
                            text: priceText,
                          ),
                        ],
                      ),
                      if (previewUrl.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _openVideo(context, previewUrl),
                            icon: const Icon(Icons.play_circle_outline),
                            label: const Text(
                              'Ön İzlemeyi Aç',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                  title: 'Erişim Durumu',
                  subtitle: 'Dersin tamamına erişim bilgisi',
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasPurchased ? Icons.lock_open : Icons.lock_outline,
                            color: hasPurchased ? _gold : Colors.white70,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasPurchased
                                  ? 'Bu ders satın alınmış. Tüm videolar açık.'
                                  : 'Bu ders henüz satın alınmamış. Sadece ön izleme videoları açık.',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!hasPurchased) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isPurchasing ? null : _purchaseCourseDemo,
                            icon: _isPurchasing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.shopping_bag_outlined),
                            label: Text(
                              _isPurchasing ? 'İşleniyor...' : 'Dersi Satın Al',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                  title: 'Ders Bilgileri',
                  subtitle: 'İçeriğin temel alanları ve teknik özeti',
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _panel,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Course ID', widget.courseId),
                      _detailRow('Kategori', category),
                      _detailRow('Süre', durationText),
                      _detailRow('Video Sayısı', videoCountText),
                      _detailRow('Fiyat', priceText),
                      _detailRow('Chef ID', chefId.isEmpty ? '-' : chefId),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionTitle(
                  title: 'Ders Videoları',
                  subtitle:
                      'Ön izleme açık, diğerleri satın alma sonrası açılır',
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('courses')
                      .doc(widget.courseId)
                      .collection('videos')
                      .orderBy('order')
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return _InfoCard(
                        icon: Icons.error_outline,
                        title: 'Videolar yüklenemedi',
                        message: snap.error.toString(),
                      );
                    }

                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: _gold),
                        ),
                      );
                    }

                    final docs = snap.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const _InfoCard(
                        icon: Icons.video_library_outlined,
                        title: 'Henüz video yok',
                        message:
                            'Bu ders için videos alt koleksiyonunda içerik bulunamadı.',
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        final videoTitle = _safeText(data['title']).isEmpty
                            ? 'Başlıksız Video'
                            : _safeText(data['title']);
                        final durationSeconds =
                            _safeInt(data['durationSeconds']);
                        final isPreview = data['isPreview'] == true;
                        final order = _safeInt(data['order']);
                        final videoUrl = _safeText(data['videoUrl']);

                        final minute = durationSeconds > 0
                            ? '${(durationSeconds / 60).ceil()} dk'
                            : 'Süre yok';

                        final canOpen = isPreview || hasPurchased;

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _panel,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: canOpen
                                  ? Colors.white10
                                  : Colors.redAccent.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _MiniBadge(
                                    text: 'Video ${order > 0 ? order : "-"}',
                                  ),
                                  if (isPreview)
                                    const _MiniBadge(text: 'Ön İzleme'),
                                  if (!isPreview && !hasPurchased)
                                    const _MiniBadge(text: 'Kilitli'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                videoTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                minute,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (videoUrl.isEmpty)
                                const Text(
                                  'Video bağlantısı eklenmemiş.',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12.5,
                                  ),
                                )
                              else if (canOpen)
                                TextButton.icon(
                                  onPressed: () =>
                                      _openVideo(context, videoUrl),
                                  icon: const Icon(
                                    Icons.open_in_new,
                                    color: _gold,
                                  ),
                                  label: Text(
                                    isPreview ? 'Ön İzlemeyi Aç' : 'Videoyu Aç',
                                    style: const TextStyle(
                                      color: _gold,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Bu video kilitli. Dersi satın aldıktan sonra açılır.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.lock_outline,
                                    color: Colors.redAccent,
                                  ),
                                  label: const Text(
                                    'Satın alma gerekli',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;

  const _MiniBadge({required this.text});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _StatChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: _gold),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
