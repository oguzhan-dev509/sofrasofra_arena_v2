class MockData {
  static const String currentMahalle = "KADIKOY";

  // Shop = Map
  static const List<Map<String, dynamic>> shops = [
    {
      "id": "s1",
      "ad": "Ayşe’nin Mutfağı",
      "mahalle": "KADIKOY",
      "kategori": "EV_YEMEKLER",
      "kapakUrl": "https://picsum.photos/seed/ev1/600/400",
      "aciklama": "Ev yemekleri • Günlük taze • 30-45 dk",
    },
    {
      "id": "s2",
      "ad": "Hatice Abla Lezzetleri",
      "mahalle": "KADIKOY",
      "kategori": "EV_YEMEKLER",
      "kapakUrl": "https://picsum.photos/seed/ev2/600/400",
      "aciklama": "Sarma • Dolma • Zeytinyağlılar",
    },
  ];

  // Product = Map
  static const List<Map<String, dynamic>> products = [
    {
      "id": "p1",
      "shopId": "s1",
      "ad": "Et Sote",
      "fiyat": 220,
      "fotoUrl": "https://picsum.photos/seed/p1/600/400",
      "onayli": true,
    },
    {
      "id": "p2",
      "shopId": "s1",
      "ad": "Tavuk Sote",
      "fiyat": 160,
      "fotoUrl": "https://picsum.photos/seed/p2/600/400",
      "onayli": true,
    },
    {
      "id": "p3",
      "shopId": "s2",
      "ad": "Yaprak Sarma",
      "fiyat": 140,
      "fotoUrl": "https://picsum.photos/seed/p3/600/400",
      "onayli": true,
    },
  ];
}
