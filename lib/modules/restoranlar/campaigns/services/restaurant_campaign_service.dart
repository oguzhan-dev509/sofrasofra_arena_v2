import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/restaurant_campaign_model.dart';

class RestaurantCampaignService {
  RestaurantCampaignService._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> campaignsRef(
    String restaurantId,
  ) {
    final safeRestaurantId = restaurantId.trim();

    if (safeRestaurantId.isEmpty) {
      throw ArgumentError.value(
        restaurantId,
        'restaurantId',
        'Restoran kimliği boş olamaz.',
      );
    }

    return _firestore
        .collection('restaurants')
        .doc(safeRestaurantId)
        .collection('campaigns');
  }

  static Stream<List<RestaurantCampaignModel>> streamCampaigns(
    String restaurantId,
  ) {
    return campaignsRef(restaurantId).snapshots().map(
      (snapshot) {
        final campaigns = snapshot.docs
            .where(
              (document) => document.data()['isArchived'] != true,
            )
            .map(RestaurantCampaignModel.fromDocument)
            .toList();

        campaigns.sort(
          (a, b) => b.startAt.compareTo(a.startAt),
        );

        return List<RestaurantCampaignModel>.unmodifiable(
          campaigns,
        );
      },
    );
  }

  static Stream<List<RestaurantCampaignModel>> streamActiveCampaigns(
    String restaurantId,
  ) {
    return campaignsRef(restaurantId).snapshots().map(
      (snapshot) {
        final campaigns = snapshot.docs
            .where((document) {
              final data = document.data();

              return data['isArchived'] != true && data['isActive'] == true;
            })
            .map(RestaurantCampaignModel.fromDocument)
            .toList();

        campaigns.sort(
          (a, b) => a.startAt.compareTo(b.startAt),
        );

        return List<RestaurantCampaignModel>.unmodifiable(
          campaigns,
        );
      },
    );
  }

  static Future<RestaurantCampaignModel?> getCampaign({
    required String restaurantId,
    required String campaignId,
  }) async {
    final safeCampaignId = campaignId.trim();

    if (safeCampaignId.isEmpty) {
      return null;
    }

    final snapshot = await campaignsRef(restaurantId).doc(safeCampaignId).get();

    if (!snapshot.exists || snapshot.data()?['isArchived'] == true) {
      return null;
    }

    return RestaurantCampaignModel.fromDocument(snapshot);
  }

  static Future<String> createCampaign({
    required RestaurantCampaignModel campaign,
  }) async {
    _validateCampaign(campaign);

    final actorUid = _requireCurrentUserUid();
    final document = campaignsRef(campaign.restaurantId).doc();

    final data =
        campaign.copyWith(id: document.id).toCreateMap(actorUid: actorUid);

    data['isArchived'] = false;

    await document.set(data);

    return document.id;
  }

  static Future<void> updateCampaign({
    required RestaurantCampaignModel campaign,
  }) async {
    _validateCampaign(campaign);

    final campaignId = campaign.id.trim();

    if (campaignId.isEmpty) {
      throw ArgumentError(
        'Güncellenecek kampanya kimliği boş olamaz.',
      );
    }

    final actorUid = _requireCurrentUserUid();
    final document = campaignsRef(campaign.restaurantId).doc(campaignId);

    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw StateError('Kampanya kaydı bulunamadı.');
    }

    if (snapshot.data()?['isArchived'] == true) {
      throw StateError(
        'Arşivlenmiş kampanya güncellenemez.',
      );
    }

    await document.update(
      campaign.toUpdateMap(actorUid: actorUid),
    );
  }

  static Future<void> setCampaignActive({
    required String restaurantId,
    required String campaignId,
    required bool isActive,
  }) async {
    final safeCampaignId = campaignId.trim();

    if (safeCampaignId.isEmpty) {
      throw ArgumentError(
        'Kampanya kimliği boş olamaz.',
      );
    }

    final actorUid = _requireCurrentUserUid();
    final document = campaignsRef(restaurantId).doc(safeCampaignId);

    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw StateError('Kampanya kaydı bulunamadı.');
    }

    if (snapshot.data()?['isArchived'] == true) {
      throw StateError(
        'Arşivlenmiş kampanya etkinleştirilemez.',
      );
    }

    await document.update({
      'isActive': isActive,
      'updatedBy': actorUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> archiveCampaign({
    required String restaurantId,
    required String campaignId,
  }) async {
    final safeCampaignId = campaignId.trim();

    if (safeCampaignId.isEmpty) {
      throw ArgumentError(
        'Arşivlenecek kampanya kimliği boş olamaz.',
      );
    }

    final actorUid = _requireCurrentUserUid();
    final document = campaignsRef(restaurantId).doc(safeCampaignId);

    final snapshot = await document.get();

    if (!snapshot.exists) {
      throw StateError('Kampanya kaydı bulunamadı.');
    }

    await document.update({
      'isActive': false,
      'isArchived': true,
      'archivedBy': actorUid,
      'archivedAt': FieldValue.serverTimestamp(),
      'updatedBy': actorUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static void _validateCampaign(
    RestaurantCampaignModel campaign,
  ) {
    if (campaign.restaurantId.trim().isEmpty) {
      throw ArgumentError(
        'Restoran kimliği boş olamaz.',
      );
    }

    if (campaign.title.trim().isEmpty) {
      throw ArgumentError(
        'Kampanya başlığı boş olamaz.',
      );
    }

    if (!campaign.discountValue.isFinite || campaign.discountValue <= 0) {
      throw ArgumentError(
        'İndirim değeri sıfırdan büyük olmalıdır.',
      );
    }

    if (!campaign.isFixedAmount && campaign.discountValue > 20) {
      throw ArgumentError(
        'Yüzde indirim en fazla %20 olabilir.',
      );
    }

    if (!campaign.minimumOrderAmount.isFinite ||
        campaign.minimumOrderAmount < 0) {
      throw ArgumentError(
        'Minimum sepet tutarı geçersiz.',
      );
    }

    if (!campaign.maximumDiscountAmount.isFinite ||
        campaign.maximumDiscountAmount < 0) {
      throw ArgumentError(
        'Maksimum indirim tutarı geçersiz.',
      );
    }

    if (!campaign.endAt.isAfter(campaign.startAt)) {
      throw ArgumentError(
        'Kampanya bitiş tarihi başlangıç tarihinden sonra olmalıdır.',
      );
    }

    if (campaign.dailyLimit < 0 ||
        campaign.totalLimit < 0 ||
        campaign.perUserLimit < 1) {
      throw ArgumentError(
        'Kampanya kullanım limitleri geçersiz.',
      );
    }

    if (campaign.totalLimit > 0 && campaign.dailyLimit > campaign.totalLimit) {
      throw ArgumentError(
        'Günlük kullanım limiti toplam limitten büyük olamaz.',
      );
    }

    if (campaign.totalLimit > 0 &&
        campaign.perUserLimit > campaign.totalLimit) {
      throw ArgumentError(
        'Kullanıcı limiti toplam kampanya limitinden büyük olamaz.',
      );
    }

    if (campaign.isPickupOnly &&
        campaign.deliveryModes.isNotEmpty &&
        !campaign.deliveryModes.contains('gel_al')) {
      throw ArgumentError(
        'Gel-Al kampanyası yalnızca gel_al teslimat modunda kullanılabilir.',
      );
    }

    if (campaign.fundedBy != 'restaurant') {
      throw ArgumentError(
        'İlk sürümde kampanya finansörü yalnızca restoran olabilir.',
      );
    }
  }

  static String _requireCurrentUserUid() {
    final user = _auth.currentUser;
    final uid = user?.uid.trim() ?? '';

    if (uid.isEmpty) {
      throw StateError(
        'Kampanya işlemi için oturum açılması gerekir.',
      );
    }

    if (user?.isAnonymous == true) {
      throw StateError(
        'Anonim müşteri hesabı kampanya yönetemez.',
      );
    }

    return uid;
  }
}
