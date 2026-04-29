class SofrasofraOrderFinance {
  final double productTotal;
  final double deliveryFee;
  final double paymentProcessingFee;

  final double producerCommissionRate;
  final double producerCommissionAmount;

  final double courierCommissionRate;
  final double courierCommissionAmount;

  final double producerNetAmount;
  final double courierNetAmount;

  final double platformProducerRevenue;
  final double platformCourierRevenue;
  final double platformTotalRevenue;

  final double customerTotalPayment;

  const SofrasofraOrderFinance({
    required this.productTotal,
    required this.deliveryFee,
    required this.paymentProcessingFee,
    required this.producerCommissionRate,
    required this.producerCommissionAmount,
    required this.courierCommissionRate,
    required this.courierCommissionAmount,
    required this.producerNetAmount,
    required this.courierNetAmount,
    required this.platformProducerRevenue,
    required this.platformCourierRevenue,
    required this.platformTotalRevenue,
    required this.customerTotalPayment,
  });

  Map<String, dynamic> toMap() {
    return {
      'productTotal': productTotal,
      'deliveryFee': deliveryFee,
      'paymentProcessingFee': paymentProcessingFee,
      'producerCommissionRate': producerCommissionRate,
      'producerCommissionAmount': producerCommissionAmount,
      'courierCommissionRate': courierCommissionRate,
      'courierCommissionAmount': courierCommissionAmount,
      'producerNetAmount': producerNetAmount,
      'courierNetAmount': courierNetAmount,
      'platformProducerRevenue': platformProducerRevenue,
      'platformCourierRevenue': platformCourierRevenue,
      'platformTotalRevenue': platformTotalRevenue,
      'customerTotalPayment': customerTotalPayment,
    };
  }

  factory SofrasofraOrderFinance.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return SofrasofraOrderFinance(
      productTotal: toDouble(map['productTotal']),
      deliveryFee: toDouble(map['deliveryFee']),
      paymentProcessingFee: toDouble(map['paymentProcessingFee']),
      producerCommissionRate: toDouble(map['producerCommissionRate']),
      producerCommissionAmount: toDouble(map['producerCommissionAmount']),
      courierCommissionRate: toDouble(map['courierCommissionRate']),
      courierCommissionAmount: toDouble(map['courierCommissionAmount']),
      producerNetAmount: toDouble(map['producerNetAmount']),
      courierNetAmount: toDouble(map['courierNetAmount']),
      platformProducerRevenue: toDouble(map['platformProducerRevenue']),
      platformCourierRevenue: toDouble(map['platformCourierRevenue']),
      platformTotalRevenue: toDouble(map['platformTotalRevenue']),
      customerTotalPayment: toDouble(map['customerTotalPayment']),
    );
  }
}
