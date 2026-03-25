import 'package:cloud_firestore/cloud_firestore.dart';

class KuryeModel {
  final String id;
  final String ad;
  final String telefon;
  final String sehir;
  final String ilce;
  final double? lat;
  final double? lng;
  final bool isActive;
  final bool isAvailable;
  final String vehicleType;
  final int activeOrderCount;
  final double rating;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  KuryeModel({
    required this.id,
    required this.ad,
    required this.telefon,
    required this.sehir,
    required this.ilce,
    this.lat,
    this.lng,
    required this.isActive,
    required this.isAvailable,
    required this.vehicleType,
    required this.activeOrderCount,
    required this.rating,
    this.createdAt,
    this.updatedAt,
  });

  factory KuryeModel.fromMap(Map<String, dynamic> data, String id) {
    return KuryeModel(
      id: id,
      ad: (data['ad'] ?? '').toString().trim(),
      telefon: (data['telefon'] ?? '').toString().trim(),
      sehir: (data['sehir'] ?? '').toString().trim(),
      ilce: (data['ilce'] ?? '').toString().trim(),
      lat: _toDouble(data['lat']),
      lng: _toDouble(data['lng']),
      isActive: (data['isActive'] ?? true) == true,
      isAvailable: (data['isAvailable'] ?? false) == true,
      vehicleType: (data['vehicleType'] ?? '').toString().trim(),
      activeOrderCount: _toInt(data['activeOrderCount']),
      rating: _toDouble(data['rating']) ?? 5.0,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  factory KuryeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return KuryeModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'ad': ad,
      'telefon': telefon,
      'sehir': sehir,
      'ilce': ilce,
      'lat': lat,
      'lng': lng,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'vehicleType': vehicleType,
      'activeOrderCount': activeOrderCount,
      'rating': rating,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get hasLocation => lat != null && lng != null;

  bool get canTakeOrder => isActive && isAvailable;

  String get displayName => ad.isNotEmpty ? ad : 'İsimsiz Kurye';

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
