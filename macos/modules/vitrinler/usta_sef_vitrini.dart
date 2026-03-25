import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../sef_profili.dart';
import '../sef_akademi_dersleri.dart';

class UstaSefVitrini extends StatefulWidget {
  const UstaSefVitrini({super.key});

  @override
  State<UstaSefVitrini> createState() => _UstaSefVitriniState();
}

class _UstaSefVitriniState extends State<UstaSefVitrini> {
  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Colors.black;
  static const Color _card = Color(0xFF141414);
  static const Color _card2 = Color(0xFF1A1A1A);

  String _selectedCategory = 'Tümü';

  final List<String> _categories = const [
    'Tümü',
    'İmza Mutfağı',
    'Akademi',
    'Özel Davet',
    'Danışmanlık',
    'Şefin Masası',
  ];

  String _safe(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? fallback;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _chefsStream() {
    return FirebaseFirestore.instance
        .collection('urunler')
        .where('tip', isEqualTo: 'Usta Sefler')
        .where('aktifMi', isEqualTo: true)
        .snapshots();
  }

  void _openChefProfile(BuildContext context, String chefId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SefProfili(chefId: chefId),
      ),
    );
  }

  void _openAcademy(BuildContext context, String chefId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SefAkademiDersleri(
          chefId: chefId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final academyPrograms = _academyProgramsFor(context, _selectedCategory);
    final chefTableExperiences = _chefTableExperiencesFor(_selectedCategory);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'USTA ŞEF ARENA',
          style: TextStyle(
            color: _gold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: .8,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeroSection(context),
          ),
          SliverToBoxAdapter(
            child: _buildFiveGateSection(context),
          ),
          SliverToBoxAdapter(
            child: _buildCategoryBar(),
          ),
          const SliverToBoxAdapter(
            child: _SectionTitle(
              title: 'Öne Çıkan Şefler',
              subtitle: 'Arena vitrininin seçkin yüzleri',
            ),
          ),
          SliverToBoxAdapter(
            child: _buildFeaturedChefs(context),
          ),
          const SliverToBoxAdapter(
            child: _SectionTitle(
              title: 'Şef Akademisi',
              subtitle:
                  'Masterclass, gastronomi kütüphanesi ve profesyonel eğitim yolları',
            ),
          ),
          SliverToBoxAdapter(
            child: _buildAcademyPreviewHeader(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _AcademyProgramCard(item: academyPrograms[index]);
                },
                childCount: academyPrograms.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: .92,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: _SectionTitle(
              title: "Chef's Table",
              subtitle:
                  'Şefle doğrudan temas kurulan özel gastronomi deneyimleri',
            ),
          ),
          SliverToBoxAdapter(
            child: _buildChefTableSection(chefTableExperiences),
          ),
          const SliverToBoxAdapter(
            child: _SectionTitle(
              title: 'Kurumsal Çözümler',
              subtitle:
                  'Restoran, otel, kafe ve özel projeler için uzman dokunuş',
            ),
          ),
          SliverToBoxAdapter(
            child: _buildConsultingSection(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chefsStream(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        final int totalChefs = docs.length;
        final int premiumCount =
            docs.where((e) => (e.data()['isPremium'] ?? false) == true).length;

        final Map<String, dynamic>? spotlight =
            docs.isNotEmpty ? docs.first.data() : null;

        final spotlightName = spotlight == null
            ? 'Usta Şef Arena'
            : _safe(
                spotlight['sefAdiSoyadi'] ??
                    spotlight['adSoyad'] ??
                    spotlight['dukkanAdi'],
                fallback: 'Usta Şef Arena',
              );

        final spotlightTitle = spotlight == null
            ? 'Signature Atelier • Chef Academy • Private Dining'
            : _safe(
                spotlight['uzmanlik'] ??
                    spotlight['imzaMutfagi'] ??
                    spotlight['uzmanlikDetayi'],
                fallback: 'Signature Atelier • Chef Academy • Private Dining',
              );

        final spotlightImage = spotlight == null
            ? ''
            : _safe(
                spotlight['kapakFoto'] ??
                    spotlight['coverImage'] ??
                    spotlight['img'],
              );

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0x18FFB300)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'USTA ŞEF ARENA',
                style: TextStyle(
                  color: _gold,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                spotlightTitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroTag(text: '$totalChefs Şef'),
                  _HeroTag(text: '$premiumCount Premium'),
                  const _HeroTag(text: 'Chef Academy'),
                  const _HeroTag(text: 'Chef’s Table'),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white10,
                        image: spotlightImage.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(spotlightImage),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: spotlightImage.isEmpty
                          ? const Icon(
                              Icons.restaurant,
                              color: Colors.white30,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Arena Spotlight',
                            style: TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            spotlightName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Burada yalnızca yemek değil; şef kimliği, itibar, eğitim, deneyim ve profesyonel görünürlük sunulur.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiveGateSection(BuildContext context) {
    final items = [
      _EntryGateItem(
        title: 'Şefin İmza Mutfağı',
        subtitle: 'Özgün tabaklar ve seçkin menüler',
        icon: Icons.restaurant_menu,
        onTap: () {
          setState(() => _selectedCategory = 'İmza Mutfağı');
        },
      ),
      _EntryGateItem(
        title: 'Şef Akademisi',
        subtitle: 'Masterclass ve gastronomi kütüphanesi',
        icon: Icons.school,
        onTap: () => _openAcademy(context, 'chef_mehmet_usta'),
      ),
      _EntryGateItem(
        title: 'Özel Davet & Catering',
        subtitle: 'Geçmiş davetler ve özel organizasyonlar',
        icon: Icons.celebration,
        onTap: () {
          setState(() => _selectedCategory = 'Özel Davet');
        },
      ),
      _EntryGateItem(
        title: 'Mutfak Danışmanlığı',
        subtitle: 'Kurumsal mutfak çözümleri',
        icon: Icons.business_center,
        onTap: () {
          setState(() => _selectedCategory = 'Danışmanlık');
        },
      ),
      _EntryGateItem(
        title: "Şefin Masası",
        subtitle: 'Şefle doğrudan deneyim alanı',
        icon: Icons.table_restaurant,
        onTap: () {
          setState(() => _selectedCategory = 'Şefin Masası');
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _EntryGateCard(item: items[0])),
              const SizedBox(width: 10),
              Expanded(child: _EntryGateCard(item: items[1])),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _EntryGateCard(item: items[2])),
              const SizedBox(width: 10),
              Expanded(child: _EntryGateCard(item: items[3])),
            ],
          ),
          const SizedBox(height: 10),
          _EntryGateCard(item: items[4], fullWidth: true),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = _categories[index];
          final selected = item == _selectedCategory;

          return InkWell(
            onTap: () {
              setState(() => _selectedCategory = item);
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? _gold.withOpacity(0.14) : _card2,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected ? _gold : const Color(0x22FFFFFF),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                item,
                style: TextStyle(
                  color: selected ? _gold : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _categories.length,
      ),
    );
  }

  Widget _buildFeaturedChefs(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _chefsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: CircularProgressIndicator(color: _gold),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          final demoItems = _demoChefs(context);

          return SizedBox(
            height: 340,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              scrollDirection: Axis.horizontal,
              itemCount: demoItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _ChefShowcaseCard(item: demoItems[index]);
              },
            ),
          );
        }

        final items = docs.map((doc) {
          final data = doc.data();

          final academyChefId = _safe(
            data['academyChefId'],
            fallback: doc.id,
          );

          final name = _safe(
            data['sefAdiSoyadi'] ?? data['adSoyad'] ?? data['dukkanAdi'],
            fallback: 'Usta Şef',
          );

          final city = _safe(data['sehir'] ?? data['city']);
          final district = _safe(data['ilce'] ?? data['district']);

          final expertise = _safe(
            data['uzmanlik'] ?? data['imzaMutfagi'] ?? data['uzmanlikDetayi'],
          );

          final rating = _toDouble(data['rating'], fallback: 0);
          final ratingText = rating > 0 ? rating.toStringAsFixed(1) : 'Yeni';

          final premium = (data['isPremium'] ?? false) == true;
          final title = _safe(data['title']);
          final badgeText = premium ? 'Premium Şef' : title;

          final image = _safe(
            data['kapakFoto'] ?? data['coverImage'] ?? data['img'],
          );

          final subtitle = _safe(data['subtitle']);
          final verified = (data['verified'] ?? true) == true;

          final services = data['services'] is Map
              ? Map<String, dynamic>.from(data['services'] as Map)
              : <String, dynamic>{};

          return _ChefCardItem(
            chefId: academyChefId,
            chefName: name,
            cityText: district.isNotEmpty ? '$district / $city' : city,
            expertise: expertise,
            ratingText: ratingText,
            badgeText: badgeText,
            imageUrl: image,
            teslimatText: subtitle,
            verified: verified,
            hasVideo: services['video'] == true,
            hasAcademy: services['academy'] == true,
            hasConsulting: services['consulting'] == true,
            onTap: () => _openChefProfile(context, academyChefId),
          );
        }).toList();

        return SizedBox(
          height: 290,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _ChefShowcaseCard(item: items[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildAcademyPreviewHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hızlandırılmış Eğitim Hatları',
                    style: TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Aşçılık, pastacılık ve işletme eğitimleriyle görünürlükten bilgi sermayesine geç.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _openAcademy(context, 'chef_mehmet_usta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'AKADEMİ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChefTableSection(List<_ExperienceItem> items) {
    return SizedBox(
      height: 185,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return _ExperienceCard(item: items[index]);
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: items.length,
      ),
    );
  }

  Widget _buildConsultingSection() {
    final services = [
      'Restoran danışmanlığı',
      'Menü mühendisliği',
      'Reçete standardizasyonu',
      'Mutfak kurulum',
      'Kafe akış tasarımı',
      'Catering planlama',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33FFB300)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bespoke Consulting',
              style: TextStyle(
                color: _gold,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Şeflerin bilgi birikimini kurumsal çözüme çeviren profesyonel alan.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: services.map((e) => _miniTag(e)).toList(),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: const Text(
                'Bu alan, restoranlar, oteller, butik mutfak projeleri ve gastronomi markaları için yüksek değerli B2B katmandır.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_AcademyProgramItem> _academyProgramsFor(
    BuildContext context,
    String category,
  ) {
    final all = <_AcademyProgramItem>[
      _AcademyProgramItem(
        title: 'Genel Türk Mutfağı',
        subtitle: 'Temel teknikler, reçete mantığı ve mutfak akışı',
        duration: '6 Saat',
        price: '1.200 ₺',
        type: 'Aşçılık',
        onTap: () => _openAcademy(context, 'chef_mehmet_usta'),
      ),
      _AcademyProgramItem(
        title: 'Osmanlı Saray Mutfağı',
        subtitle: 'Klasik saray tabakları ve hikâye temelli sunum',
        duration: '8 Saat',
        price: '1.600 ₺',
        type: 'Aşçılık',
        onTap: () => _openAcademy(context, 'chef_mehmet_usta'),
      ),
      _AcademyProgramItem(
        title: 'Pasta Yapım Teknikleri',
        subtitle: 'Modern pastacılık ve dekor odaklı uygulamalar',
        duration: '5 Saat',
        price: '1.100 ₺',
        type: 'Pastacılık',
        onTap: () => _openAcademy(context, 'chef_mehmet_usta'),
      ),
      _AcademyProgramItem(
        title: 'Çikolata Atölyesi',
        subtitle: 'Temperleme, kaplama ve ganaj temelleri',
        duration: '4 Saat',
        price: '950 ₺',
        type: 'Pastacılık',
        onTap: () => _openAcademy(context, 'chef_mehmet_usta'),
      ),
      _AcademyProgramItem(
        title: 'Kafe İşletme Akışı',
        subtitle: 'Ekipman, satış, menü ve günlük operasyon tasarımı',
        duration: '4 Saat',
        price: '900 ₺',
        type: 'Kafe / İşletme',
        onTap: () => _openAcademy(context, 'chef_mehmet_usta'),
      ),
      _AcademyProgramItem(
        title: 'Maliyet & Reçete Standardı',
        subtitle: 'Karlılık, reçete kontrolü ve süreç optimizasyonu',
        duration: '3 Saat',
        price: '850 ₺',
        type: 'Kafe / İşletme',
        onTap: () => _openAcademy(context, 'chef_mehmet_usta'),
      ),
    ];

    switch (category) {
      case 'Akademi':
        return all;
      case 'İmza Mutfağı':
        return all.where((e) => e.type == 'Aşçılık').toList();
      case 'Danışmanlık':
        return all.where((e) => e.type == 'Kafe / İşletme').toList();
      default:
        return all;
    }
  }

  List<_ExperienceItem> _chefTableExperiencesFor(String category) {
    final all = const [
      _ExperienceItem(
        title: 'Evde Şef Deneyimi',
        subtitle: 'Butik akşam yemeği ve özel menü deneyimi',
      ),
      _ExperienceItem(
        title: 'Tasting Dinner',
        subtitle: 'Tadım menüsü ve hikâyeli sunum gecesi',
      ),
      _ExperienceItem(
        title: 'Özel Masa',
        subtitle: 'Küçük gruplar için seçkin chef’s table akışı',
      ),
      _ExperienceItem(
        title: 'Seasonal Menu Night',
        subtitle: 'Mevsimsel imza menü geceleri',
      ),
    ];

    if (category == 'Şefin Masası' || category == 'Tümü') {
      return all;
    }
    return all.take(2).toList();
  }

  List<_ChefCardItem> _demoChefs(BuildContext context) {
    return [
      _ChefCardItem(
        chefId: 'chef_mehmet_usta',
        chefName: 'Şef Mehmet Usta',
        cityText: 'Kadıköy / İstanbul',
        expertise: 'Türk Mutfağı',
        ratingText: '4.9',
        badgeText: 'Premium Şef',
        imageUrl: '',
        teslimatText: '120 deneyim',
        verified: true,
        hasVideo: true,
        hasAcademy: true,
        hasConsulting: true,
        onTap: () => _openChefProfile(context, 'chef_mehmet_usta'),
      ),
      _ChefCardItem(
        chefId: 'chef_ayse_hanim',
        chefName: 'Şef Ayşe Hanım',
        cityText: 'Beşiktaş / İstanbul',
        expertise: 'Fine Dining & İmza Menü',
        ratingText: '4.8',
        badgeText: 'Verified Chef',
        imageUrl: '',
        teslimatText: '96 deneyim',
        verified: true,
        hasVideo: true,
        hasAcademy: true,
        hasConsulting: true,
        onTap: () => _openChefProfile(context, 'chef_ayse_hanim'),
      ),
      _ChefCardItem(
        chefId: 'chef_elif_nur',
        chefName: 'Şef Elif Nur',
        cityText: 'Çankaya / Ankara',
        expertise: 'Pastacılık & Eğitim',
        ratingText: '5.0',
        badgeText: 'Chef Academy',
        imageUrl: '',
        teslimatText: '84 program',
        verified: true,
        hasVideo: true,
        hasAcademy: true,
        hasConsulting: true,
        onTap: () => _openChefProfile(context, 'chef_elif_nur'),
      ),
    ];
  }

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _gold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _gold.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EntryGateItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _EntryGateItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}

class _EntryGateCard extends StatelessWidget {
  final _EntryGateItem item;
  final bool fullWidth;

  const _EntryGateCard({
    required this.item,
    this.fullWidth = false,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x18FFB300)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _gold.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _gold.withOpacity(0.30)),
              ),
              child: Icon(item.icon, color: _gold, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChefCardItem {
  final String chefId;
  final String chefName;
  final String cityText;
  final String expertise;
  final String ratingText;
  final String badgeText;
  final String imageUrl;
  final String teslimatText;
  final bool verified;
  final bool hasVideo;
  final bool hasAcademy;
  final bool hasConsulting;
  final VoidCallback onTap;

  const _ChefCardItem({
    required this.chefId,
    required this.chefName,
    required this.cityText,
    required this.expertise,
    required this.ratingText,
    required this.badgeText,
    required this.imageUrl,
    required this.teslimatText,
    required this.verified,
    required this.hasVideo,
    required this.hasAcademy,
    required this.hasConsulting,
    required this.onTap,
  });
}

class _ChefShowcaseCard extends StatelessWidget {
  final _ChefCardItem item;

  const _ChefShowcaseCard({required this.item});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF171717);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 230,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x18FFB300)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(22),
                ),
                image: item.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.imageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.white24,
                        size: 34,
                      ),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Text(
                item.chefName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
              child: Text(
                item.cityText,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (item.hasVideo)
                    const _CardBadge(
                      icon: Icons.play_circle_fill,
                      label: 'Video',
                    ),
                  if (item.hasAcademy)
                    const _CardBadge(
                      icon: Icons.school,
                      label: 'Akademi',
                    ),
                  if (item.hasConsulting)
                    const _CardBadge(
                      icon: Icons.business_center,
                      label: 'Danışmanlık',
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _CardTag(text: item.expertise),
                  _CardTag(text: '⭐ ${item.ratingText}'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                item.badgeText,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.teslimatText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: _gold, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTag extends StatelessWidget {
  final String text;

  const _CardTag({required this.text});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CardBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CardBadge({
    required this.icon,
    required this.label,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _gold.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _gold),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: _gold,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcademyProgramItem {
  final String title;
  final String subtitle;
  final String duration;
  final String price;
  final String type;
  final VoidCallback onTap;

  const _AcademyProgramItem({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.price,
    required this.type,
    required this.onTap,
  });
}

class _AcademyProgramCard extends StatelessWidget {
  final _AcademyProgramItem item;

  const _AcademyProgramCard({required this.item});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school, color: _gold),
              ),
              const SizedBox(height: 12),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                item.type,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    item.duration,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.price,
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
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

class _ExperienceItem {
  final String title;
  final String subtitle;

  const _ExperienceItem({
    required this.title,
    required this.subtitle,
  });
}

class _ExperienceCard extends StatelessWidget {
  final _ExperienceItem item;

  const _ExperienceCard({required this.item});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.table_restaurant, color: _gold),
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const Spacer(),
          const Row(
            children: [
              Text(
                'Özel Deneyim',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Spacer(),
              Icon(Icons.arrow_forward, color: _gold, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
