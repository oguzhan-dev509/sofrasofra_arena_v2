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
  }) {
    final safeProductTotal = _nonNegative(productTotal);
    final safeDeliveryFee = _nonNegative(deliveryFee);

    final producerRate = producerCommissionRateOverride ??
        SofrasofraPricingModel.getProducerCommission(
          userType: userType,
          plan: plan,
        );

    final courierRate = courierCommissionRateOverride ??
        SofrasofraPricingModel.getCourierCommissionRate();

    final paymentRate =
        paymentFeeRateOverride ?? SofrasofraPricingModel.getPaymentFeeRate();

    final customerTotalPayment = safeProductTotal + safeDeliveryFee;

    final paymentProcessingFee = _roundMoney(
      customerTotalPayment * paymentRate,
    );

    final producerCommissionAmount = _roundMoney(
      safeProductTotal * producerRate,
    );

    final courierCommissionAmount = _roundMoney(
      safeDeliveryFee * courierRate,
    );

    final producerNetAmount = _roundMoney(
      safeProductTotal - producerCommissionAmount - paymentProcessingFee,
    );

    final courierNetAmount = _roundMoney(
      safeDeliveryFee - courierCommissionAmount,
    );

    final platformProducerRevenue = producerCommissionAmount;
    final platformCourierRevenue = courierCommissionAmount;

    final platformTotalRevenue = _roundMoney(
      platformProducerRevenue + platformCourierRevenue,
    );

    return SofrasofraOrderFinance(
      productTotal: _roundMoney(safeProductTotal),
      deliveryFee: _roundMoney(safeDeliveryFee),
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
      customerTotalPayment: _roundMoney(customerTotalPayment),
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
