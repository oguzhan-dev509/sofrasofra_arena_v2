import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AkademiMerkeziSayfasi extends StatefulWidget {
  const AkademiMerkeziSayfasi({super.key});

  @override
  State<AkademiMerkeziSayfasi> createState() => _AkademiMerkeziSayfasiState();
}

class _AkademiMerkeziSayfasiState extends State<AkademiMerkeziSayfasi> {
  static const Color _bg = Colors.black;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _goldSoft = Color(0xFFFFD54F);

  String _selectedCategory = 'all';

  Stream<List<_AcademyCategory>> _categoriesStream() {
    return FirebaseFirestore.instance
        .collection('academy_categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _AcademyCategory.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<_LessonItem>> _lessonsStream() {
    return FirebaseFirestore.instance
        .collection('dersler')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _LessonItem.fromMap(doc.id, doc.data()))
              .where((item) => item.isPublished)
              .toList(),
        );
  }

  List<_LessonItem> _filterLessons(List<_LessonItem> items) {
    if (_selectedCategory == 'all') return items;

    return items.where((lesson) {
      final normalized = _normalizeLessonCategory(lesson);
      return normalized == _selectedCategory;
    }).toList();
  }

  String _normalizeLessonCategory(_LessonItem lesson) {
    final direct = lesson.category.trim();
    if (direct.isNotEmpty) {
      final normalizedDirect = _normalizeText(direct);

      if (normalizedDirect.contains('osmanli') ||
          normalizedDirect.contains('turk') ||
          normalizedDirect.contains('yoresel') ||
          normalizedDirect.contains('saray')) {
        return 'osmanli_turk';
      }

      if (normalizedDirect.contains('dunya') ||
          normalizedDirect.contains('avrupa') ||
          normalizedDirect.contains('asya') ||
          normalizedDirect.contains('akdeniz') ||
          normalizedDirect.contains('global')) {
        return 'dunya_mutfagi';
      }

      if (normalizedDirect.contains('tabak') ||
          normalizedDirect.contains('sunum') ||
          normalizedDirect.contains('plating') ||
          normalizedDirect.contains('fine dining') ||
          normalizedDirect.contains('kompozisyon')) {
        return 'tabak_tasarimi';
      }

      if (normalizedDirect.contains('pisirme') ||
          normalizedDirect.contains('teknik') ||
          normalizedDirect.contains('hijyen') ||
          normalizedDirect.contains('urun isleme') ||
          normalizedDirect.contains('mutfak disiplini')) {
        return 'mutfak_teknikleri';
      }

      if (normalizedDirect.contains('pastac') ||
          normalizedDirect.contains('cikolata') ||
          normalizedDirect.contains('kek') ||
          normalizedDirect.contains('kurabiye') ||
          normalizedDirect.contains('tatli') ||
          normalizedDirect.contains('borek') ||
          normalizedDirect.contains('pasta')) {
        return 'pastacilik_tatli';
      }

      if (normalizedDirect.contains('maliyet') ||
          normalizedDirect.contains('food cost') ||
          normalizedDirect.contains('isletme') ||
          normalizedDirect.contains('karlilik') ||
          normalizedDirect.contains('menu') ||
          normalizedDirect.contains('ekipman') ||
          normalizedDirect.contains('satis')) {
        return 'maliyet_isletme';
      }

      if (normalizedDirect.contains('danisman') ||
          normalizedDirect.contains('kurulum') ||
          normalizedDirect.contains('operasyon') ||
          normalizedDirect.contains('konsept') ||
          normalizedDirect.contains('personel egitimi')) {
        return 'danismanlik_kurulum';
      }

      if (normalizedDirect.contains('marka') ||
          normalizedDirect.contains('kariyer') ||
          normalizedDirect.contains('prestij') ||
          normalizedDirect.contains('musteri yonetimi') ||
          normalizedDirect.contains('fiyatlandirma') ||
          normalizedDirect.contains('usta sef')) {
        return 'sef_marka_kariyer';
      }
    }

    final raw = _normalizeText('''
${lesson.categoryTitle}
${lesson.subCategory}
${lesson.title}
${lesson.summary}
${lesson.tags.join(' ')}
''');

    if (raw.contains('osmanli') ||
        raw.contains('turk mutfagi') ||
        raw.contains('turk') ||
        raw.contains('yoresel') ||
        raw.contains('saray mutfagi')) {
      return 'osmanli_turk';
    }

    if (raw.contains('dunya mutfagi') ||
        raw.contains('avrupa') ||
        raw.contains('asya') ||
        raw.contains('akdeniz') ||
        raw.contains('global')) {
      return 'dunya_mutfagi';
    }

    if (raw.contains('tabak') ||
        raw.contains('sunum') ||
        raw.contains('plating') ||
        raw.contains('fine dining') ||
        raw.contains('kompozisyon')) {
      return 'tabak_tasarimi';
    }

    if (raw.contains('pisirme') ||
        raw.contains('teknik') ||
        raw.contains('hijyen') ||
        raw.contains('urun isleme') ||
        raw.contains('mutfak disiplini')) {
      return 'mutfak_teknikleri';
    }

    if (raw.contains('pastac') ||
        raw.contains('cikolata') ||
        raw.contains('kek') ||
        raw.contains('kurabiye') ||
        raw.contains('tatli') ||
        raw.contains('borek') ||
        raw.contains('pasta')) {
      return 'pastacilik_tatli';
    }

    if (raw.contains('maliyet') ||
        raw.contains('food cost') ||
        raw.contains('isletme') ||
        raw.contains('karlilik') ||
        raw.contains('menu') ||
        raw.contains('ekipman') ||
        raw.contains('satis')) {
      return 'maliyet_isletme';
    }

    if (raw.contains('danisman') ||
        raw.contains('kurulum') ||
        raw.contains('operasyon') ||
        raw.contains('konsept') ||
        raw.contains('personel egitimi')) {
      return 'danismanlik_kurulum';
    }

    if (raw.contains('marka') ||
        raw.contains('kariyer') ||
        raw.contains('prestij') ||
        raw.contains('musteri yonetimi') ||
        raw.contains('fiyatlandirma') ||
        raw.contains('usta sef')) {
      return 'sef_marka_kariyer';
    }

    return '';
  }

  String _categoryTitleFromId(String id, List<_AcademyCategory> categories) {
    if (id == 'all') return 'Tümü';

    for (final item in categories) {
      if (item.id == id) return item.title;
    }

    switch (id) {
      case 'osmanli_turk':
        return 'Osmanlı & Türk Mutfağı';
      case 'dunya_mutfagi':
        return 'Dünya Mutfağı';
      case 'tabak_tasarimi':
        return 'Tabak Tasarımı';
      case 'mutfak_teknikleri':
        return 'Mutfak Teknikleri';
      case 'pastacilik_tatli':
        return 'Pastacılık & Tatlı';
      case 'maliyet_isletme':
        return 'Maliyet & İşletme';
      case 'danismanlik_kurulum':
        return 'Danışmanlık & Kurulum';
      case 'sef_marka_kariyer':
        return 'Şef Marka & Kariyer';
      default:
        return 'Kategori';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        titleSpacing: 16,
        title: const Text(
          'ŞEF AKADEMİ MERKEZİ',
          style: TextStyle(
            color: _gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: StreamBuilder<List<_AcademyCategory>>(
        stream: _categoriesStream(),
        builder: (context, categorySnapshot) {
          final categories =
              categorySnapshot.data ?? const <_AcademyCategory>[];

          return StreamBuilder<List<_LessonItem>>(
            stream: _lessonsStream(),
            builder: (context, lessonSnapshot) {
              final allLessons = lessonSnapshot.data ?? const <_LessonItem>[];
              final filteredLessons = _filterLessons(allLessons);

              final isLoading =
                  categorySnapshot.connectionState == ConnectionState.waiting ||
                      lessonSnapshot.connectionState == ConnectionState.waiting;

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeroBlock(
                            selectedTitle: _categoryTitleFromId(
                              _selectedCategory,
                              categories,
                            ),
                            totalLessonCount: filteredLessons.length,
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Kategoriler',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _CategoryBar(
                            categories: categories,
                            selectedCategory: _selectedCategory,
                            onSelected: (value) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Text(
                                'Akademi Ders Programı',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x14FFB300),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0x33FFB300),
                                  ),
                                ),
                                child: Text(
                                  '${filteredLessons.length} ders',
                                  style: const TextStyle(
                                    color: _goldSoft,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Şefin uzmanlığını, prestijini ve gelir katmanlarını büyüten modüller.',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CircularProgressIndicator(color: _gold),
                      ),
                    )
                  else if (lessonSnapshot.hasError)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Dersler yüklenemedi: ${lessonSnapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (filteredLessons.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Bu kategoride henüz yayınlanmış ders görünmüyor.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filteredLessons[index];
                            final normalizedCategory =
                                _normalizeLessonCategory(item);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _LessonCard(
                                item: item,
                                normalizedCategoryId: normalizedCategory,
                                categoryTitle: _categoryTitleFromId(
                                  normalizedCategory,
                                  categories,
                                ),
                              ),
                            );
                          },
                          childCount: filteredLessons.length,
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

class _AcademyCategory {
  final String id;
  final String title;
  final int order;
  final bool isActive;

  const _AcademyCategory({
    required this.id,
    required this.title,
    required this.order,
    required this.isActive,
  });

  factory _AcademyCategory.fromMap(Map<String, dynamic> map) {
    return _AcademyCategory(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      order: _toInt(map['order'], fallback: 999),
      isActive: (map['isActive'] ?? true) == true,
    );
  }
}

class _LessonItem {
  final String id;
  final String title;
  final String summary;
  final String category;
  final String categoryTitle;
  final String subCategory;
  final String chefId;
  final String chefName;
  final int duration;
  final int videoCount;
  final String level;
  final bool isPremium;
  final bool isPublished;
  final List<String> tags;
  final String coverImage;

  const _LessonItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.categoryTitle,
    required this.subCategory,
    required this.chefId,
    required this.chefName,
    required this.duration,
    required this.videoCount,
    required this.level,
    required this.isPremium,
    required this.isPublished,
    required this.tags,
    required this.coverImage,
  });

  factory _LessonItem.fromMap(String id, Map<String, dynamic> map) {
    final title = _readFirstString(
      map,
      const ['title', 'baslik', 'name', 'ad'],
      fallback: 'İsimsiz Ders',
    );

    final summary = _readFirstString(
      map,
      const ['summary', 'aciklama', 'description', 'desc'],
      fallback: '',
    );

    final category = _readFirstString(
      map,
      const ['category', 'kategori'],
      fallback: '',
    );

    final categoryTitle = _readFirstString(
      map,
      const ['categoryTitle', 'kategoriBaslik', 'kategoriTitle'],
      fallback: '',
    );

    final subCategory = _readFirstString(
      map,
      const ['subCategory', 'altKategori', 'altKategoriAdi'],
      fallback: '',
    );

    final chefId = _readFirstString(
      map,
      const ['chefId', 'dukkanId', 'ownerId'],
      fallback: '',
    );

    final chefName = _readFirstString(
      map,
      const ['chefName', 'chef', 'egitmen', 'instructorName'],
      fallback: '',
    );

    final duration = _toInt(
      map['duration'] ?? map['sure'] ?? map['durationMinutes'],
      fallback: 0,
    );

    final videoCount = _toInt(
      map['videoCount'] ?? map['video_count'],
      fallback: 0,
    );

    final level = _readFirstString(
      map,
      const ['level', 'seviye'],
      fallback: 'Genel Seviye',
    );

    final isPremium = _toBool(
      map['isPremium'] ?? map['premium'] ?? !(map['ucretsiz'] ?? false),
      fallback: true,
    );

    final isPublished = _toBool(
      map['isPublished'] ?? map['published'] ?? true,
      fallback: true,
    );

    final coverImage = _readFirstString(
      map,
      const ['coverImage', 'img', 'imageUrl', 'thumbnail'],
      fallback: '',
    );

    final tags = _toStringList(map['tags']);

    return _LessonItem(
      id: id,
      title: title,
      summary: summary,
      category: category,
      categoryTitle: categoryTitle,
      subCategory: subCategory,
      chefId: chefId,
      chefName: chefName,
      duration: duration,
      videoCount: videoCount,
      level: level,
      isPremium: isPremium,
      isPublished: isPublished,
      tags: tags,
      coverImage: coverImage,
    );
  }
}

class _HeroBlock extends StatelessWidget {
  final String selectedTitle;
  final int totalLessonCount;

  const _HeroBlock({
    required this.selectedTitle,
    required this.totalLessonCount,
  });

  static const Color _goldSoft = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0x1AFFD54F),
            Color(0x0DFFB300),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33FFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Şef Akademi',
            style: TextStyle(
              color: _goldSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Uzmanlığını derse,\nprestijini sisteme dönüştür.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Akademi modülleri; Osmanlı, dünya mutfağı, tabak tasarımı, maliyet, danışmanlık ve marka katmanlarıyla büyür.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroBadge(
                icon: Icons.category_rounded,
                label: selectedTitle,
              ),
              _HeroBadge(
                icon: Icons.play_lesson_rounded,
                label: '$totalLessonCount ders',
              ),
              const _HeroBadge(
                icon: Icons.workspace_premium_rounded,
                label: 'Premium görünüm',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({
    required this.icon,
    required this.label,
  });

  static const Color _goldSoft = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x14151515),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _goldSoft, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final List<_AcademyCategory> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategoryBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, String>>[
      {'id': 'all', 'title': 'Tümü'},
      ...categories.map((e) => {'id': e.id, 'title': e.title}),
    ];

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final id = item['id']!;
          final title = item['title']!;
          final isSelected = selectedCategory == id;

          return GestureDetector(
            onTap: () => onSelected(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? _gold : const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFD54F) : Colors.white12,
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final _LessonItem item;
  final String normalizedCategoryId;
  final String categoryTitle;

  const _LessonCard({
    required this.item,
    required this.normalizedCategoryId,
    required this.categoryTitle,
  });

  static const Color _card = Color(0xFF121212);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _goldSoft = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    final subtitle = item.summary.trim().isEmpty
        ? 'Bu dersin açıklaması yakında daha detaylı eklenecek.'
        : item.summary.trim();

    final effectiveCategoryTitle =
        categoryTitle.trim().isEmpty ? 'Akademi Dersi' : categoryTitle;

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: item.isPremium
              ? const Color(0x33FFB300)
              : const Color(0x18FFFFFF),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.coverImage.trim().isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 8.5,
                  child: Image.network(
                    item.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1A1A),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white24,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  text: effectiveCategoryTitle,
                  icon: Icons.category_rounded,
                  highlighted: true,
                ),
                if (item.level.trim().isNotEmpty)
                  _chip(
                    text: item.level,
                    icon: Icons.bar_chart_rounded,
                  ),
                if (item.duration > 0)
                  _chip(
                    text: '${item.duration} dk',
                    icon: Icons.schedule_rounded,
                  ),
                if (item.videoCount > 0)
                  _chip(
                    text: '${item.videoCount} video',
                    icon: Icons.ondemand_video_rounded,
                  ),
                if (item.isPremium)
                  _chip(
                    text: 'Premium',
                    icon: Icons.workspace_premium_rounded,
                    highlighted: true,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12.8,
                height: 1.55,
              ),
            ),
            if (item.chefName.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    color: _goldSoft,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.chefName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.tags
                    .take(5)
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (normalizedCategoryId.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0x14FFFFFF), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: _gold,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kategori eşleşmesi aktif',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.84),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip({
    required String text,
    required IconData icon,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0x14FFB300) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted ? const Color(0x33FFB300) : Colors.white10,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted ? _goldSoft : Colors.white70,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: highlighted ? _goldSoft : Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

bool _toBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

String _readFirstString(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

List<String> _toStringList(dynamic value) {
  if (value == null) return const [];

  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  final raw = value.toString().trim();
  if (raw.isEmpty) return const [];

  return raw
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

String _normalizeText(String input) {
  return input
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('Ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('Ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('Ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('Ç', 'c')
      .replaceAll('\n', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
