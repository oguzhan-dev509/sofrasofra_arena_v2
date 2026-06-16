import 'package:sofrasofra_arena_v2/finance/sofrasofra_order_finance.dart';
import 'package:sofrasofra_arena_v2/finance/sofrasofra_pricing_model.dart';

class SofrasofraFinanceCalculator {
  const SofrasofraFinanceCalculator._();

  static SofrasofraOrderFinance calculate({
    required double productTotal,
    required double deliveryFee,
    required UserType userType,
    required PlanType plan,
    double? producerCommissionRateOverride,
    double? courierCommissionRateOverride,
    double? paymentFeeRateOverride,
    double? paymentFixedFeeOverride,
    // Nihai fiyat senaryoları:
    // Ev Galeri / Şef Galeri gibi fiyat zaten teslimat veya işlem bedelini içeriyorsa
    // müşteriye tekrar ücret bindirilmez.
    bool deliveryIncludedInPrice = false,
    bool feeIncludedInPrice = false,

    // true: ödeme işlem ücreti müşteri toplamına eklenir.
    // false: işlem ücreti platform/üretici finansında kalır, müşteriye ayrıca yansımaz.
    bool chargePaymentFeeToCustomer = false,
  }) {
    final safeProductTotal = _roundMoney(_nonNegative(productTotal));
    final rawDeliveryFee = _roundMoney(_nonNegative(deliveryFee));

    final effectiveDeliveryFee = deliveryIncludedInPrice ? 0.0 : rawDeliveryFee;

    final producerRate = producerCommissionRateOverride ??
        SofrasofraPricingModel.getProducerCommission(
          userType: userType,
          plan: plan,
        );

    final courierRate = courierCommissionRateOverride ??
        SofrasofraPricingModel.getCourierCommissionRate();

    final paymentRate =
        paymentFeeRateOverride ?? SofrasofraPricingModel.getPaymentFeeRate();

    final paymentFixedFee =
        paymentFixedFeeOverride ?? SofrasofraPricingModel.getPaymentFixedFee();

    final paymentBase = _roundMoney(safeProductTotal + effectiveDeliveryFee);

    final calculatedPaymentFee = _roundMoney(
      (paymentBase * paymentRate) + paymentFixedFee,
    );

    final paymentProcessingFee =
        feeIncludedInPrice ? calculatedPaymentFee : calculatedPaymentFee;

    final producerCommissionAmount = _roundMoney(
      safeProductTotal * producerRate,
    );

    final courierCommissionAmount = _roundMoney(
      effectiveDeliveryFee * courierRate,
    );

    final customerTotalPayment = _roundMoney(
      paymentBase + (chargePaymentFeeToCustomer ? paymentProcessingFee : 0.0),
    );

    final producerNetAmount = _roundMoney(
      safeProductTotal - producerCommissionAmount - paymentProcessingFee,
    );

    final courierNetAmount = _roundMoney(
      effectiveDeliveryFee - courierCommissionAmount,
    );

    final platformProducerRevenue = producerCommissionAmount;
    final platformCourierRevenue = courierCommissionAmount;

    final platformTotalRevenue = _roundMoney(
      platformProducerRevenue + platformCourierRevenue,
    );

    return SofrasofraOrderFinance(
      productTotal: safeProductTotal,
      deliveryFee: effectiveDeliveryFee,
      paymentProcessingFee: paymentProcessingFee,
      producerCommissionRate: producerRate,
      producerCommissionAmount: producerCommissionAmount,
      courierCommissionRate: courierRate,
      courierCommissionAmount: courierCommissionAmount,
      producerNetAmount: producerNetAmount,
      courierNetAmount: courierNetAmount,
      platformProducerRevenue: platformProducerRevenue,
      platformCourierRevenue: platformCourierRevenue,
      platformTotalRevenue: platformTotalRevenue,
      customerTotalPayment: customerTotalPayment,
    );
  }

  static double _nonNegative(double value) {
    if (value.isNaN || value.isInfinite || value < 0) return 0.0;
    return value;
  }

  static double _roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
