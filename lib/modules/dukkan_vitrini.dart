import 'package:flutter/material.dart';
// 🚀 YOLLARIN KONTROLÜ
import 'vitrin_merkezi.dart';
import 'akademi_merkezi.dart';
import 'urun_detay.dart';
// ✨ SEPETİM BAĞLANTISI (Mutlak Yol ile en garantisi)
import 'sepetim.dart';

class DukkanVitrini extends StatelessWidget {
  final String dukkanAdi;
  const DukkanVitrini({super.key, required this.dukkanAdi});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // 🖼️ DÜKKAN ÜST ALANI
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(dukkanAdi,
                  style: const TextStyle(
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              background: Image.network(
                "https://images.unsplash.com/photo-1556910103-1c02745aae4d",
                fit: BoxFit.cover,
                color: Colors.black.withValues(
                    alpha: 0.4), // ✨ Eski withOpacity yerine güncel kullanım
              ),
            ),
          ),

          // 🌉 ARENA KÖPRÜLERİ
          SliverToBoxAdapter(
            child: _modulKopruleri(context),
          ),

          // 🏮 ÜRÜN LİSTESİ
          SliverList(
            delegate: SliverChildListDelegate([
              _bolumBasligi("EV YAPIMI ÖZEL SEÇKİ"),
              _urunKarti(
                  context,
                  "El Açması Mantı",
                  "320 TL",
                  "Geleneksel ev usulü",
                  "https://images.unsplash.com/photo-1534422298391-e4f8c170db76"),
              _urunKarti(context, "Köy Tereyağı", "450 TL", "Taze ve katkısız",
                  "https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d"),
              const SizedBox(height: 50),
            ]),
          ),
        ],
      ),
    );
  }

  // ✨ MODÜLLER ARASI IŞINLANMA KÖPRÜSÜ
  Widget _modulKopruleri(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // ❌ ESKİ: const VitrinMerkezi() -> HATALIYDI
          // ✅ YENİ: VitrinMerkezi() -> DOĞRU
          _kucukKopruButonu(
              context, Icons.auto_awesome, "VİTRİNİM", const VitrinMerkezi()),
          _kucukKopruButonu(
              context, Icons.school, "AKADEMİM", const AkademiMerkezi()),

          // 🔥 İŞTE O HATALI SATIRIN TAMİRİ BURADA:
          // 'const Sepetim()' ifadesindeki 'const' kaldırıldı!
          _kucukKopruButonu(context, Icons.shopping_cart, "SEPETİM", Sepetim()),
        ],
      ),
    );
  }

  Widget _kucukKopruButonu(
      BuildContext context, IconData ikon, String etiket, Widget sayfa) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => sayfa)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ikon, color: const Color(0xFFFFB300), size: 24),
          ),
          const SizedBox(height: 6),
          Text(etiket,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _bolumBasligi(String baslik) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
      child: Text(baslik,
          style: const TextStyle(
              color: Color(0xFFFFB300),
              fontSize: 14,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _urunKarti(BuildContext context, String ad, String fiyat,
      String aciklama, String gorsel) {
    return ListTile(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => UrunDetay(
                  urunAdi: ad, urunFiyat: fiyat, urunGorsel: gorsel))),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(gorsel,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.restaurant, color: Color(0xFFFFB300))),
      ),
      title: Text(ad,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(aciklama,
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: Text(fiyat,
          style: const TextStyle(
              color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
    );
  }
}
