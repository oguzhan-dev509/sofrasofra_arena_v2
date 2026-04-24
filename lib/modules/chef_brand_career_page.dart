import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/consulting_requests_page.dart';
import 'package:sofrasofra_arena_v2/modules/create_reservation_page.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_ders_detay_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/workshop_requests_page.dart';

enum ReservationServiceType {
  chefsTable,
  privateDining,
}

class ChefBrandCareerPage extends StatefulWidget {
  final String chefId;
  final String chefName;

  const ChefBrandCareerPage({
    super.key,
    required this.chefId,
    required this.chefName,
  });

  @override
  State<ChefBrandCareerPage> createState() => _ChefBrandCareerPageState();
}

class _ChefBrandCareerPageState extends State<ChefBrandCareerPage> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

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

  int _lessonOrder(Map<String, dynamic> m) {
    return (m['order'] as num?)?.toInt() ?? 9999;
  }

  bool _isBrandLesson(Map<String, dynamic> m) {
    final raw = [
      (m['category'] ?? '').toString(),
      (m['categorySlug'] ?? '').toString(),
      (m['categoryName'] ?? '').toString(),
      (m['subCategory'] ?? '').toString(),
      (m['kategori'] ?? '').toString(),
      (m['title'] ?? '').toString(),
      (m['baslik'] ?? '').toString(),
    ].join(' ').toLowerCase();

    return raw.contains('marka') ||
        raw.contains('kariyer') ||
        raw.contains('fiyatland') ||
        raw.contains('musteri') ||
        raw.contains('müşteri') ||
        raw.contains('kişisel marka') ||
        raw.contains('kisisel marka');
  }

  String _profileText(Map<String, dynamic>? data, String key, String fallback) {
    final val = data?[key];
    if (val == null) return fallback;
    final text = val.toString().trim();
    if (text.isEmpty) return fallback;
    return text;
  }

  List<String> _profileList(
    Map<String, dynamic>? data,
    String key,
    List<String> fallback,
  ) {
    final raw = data?[key];
    if (raw is List) {
      final list = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
    return fallback;
  }

  Widget _buildPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildLessonCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data();
    final baslik = _lessonTitle(m);
    final aciklama = _lessonDescription(m);
    final sure = _lessonDurationLabel(m);
    final ucretsiz = _lessonIsFree(m);
    final videoSayisi = _lessonVideoCount(m);

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
                dersId: doc.id,
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
            border: Border.all(color: Colors.white.withOpacity(0.10)),
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
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: gold.withOpacity(0.22)),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: gold,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            baslik,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: gold.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Şef Marka & Kariyer',
                                  style: TextStyle(
                                    color: gold,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ucretsiz
                                      ? const Color(0xFF0E3B33)
                                      : Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: ucretsiz
                                        ? const Color(0xFF1F8A70)
                                        : Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: Text(
                                  ucretsiz ? 'ÜCRETSİZ' : 'PREMIUM',
                                  style: TextStyle(
                                    color: ucretsiz
                                        ? const Color(0xFF8EF0D0)
                                        : Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
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
                    _BrandInfoChip(
                      icon: Icons.schedule_rounded,
                      label: sure,
                    ),
                    _BrandInfoChip(
                      icon: Icons.video_library_rounded,
                      label: '$videoSayisi video',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Text(
                      'Modülü Aç',
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
  }

  Widget _buildLessonSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('dersler')
          .where('chefId', isEqualTo: widget.chefId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: gold),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Text(
              'Marka modülleri yüklenemedi: ${snapshot.error}',
              style: const TextStyle(color: Colors.white54),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) => _isBrandLesson(doc.data())).toList()
          ..sort(
            (a, b) => _lessonOrder(a.data()).compareTo(_lessonOrder(b.data())),
          );

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Henüz aktif marka modülü görünmüyor.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kişisel marka, fiyatlandırma, müşteri yönetimi ve premium konumlandırma içerikleri burada listelenecek.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ...docs.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildLessonCard(context, doc),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCareerSummary(String summary, List<String> highlights) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: gold, size: 18),
              SizedBox(width: 8),
              Text(
                'KARİYER ÖZETİ',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            summary,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: highlights.map(_buildPill).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseSection(List<String> expertise) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: gold, size: 18),
              SizedBox(width: 8),
              Text(
                'UZMANLIK ALANLARI',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: expertise.map(_buildPill).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard({
    required String year,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withOpacity(0.22)),
            ),
            child: Text(
              year,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: gold,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
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

  Widget _buildTextShowcase({
    required String title,
    required String text,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: gold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileStream = FirebaseFirestore.instance
        .collection('chef_profiles')
        .doc(widget.chefId)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: profileStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        final profileName = _profileText(
          data,
          'displayName',
          widget.chefName,
        );

        final heroTagline = _profileText(
          data,
          'heroTagline',
          'Fine Dining & Modern Türk Mutfağı Uzmanı',
        );

        final heroDescription = _profileText(
          data,
          'heroDescription',
          'Şefin profesyonel geçmişini, uzmanlık alanlarını, marka gücünü ve premium hizmetlerini keşfedin.',
        );

        final highlights = _profileList(
          data,
          'careerHighlights',
          const [
            'Kişisel Marka',
            'Fiyatlandırma',
            'Müşteri Yönetimi',
            'Premium Konumlandırma',
          ],
        );

        final careerSummary = _profileText(
          data,
          'careerSummary',
          'Şefin kariyer özeti burada yer alır.',
        );

        final expertise = _profileList(
          data,
          'expertise',
          const [
            'Fine Dining',
            'Modern Türk Mutfağı',
            'Danışmanlık',
          ],
        );

        final consultingText = _profileText(
          data,
          'serviceConsultingText',
          'Şef kimliğini netleştirme, güven veren vitrin dili oluşturma ve doğru müşteri algısı kurma.',
        );

        final privateDiningText = _profileText(
          data,
          'servicePrivateDiningText',
          'Algı, değer ve hizmet seviyesine göre premium deneyim tasarlama.',
        );

        final workshopText = _profileText(
          data,
          'serviceWorkshopText',
          'Doğru müşteriyle çalışma, sadakat oluşturma ve eğitim akışı tasarlama.',
        );

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: gold),
            title: const Text(
              'Şef Marka & Kariyer',
              style: TextStyle(
                color: gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x33FFB300),
                          Color(0xFF1A1A1A),
                          Color(0xFF080808),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D000000),
                          blurRadius: 30,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.10),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                color: gold,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'ŞEF MARKA & KARİYER',
                                style: TextStyle(
                                  color: gold,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          profileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          heroTagline,
                          style: const TextStyle(
                            color: gold,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          heroDescription,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            height: 1.7,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: highlights.map(_buildPill).toList(),
                        ),
                        const SizedBox(height: 18),
                        const Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _MetricCard(
                              title: 'PREMIUM',
                              subtitle: 'Marka Odağı',
                            ),
                            _MetricCard(
                              title: 'PRIVATE DINING',
                              subtitle: 'Ana Hizmet',
                            ),
                            _MetricCard(
                              title: 'DANIŞMANLIK',
                              subtitle: 'Gelir Alanı',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.22),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.grid_view_rounded,
                                color: gold, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'PREMIUM HİZMETLER',
                              style: TextStyle(
                                color: gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Şefin marka değerini taşıyan ana servis alanları tek vitrinde sunulur.',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ExpandableServiceCard(
                          icon: Icons.person_outline_rounded,
                          title: 'Danışmanlık',
                          subtitle: consultingText,
                        ),
                        const SizedBox(height: 12),
                        _ExpandableServiceCard(
                          icon: Icons.sell_rounded,
                          title: 'Private Dining',
                          subtitle: privateDiningText,
                        ),
                        const SizedBox(height: 12),
                        _ExpandableServiceCard(
                          icon: Icons.people_alt_rounded,
                          title: 'Workshop & Eğitim',
                          subtitle: workshopText,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _CTAButton(
                                title: 'Danışmanlık',
                                icon: Icons.person_outline_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ConsultingRequestsPage(
                                        chefId: widget.chefId,
                                        chefName: widget.chefName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CTAButton(
                                title: 'Private Dining',
                                icon: Icons.sell_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateReservationPage(
                                        chefId: widget.chefId,
                                        chefName: widget.chefName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _CTAButton(
                                title: 'Workshop',
                                icon: Icons.people_alt_rounded,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WorkshopRequestsPage(
                                        chefId: widget.chefId,
                                        chefName: widget.chefName,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: [
                      _buildCareerSummary(careerSummary, highlights),
                      const SizedBox(height: 16),
                      _buildExpertiseSection(expertise),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.timeline_rounded, color: gold, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'KARİYER YOLCULUĞU',
                              style: TextStyle(
                                color: gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTimelineCard(
                          year: '2013',
                          title: _profileText(
                              data, 'timeline2013Title', 'Başlangıç'),
                          subtitle: _profileText(
                            data,
                            'timeline2013Subtitle',
                            'Profesyonel mutfak disiplininin ilk adımları.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTimelineCard(
                          year: '2018',
                          title: _profileText(
                              data, 'timeline2018Title', 'Uzmanlaşma'),
                          subtitle: _profileText(
                            data,
                            'timeline2018Subtitle',
                            'Fine dining yaklaşımının güçlendiği dönem.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTimelineCard(
                          year: '2021',
                          title: _profileText(
                              data, 'timeline2021Title', 'Dönüşüm'),
                          subtitle: _profileText(
                            data,
                            'timeline2021Subtitle',
                            'Marka, danışmanlık ve premium servis dilinin kurulduğu dönem.',
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTimelineCard(
                          year: '2024',
                          title: _profileText(
                              data, 'timeline2024Title', 'Premium Vitrin'),
                          subtitle: _profileText(
                            data,
                            'timeline2024Subtitle',
                            'Şef marka ve kariyer yüzeyinin premium seviyeye taşındığı aşama.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome_rounded,
                                color: gold, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'MARKA & BASIN',
                              style: TextStyle(
                                color: gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextShowcase(
                          title: 'Ödüller & Basın',
                          text: _profileText(
                            data,
                            'awardsPressText',
                            'Şefin sektördeki görünürlüğünü ve profesyonel güvenilirliğini artıran ödül, basın ve görünürlük alanı.',
                          ),
                          icon: Icons.emoji_events_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildTextShowcase(
                          title: 'Marka İş Birlikleri',
                          text: _profileText(
                            data,
                            'brandCollaborationsText',
                            'Markalar, kurumsal projeler ve premium iş birlikleri için uygun iş ortaklığı vitrini.',
                          ),
                          icon: Icons.handshake_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildTextShowcase(
                          title: 'Medya Kiti',
                          text: _profileText(
                            data,
                            'mediaKitText',
                            'Basın, marka iş birlikleri ve profesyonel tanıtım dosyaları için medya kiti alanı.',
                          ),
                          icon: Icons.perm_media_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.monetization_on_outlined,
                                color: gold, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'GELİR MODELLERİ',
                              style: TextStyle(
                                color: gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextShowcase(
                          title: 'Catering',
                          text: _profileText(
                            data,
                            'serviceCateringText',
                            'Kurumsal davet ve butik etkinlikler için premium catering deneyimi.',
                          ),
                          icon: Icons.restaurant_menu,
                        ),
                        const SizedBox(height: 12),
                        _buildTextShowcase(
                          title: 'Konuşmacılık',
                          text: _profileText(
                            data,
                            'serviceSpeakingText',
                            'Gastronomi, fine dining ve marka konumlandırması üzerine konuşma içerikleri.',
                          ),
                          icon: Icons.mic_none,
                        ),
                        const SizedBox(height: 12),
                        _buildTextShowcase(
                          title: 'Workshop & Sahne',
                          text: _profileText(
                            data,
                            'workshopStageText',
                            'Workshop ve sahne sunumlarında premium anlatım ve uygulama akışı.',
                          ),
                          icon: Icons.groups,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.school_rounded, color: gold, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'MARKA MODÜLLERİ',
                              style: TextStyle(
                                color: gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Şefin marka gücünü artıran, fiyat algısını yükselten ve doğru müşteriyle bağ kurmasını sağlayan eğitim modülleri.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildLessonSection(),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 28),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BrandInfoChip({
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
        border: Border.all(color: Colors.white.withOpacity(0.12)),
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

class _CTAButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _CTAButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFB300),
              Color(0xFFFFD54F),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableServiceCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ExpandableServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_ExpandableServiceCard> createState() => _ExpandableServiceCardState();
}

class _ExpandableServiceCardState extends State<_ExpandableServiceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _expanded = !_expanded;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: const Color(0xFFFFB300),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _expanded
                            ? widget.subtitle
                            : _shortPreview(widget.subtitle),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFFFFB300),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortPreview(String text) {
    final clean = text.trim();
    if (clean.length <= 95) return clean;
    return '${clean.substring(0, 95).trim()}...';
  }
}
