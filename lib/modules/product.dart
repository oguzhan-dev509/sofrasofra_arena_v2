class Product {
  final String id;
  final String shopId;
  final String ad;
  final int fiyat; // TL
  final String fotoUrl;
  final bool onayli;

  const Product({
    required this.id,
    required this.shopId,
    required this.ad,
    required this.fiyat,
    required this.fotoUrl,
    required this.onayli,
  });
}
