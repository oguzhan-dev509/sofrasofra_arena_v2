import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sef_akademi_dersleri.dart'; // ✅ Yeni oluşturduğumuz sayfa

class SefItibarSayfasi extends StatelessWidget {
  final String sefAdi;
  const SefItibarSayfasi({super.key, required this.sefAdi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // 🛰️ Canlı Veri Dinleyici: Şefin tüm verilerini (müfredat dahil) buradan alıyoruz
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('urunler')
            .where('dukkan', isEqualTo: sefAdi)
            .where('tip', isEqualTo: 'Usta Sefler')
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFB300)));

          // Şefin verilerini paketliyoruz
          final data = snapshot.data!.docs.isNotEmpty
              ? snapshot.data!.docs.first.data() as Map<String, dynamic>
              : <String, dynamic>{};

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildPrestijRozetleri(),
                    const SizedBox(height: 30),
                    _buildVideoKapak(context, data['youtube_url']),
                    const SizedBox(height: 30),

                    // 🍴 01. İMZA MUTFAĞI
                    _buildEliteCategory(
                        context,
                        "01",
                        "SEFIN IMZA MUTFAGI",
                        "Sadece en seckin receteler.",
                        Icons.auto_awesome_outlined,
                        onTap: () => _uyariGoster(context, "Imza Mutfagi")),

                    // 🎓 02. ŞEF AKADEMİSİ (AKTİF!)
                    _buildEliteCategory(
                        context,
                        "02",
                        "SEF AKADEMISI",
                        "Gastronomi teknik egitimleri.",
                        Icons.school_outlined, onTap: () {
                      // 🚀 İşte o meşhur geçiş!
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SefAkademiDersleri(
                            sefAdi: sefAdi,
                            dersler: data['akadem_mufredat'] ?? [],
                          ),
                        ),
                      );
                    }),

                    _buildEliteCategory(
                        context,
                        "03",
                        "OZEL DAVET ARSIVI",
                        "Seckin etkinlik portfolyosu.",
                        Icons.history_edu_outlined,
                        onTap: () => _uyariGoster(context, "Davet Arsivi")),

                    _buildEliteCategory(
                        context,
                        "04",
                        "MUTFAK DANISMANLIGI",
                        "Profesyonel mentorluk.",
                        Icons.business_center_outlined,
                        onTap: () => _uyariGoster(context, "Danismanlik")),

                    _buildEliteCategory(context, "05", "SEFIN MASASI",
                        "Size ozel rezervasyon.", Icons.event_seat_outlined,
                        onTap: () => _uyariGoster(context, "Sefin Masasi")),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI BİLEŞENLERİ ---

  // lib/modules/sef_itibar_sayfasi.dart içindeki ilgili bölümü bununla değiştir:

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(sefAdi.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ✅ Hata Veren Kısım Düzeltildi: Opacity artık çakışmayacak
            Opacity(
              opacity: 0.4,
              child: Image.network(
                  "https://images.unsplash.com/photo-1583394293214-28dea15ee548",
                  fit: BoxFit.cover),
            ),
            const DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black, Colors.transparent]))),
          ],
        ),
      ),
    );
  }

  Widget _buildPrestijRozetleri() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _singleBadge(Icons.verified, "ONAYLI"),
        _singleBadge(Icons.star, "9.8 PUAN"),
        _singleBadge(Icons.timer, "15 YIL"),
      ],
    );
  }

  Widget _singleBadge(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFFB300), size: 18),
        const SizedBox(height: 5),
        Text(text,
            style: const TextStyle(
                color: Colors.white38, fontSize: 8, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildVideoKapak(BuildContext context, String? ytUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          image: const DecorationImage(
              image: NetworkImage(
                  "https://images.unsplash.com/photo-1556910103-1c02745aae4d"),
              fit: BoxFit.cover,
              opacity: 0.5),
        ),
        child: const Center(
            child: Icon(Icons.play_circle_fill,
                color: Color(0xFFFFB300), size: 50)),
      ),
    );
  }

  Widget _buildEliteCategory(BuildContext context, String index, String baslik,
      String alt, IconData ikon,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: ListTile(
            leading: Text(index,
                style: const TextStyle(color: Color(0xFFFFB300), fontSize: 18)),
            title: Text(baslik,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            subtitle: Text(alt,
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontStyle: FontStyle.italic)),
            trailing: Icon(ikon, color: const Color(0xFFFFB300), size: 18),
          ),
        ),
      ),
    );
  }

  void _uyariGoster(BuildContext context, String sayfa) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$sayfa yakinda Arena'da!")));
  }
}
