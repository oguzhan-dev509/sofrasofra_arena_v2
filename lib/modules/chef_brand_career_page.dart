import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_ders_detay_sayfasi.dart';

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
        raw.contains('kişisel marka') ||
        raw.contains('kisisel marka');
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

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: gold),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
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
          ..sort((a, b) =>
              _lessonOrder(a.data()).compareTo(_lessonOrder(b.data())));

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
            ...docs.map((doc) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildLessonCard(context, doc),
                )),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
                  bottom: BorderSide(color: Colors.white.withOpacity(0.10)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.workspace_premium_rounded,
                          color: gold, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'ŞEF MARKA & KARİYER',
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
                    widget.chefName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kişisel marka, premium konumlandırma, fiyatlandırma ve müşteri yönetimi ile şef görünürlüğünü sürdürülebilir gelir katmanına dönüştürün.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPill('Kişisel Marka'),
                      _buildPill('Fiyatlandırma'),
                      _buildPill('Müşteri Yönetimi'),
                      _buildPill('Premium Konumlandırma'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  _buildServiceCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Kişisel Marka',
                    subtitle:
                        'Şef kimliğini netleştirme, güven veren vitrin dili oluşturma ve doğru müşteri algısı kurma.',
                  ),
                  const SizedBox(height: 12),
                  _buildServiceCard(
                    icon: Icons.sell_rounded,
                    title: 'Premium Fiyatlandırma',
                    subtitle:
                        'Algı, değer ve hizmet seviyesine göre fiyat yükseltme, premium müşteri çekme ve gelir optimizasyonu.',
                  ),
                  const SizedBox(height: 12),
                  _buildServiceCard(
                    icon: Icons.people_alt_rounded,
                    title: 'Müşteri Yönetimi',
                    subtitle:
                        'Doğru müşteriyle çalışma, sadakat oluşturma ve premium deneyim akışı tasarlama.',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
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
                          'MARKA MODÜLLERİ',
                          style: TextStyle(
                            color: gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Şefin marka gücünü artıran, fiyat algısını yükselten ve doğru müşteriyle bağ kurmasını sağlayan eğitim modülleri.',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildLessonSection(),
                  const SizedBox(height: 24),
                ],
              ),
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
