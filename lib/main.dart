import 'package:flutter/material.dart';

// Modülleri çağırıyoruz
import 'modules/vitrin_merkezi.dart';
import 'modules/akademi_merkezi.dart';
import 'modules/pazar_yeri.dart';
import 'modules/sepetim.dart';

void main() {
  runApp(const SofrasofraArena());
}

class SofrasofraArena extends StatelessWidget {
  const SofrasofraArena({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sofrasofra Arena',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFFB300),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("SOFRASOFRA ARENA",
            style: TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                letterSpacing: 2)),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Center(
                child: Icon(Icons.restaurant_menu,
                    color: Color(0xFFFFB300), size: 80),
              ),
            ),
            _menuElemani(
                context, Icons.store, "VİTRİNİM", const VitrinMerkezi()),
            _menuElemani(
                context, Icons.school, "AKADEMİM", const AkademiMerkezi()),
            _menuElemani(context, Icons.shopping_bag, "PAZAR YERİ",
                const PazarYeri(secilenSehir: "İSTANBUL")),
            _menuElemani(
                context, Icons.shopping_cart, "SEPETİM", const Sepetim()),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text("v2.0 - Arena Edition",
                  style: TextStyle(color: Colors.white24, fontSize: 10)),
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF1A1A1A)],
          ),
        ),
        child: SingleChildScrollView(
          // 🚀 Taşma olmaması için Scroll eklendi
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.auto_awesome,
                  color: Color(0xFFFFB300), size: 80),
              const SizedBox(height: 20),
              const Text("ARENA'YA HOŞ GELDİNİZ",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
              const Text("Dünya Gastronomi Merkezi",
                  style: TextStyle(color: Color(0xFFFFB300), fontSize: 14)),

              const SizedBox(height: 40),

              // 🚀 İŞTE O MUHTEŞEM PORTAL KARTLARI
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 1.2,
                  children: [
                    _portalKarti(context, Icons.auto_awesome, "VİTRİNİM",
                        "Şef Dünyası", const VitrinMerkezi()),
                    _portalKarti(context, Icons.school, "AKADEMİM", "Eğitimler",
                        const AkademiMerkezi()),
                    _portalKarti(context, Icons.storefront, "PAZAR YERİ",
                        "Ürünler", const PazarYeri(secilenSehir: "İSTANBUL")),
                    _portalKarti(context, Icons.shopping_cart, "SEPETİM",
                        "Siparişler", const Sepetim()),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ✨ PORTAL KART WIDGET'I (Doğru yere taşındı)
  Widget _portalKarti(BuildContext context, IconData ikon, String baslik,
      String altBaslik, Widget sayfa) {
    return InkWell(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => sayfa)),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, color: const Color(0xFFFFB300), size: 30),
            const SizedBox(height: 8),
            Text(baslik,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(altBaslik,
                style: const TextStyle(color: Colors.white24, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _menuElemani(
      BuildContext context, IconData ikon, String baslik, Widget sayfa) {
    return ListTile(
      leading: Icon(ikon, color: const Color(0xFFFFB300)),
      title: Text(baslik,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => sayfa));
      },
    );
  }
}
