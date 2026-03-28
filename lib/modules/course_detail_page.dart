import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sofrasofra_arena_v2/modules/kurslarim_sayfasi.dart';
import 'package:sofrasofra_arena_v2/services/auth_service.dart';
import 'package:sofrasofra_arena_v2/services/course_purchase_service.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseId;
  final String title;

  const CourseDetailPage({
    super.key,
    required this.courseId,
    required this.title,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  static const Color gold = Color(0xFFFFB300);
  static const Color card = Color(0xFF171717);

  bool _hasAccess = false;
  bool _loadingAccess = true;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '📗 COURSE DETAIL OPENED => ${widget.courseId} / ${widget.title}');
    _loadAccess();
  }

  Future<bool> _checkUserAccess(String courseId) async {
    final userId = AuthService.currentUserId!;

    final result = await FirebaseFirestore.instance
        .collection('user_courses')
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<void> _loadAccess() async {
    try {
      final hasAccess = await _checkUserAccess(widget.courseId);

      if (!mounted) return;

      setState(() {
        _hasAccess = hasAccess;
        _loadingAccess = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _hasAccess = false;
        _loadingAccess = false;
      });
    }
  }

  Future<void> _purchaseCourse(Map<String, dynamic> courseData) async {
    final result = await CoursePurchaseService.purchaseCourse(
      userId: AuthService.currentUserId!,
      courseId: widget.courseId,
      courseTitle: (courseData['title'] ?? widget.title).toString(),
      chefId: (courseData['chefId'] ?? 'chef_mehmet_usta').toString(),
      chefName: (courseData['chefName'] ?? 'Mehmet Usta').toString(),
      price: (courseData['price'] as num?) ?? 0,
    );

    if (!mounted) return;

    if (result.success) {
      setState(() {
        _hasAccess = true;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );
  }

  Future<void> _handleVideoTap({
    required bool isPreview,
    required String videoUrl,
  }) async {
    final canWatch = isPreview || _hasAccess;

    if (!canWatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu içerik satın alma sonrası açılır 🔒'),
        ),
      );
      return;
    }

    if (videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video bağlantısı bulunamadı'),
        ),
      );
      return;
    }

    final uri = Uri.tryParse(videoUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video bağlantısı geçersiz'),
        ),
      );
      return;
    }

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video açılamadı'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: gold),
            tooltip: 'Kurslarım',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KurslarimSayfasi(),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('courses')
            .doc(widget.courseId)
            .get(),
        builder: (context, courseSnapshot) {
          if (courseSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: gold),
            );
          }

          if (courseSnapshot.hasError) {
            return Center(
              child: Text(
                'Kurs yüklenemedi: ${courseSnapshot.error}',
                style: const TextStyle(color: Colors.white54),
              ),
            );
          }

          final courseData = courseSnapshot.data?.data();

          if (courseData == null) {
            return const Center(
              child: Text(
                'Kurs bulunamadı',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          final String courseTitle =
              (courseData['title'] ?? widget.title).toString();
          final String courseDescription =
              (courseData['description'] ?? '').toString();
          final num price = (courseData['price'] as num?) ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      courseTitle,
                      style: const TextStyle(
                        color: gold,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (courseDescription.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        courseDescription,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      '$price TL',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadingAccess || _hasAccess
                            ? null
                            : () => _purchaseCourse(courseData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          _loadingAccess
                              ? 'Erişim kontrol ediliyor...'
                              : _hasAccess
                                  ? 'Satın Alındı ✅'
                                  : 'Satın Al - $price TL',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('courses')
                      .doc(widget.courseId)
                      .collection('videos')
                      .orderBy('order')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: gold),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Videolar yüklenemedi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    final videos = snapshot.data?.docs ?? [];

                    if (videos.isEmpty) {
                      return const Center(
                        child: Text(
                          'Henüz video eklenmemiş.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: videos.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final v = videos[index].data();

                        final String videoTitle =
                            (v['title'] ?? 'Video').toString();
                        final int duration =
                            (v['durationSeconds'] as num?)?.toInt() ?? 0;
                        final bool isPreview = v['isPreview'] == true;
                        final String videoUrl =
                            (v['videoUrl'] ?? '').toString();

                        final bool canWatch = isPreview || _hasAccess;

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _handleVideoTap(
                            isPreview: isPreview,
                            videoUrl: videoUrl,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0x22FFB300),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  canWatch
                                      ? Icons.play_circle_fill_rounded
                                      : Icons.lock,
                                  color: canWatch ? gold : Colors.white54,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    videoTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${duration ~/ 60} dk',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
