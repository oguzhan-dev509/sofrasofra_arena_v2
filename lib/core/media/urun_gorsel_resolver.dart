class UrunGorselResolver {
  const UrunGorselResolver._();

  static List<String> resolveList(Map<String, dynamic> data) {
    final rawImages = data['images'];

    final List<String> images = (rawImages is List)
        ? rawImages
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    if (images.isNotEmpty) return images;

    final fallbackCandidates = <String>[
      (data['img'] ?? '').toString().trim(),
      (data['imageUrl'] ?? '').toString().trim(),
      (data['imgUrl'] ?? '').toString().trim(),
      (data['resim'] ?? '').toString().trim(),
      (data['foto'] ?? '').toString().trim(),
      (data['gorselUrl'] ?? '').toString().trim(),
    ].where((e) => e.isNotEmpty).toList();

    return fallbackCandidates;
  }

  static String resolveCover(Map<String, dynamic> data) {
    final images = resolveList(data);
    return images.isNotEmpty ? images.first : '';
  }
}
