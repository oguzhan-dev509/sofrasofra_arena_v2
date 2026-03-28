import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/course_detail_page.dart';
import 'package:sofrasofra_arena_v2/services/auth_service.dart';

class KurslarimSayfasi extends StatelessWidget {
  const KurslarimSayfasi({super.key});

  static const Color gold = Color(0xFFFFB300);
  static const Color card = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUserId;

    if (userId == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Kurslarım'),
        ),
        body: const Center(
          child: Text(
            'Kullanıcı bulunamadı.',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Kurslarım',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('user_courses')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, userCoursesSnapshot) {
          if (userCoursesSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: gold),
            );
          }

          if (userCoursesSnapshot.hasError) {
            return Center(
              child: Text(
                'Kurslar yüklenemedi: ${userCoursesSnapshot.error}',
                style: const TextStyle(color: Colors.white54),
              ),
            );
          }

          final userCourseDocs = userCoursesSnapshot.data?.docs ?? [];

          if (userCourseDocs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz satın aldığın bir kurs yok.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: userCourseDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final userCourse = userCourseDocs[index].data();
              final String courseId = (userCourse['courseId'] ?? '').toString();

              if (courseId.isEmpty) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('courses')
                    .doc(courseId)
                    .get(),
                builder: (context, courseSnapshot) {
                  if (courseSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x22FFB300)),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Kurs yükleniyor...',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (courseSnapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x22FFB300)),
                      ),
                      child: Text(
                        'Kurs okunamadı: ${courseSnapshot.error}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  final courseData = courseSnapshot.data?.data();

                  if (courseData == null) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x22FFB300)),
                      ),
                      child: const Text(
                        'Kurs bulunamadı.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  final String title =
                      (courseData['title'] ?? 'Kurs').toString();
                  final String description =
                      (courseData['description'] ?? '').toString();
                  final num price = (courseData['price'] as num?) ?? 0;
                  final String chefName =
                      (courseData['chefName'] ?? 'Şef').toString();

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourseDetailPage(
                            courseId: courseId,
                            title: title,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x22FFB300)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                color: gold,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white38,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Şef: $chefName',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_rounded,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Satın alındı',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$price TL',
                                style: const TextStyle(
                                  color: gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
