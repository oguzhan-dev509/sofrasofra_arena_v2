import 'package:flutter/material.dart';

class OdemeSayfasi extends StatelessWidget {
  const OdemeSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("GÜVENLİ ÖDEME",
            style: TextStyle(
                color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🛡️ GÜVENLİK BİLGİSİ
            _odemeBilgiKarti("TOPLAM TUTAR", "150 TL"),
            const SizedBox(height: 30),

            const Text("ÖDEME YÖNTEMİ SEÇİN",
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // 💳 ÖDEME SEÇENEKLERİ
            _odemeYontemKarti(
                "Online Kredi / Banka Kartı", Icons.credit_card, true),
            _odemeYontemKarti(
                "Kapıda Nakit Ödeme", Icons.payments_outlined, false),
            _odemeYontemKarti(
                "Kapıda Temassız POS", Icons.contactless_outlined, false),

            const Spacer(),

            // 🔒 GÜVENLİK MÜHRÜ
            const Center(
              child: Column(
                children: [
                  Icon(Icons.verified_user, color: Colors.green, size: 20),
                  SizedBox(height: 5),
                  Text("256-Bit SSL Sertifikalı Güvenli Ödeme",
                      style: TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🚀 SİPARİŞİ TAMAMLA BUTONU
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => _odemeOnayDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("SİPARİŞİ ONAYLA",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _odemeBilgiKarti(String baslik, String tutar) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFB300).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(baslik,
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(tutar,
              style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _odemeYontemKarti(String ad, IconData ikon, bool secili) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color: secili ? const Color(0xFFFFB300) : Colors.white10),
      ),
      child: Row(
        children: [
          Icon(ikon, color: secili ? const Color(0xFFFFB300) : Colors.white38),
          const SizedBox(width: 15),
          Text(ad,
              style: TextStyle(
                  color: secili ? Colors.white : Colors.white38,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          if (secili)
            const Icon(Icons.check_circle, color: Color(0xFFFFB300), size: 20),
        ],
      ),
    );
  }

  void _odemeOnayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            const Icon(Icons.check_circle, color: Color(0xFFFFB300), size: 50),
        content: const Text(
            "Siparişiniz Başarıyla Alındı!\nAyşe Hanım hazırlamaya başlıyor.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("ANA SAYFAYA DÖN",
                style: TextStyle(color: Color(0xFFFFB300))),
          ),
        ],
      ),
    );
  }
}
