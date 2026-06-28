import '../models/restaurant_campaign_model.dart';

class RestaurantCampaignCalculationResult {
  const RestaurantCampaignCalculationResult({
    required this.isApplicable,
    required this.discountAmount,
    required this.discountedFoodAmount,
    required this.finalCustomerTotal,
    required this.reason,
  });

  final bool isApplicable;
  final double discountAmount;
  final double discountedFoodAmount;
  final double finalCustomerTotal;
  final String reason;
}

class RestaurantCampaignCalculator {
  const RestaurantCampaignCalculator._();

  static RestaurantCampaignCalculationResult calculate({
    required RestaurantCampaignModel campaign,
    required double foodAmount,
    required double addonsAmount,
    required double deliveryAmount,
    required String deliveryMode,
    required DateTime now,
  }) {
    final safeFoodAmount = _nonNegative(foodAmount);
    final safeAddonsAmount = _nonNegative(addonsAmount);
    final safeDeliveryAmount = _nonNegative(deliveryAmount);

    final campaignBaseAmount = safeFoodAmount + safeAddonsAmount;
    final safeTotalBeforeDiscount = campaignBaseAmount + safeDeliveryAmount;

    if (!campaign.isCurrentlyValidAt(now)) {
      return _notApplicable(
        total: safeTotalBeforeDiscount,
        foodAmount: campaignBaseAmount,
        reason: 'Kampanya şu anda geçerli değil.',
      );
    }

    if (campaign.fundedBy != 'restaurant') {
      return _notApplicable(
        total: safeTotalBeforeDiscount,
        foodAmount: campaignBaseAmount,
        reason: 'Kampanya finansman modeli desteklenmiyor.',
      );
    }

    if (campaignBaseAmount < campaign.minimumOrderAmount) {
      return _notApplicable(
        total: safeTotalBeforeDiscount,
        foodAmount: campaignBaseAmount,
        reason: 'Minimum sepet tutarı karşılanmadı.',
      );
    }

    if (campaign.isPickupOnly && deliveryMode != 'gel_al') {
      return _notApplicable(
        total: safeTotalBeforeDiscount,
        foodAmount: campaignBaseAmount,
        reason: 'Bu kampanya yalnızca Gel-Al siparişlerinde geçerlidir.',
      );
    }

    if (campaign.deliveryModes.isNotEmpty &&
        !campaign.deliveryModes.contains(deliveryMode)) {
      return _notApplicable(
        total: safeTotalBeforeDiscount,
        foodAmount: campaignBaseAmount,
        reason: 'Seçilen teslimat modu kampanyaya uygun değil.',
      );
    }

    double rawDiscount;

    if (campaign.isFixedAmount) {
      rawDiscount = campaign.discountValue;
    } else {
      final safePercentage = campaign.discountValue.clamp(0, 20).toDouble();

      rawDiscount = campaignBaseAmount * safePercentage / 100;
    }

    final maximumDiscount = campaign.maximumDiscountAmount > 0
        ? campaign.maximumDiscountAmount
        : double.infinity;

    final discountAmount = rawDiscount
        .clamp(0, maximumDiscount)
        .clamp(0, campaignBaseAmount)
        .toDouble();

    final discountedFoodAmount = (campaignBaseAmount - discountAmount)
        .clamp(0, double.infinity)
        .toDouble();

    final finalCustomerTotal = discountedFoodAmount + safeDeliveryAmount;

    return RestaurantCampaignCalculationResult(
      isApplicable: discountAmount > 0,
      discountAmount: _roundCurrency(discountAmount),
      discountedFoodAmount: _roundCurrency(discountedFoodAmount),
      finalCustomerTotal: _roundCurrency(finalCustomerTotal),
      reason: discountAmount > 0
          ? 'Kampanya başarıyla uygulandı.'
          : 'Uygulanabilir indirim bulunamadı.',
    );
  }

  static RestaurantCampaignCalculationResult _notApplicable({
    required double total,
    required double foodAmount,
    required String reason,
  }) {
    return RestaurantCampaignCalculationResult(
      isApplicable: false,
      discountAmount: 0,
      discountedFoodAmount: _roundCurrency(foodAmount),
      finalCustomerTotal: _roundCurrency(total),
      reason: reason,
    );
  }

  static double _nonNegative(double value) {
    if (!value.isFinite || value <= 0) return 0;
    return value;
  }

  static double _roundCurrency(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
