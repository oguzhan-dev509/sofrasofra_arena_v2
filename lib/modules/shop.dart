class Shop {
  final String id;
  final String ad;
  final String mahalle;
  final String kategori; // EV_YEMEKLER / RESTORAN / USTA_SEF
  final String kapakUrl;
  final String aciklama;

  const Shop({
    required this.id,
    required this.ad,
    required this.mahalle,
    required this.kategori,
    required this.kapakUrl,
    required this.aciklama,
  });
}
