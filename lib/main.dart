import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';

// Modüller
import 'package:sofrasofra_arena_v2/modules/ev_lezzetleri_vitrini.dart';
import 'modules/sef_vitrini.dart';
import 'modules/restoranlar_vitrini.dart';

// Satıcı + test
import 'merchant/merchant_dashboard.dart';
import 'firestore_test_page.dart';

final ValueNotifier<String?> selectedSehir = ValueNotifier<String?>(null);
final ValueNotifier<String?> selectedIlce = ValueNotifier<String?>(null);

// (Opsiyonel) Local havuz
List<Map<String, dynamic>> arenaUrunHavuzu = [
  {
    "dukkanAdi": "Ayşe Hanım Mutfağı",
    "urunler": [
      {"ad": "Mantı", "tarif": "Bol kıymalı...", "fiyat": 150, "img": "..."},
      {"ad": "Sarma", "tarif": "Zeytinyağlı...", "fiyat": 120, "img": "..."},
    ]
  }
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    final cred = await FirebaseAuth.instance.signInAnonymously();
    // ignore: avoid_print
    print("✅ ANON LOGIN UID: ${cred.user?.uid}");
  } catch (e) {
    // ignore: avoid_print
    print("❌ Anonymous login failed: $e");
  }

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

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  String? _secilenSehir;
  String? _secilenIlce;

  Map<String, List<String>> _ilcelerMap = {};
  bool _lokasyonYukleniyor = true;

  @override
  void initState() {
    super.initState();
    _ilceleriYukle();
  }

  Future<void> _ilceleriYukle() async {
    try {
      final raw = await rootBundle.loadString('assets/ilceler.json');
      final Map<String, dynamic> decoded = jsonDecode(raw);

      final map = decoded.map((k, v) {
        final list = (v as List).map((e) => e.toString()).toList();
        return MapEntry(k.toString(), list);
      });

      if (!mounted) return;
      setState(() {
        _ilcelerMap = Map<String, List<String>>.from(map);
        _lokasyonYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _lokasyonYukleniyor = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ İlçe listesi yüklenemedi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sehir = _secilenSehir;
    final ilce = _secilenIlce;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "SOFRASOFRA ARENA",
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 20),

              // Şehir seçici
              _secimKutusu(
                icon: Icons.location_on,
                text: sehir ?? "ŞEHİR SEÇİNİZ",
                onTap: () async {
                  final secim = await _sehirSeciciGoster(context);
                  if (secim != null) {
                    setState(() {
                      _secilenSehir = secim;
                      _secilenIlce = null; // şehir değişince ilçe sıfır
                    });
                  }
                },
              ),

              const SizedBox(height: 14),

              // İlçe seçici
              _secimKutusu(
                icon: Icons.location_city,
                text: _lokasyonYukleniyor
                    ? "İLÇELER YÜKLENİYOR..."
                    : (ilce ?? "İLÇE SEÇİNİZ"),
                onTap: () async {
                  if (sehir == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Önce şehir seçiniz.")),
                    );
                    return;
                  }
                  if (_lokasyonYukleniyor) return;

                  final secim = await _ilceSeciciGoster(context, sehir);
                  if (secim != null) {
                    setState(() => _secilenIlce = secim);
                    selectedSehir.value = _secilenSehir;
                    selectedIlce.value = _secilenIlce;
                  }
                },
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  if (_secilenSehir == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Lütfen önce şehir seçiniz.")),
                    );
                    return;
                  }
                  if (_secilenIlce == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lütfen ilçe seçiniz.")),
                    );
                    return;
                  }
                  _kategoriSeciminiGoster(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  "ARENA'YA GİRİŞ YAP",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 26),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MerchantDashboard()),
                  );
                },
                child: Text(
                  "Satıcı Girişi için Tıklayın",
                  style: TextStyle(
                    color: Colors.white.withAlpha(150),
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FirestoreTestPage()),
                  );
                },
                child: Text(
                  "Firestore Test",
                  style: TextStyle(
                    color: Colors.white.withAlpha(120),
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secimKutusu({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFFFB300).withAlpha(128)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFFB300), size: 18),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_drop_down, color: Color(0xFFFFB300)),
          ],
        ),
      ),
    );
  }

  Future<String?> _sehirSeciciGoster(BuildContext context) async {
    final List<String> sehirler = [
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
      "KILIS",
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
      "SİİRT",
      "SİNOP",
      "SİVAS",
      "ŞANLIURFA",
      "ŞIRNAK",
      "TEKİRDAĞ",
      "TOKAT",
      "TRABZON",
      "TUNCELİ",
      "UŞAK",
      "VAN",
      "YALOVA",
      "YOZGAT",
      "ZONGULDAK",
      "K.K.T.C."
    ];

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "HİZMET NOKTALARI (81 İL + K.K.T.C.)",
                style: TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: sehirler.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    sehirler[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white12,
                    size: 16,
                  ),
                  onTap: () => Navigator.pop(context, sehirler[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _ilceSeciciGoster(BuildContext context, String sehir) async {
    // JSON anahtarı "ISTANBUL" vs UI "İSTANBUL" olabiliyor.
    final key = sehir.replaceAll("İ", "I");

    final ilceler = _ilcelerMap[key] ?? _ilcelerMap[sehir] ?? <String>[];

    if (ilceler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$sehir için ilçe listesi bulunamadı.")),
      );
      return null;
    }

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "$sehir • İLÇE SEÇ",
                style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: ilceler.length,
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    ilceler[index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white12,
                    size: 16,
                  ),
                  onTap: () => Navigator.pop(context, ilceler[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _kategoriSeciminiGoster(BuildContext context) {
    final sehir = _secilenSehir!;
    final ilce = _secilenIlce!;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "KATEGORİ SEÇİN",
              style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            // 1. Ev Lezzetleri
            _menuButonu(
              context,
              "EV LEZZETLERİ",
              Icons.restaurant_menu,
              _tryBuildEvLezzetleri(sehir, ilce),
            ),
            const Divider(color: Colors.white10),

            // 2. Restoranlar
            _menuButonu(
              context,
              "RESTORANLAR",
              Icons.storefront,
              _tryBuildRestoranlar(sehir, ilce),
            ),
            const Divider(color: Colors.white10),

            // 3. Usta Şefler
            _menuButonu(
              context,
              "USTA ŞEFLER",
              Icons.star_border_purple500,
              _tryBuildSefler(sehir, ilce),
            ),
          ],
        ),
      ),
    );
  }

  // Sayfaların parametreli/parametresiz olma ihtimaline karşı güvenli builderlar:
  Widget _tryBuildEvLezzetleri(String sehir, String ilce) {
    try {
      // Eğer sen sayfayı parametreli yaptıysan bunu kullan:
      // ignore: unnecessary_cast
      return (const EvLezzetleriVitriniPage() as Widget);
    } catch (_) {
      // Parametresiz eski hali varsa:
      return const EvLezzetleriVitriniPage();
    }
  }

  Widget _tryBuildRestoranlar(String sehir, String ilce) {
    try {
      return (const RestoranlarVitrini() as Widget);
    } catch (_) {
      return const RestoranlarVitrini();
    }
  }

  Widget _tryBuildSefler(String sehir, String ilce) {
    try {
      return (const SefVitrini() as Widget);
    } catch (_) {
      return const SefVitrini();
    }
  }

  Widget _menuButonu(
    BuildContext context,
    String baslik,
    IconData ikon,
    Widget hedef,
  ) {
    return ListTile(
      leading: Icon(ikon, color: const Color(0xFFFFB300)),
      title: Text(
        baslik,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => hedef));
      },
    );
  }
}
