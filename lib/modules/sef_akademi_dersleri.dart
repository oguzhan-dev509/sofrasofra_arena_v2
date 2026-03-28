import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'course_detail_page.dart';
import 'kurslarim_sayfasi.dart';

class SefAkademiDersleri extends StatelessWidget {
  final String chefId;

  const SefAkademiDersleri({
    super.key,
    required this.chefId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text(
          'ŞEF AKADEMİSİ',
          style: TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Kurslarım',
            icon: const Icon(
              Icons.play_lesson_rounded,
              color: Color(0xFFFFD54F),
            ),
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x33FFD54F)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Şefin Akademi Dersleri',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Satın aldığınız kurslara girerek videoları izleyebilir, içerikleri takip edebilirsiniz.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('courses')
                  .where('chefId', isEqualTo: chefId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFD54F),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Kurslar yüklenirken hata oluştu.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Henüz yayınlanmış kurs bulunmuyor.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }

                final items = docs.map((doc) {
                  final m = doc.data();

                  final rawCreatedAt = m['createdAt'];
                  DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(0);
                  if (rawCreatedAt is Timestamp) {
                    createdAt = rawCreatedAt.toDate();
                  }

                  return _CourseItem(
                    id: doc.id,
                    title: (m['title'] ?? 'İsimsiz Eğitim').toString(),
                    description: (m['description'] ?? '').toString(),
                    category: (m['category'] ?? '').toString(),
                    price: m['price'],
                    durationMinutes: m['durationMinutes'],
                    createdAt: createdAt,
                    isActive: m['isActive'] == true,
                  );
                }).toList();

                items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                for (final item in items) {
                  debugPrint('📚 COURSE => ${item.id} / ${item.title}');
                }

                final seenTitles = <String>{};
                final uniqueItems = items.where((item) {
                  final key = item.title.trim().toLowerCase();
                  if (seenTitles.contains(key)) return false;
                  seenTitles.add(key);
                  return true;
                }).toList();

                for (final item in uniqueItems) {
                  debugPrint('✅ UNIQUE COURSE => ${item.id} / ${item.title}');
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: uniqueItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = uniqueItems[index];

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        debugPrint(
                            '🟡 COURSE CARD TAPPED => ${item.id} / ${item.title}');

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CourseDetailPage(
                              courseId: item.id,
                              title: item.title,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1B1B),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: item.isActive
                                ? const Color(0x33FFD54F)
                                : const Color(0x22FFFFFF),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.category.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x22FFD54F),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: Color(0xFFFFD54F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                item.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  icon: Icons.schedule_rounded,
                                  label: item.durationText,
                                ),
                                _InfoChip(
                                  icon: Icons.payments_rounded,
                                  label: item.priceText,
                                ),
                                _InfoChip(
                                  icon: item.isActive
                                      ? Icons.check_circle
                                      : Icons.pause_circle,
                                  label: item.isActive ? 'Aktif' : 'Pasif',
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
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final dynamic price;
  final dynamic durationMinutes;
  final DateTime createdAt;
  final bool isActive;

  _CourseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.durationMinutes,
    required this.createdAt,
    required this.isActive,
  });

  String get priceText {
    if (price == null) return 'Fiyat yok';
    return '$price TL';
  }

  String get durationText {
    if (durationMinutes == null) return 'Süre yok';
    return '$durationMinutes dk';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFFFFD54F),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
