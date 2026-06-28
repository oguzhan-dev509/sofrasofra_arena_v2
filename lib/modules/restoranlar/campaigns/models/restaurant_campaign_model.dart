import 'package:cloud_firestore/cloud_firestore.dart';

enum RestaurantCampaignType {
  percentage,
  fixedAmount,
  pickupOnly,
}

extension RestaurantCampaignTypeX on RestaurantCampaignType {
  String get value {
    switch (this) {
      case RestaurantCampaignType.percentage:
        return 'percentage';
      case RestaurantCampaignType.fixedAmount:
        return 'fixed_amount';
      case RestaurantCampaignType.pickupOnly:
        return 'pickup_only';
    }
  }

  String get label {
    switch (this) {
      case RestaurantCampaignType.percentage:
        return 'Yüzde İndirim';
      case RestaurantCampaignType.fixedAmount:
        return 'Sabit Tutar İndirimi';
      case RestaurantCampaignType.pickupOnly:
        return 'Gel-Al Kampanyası';
    }
  }

  static RestaurantCampaignType fromValue(dynamic rawValue) {
    switch ((rawValue ?? '').toString().trim()) {
      case 'fixed_amount':
        return RestaurantCampaignType.fixedAmount;
      case 'pickup_only':
        return RestaurantCampaignType.pickupOnly;
      case 'percentage':
      default:
        return RestaurantCampaignType.percentage;
    }
  }
}

class RestaurantCampaignModel {
  const RestaurantCampaignModel({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.description,
    required this.type,
    required this.discountValue,
    required this.minimumOrderAmount,
    required this.maximumDiscountAmount,
    required this.startAt,
    required this.endAt,
    required this.isActive,
    required this.dailyLimit,
    required this.totalLimit,
    required this.perUserLimit,
    required this.usedCount,
    required this.neighborhoods,
    required this.deliveryModes,
    required this.productIds,
    required this.fundedBy,
    this.createdAt,
    this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
  });

  final String id;
  final String restaurantId;
  final String title;
  final String description;
  final RestaurantCampaignType type;

  /// Yüzde kampanyasında yüzde değerini,
  /// sabit kampanyada TL tutarını ifade eder.
  final double discountValue;

  final double minimumOrderAmount;
  final double maximumDiscountAmount;
  final DateTime startAt;
  final DateTime endAt;
  final bool isActive;
  final int dailyLimit;
  final int totalLimit;
  final int perUserLimit;
  final int usedCount;
  final List<String> neighborhoods;
  final List<String> deliveryModes;
  final List<String> productIds;

  /// İlk sürümde yalnızca restaurant değeri kullanılacaktır.
  final String fundedBy;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final String updatedBy;

  bool get isPercentage =>
      type == RestaurantCampaignType.percentage ||
      type == RestaurantCampaignType.pickupOnly;

  bool get isFixedAmount => type == RestaurantCampaignType.fixedAmount;

  bool get isPickupOnly => type == RestaurantCampaignType.pickupOnly;

  bool get hasUsageCapacity => totalLimit <= 0 || usedCount < totalLimit;

  bool isCurrentlyValidAt(DateTime now) {
    return isActive &&
        !now.isBefore(startAt) &&
        now.isBefore(endAt) &&
        hasUsageCapacity;
  }

  String get discountLabel {
    if (isFixedAmount) {
      return '${discountValue.toStringAsFixed(0)} TL indirim';
    }

    return '%${discountValue.toStringAsFixed(0)} indirim';
  }

  factory RestaurantCampaignModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return RestaurantCampaignModel.fromMap(
      document.id,
      document.data() ?? const <String, dynamic>{},
    );
  }

  factory RestaurantCampaignModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return RestaurantCampaignModel(
      id: id,
      restaurantId: _safeString(map['restaurantId']),
      title: _safeString(map['title']),
      description: _safeString(map['description']),
      type: RestaurantCampaignTypeX.fromValue(map['campaignType']),
      discountValue: _safeDouble(map['discountValue']),
      minimumOrderAmount: _safeDouble(map['minimumOrderAmount']),
      maximumDiscountAmount: _safeDouble(map['maximumDiscountAmount']),
      startAt: _safeDateTime(map['startAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endAt:
          _safeDateTime(map['endAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      isActive: _safeBool(map['isActive']),
      dailyLimit: _safeInt(map['dailyLimit']),
      totalLimit: _safeInt(map['totalLimit']),
      perUserLimit: _safeInt(
        map['perUserLimit'],
        fallback: 1,
      ),
      usedCount: _safeInt(map['usedCount']),
      neighborhoods: _safeStringList(map['neighborhoods']),
      deliveryModes: _safeStringList(map['deliveryModes']),
      productIds: _safeStringList(map['productIds']),
      fundedBy: _safeString(
        map['fundedBy'],
        fallback: 'restaurant',
      ),
      createdAt: _safeDateTime(map['createdAt']),
      updatedAt: _safeDateTime(map['updatedAt']),
      createdBy: _safeString(map['createdBy']),
      updatedBy: _safeString(map['updatedBy']),
    );
  }

  Map<String, dynamic> toCreateMap({
    required String actorUid,
  }) {
    return {
      'restaurantId': restaurantId,
      'title': title.trim(),
      'description': description.trim(),
      'campaignType': type.value,
      'discountValue': discountValue,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumDiscountAmount': maximumDiscountAmount,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'isActive': isActive,
      'dailyLimit': dailyLimit,
      'totalLimit': totalLimit,
      'perUserLimit': perUserLimit,
      'usedCount': 0,
      'neighborhoods': neighborhoods,
      'deliveryModes': deliveryModes,
      'productIds': productIds,
      'fundedBy': 'restaurant',
      'createdBy': actorUid,
      'updatedBy': actorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    };
  }

  Map<String, dynamic> toUpdateMap({
    required String actorUid,
  }) {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'campaignType': type.value,
      'discountValue': discountValue,
      'minimumOrderAmount': minimumOrderAmount,
      'maximumDiscountAmount': maximumDiscountAmount,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'isActive': isActive,
      'dailyLimit': dailyLimit,
      'totalLimit': totalLimit,
      'perUserLimit': perUserLimit,
      'neighborhoods': neighborhoods,
      'deliveryModes': deliveryModes,
      'productIds': productIds,
      'fundedBy': 'restaurant',
      'updatedBy': actorUid,
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 1,
    };
  }

  RestaurantCampaignModel copyWith({
    String? id,
    String? restaurantId,
    String? title,
    String? description,
    RestaurantCampaignType? type,
    double? discountValue,
    double? minimumOrderAmount,
    double? maximumDiscountAmount,
    DateTime? startAt,
    DateTime? endAt,
    bool? isActive,
    int? dailyLimit,
    int? totalLimit,
    int? perUserLimit,
    int? usedCount,
    List<String>? neighborhoods,
    List<String>? deliveryModes,
    List<String>? productIds,
    String? fundedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) {
    return RestaurantCampaignModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      discountValue: discountValue ?? this.discountValue,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      maximumDiscountAmount:
          maximumDiscountAmount ?? this.maximumDiscountAmount,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isActive: isActive ?? this.isActive,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      totalLimit: totalLimit ?? this.totalLimit,
      perUserLimit: perUserLimit ?? this.perUserLimit,
      usedCount: usedCount ?? this.usedCount,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      deliveryModes: deliveryModes ?? this.deliveryModes,
      productIds: productIds ?? this.productIds,
      fundedBy: fundedBy ?? this.fundedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  static String _safeString(
    dynamic value, {
    String fallback = '',
  }) {
    final result = (value ?? '').toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static double _safeDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  static int _safeInt(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static bool _safeBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final normalized = (value ?? '').toString().toLowerCase().trim();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  static DateTime? _safeDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse((value ?? '').toString());
  }

  static List<String> _safeStringList(dynamic value) {
    if (value is! Iterable) {
      return const <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
