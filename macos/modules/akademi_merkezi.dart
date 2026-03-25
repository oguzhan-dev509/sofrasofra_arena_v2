import 'package:flutter/material.dart';

class AkademiMerkeziSayfasi extends StatelessWidget {
  const AkademiMerkeziSayfasi({super.key});

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Colors.black;
  static const Color _card = Color(0xFF151515);
  static const Color _card2 = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          "ŞEF AKADEMİ MERKEZİ",
          style: TextStyle(
            color: _gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: .8,
          ),
        ),
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: CustomScrollView(
        slivers: [
          // 🔥 HERO
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0x33FFB300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Chef Academy",
                    style: TextStyle(
                      color: _gold,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Masterclass • Gastronomy Library • Professional Tracks",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🧩 KATEGORİLER
          SliverToBoxAdapter(
            child: _CategoryStrip(
              categories: const [
                "Aşçılık",
                "Pastacılık",
                "Kafe / İşletme",
              ],
            ),
          ),

          // 🍳 AŞÇILIK
          SliverToBoxAdapter(
            child: _SectionTitle(title: "Aşçılık Eğitimi"),
          ),
          SliverToBoxAdapter(
            child: _ChipRow(items: const [
              "Genel Türk Mutfağı",
              "Yöresel Mutfaklar",
              "Osmanlı Saray Mutfağı",
              "Dünya Mutfakları",
              "Pişirme Teknikleri",
              "Hijyen & Sağlık",
              "Tabak Tasarımı",
              "Müşteri Servisi",
            ]),
          ),
          _ProgramGrid(
            items: _demoPrograms("Aşçılık"),
          ),

          // 🍰 PASTACILIK
          SliverToBoxAdapter(
            child: _SectionTitle(title: "Pastacılık Eğitimi"),
          ),
          SliverToBoxAdapter(
            child: _ChipRow(items: const [
              "Pasta Teknikleri",
              "Çikolata",
              "Kek & Kurabiye",
              "Sütlü Tatlılar",
              "Börek Çeşitleri",
            ]),
          ),
          _ProgramGrid(
            items: _demoPrograms("Pastacılık"),
          ),

          // ☕ KAFE / İŞLETME
          SliverToBoxAdapter(
            child: _SectionTitle(title: "Kafe / İşletme"),
          ),
          SliverToBoxAdapter(
            child: _ChipRow(items: const [
              "Maliyet Hesaplama",
              "Ekipmanlar",
              "Menü & Reçete",
              "Satış",
              "İş Akışı",
            ]),
          ),
          _ProgramGrid(
            items: _demoPrograms("Kafe"),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}

// ====== WIDGETS ======

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          const Icon(Icons.school, color: _gold, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: _gold,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final List<String> categories;
  const _CategoryStrip({required this.categories});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF151515),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0x33FFB300)),
            ),
            alignment: Alignment.center,
            child: Text(
              categories[i],
              style: const TextStyle(
                color: _gold,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> items;
  const _ChipRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            alignment: Alignment.center,
            child: Text(
              items[i],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgramGrid extends StatelessWidget {
  final List<_ProgramItem> items;
  const _ProgramGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _ProgramCard(item: items[i]),
          childCount: items.length,
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: .95,
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final _ProgramItem item;
  const _ProgramCard({required this.item});

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.title} açılacak (detay sayfası)')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x22FFB300)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // görsel placeholder
            Container(
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFF202020),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_outline,
                    color: Colors.white54, size: 28),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white54, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    item.duration,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  const Spacer(),
                  Text(
                    item.price,
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== DEMO DATA (sonra Firestore bağlanır) ======

class _ProgramItem {
  final String title;
  final String subtitle;
  final String duration;
  final String price;

  const _ProgramItem({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.price,
  });
}

List<_ProgramItem> _demoPrograms(String type) {
  if (type == "Aşçılık") {
    return const [
      _ProgramItem(
        title: "Osmanlı Saray Mutfağı",
        subtitle: "Klasik tarifler ve sunum teknikleri",
        duration: "6 saat",
        price: "1.200 ₺",
      ),
      _ProgramItem(
        title: "Dünya Mutfakları",
        subtitle: "İtalyan, Fransız ve Asya",
        duration: "8 saat",
        price: "1.600 ₺",
      ),
    ];
  }
  if (type == "Pastacılık") {
    return const [
      _ProgramItem(
        title: "Çikolata Atölyesi",
        subtitle: "Temperleme ve ganaj teknikleri",
        duration: "4 saat",
        price: "900 ₺",
      ),
      _ProgramItem(
        title: "Pasta Tasarımı",
        subtitle: "Modern dekor ve kaplama",
        duration: "5 saat",
        price: "1.100 ₺",
      ),
    ];
  }
  return const [
    _ProgramItem(
      title: "Kafe Kurulumu",
      subtitle: "Maliyet, ekipman, akış",
      duration: "3 saat",
      price: "800 ₺",
    ),
    _ProgramItem(
      title: "Menü & Reçete",
      subtitle: "Standartizasyon ve kârlılık",
      duration: "4 saat",
      price: "950 ₺",
    ),
  ];
}
