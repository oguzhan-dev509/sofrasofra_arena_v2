import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/consulting_requests_page.dart';
import 'package:sofrasofra_arena_v2/modules/chef_content_editor_page.dart';

class SefMarkaKariyerSayfasi extends StatelessWidget {
  final String chefName;
  final String chefId;
  final bool isAdmin;

  const SefMarkaKariyerSayfasi({
    super.key,
    required this.chefName,
    this.chefId = 'gmRQ6eKx6WZ0fqDDFytHEgi88RH3',
    this.isAdmin = false,
  });

  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);
  static const Color soft = Color(0xFF1A1A1A);

  static const String _fallbackCareerSummary =
      '15+ yıllık profesyonel mutfak deneyimiyle; Türk ve Osmanlı mutfağını modern tekniklerle yeniden yorumlayan bir şef.\n\n'
      'Restoranlardan butik mutfaklara kadar farklı ölçeklerde:\n'
      '• Menü mühendisliği\n'
      '• Operasyon verimliliği\n'
      '• Karlı mutfak sistemleri\n\n'
      'kurarak işletmelere sürdürülebilir büyüme sağlar.\n\n'
      'Private dining, premium davet ve danışmanlık projelerinde:\n'
      'lezzet, sunum ve deneyimi tek bir bütün olarak ele alır.';

  static const List<String> _fallbackCareerHighlights = [
    '15+ Yıl Deneyim',
    'Fine Dining',
    'Osmanlı & Türk Mutfağı',
    'Menü Kurgusu',
    'Private Dining',
    'Mutfak Danışmanlığı',
    'Operasyon Kurulumu',
  ];

  static const List<String> _fallbackExpertise = [
    'Fine Dining',
    'Tadım Menüsü Kurgusu',
    'Osmanlı Mutfağı',
    'Modern Türk Mutfağı',
    'Tabak Tasarımı',
    'Gastronomi Eğitimi',
    'Mutfak Kurulum',
    'Operasyon Akışı',
    'Kârlı Menü Mühendisliği',
    'Workshop Yönetimi',
    'Private Dining Deneyimi',
    'Etkinlik Menü Tasarımı',
  ];

  static List<String> _stringListOrFallback(
      dynamic value, List<String> fallback) {
    if (value is List) {
      final cleaned = value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (cleaned.isNotEmpty) return cleaned;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('chef_profiles')
          .doc(chefId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};

        final profileName = (data['displayName'] ??
                data['adSoyad'] ??
                data['ad'] ??
                data['chefName'] ??
                chefName)
            .toString();

        final careerSummary =
            (data['careerSummary'] as String?)?.trim().isNotEmpty == true
                ? data['careerSummary'].toString()
                : _fallbackCareerSummary;

        final careerHighlights = _stringListOrFallback(
          data['careerHighlights'],
          _fallbackCareerHighlights,
        );

        final expertise = _stringListOrFallback(
          data['expertise'],
          _fallbackExpertise,
        );

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            iconTheme: const IconThemeData(color: gold),
            title: const Text(
              'ŞEF MARKA & KARİYER',
              style: TextStyle(
                color: gold,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHero(profileName)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    children: [
                      _buildCareerSummary(careerSummary, careerHighlights),
                      const SizedBox(height: 16),
                      _buildExpertiseSection(expertise),
                      const SizedBox(height: 16),
                      _buildCareerTimeline(),
                      const SizedBox(height: 16),
                      _buildAwardsPressSection(),
                      const SizedBox(height: 16),
                      _buildBrandCollaborations(),
                      const SizedBox(height: 16),
                      _buildServicesSection(context),
                      const SizedBox(height: 16),
                      _buildSpeakingWorkshops(),
                      const SizedBox(height: 16),
                      _buildMediaKitSection(),
                      if (isAdmin) ...[
                        const SizedBox(height: 16),
                        _buildAdminActions(context),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHero(String profileName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
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
            color: Colors.white.withOpacity(0.10),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.workspace_premium_rounded, color: gold, size: 18),
              SizedBox(width: 8),
              Text(
                'MARKA KİMLİĞİ & KARİYER VİTRİNİ',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            profileName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Fine Dining & Modern Türk Mutfağı Uzmanı',
            style: TextStyle(
              color: gold,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Şefin profesyonel geçmişini, uzmanlık alanlarını, marka gücünü ve premium hizmetlerini tek merkezde sunan kariyer vitrini.\n\nPrivate dining, danışmanlık, eğitim ve marka iş birlikleriyle gastronomi deneyimini uçtan uca tasarlayan profesyonel yapı.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.2,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _MetricChip(
                icon: Icons.restaurant_menu_rounded,
                label: 'İmza Tabaklar',
                value: '12+',
              ),
              _MetricChip(
                icon: Icons.groups_rounded,
                label: 'Etkinlik / Davet',
                value: '40+',
              ),
              _MetricChip(
                icon: Icons.school_rounded,
                label: 'Eğitim / Workshop',
                value: '25+',
              ),
              _MetricChip(
                icon: Icons.public_rounded,
                label: 'İş Birliği',
                value: '8+',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareerSummary(String summary, List<String> highlights) {
    return _SectionCard(
      title: 'KARİYER ÖZETİ',
      icon: Icons.auto_awesome_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                highlights.map((item) => _InfoBadge(label: item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseSection(List<String> expertise) {
    return _SectionCard(
      title: 'UZMANLIK ALANLARI',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Şefin güçlü olduğu mutfak, teknik ve operasyon alanları:\n\n• Menü mühendisliği ile kârlılık artırma\n• Operasyon akışı ile maliyet ve zaman optimizasyonu\n• Tabak tasarımı ile deneyim kalitesini yükseltme\n• Eğitim ve workshop ile ekip gelişimi sağlama',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: expertise.map((item) => _SkillChip(label: item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerTimeline() {
    return _SectionCard(
      title: 'KARİYER ZAMAN ÇİZGİSİ',
      icon: Icons.timeline_rounded,
      child: Column(
        children: const [
          _TimelineItem(
            year: '2024 - Bugün',
            title: 'Bağımsız Şef Marka Yapılanması',
            subtitle:
                'Private dining, premium davetler, workshop ve danışmanlık projeleriyle kişisel şef markasının büyütülmesi.\n\nGastronomi deneyimini servis, hikâye ve sunumla bütünleştiren özel konseptler geliştirilmesi.',
          ),
          SizedBox(height: 14),
          _TimelineItem(
            year: '2021 - 2024',
            title: 'Executive Chef / Menü Geliştirme',
            subtitle:
                '• Menülerin yeniden kurgulanması\n• Reçete standardizasyonu\n• Operasyonun verimlilik odaklı yeniden yapılandırılması\n• Ekip yönetimi ve mutfak içi eğitim sistemi kurulumu',
          ),
          SizedBox(height: 14),
          _TimelineItem(
            year: '2018 - 2021',
            title: 'Şef Eğitmeni / Workshop Lideri',
            subtitle:
                'Profesyonel mutfak eğitimleri, butik workshop organizasyonları ve marka iş birlikleri kapsamında eğitim programları geliştirme ve uygulama.',
          ),
          SizedBox(height: 14),
          _TimelineItem(
            year: '2013 - 2018',
            title: 'Mutfak Kariyerinin Temel Dönemi',
            subtitle:
                'Yoğun servis temposunda teknik gelişim, mutfak disiplini kazanımı ve farklı mutfak kültürlerinin öğrenilmesi.',
          ),
        ],
      ),
    );
  }

  Widget _buildAwardsPressSection() {
    return _SectionCard(
      title: 'ÖDÜLLER & BASIN',
      icon: Icons.emoji_events_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Şefin sektördeki görünürlüğünü ve profesyonel güvenilirliğini artıran medya ve başarı alanı.\n\n• Gastronomi dergileri ve yayınlar\n• TV programları ve dijital içerikler\n• Özel davet ve marka etkinlikleri\n• Ödül ve takdirler\n\nBu alan, şefin sektördeki konumunu ve referans gücünü yansıtır.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _MiniStatCard(
                  title: 'Basın Görünürlüğü',
                  value: 'Hazır Alan',
                  icon: Icons.article_rounded,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  title: 'Ödül / Takdir',
                  value: 'Hazır Alan',
                  icon: Icons.star_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCollaborations() {
    return _SectionCard(
      title: 'MARKA İŞ BİRLİKLERİ',
      icon: Icons.handshake_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Şefin birlikte çalıştığı ve değer ürettiği iş ortaklıkları:\n\n• Premium restoranlar\n• Gıda ve içecek markaları\n• Etkinlik ve davet organizasyonları\n• Mutfak ekipman üreticileri\n\nHer iş birliği; kalite, deneyim ve marka değerini büyütme hedefiyle gerçekleştirilir.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PartnerPill(label: 'Premium Restoran Partneri'),
              _PartnerPill(label: 'Workshop Partneri'),
              _PartnerPill(label: 'Kurumsal Etkinlik'),
              _PartnerPill(label: 'Mutfak Ekipman Markası'),
              _PartnerPill(label: 'Yöresel Üretici'),
              _PartnerPill(label: 'Gıda Tedarik Partneri'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    return _SectionCard(
      title: 'PREMIUM HİZMETLER',
      icon: Icons.local_fire_department_rounded,
      child: Column(
        children: [
          _ServiceRow(
            title: 'Danışmanlık',
            subtitle:
                'İşletmenizi büyütmek için stratejik mutfak danışmanlığı:\n\n• Menü tasarımı ve fiyat dengesi\n• Mutfak kurulumu ve ekip organizasyonu\n• Operasyon planlama ve süreç yönetimi\n• Marka konumlandırma ve deneyim tasarımı\n\nAmaç: Daha kârlı, daha verimli ve sürdürülebilir bir gastronomi sistemi kurmak.',
            icon: Icons.support_agent_rounded,
            actionLabel: 'Talep Oluştur',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConsultingRequestsPage(
                    chefId: chefId,
                    chefName: chefName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const _ServiceRow(
            title: 'Private Dining',
            subtitle:
                'Kişiye özel menülerle, yüksek deneyim odaklı özel şef hizmeti.\n\nÖzel davetler, butik organizasyonlar ve premium sofralar için uçtan uca deneyim tasarımı.',
            icon: Icons.dinner_dining_rounded,
          ),
          const SizedBox(height: 12),
          const _ServiceRow(
            title: 'Workshop & Eğitim',
            subtitle:
                'Profesyonel mutfak teknikleri, gastronomi eğitimi ve ekip gelişimi için tasarlanmış butik eğitim programları.',
            icon: Icons.school_rounded,
          ),
          const SizedBox(height: 12),
          const _ServiceRow(
            title: 'Kurumsal Davet & Catering',
            subtitle:
                'Etkinlik menüsü tasarımı, servis akışı planlama ve deneyim odaklı premium catering hizmeti.',
            icon: Icons.corporate_fare_rounded,
          ),
          const SizedBox(height: 12),
          const _ServiceRow(
            title: 'Konuşmacılık / Sahne',
            subtitle:
                'Panel, etkinlik ve gastronomi sahnesinde bilgi paylaşımı ve marka temsili.',
            icon: Icons.mic_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakingWorkshops() {
    return _SectionCard(
      title: 'WORKSHOP & SAHNE GÜCÜ',
      icon: Icons.campaign_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Şef sadece mutfakta değil:\n\n• eğitimde\n• sahnede\n• marka yüzü olarak\n\naktif rol alır.\n\nWorkshop, panel ve etkinliklerle bilgi ve deneyimini paylaşarak gastronomi dünyasına katkı sağlar.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _MiniStatCard(
                  title: 'Workshop',
                  value: '25+',
                  icon: Icons.school_rounded,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  title: 'Sahne / Konuşma',
                  value: '12+',
                  icon: Icons.record_voice_over_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaKitSection() {
    return _SectionCard(
      title: 'MEDYA KİTİ & PROFESYONEL DOSYA',
      icon: Icons.folder_special_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profesyonel medya ve iş birliği dosyalarının yer aldığı alan.\n\n• Medya kiti (PDF)\n• Marka iş birliği dosyası\n• Kısa biyografi\n• Yüksek çözünürlüklü görseller\n\nBu alan, kurumsal başvurular ve iş birlikleri için referans noktasıdır.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: const Text(
              'Medya kiti dosyası, iş birliği başvuru butonu, kurumsal tanıtım dökümanı ve referans galerisi buraya bağlanabilir.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return _SectionCard(
      title: 'YÖNETİM AKSİYONLARI',
      icon: Icons.admin_panel_settings_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _AdminActionButton(
                  icon: Icons.edit_rounded,
                  label: 'İçeriği Düzenle',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChefContentEditorPage(
                          chefId: chefId,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AdminActionButton(
                  icon: Icons.add_photo_alternate_rounded,
                  label: 'Medya Ekle',
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AdminActionButton(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Başarı Ekle',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AdminActionButton(
                  icon: Icons.handshake_rounded,
                  label: 'İş Birliği Ekle',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  static const Color gold = Color(0xFFFFB300);
  static const Color card = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Icon(icon, color: gold, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: gold, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label • $value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;

  const _InfoBadge({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip({
    required this.label,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: gold.withOpacity(0.40)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String year;
  final String title;
  final String subtitle;

  const _TimelineItem({
    required this.year,
    required this.title,
    required this.subtitle,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: gold,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 3,
              height: 72,
              color: gold.withOpacity(0.60),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  year,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: gold, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerPill extends StatelessWidget {
  final String label;

  const _PartnerPill({
    required this.label,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: gold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _ServiceRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onTap,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
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
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: gold,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: gold.withOpacity(0.35)),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AdminActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: gold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
