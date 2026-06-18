enum UserType {
  evLezzetleri,
  ustaSef,
  restoran,
}

enum PlanType {
  free,
  pro,
  premium,
  founding, // ilk 200
}

class SofrasofraPricingModel {
  static double getProducerCommission({
    required UserType userType,
    required PlanType plan,
  }) {
    if (plan == PlanType.founding) return 0.0;

    switch (userType) {
      case UserType.evLezzetleri:
        switch (plan) {
          case PlanType.free:
            return 0.08;
          case PlanType.pro:
            return 0.05;
          case PlanType.premium:
            return 0.02;
          default:
            return 0.0;
        }

      case UserType.ustaSef:
        switch (plan) {
          case PlanType.free:
            return 0.11;
          case PlanType.pro:
            return 0.07;
          case PlanType.premium:
            return 0.04;
          default:
            return 0.0;
        }

      case UserType.restoran:
        switch (plan) {
          case PlanType.free:
            return 0.10;
          case PlanType.pro:
            return 0.07;
          case PlanType.premium:
            return 0.04;
          default:
            return 0.0;
        }
    }
  }

  static double getCourierCommissionRate() {
    return 0.06; // %6 sabit başlangıç
  }

  static double getPaymentFeeRate() {
    return 0.0199; // PAYTR %1,99
  }

  static double getPaymentFixedFee() {
    return 0.0; // PAYTR ek sabit işlem ücreti yok
  }
}
