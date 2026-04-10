import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_ders_detay_sayfasi.dart';

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

    final slug = (data['categorySlug'] ?? '').toString().trim().toLowerCase();
    return slug == _selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              border: Border(
                bottom: BorderSide(color: Colors.white.withAlpha(15)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chefName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'chefId: ${widget.chefId}',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Şef akademisine ait ders içerikleri aşağıda listelenir.',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('academy_categories')
                      .where('isActive', isEqualTo: true)
                      .orderBy('order')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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

                    final docs = snapshot.data?.docs ?? [];

                    final chips = <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
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
                          backgroundColor: Colors.white.withAlpha(10),
                          shape: StadiumBorder(
                            side: BorderSide(color: Colors.white.withAlpha(18)),
                          ),
                        ),
                      ),
                    ];

                    for (final doc in docs) {
                      final m = doc.data();
                      final slug = (m['slug'] ?? doc.id).toString();
                      final title = (m['title'] ?? doc.id).toString();

                      chips.add(
                        Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
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
                            backgroundColor: Colors.white.withAlpha(10),
                            shape: StadiumBorder(
                              side: BorderSide(
                                color: Colors.white.withAlpha(18),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('dersler')
                  .where('chefId', isEqualTo: widget.chefId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: gold),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Dersler yüklenemedi: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs
                    .where((doc) => _matchesCategory(doc.data()))
                    .toList()
                  ..sort((a, b) {
                    final ao = (a.data()['order'] as num?)?.toInt() ?? 9999;
                    final bo = (b.data()['order'] as num?)?.toInt() ?? 9999;
                    return ao.compareTo(bo);
                  });

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      _selectedCategory == 'all'
                          ? 'Bu şef için henüz ders içeriği eklenmedi.'
                          : 'Bu kategoride ders bulunamadı.',
                      style: const TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final m = docs[index].data();

                    final String baslik =
                        (m['baslik'] ?? m['title'] ?? 'İsimsiz Eğitim')
                            .toString();
                    final String sure =
                        (m['sure'] ?? 'Süre belirtilmedi').toString();
                    final String aciklama =
                        (m['aciklama'] ?? 'Açıklama eklenmemiş').toString();
                    final bool ucretsiz = m['ucretsiz'] == true;
                    final int videoSayisi =
                        (m['videoCount'] as num?)?.toInt() ?? 0;

                    final String categoryText =
                        (m['category'] ?? m['kategori'] ?? '').toString();

                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
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
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x22FFB300)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: gold.withAlpha(22),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.play_lesson_rounded,
                                    color: gold,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    baslik.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
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
                                        ? Colors.green.withAlpha(24)
                                        : Colors.white.withAlpha(10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: ucretsiz
                                          ? Colors.green.withAlpha(70)
                                          : Colors.white10,
                                    ),
                                  ),
                                  child: Text(
                                    ucretsiz ? 'ÜCRETSİZ' : 'PREMIUM',
                                    style: TextStyle(
                                      color: ucretsiz
                                          ? Colors.greenAccent
                                          : Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            if (categoryText.trim().isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(8),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  categoryText,
                                  style: const TextStyle(
                                    color: gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              aciklama,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  color: gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  sure,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.ondemand_video_rounded,
                                  color: gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$videoSayisi video',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
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
            ),
          ),
        ],
      ),
    );
  }
}
