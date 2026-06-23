class MembershipPlan {
  final String type;
  final int maxPhotoCount;
  final int maxVideoCount;
  final bool canUseYoutube;
  final bool canBeFeatured;
  final bool canJoinMainShowcase;
  final String featuredScope;
  final int priorityScore;
  final String badgeType;

  const MembershipPlan({
    required this.type,
    required this.maxPhotoCount,
    required this.maxVideoCount,
    required this.canUseYoutube,
    required this.canBeFeatured,
    required this.canJoinMainShowcase,
    required this.featuredScope,
    required this.priorityScore,
    required this.badgeType,
  });

  Map<String, dynamic> toMap() {
    return {
      'membershipType': type,
      'maxPhotoCount': maxPhotoCount,
      'maxVideoCount': maxVideoCount,
      'canUseYoutube': canUseYoutube,
      'canBeFeatured': canBeFeatured,
      'canJoinMainShowcase': canJoinMainShowcase,
      'featuredScope': featuredScope,
      'priorityScore': priorityScore,
      'badgeType': badgeType,
    };
  }
}

class MembershipPlanService {
  static const MembershipPlan free = MembershipPlan(
    type: 'free',
    maxPhotoCount: 3,
    maxVideoCount: 0,
    canUseYoutube: false,
    canBeFeatured: false,
    canJoinMainShowcase: false,
    featuredScope: 'none',
    priorityScore: 0,
    badgeType: 'none',
  );

  static const MembershipPlan founding = MembershipPlan(
    type: 'founding',
    maxPhotoCount: 3,
    maxVideoCount: 0,
    canUseYoutube: false,
    canBeFeatured: false,
    canJoinMainShowcase: false,
    featuredScope: 'none',
    priorityScore: 10,
    badgeType: 'founding',
  );

  static const MembershipPlan pro = MembershipPlan(
    type: 'pro',
    maxPhotoCount: 8,
    maxVideoCount: 1,
    canUseYoutube: true,
    canBeFeatured: true,
    canJoinMainShowcase: false,
    featuredScope: 'district',
    priorityScore: 20,
    badgeType: 'trusted',
  );

  static const MembershipPlan premium = MembershipPlan(
    type: 'premium',
    maxPhotoCount: 15,
    maxVideoCount: 2,
    canUseYoutube: true,
    canBeFeatured: true,
    canJoinMainShowcase: true,
    featuredScope: 'city',
    priorityScore: 50,
    badgeType: 'premium',
  );

  static MembershipPlan fromType(String? type) {
    switch ((type ?? 'free').toLowerCase().trim()) {
      case 'founding':
      case 'kurucu':
        return founding;
      case 'pro':
        return pro;
      case 'premium':
        return premium;
      default:
        return free;
    }
  }

  static MembershipPlan fromSellerData(
    Map<String, dynamic>? sellerData,
  ) {
    final type = (sellerData?['membershipType'] ??
            sellerData?['packageType'] ??
            sellerData?['plan'] ??
            'free')
        .toString();

    return fromType(type);
  }

  static Map<String, dynamic> buildSellerPlanFields(
    String? membershipType,
  ) {
    final plan = fromType(membershipType);

    return {
      ...plan.toMap(),
      'membershipStatus': 'active',
    };
  }

  static bool canAddMorePhotos({
    required int currentPhotoCount,
    required String? membershipType,
  }) {
    final plan = fromType(membershipType);
    return currentPhotoCount < plan.maxPhotoCount;
  }

  static bool canAddMoreVideos({
    required int currentVideoCount,
    required String? membershipType,
  }) {
    final plan = fromType(membershipType);
    return currentVideoCount < plan.maxVideoCount;
  }

  static String badgeLabel(String? badgeType) {
    switch ((badgeType ?? 'none').toLowerCase().trim()) {
      case 'founding':
        return 'Kurucu Üye';
      case 'trusted':
        return 'Güvenilir Mutfak';
      case 'premium':
        return 'Premium Ev Lezzeti';
      default:
        return '';
    }
  }

  static String planDisplayName(String? membershipType) {
    switch ((membershipType ?? 'free').toLowerCase().trim()) {
      case 'founding':
      case 'kurucu':
        return 'Kurucu Üye';
      case 'pro':
        return 'Pro';
      case 'premium':
        return 'Premium';
      default:
        return 'Ücretsiz';
    }
  }
}
