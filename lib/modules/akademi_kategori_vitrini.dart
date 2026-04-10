import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/course_detail_page.dart';

class AkademiKategoriVitrini extends StatefulWidget {
  const AkademiKategoriVitrini({super.key});

  @override
  State<AkademiKategoriVitrini> createState() => _AkademiKategoriVitriniState();
}

class _AkademiKategoriVitriniState extends State<AkademiKategoriVitrini> {
  static const Color _bg = Color(0xFF111111);
  static const Color _panel = Color(0xFF1A1A1A);
  static const Color _panel2 = Color(0xFF202020);
  static const Color _gold = Color(0xFFFFB300);

  String _selectedCategory = 'Tümü';

  final List<String> _categories = const [
    'Tümü',
    'Genel Türk Mutfağı',
    'Osmanlı Mutfağı',
    'Dünya Mutfağı',
    'Pastacılık',
    'Tabak Tasarım',
    'Maliyet & İşletme',
  ];

  Query<Map<String, dynamic>> _query() {
    return FirebaseFirestore.instance
        .collection('courses')
        .where('isActive', isEqualTo: true);
  }

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

  Timestamp? _asTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }

  bool _isValidCourse(Map<String, dynamic> data) {
    final title = _safeText(data['title']);
    final description = _safeText(data['description']);
    final category = _safeText(data['category']);
    return title.isNotEmpty && (description.isNotEmpty || category.isNotEmpty);
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

  String _mapCategory(Map<String, dynamic> data) {
    final raw = _normalize(_safeText(data['category']));

    if (raw.contains('osmanli')) {
      return 'Osmanlı Mutfağı';
    }

    if (raw.contains('dunya')) {
      return 'Dünya Mutfağı';
    }

    if (raw.contains('pastac') ||
        raw.contains('pasta') ||
        raw.contains('tatli') ||
        raw.contains('cikolata') ||
        raw.contains('firin')) {
      return 'Pastacılık';
    }

    if (raw.contains('tabak') ||
        raw.contains('sunum') ||
        raw.contains('plating')) {
      return 'Tabak Tasarım';
    }

    if (raw.contains('maliyet') ||
        raw.contains('isletme') ||
        raw.contains('kafe') ||
        raw.contains('menu') ||
        raw.contains('cost')) {
      return 'Maliyet & İşletme';
    }

    return 'Genel Türk Mutfağı';
  }

  bool _matchesSelectedCategory(Map<String, dynamic> data) {
    if (_selectedCategory == 'Tümü') return true;
    return _mapCategory(data) == _selectedCategory;
  }

  double _readTrendScore(Map<String, dynamic> data) {
    final explicitScore = data['score'];
    if (explicitScore is num) return explicitScore.toDouble();

    double score = 0;

    final price = _safeDouble(data['price']);
    final durationMinutes = _safeInt(data['durationMinutes']);
    final videoCount = _safeInt(data['videoCount']);
    final isPreview = data['isPreview'] == true;
    final isPopular = data['isPopular'] == true;
    final isFeatured = data['isFeatured'] == true;

    score += videoCount * 12;
    score += durationMinutes * 0.15;
    score += price > 0 ? 20 : 8;
    if (isPreview) score += 15;
    if (isPopular) score += 25;
    if (isFeatured) score += 30;

    return score;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortByScore(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = [...docs];
    items.sort((a, b) {
      final bScore = _readTrendScore(b.data());
      final aScore = _readTrendScore(a.data());
      return bScore.compareTo(aScore);
    });
    return items;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortByCreatedAt(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = [...docs];
    items.sort((a, b) {
      final bTs = _asTimestamp(
        b.data()['updatedAt'] ?? b.data()['createdAt'],
      );
      final aTs = _asTimestamp(
        a.data()['updatedAt'] ?? a.data()['createdAt'],
      );

      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;

      return bTs.toDate().compareTo(aTs.toDate());
    });
    return items;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _featuredDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final featured = docs.where((doc) {
      final data = doc.data();
      return data['isFeatured'] == true || data['isPopular'] == true;
    }).toList();

    if (featured.isEmpty) {
      return _sortByScore(docs).take(8).toList();
    }

    return _sortByScore(featured).take(8).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _trendDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return _sortByScore(docs).take(10).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _newDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return _sortByCreatedAt(docs).take(10).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _previewDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final previews = docs.where((doc) {
      final data = doc.data();
      return data['isPreview'] == true || _safeInt(data['videoCount']) > 0;
    }).toList();

    if (previews.isEmpty) {
      return _sortByCreatedAt(docs).take(10).toList();
    }

    return _sortByScore(previews).take(10).toList();
  }

  String _priceText(Map<String, dynamic> data) {
    final price = _safeDouble(data['price']);
    if (price <= 0) return 'Yakında';
    return '${price.toStringAsFixed(0)} ₺';
  }

  String _durationText(Map<String, dynamic> data) {
    final minutes = _safeInt(data['durationMinutes']);
    if (minutes <= 0) return 'Süre yakında';
    return '$minutes dk';
  }

  String _videoCountText(Map<String, dynamic> data) {
    final count = _safeInt(data['videoCount']);
    if (count <= 0) return 'Video bilgisi yakında';
    return '$count video';
  }

  void _openDetail(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailPage(
          courseId: doc.id,
          courseData: doc.data(),
        ),
      ),
    );
  }

  Widget _buildHorizontalSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    if (docs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, subtitle: subtitle),
        const SizedBox(height: 14),
        SizedBox(
          height: 295,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              return _HorizontalCourseCard(
                title: _safeText(data['title']),
                subtitle: _safeText(data['description']).isNotEmpty
                    ? _safeText(data['description'])
                    : 'Profesyonel mutfak becerilerini geliştirmek için hazırlanmış eğitim içeriği.',
                category: _mapCategory(data),
                priceText: _priceText(data),
                durationText: _durationText(data),
                videoCountText: _videoCountText(data),
                onTap: () => _openDetail(context, doc),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'ŞEF AKADEMİSİ',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return _CenterInfo(
              icon: Icons.error_outline,
              title: 'Hata',
              message: snap.error.toString(),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final allDocs = snap.data?.docs ?? [];
          final validDocs =
              allDocs.where((doc) => _isValidCourse(doc.data())).toList();

          final docs = validDocs
              .where((doc) => _matchesSelectedCategory(doc.data()))
              .toList();

          if (validDocs.isEmpty) {
            return const _CenterInfo(
              icon: Icons.school_outlined,
              title: 'Henüz ders yok',
              message: 'Aktif akademi dersi bulunamadı.',
            );
          }

          final featuredDocs = _featuredDocs(docs);
          final trendDocs = _trendDocs(docs);
          final newDocs = _newDocs(docs);
          final previewDocs = _previewDocs(docs);

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 760;

              int crossAxisCount = 1;
              if (width >= 760 && width < 1180) {
                crossAxisCount = 2;
              } else if (width >= 1180) {
                crossAxisCount = 3;
              }

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroSection(isMobile: isMobile),
                          const SizedBox(height: 18),
                          _AcademyIdeaCard(isMobile: isMobile),
                          const SizedBox(height: 22),
                          _SectionTitle(
                            title: 'Kategoriler',
                            subtitle:
                                'İhtiyacına göre doğru akademi içeriğini keşfet',
                          ),
                          const SizedBox(height: 12),
                          _CategoryBar(
                            categories: _categories,
                            selected: _selectedCategory,
                            onSelected: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildHorizontalSection(
                            context: context,
                            title: 'Öne Çıkan Dersler',
                            subtitle:
                                'Öncelikli gösterilen ve güçlü içerik yapısına sahip eğitimler',
                            docs: featuredDocs,
                          ),
                          const SizedBox(height: 24),
                          _buildHorizontalSection(
                            context: context,
                            title: 'Trend Dersler',
                            subtitle:
                                'Video sayısı, içerik derinliği ve görünürlük puanına göre öne çıkanlar',
                            docs: trendDocs,
                          ),
                          const SizedBox(height: 24),
                          _buildHorizontalSection(
                            context: context,
                            title: 'Yeni Eklenenler',
                            subtitle:
                                'Son eklenen veya son güncellenen akademi içerikleri',
                            docs: newDocs,
                          ),
                          const SizedBox(height: 24),
                          _buildHorizontalSection(
                            context: context,
                            title: 'Ön İzlemeli Dersler',
                            subtitle:
                                'İçeriğine hızlı bakış atabileceğin seçili dersler',
                            docs: previewDocs,
                          ),
                          const SizedBox(height: 26),
                          _SectionTitle(
                            title: _selectedCategory == 'Tümü'
                                ? 'Tüm Akademi Dersleri'
                                : _selectedCategory,
                            subtitle:
                                'Grid görünümde tüm aktif dersleri keşfet',
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  if (docs.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 80),
                        child: _CenterInfo(
                          icon: Icons.search_off_rounded,
                          title: 'Bu kategoride ders bulunamadı',
                          message:
                              'Başka bir kategori seçebilir veya tüm derslere dönebilirsiniz.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doc = docs[index];
                            final data = doc.data();

                            return _PremiumCourseCard(
                              title: _safeText(data['title']),
                              subtitle: _safeText(data['description'])
                                      .isNotEmpty
                                  ? _safeText(data['description'])
                                  : 'Profesyonel mutfak gelişimi için hazırlanmış ders içeriği.',
                              category: _mapCategory(data),
                              priceText: _priceText(data),
                              durationText: _durationText(data),
                              videoCountText: _videoCountText(data),
                              onTap: () => _openDetail(context, doc),
                            );
                          },
                          childCount: docs.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: isMobile ? 0.86 : 0.84,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final bool isMobile;

  const _HeroSection({required this.isMobile});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _panel = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
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
        border: Border.all(color: _gold.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroTextBlock(),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _HeroTag(text: 'Premium Akademi'),
                    _HeroTag(text: 'Video Dersler'),
                    _HeroTag(text: 'Kategoriye Göre Keşif'),
                    _HeroTag(text: 'Şef Odaklı Eğitim'),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                const Expanded(
                  flex: 6,
                  child: _HeroTextBlock(),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: Container(
                    height: 270,
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: const Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _HeroTag(text: 'Türk Mutfağı'),
                        _HeroTag(text: 'Osmanlı'),
                        _HeroTag(text: 'Dünya Mutfağı'),
                        _HeroTag(text: 'Pastacılık'),
                        _HeroTag(text: 'Tabak Tasarım'),
                        _HeroTag(text: 'Maliyet & İşletme'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeroTextBlock extends StatelessWidget {
  const _HeroTextBlock();

  static const Color _gold = Color(0xFFFFB300);
  static const Color _softGold = Color(0xFFFFE0A3);

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Şef Akademisi',
          style: TextStyle(
            color: _gold,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Aşçılık, pastacılık, mutfak yönetimi ve profesyonel gelişim için hazırlanmış premium eğitim alanı.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Gerçek eğitim akışı • güçlü kategori deneyimi • premium vitrin',
          style: TextStyle(
            color: _softGold,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String text;

  const _HeroTag({required this.text});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _gold.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = categories[index];
          final isSelected = item == selected;

          return GestureDetector(
            onTap: () => onSelected(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? _gold : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? _gold : Colors.white12,
                ),
              ),
              child: Center(
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          );
        },
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

class _AcademyIdeaCard extends StatelessWidget {
  final bool isMobile;

  const _AcademyIdeaCard({required this.isMobile});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome, color: _gold),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hangi eğitimi almalıyım?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Bu alan ileride kullanıcı hedefi, beceri seviyesi ve ilgi alanına göre en doğru akademi derslerini önermek için kullanılabilir.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _CenterInfo({
    required this.icon,
    required this.title,
    required this.message,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: _gold),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: Colors.white70,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalCourseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String category;
  final String priceText;
  final String durationText;
  final String videoCountText;
  final VoidCallback onTap;

  const _HorizontalCourseCard({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.priceText,
    required this.durationText,
    required this.videoCountText,
    required this.onTap,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 270,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1B1B1B),
              Color(0xFF232323),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniBadge(text: category),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(icon: Icons.ondemand_video, text: videoCountText),
                  _StatChip(icon: Icons.schedule, text: durationText),
                  _StatChip(icon: Icons.sell_outlined, text: priceText),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Text(
                    'Detaya Git',
                    style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: _gold, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumCourseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String category;
  final String priceText;
  final String durationText;
  final String videoCountText;
  final VoidCallback onTap;

  const _PremiumCourseCard({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.priceText,
    required this.durationText,
    required this.videoCountText,
    required this.onTap,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF242424),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MiniBadge(text: category),
              const SizedBox(height: 14),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  subtitle,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.2,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(icon: Icons.ondemand_video, text: videoCountText),
                  _StatChip(icon: Icons.schedule, text: durationText),
                  _StatChip(icon: Icons.sell_outlined, text: priceText),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Ders detayını aç',
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: _gold, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
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
        color: _gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _gold.withOpacity(0.35)),
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
        color: Colors.white.withOpacity(0.05),
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
