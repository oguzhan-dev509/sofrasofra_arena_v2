import 'package:flutter/material.dart';
import 'modules/ev_lezzetleri_vitrini.dart';
import 'modules/sef_itibar_sayfasi.dart';
import 'modules/restoranlar_vitrini.dart'; // Eğer bu dosya varsa kalsın
import 'merchant/merchant_dashboard.dart'; // Satıcı paneli için

// main.dart içindeki liste bu şekilde olmalı:
List<Map<String, dynamic>> arenaUrunHavuzu = [
  {
    "ad": "Ayşe Teyze Mantısı",
    "dukkan": "Ayşe Teyze Mutfağı",
    "fiyat": "150",
    "tip": "Ev Lezzetleri",
    "img": "https://images.unsplash.com/photo-1626128665085-47372a396d47",
    "videoUrl": "", // 🚀 YouTube Linki buraya gelecek
    "galeri": [] // 🖼️ 18 fotoğraf buraya dolacak
  },
];
void main() {
  runApp(const SofrasofraZirve());
}

class SofrasofraZirve extends StatelessWidget {
  const SofrasofraZirve({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sofrasofra Arena',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFFFB300),
      ),
      home: const GirisEkrani(),
    );
  }
}

class GirisEkrani extends StatelessWidget {
  const GirisEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("SOFRASOFRA ARENA",
                style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3)),
            const SizedBox(height: 20),

            // 🌍 81 İL SEÇİCİ
            GestureDetector(
              onTap: () => _sehirSeciciGoster(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: const Color(0xFFFFB300).withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Color(0xFFFFB300), size: 18),
                    SizedBox(width: 10),
                    Text("ŞEHİR SEÇİNİZ (81 İL)",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_drop_down, color: Color(0xFFFFB300)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () => _kategoriSeciminiGoster(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
              ),
              child: const Text("ARENA'YA GİRİŞ YAP",
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 30),

            // 🗝️ SATICI GİRİŞİ (Burası eklendi ki dükkan sahipleri girebilsin)
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MerchantDashboard()));
              },
              child: Text(
                "Satıcı Girişi için Tıklayın",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sehirSeciciGoster(BuildContext context) {
    final List<String> sehirler = [
      "K.K.T.C.",
      "ADANA",
      "ADIYAMAN",
      "AFYONKARAHİSAR",
      "AĞRI",
      "AKSARAY",
      "AMASYA",
      "ANKARA",
      "ANTALYA",
      "ARDAHAN",
      "ARTVİN",
      "AYDIN",
      "BALIKESİR",
      "BARTIN",
      "BATMAN",
      "BAYBURT",
      "BİLECİK",
      "BİNGÖL",
      "BİTLİS",
      "BOLU",
      "BURDUR",
      "BURSA",
      "ÇANAKKALE",
      "ÇANKIRI",
      "ÇORUM",
      "DENİZLİ",
      "DİYARBAKIR",
      "DÜZCE",
      "EDİRNE",
      "ELAZIĞ",
      "ERZİNCAN",
      "ERZURUM",
      "ESKİŞEHİR",
      "GAZİANTEP",
      "GİRESUN",
      "GÜMÜŞHANE",
      "HAKKARİ",
      "HATAY",
      "IĞDIR",
      "ISPARTA",
      "İSTANBUL",
      "İZMİR",
      "KAHRAMANMARAŞ",
      "KARABÜK",
      "KARAMAN",
      "KARS",
      "KASTAMONU",
      "KAYSERİ",
      "KİLİS",
      "KIRIKKALE",
      "KIRKLARELİ",
      "KIRŞEHİR",
      "KOCAELİ",
      "KONYA",
      "KÜTAHYA",
      "MALATYA",
      "MANİSA",
      "MARDİN",
      "MERSİN",
      "MUĞLA",
      "MUŞ",
      "NEVŞEHİR",
      "NİĞDE",
      "ORDU",
      "OSMANİYE",
      "RİZE",
      "SAKARYA",
      "SAMSUN",
      "ŞANLIURFA",
      "SİİRT",
      "SİNOP",
      "SİVAS",
      "ŞIRNAK",
      "TEKİRDAĞ",
      "TOKAT",
      "TRABZON",
      "TUNCELİ",
      "UŞAK",
      "VAN",
      "YALOVA",
      "YOZGAT",
      "ZONGULDAK"
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("ARENA HİZMET NOKTALARI (TAM LİSTE)",
                  style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 13)),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: sehirler.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) => ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: Color(0xFFFFB300), size: 18),
                  title: Text(sehirler[index],
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _kategoriSeciminiGoster(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("NEREYE GİDİYORUZ KAPTAN?",
                style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 25),
            _menuButonu(context, "EV LEZZETLERİ", Icons.restaurant_menu,
                const EvLezzetleriVitrini()),
            const Divider(color: Colors.white10),
            _menuButonu(context, "USTA ŞEFLER", Icons.star_border_purple500,
                const SefItibarSayfasi(sefAdi: "Şef Jean-Pierre")),
            const Divider(color: Colors.white10),
            _menuButonu(context, "RESTORANLAR", Icons.storefront,
                const RestoranlarVitrini()),
          ],
        ),
      ),
    );
  }

  Widget _menuButonu(
      BuildContext context, String baslik, IconData ikon, Widget? hedef) {
    return ListTile(
      leading: Icon(ikon, color: const Color(0xFFFFB300)),
      title: Text(baslik,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      trailing:
          const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
      onTap: () {
        if (hedef != null) {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => hedef));
        }
      },
    );
  }
}
