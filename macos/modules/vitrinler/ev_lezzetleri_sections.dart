import 'package:cloud_firestore/cloud_firestore.dart';

double readEvLezzetleriPrice(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }
  return 0;
}

String safeEvLezzetleriText(dynamic value) {
  return (value ?? '').toString().trim();
}

Timestamp? asEvLezzetleriTimestamp(dynamic value) {
  if (value is Timestamp) return value;
  return null;
}

double readEvLezzetleriScore(Map<String, dynamic> data) {
  final rawScore = data['score'];
  if (rawScore is num) return rawScore.toDouble();

  final puan = data['puan'];
  final yorumSayisi = data['yorumSayisi'];
  final bugunPisiyor = data['bugunPisiyor'] == true;

  double score = 0;

  if (puan is num) {
    score += puan.toDouble() * 20;
  }

  if (yorumSayisi is num) {
    score += yorumSayisi.toDouble().clamp(0, 200);
  }

  if (bugunPisiyor) {
    score += 25;
  }

  return score;
}

String mapEvLezzetleriCategory(Map<String, dynamic> data) {
  final raw = safeEvLezzetleriText(
    data['kategori'] ?? data['altKategori'] ?? data['category'],
  ).toLowerCase();

  if (raw.contains('tatlı') ||
      raw.contains('cikolata') ||
      raw.contains('çikolata')) {
    return 'Çikolata & Tatlılar';
  }

  if (raw.contains('sut') ||
      raw.contains('süt') ||
      raw.contains('peynir') ||
      raw.contains('yoğurt') ||
      raw.contains('yogurt')) {
    return 'Süt Ürünleri';
  }

  if (raw.contains('turşu') ||
      raw.contains('tursu') ||
      raw.contains('reçel') ||
      raw.contains('recel') ||
      raw.contains('kahvalt')) {
    return 'Turşu & Diğerleri';
  }

  if (raw.contains('baharat') ||
      raw.contains('sos') ||
      raw.contains('salça') ||
      raw.contains('salca')) {
    return 'Baharat & Soslar';
  }

  return 'Ev Yemekleri';
}

bool matchesEvLezzetleriCategory(
  Map<String, dynamic> data,
  String selectedCategory,
) {
  if (selectedCategory == 'Tümü') return true;
  return mapEvLezzetleriCategory(data) == selectedCategory;
}

bool isEvLezzetleriBugunPisiyor(Map<String, dynamic> data) {
  return data['bugunPisiyor'] == true;
}
