import 'package:flutter/material.dart';

class SefVitrini extends StatelessWidget {
  const SefVitrini({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Arena ruhuna uygun siyah
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          "GASTRONOMİ AKADEMİSİ",
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => _sefKart(index),
      ),
    );
  }

  Widget _sefKart(int index) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 52,
            backgroundColor: Color(0xFFFFB300), // Şefin etrafında altın çerçeve
            child: CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                "https://images.unsplash.com/photo-1583394838336-acd977736f90",
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Şef Arda Türkmen",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            "İtalyan Mutfağı Uzmanı",
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Colors.white10),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "ŞEFİN İMZA TABAKLARI",
              style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ozelTabak(),
                _ozelTabak(),
                _ozelTabak(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozelTabak() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              "https://images.unsplash.com/photo-1473093226795-af9932fe5856",
              height: 100,
              width: 160,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "İmzalı Risotto",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
