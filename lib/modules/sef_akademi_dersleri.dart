import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/consulting_requests_page.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_ders_detay_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/chef_brand_career_page.dart';

class SefAkademiDersleri extends StatefulWidget {
  final String chefId;
  final String chefName;

  const SefAkademiDersleri({
    super.key,
    required this.chefId,
    this.chefName = 'Usta Şef',
  });

  @override
  State<SefAkademiDersleri> createState() => _SefAkademiDersleriState();
}

class _SefAkademiDersleriState extends State<SefAkademiDersleri> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  String _selectedCategory = 'all';

  bool _matchesCategory(Map<String, dynamic> data) {
    if (_selectedCategory == 'all') return true;

    final slug = (data['categorySlug'] ?? data['category'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    return slug == _selectedCategory.toLowerCase();
  }

  String _lessonTitle(Map<String, dynamic> m) {
    return (m['title'] ?? m['baslik'] ?? 'İsimsiz Eğitim').toString();
  }

  String _lessonDescription(Map<String, dynamic> m) {
    return (m['description'] ?? m['aciklama'] ?? 'Açıklama eklenmemiş')
        .toString();
  }

  String _lessonDurationLabel(Map<String, dynamic> m) {
    final raw = m['durationLabel'] ?? m['sure'];

    if (raw == null) return 'Süre belirtilmedi';
    if (raw is num) return '${raw.toInt()} dk';
    return raw.toString();
  }

  int _lessonVideoCount(Map<String, dynamic> m) {
    return (m['videoCount'] as num?)?.toInt() ?? 0;
  }

  bool _lessonIsFree(Map<String, dynamic> m) {
    if (m['ucretsiz'] == true) return true;
    if (m['isPremium'] == true) return false;
    return false;
  }

  String _lessonCategoryText(Map<String, dynamic> m) {
    return (m['categoryName'] ?? m['category'] ?? m['kategori'] ?? '')
        .toString()
        .trim();
  }

  int _lessonOrder(Map<String, dynamic> m) {
    return (m['order'] as num?)?.toInt() ?? 9999;
  }

  void _openBrandComingSoon() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _AcademyComingSoonPage(
          title: 'Şef Marka & Kariyer',
          description:
              'Bu alan bir sonraki adımda kişisel marka, premium konumlandırma, fiyatlandırma ve müşteri yönetimi modülleri ile açılacak.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'AKADEMİ DERS PROGRAMI',
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('dersler')
            .where('chefId', isEqualTo: widget.chefId)
            .snapshots(),
        builder: (context, lessonSnapshot) {
          if (lessonSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: gold),
            );
          }

          if (lessonSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Dersler yüklenemedi: ${lessonSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }

          final allDocs = lessonSnapshot.data?.docs ?? [];
          final docs =
              allDocs.where((doc) => _matchesCategory(doc.data())).toList()
                ..sort(
                  (a, b) =>
                      _lessonOrder(a.data()).compareTo(_lessonOrder(b.data())),
                );

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gold.withOpacity(0.14),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withOpacity(0.12),
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.school_rounded, color: gold, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'ŞEF AKADEMİSİ',
                            style: TextStyle(
                              color: gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.chefName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Profesyonel eğitim modülleri, ders içerikleri ve mutfak uzmanlığı tek ekranda.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _AcademyMetaChip(
                            icon: Icons.menu_book_rounded,
                            label: 'Ders Modülleri',
                          ),
                          _AcademyMetaChip(
                            icon: Icons.play_circle_rounded,
                            label: 'Video İçerikleri',
                          ),
                          _AcademyMetaChip(
                            icon: Icons.workspace_premium_rounded,
                            label: 'Premium Akademi',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('academy_categories')
                            .where('isActive', isEqualTo: true)
                            .orderBy('order')
                            .snapshots(),
                        builder: (context, categorySnapshot) {
                          if (categorySnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: SizedBox(
                                height: 24,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: gold,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          final categoryDocs =
                              categorySnapshot.data?.docs ?? [];

                          final chips = <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.only(right: 8, bottom: 8),
                              child: ChoiceChip(
                                label: const Text('Tümü'),
                                selected: _selectedCategory == 'all',
                                onSelected: (_) {
                                  setState(() => _selectedCategory = 'all');
                                },
                                labelStyle: TextStyle(
                                  color: _selectedCategory == 'all'
                                      ? Colors.black
                                      : Colors.white70,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                                selectedColor: gold,
                                backgroundColor: Colors.white.withOpacity(0.08),
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.14),
                                  ),
                                ),
                              ),
                            ),
                          ];

                          for (final doc in categoryDocs) {
                            final m = doc.data();
                            final slug =
                                (m['id'] ?? m['slug'] ?? doc.id).toString();
                            final title =
                                (m['title'] ?? m['shortTitle'] ?? doc.id)
                                    .toString();

                            chips.add(
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 8, bottom: 8),
                                child: ChoiceChip(
                                  label: Text(title),
                                  selected: _selectedCategory == slug,
                                  onSelected: (_) {
                                    setState(() => _selectedCategory = slug);
                                  },
                                  labelStyle: TextStyle(
                                    color: _selectedCategory == slug
                                        ? Colors.black
                                        : Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                  selectedColor: gold,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.08),
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: Colors.white.withOpacity(0.14),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KATEGORİLER',
                                style: TextStyle(
                                  color: gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(children: chips),
                              const SizedBox(height: 6),
                              Text(
                                _selectedCategory == 'all'
                                    ? 'Tüm kategoriler gösteriliyor'
                                    : 'Seçili kategori: $_selectedCategory',
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AcademyPremiumBridgeCard(
                        icon: Icons.support_agent_rounded,
                        eyebrow: 'YÜKSEK GELİR KATMANI',
                        title: 'Danışmanlık & Kurulum',
                        subtitle:
                            'Menü danışmanlığı, mutfak kurulum ve operasyon desteği ile şef bilgisini premium hizmete dönüştür.',
                        badges: const [
                          'Menü Danışmanlığı',
                          'Kurulum',
                          'Operasyon',
                        ],
                        cta: 'Modülü Aç',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsultingRequestsPage(
                                chefId: widget.chefId,
                                chefName: widget.chefName,
                                isAdmin: false,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _AcademyPremiumBridgeCard(
                        icon: Icons.workspace_premium_rounded,
                        eyebrow: 'MARKA KATMANI',
                        title: 'Şef Marka & Kariyer',
                        subtitle:
                            'Kişisel marka, premium konumlandırma, müşteri yönetimi ve fiyatlandırma stratejileriyle şef görünürlüğünü büyüt.',
                        badges: const [
                          'Kişisel Marka',
                          'Fiyatlandırma',
                          'Müşteri Yönetimi',
                        ],
                        cta: 'Modülü Aç',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChefBrandCareerPage(
                                chefId: widget.chefId,
                                chefName: widget.chefName,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (docs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Text(
                          _selectedCategory == 'all'
                              ? 'Bu şef için henüz ders içeriği eklenmedi.'
                              : 'Bu kategoride ders bulunamadı.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, rawIndex) {
                        if (rawIndex.isOdd) {
                          return const SizedBox(height: 14);
                        }

                        final index = rawIndex ~/ 2;
                        final m = docs[index].data();

                        final baslik = _lessonTitle(m);
                        final sure = _lessonDurationLabel(m);
                        final aciklama = _lessonDescription(m);
                        final ucretsiz = _lessonIsFree(m);
                        final videoSayisi = _lessonVideoCount(m);
                        final categoryText = _lessonCategoryText(m);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SefAkademiDersDetaySayfasi(
                                    baslik: baslik,
                                    dersId: docs[index].id,
                                    aciklama: aciklama,
                                    sure: sure,
                                    ucretsiz: ucretsiz,
                                    videoSayisi: videoSayisi,
                                    chefName: widget.chefName,
                                  ),
                                ),
                              );
                            },
                            child: Ink(
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.10),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.24),
                                    blurRadius: 22,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 54,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            color: gold.withOpacity(0.14),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: gold.withOpacity(0.22),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.play_lesson_rounded,
                                            color: gold,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                baslik.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w900,
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  if (categoryText.isNotEmpty)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: gold
                                                            .withOpacity(0.12),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(999),
                                                      ),
                                                      child: Text(
                                                        categoryText,
                                                        style: const TextStyle(
                                                          color: gold,
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: ucretsiz
                                                          ? const Color(
                                                              0xFF0E3B33)
                                                          : Colors.white
                                                              .withOpacity(
                                                                  0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                      border: Border.all(
                                                        color: ucretsiz
                                                            ? const Color(
                                                                0xFF1F8A70)
                                                            : Colors.white
                                                                .withOpacity(
                                                                    0.12),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      ucretsiz
                                                          ? 'ÜCRETSİZ'
                                                          : 'PREMIUM',
                                                      style: TextStyle(
                                                        color: ucretsiz
                                                            ? const Color(
                                                                0xFF8EF0D0)
                                                            : Colors.white70,
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      aciklama,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.55,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        _LessonInfoChip(
                                          icon: Icons.schedule_rounded,
                                          label: sure,
                                        ),
                                        _LessonInfoChip(
                                          icon: Icons.video_library_rounded,
                                          label: '$videoSayisi video',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Row(
                                      children: const [
                                        Text(
                                          'Dersi Aç',
                                          style: TextStyle(
                                            color: gold,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: gold,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: docs.isEmpty ? 0 : (docs.length * 2 - 1),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AcademyMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AcademyMetaChip({
    required this.icon,
    required this.label,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _LessonInfoChip({
    required this.icon,
    required this.label,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: gold),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyPremiumBridgeCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<String> badges;
  final String cta;
  final VoidCallback? onTap;

  const _AcademyPremiumBridgeCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.badges,
    required this.cta,
    this.onTap,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: gold.withOpacity(0.20),
                      ),
                    ),
                    child: Icon(icon, color: gold, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            color: gold,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.8,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges
                    .map(
                      (badge) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    cta,
                    style: const TextStyle(
                      color: gold,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: gold,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AcademyComingSoonPage extends StatelessWidget {
  final String title;
  final String description;

  const _AcademyComingSoonPage({
    required this.title,
    required this.description,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: Text(
          title,
          style: const TextStyle(
            color: gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: gold,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
