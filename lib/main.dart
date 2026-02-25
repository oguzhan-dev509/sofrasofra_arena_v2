import 'package:flutter/material.dart';
import 'modules/ev_lezzetleri_vitrini.dart';
import 'modules/sef_vitrini.dart';
import 'modules/restoranlar_vitrini.dart';
import 'merchant/merchant_dashboard.dart';

// main.dart içindeki global değişkenimiz
List<Map<String, dynamic>> arenaUrunHavuzu = [
  {
    "dukkanAdi": "Ayşe Hanım Mutfağı",
    "urunler": [
      {"ad": "Mantı", "tarif": "Bol kıymalı...", "fiyat": 150, "img": "..."},
      {"ad": "Sarma", "tarif": "Zeytinyağlı...", "fiyat": 120, "img": "..."},
      // ... 18'e kadar gider
    ]
  }
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

            // 🌍 TAM LİSTE ŞEHİR SEÇİCİ
            GestureDetector(
              onTap: () => _sehirSeciciGoster(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: const Color(0xFFFFB300).withAlpha(128)),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Color(0xFFFFB300), size: 18),
                    SizedBox(width: 10),
                    Text("ŞEHİR SEÇİNİZ",
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
                    color: Colors.white.withAlpha(150),
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
    // 🏛️ ARENA RESMİ ŞEHİR LİSTESİ (81 İL + K.K.T.C.)
    final List<String> sehirler = [
      "ADANA", "ADIYAMAN", "AFYONKARAHİSAR", "AĞRI", "AMASYA", "ANKARA",
      "ANTALYA", "ARTVİN", "AYDIN", "BALIKESİR",
      "BİLECİK", "BİNGÖL", "BİTLİS", "BOLU", "BURDUR", "BURSA", "ÇANAKKALE",
      "ÇANKIRI", "ÇORUM", "DENİZLİ",
      "DİYARBAKIR", "EDİRNE", "ELAZIĞ", "ERZİNCAN", "ERZURUM", "ESKİŞEHİR",
      "GAZİANTEP", "GİRESUN", "GÜMÜŞHANE", "HAKKARİ",
      "HATAY", "ISPARTA", "MERSİN", "İSTANBUL", "İZMİR", "KARS", "KASTAMONU",
      "KAYSERİ", "KIRKLARELİ", "KIRŞEHİR",
      "KOCAELİ", "KONYA", "KÜTAHYA", "MALATYA", "MANİSA", "KAHRAMANMARAŞ",
      "MARDİN", "MUĞLA", "MUŞ", "NEVŞEHİR",
      "NİĞDE", "ORDU", "RIZE", "SAKARYA", "SAMSUN", "SİİRT", "SİNOP", "SİVAS",
      "TEKİRDAĞ", "TOKAT",
      "TRABZON", "TUNCELİ", "ŞANLIURFA", "UŞAK", "VAN", "YOZGAT", "ZONGULDAK",
      "AKSARAY", "BAYBURT", "KARAMAN",
      "KIRIKKALE", "BATMAN", "ŞIRNAK", "BARTIN", "ARDAHAN", "IĞDIR", "YALOVA",
      "KARABÜK", "KİLİS", "OSMANİYE", "DÜZCE",
      "K.K.T.C." // 🌟 Yavru Vatan Mühürlendi!
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
              child: Text("HİZMET NOKTALARI (81 İL + K.K.T.C.)",
                  style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2)),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: sehirler.length,
                separatorBuilder: (context, index) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) => ListTile(
                  title: Text(sehirler[index],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right,
                      color: Colors.white12, size: 16),
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kategori seçimi ve butonlar aynı kalıyor...
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
            const Text("KATEGORİ SEÇİN",
                style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),
            _menuButonu(context, "EV LEZZETLERİ", Icons.restaurant_menu,
                const EvLezzetleriVitrini()),
            const Divider(color: Colors.white10),
            _menuButonu(context, "USTA ŞEFLER", Icons.star_border_purple500,
                const SefVitrini()),
            const Divider(color: Colors.white10),
            _menuButonu(context, "RESTORANLAR", Icons.storefront,
                const RestoranlarVitrini()),
          ],
        ),
      ),
    );
  }

  Widget _menuButonu(
      BuildContext context, String baslik, IconData ikon, Widget hedef) {
    return ListTile(
      leading: Icon(ikon, color: const Color(0xFFFFB300)),
      title: Text(baslik,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => hedef));
      },
    );
  }
}
