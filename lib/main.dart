import 'package:flutter/material.dart';

// Modülleri "Kestirme Yol" ile çağırıyoruz
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
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFFB300), size: 100),
            SizedBox(height: 20),
            Text("ARENA'YA HOŞ GELDİNİZ",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            Text("Dünya Gastronomi Merkezi",
                style: TextStyle(color: Color(0xFFFFB300), fontSize: 14)),
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
        Navigator.pop(context); // Drawer'ı kapat
        Navigator.push(context, MaterialPageRoute(builder: (context) => sayfa));
      },
    );
  }
}
