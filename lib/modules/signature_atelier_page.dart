import 'package:flutter/material.dart';

class SignatureAtelierPage extends StatelessWidget {
  const SignatureAtelierPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("İMZA MUTFAĞI",
            style: TextStyle(
                color: Color(0xFFFFB300),
                letterSpacing: 3,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          _buildSignatureDish(
            context,
            title: "ALTIN KROKANTLI DENİZ LEVREĞİ",
            philosophy: "Okyanusun derinliklerinden, safran dokunuşuyla.",
            price: "1.250 ₺",
            imageUrl:
                "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2",
          ),
          _buildSignatureDish(
            context,
            title: "TRÜF MANTARLI DANA YANAĞI",
            philosophy: "48 saatlik ağır ateşin sabır dolu meyvesi.",
            price: "1.850 ₺",
            imageUrl:
                "https://images.unsplash.com/photo-1544025162-d76694265947",
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureDish(BuildContext context,
      {required String title,
      required String philosophy,
      required String price,
      required String imageUrl}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🖼️ ÜSTÜN GÖRSEL DENEYİM
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                image: DecorationImage(
                    image: NetworkImage(imageUrl), fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 15),
          // ✍️ ŞIK METİN BLOĞU
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 5),
                      Text(philosophy,
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                Text(price,
                    style: const TextStyle(
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Divider(color: Colors.white10),
          )
        ],
      ),
    );
  }
}
