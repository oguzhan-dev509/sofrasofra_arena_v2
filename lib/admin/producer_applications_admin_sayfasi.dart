import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProducerApplicationsAdminSayfasi extends StatelessWidget {
  const ProducerApplicationsAdminSayfasi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _border = Color(0x44FFB300);

  String _typeLabel(String? type) {
    switch (type) {
      case 'ev_lezzetleri':
        return 'Ev Lezzetleri';
      case 'profesyonel_isletme':
        return 'Usta Şef / Restoran';
      default:
        return 'Başvuru';
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'submitted':
        return 'İncelemede';
      case 'reviewed':
        return 'İncelendi';
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'İncelemede';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'reviewed':
        return Colors.orangeAccent;
      case 'submitted':
      default:
        return Colors.amber;
    }
  }

  String _professionalStatusLabel(String? value) {
    switch (value) {
      case 'individual_chef':
        return 'Bireysel / Çalışan Şef';
      case 'freelance_chef':
        return 'Serbest Profesyonel Şef';
      case 'business_owner':
        return 'İşletme Sahibi';
      case 'corporate_catering':
        return 'Catering / Kurumsal';
      default:
        return 'Belirtilmemiş';
    }
  }

  String _businessTypeLabel(String? value) {
    switch (value) {
      case 'usta_sef':
        return 'Usta Şef';
      case 'restoran':
        return 'Restoran';
      case 'kafe':
        return 'Kafe';
      case 'catering':
        return 'Catering';
      default:
        return 'Belirtilmemiş';
    }
  }

  String _yesNo(dynamic value) {
    if (value == true) return 'Evet';
    if (value == false) return 'Hayır';
    return 'Belirtilmemiş';
  }

  String _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  String _stringValue(
    Map<String, dynamic> data,
    String key, {
    String fallback = '',
  }) {
    final value = data[key]?.toString().trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  Map<String, dynamic> _founderEntitlementFields(
    Map<String, dynamic> applicationData,
  ) {
    final isFounder = applicationData['isFounder'] == true;

    final effectivePlan = isFounder
        ? 'founding'
        : _stringValue(
            applicationData,
            'membershipType',
            fallback: 'free',
          );

    return <String, dynamic>{
      'isFounder': isFounder,
      'founderCategory': applicationData['founderCategory'],
      'founderSequence': applicationData['founderSequence'],
      'founderGrantedAt': applicationData['founderGrantedAt'],
      'founderExpiresAt': applicationData['founderExpiresAt'],
      'founderCampaignVersion':
          applicationData['founderCampaignVersion'] ?? 'founder_100_2026_v1',
      'founderBenefitStatus': applicationData['founderBenefitStatus'] ??
          (isFounder ? 'active' : 'not_eligible'),
      'plan': effectivePlan,
      'planType': effectivePlan,
      'membershipType': effectivePlan,
      'packageType': effectivePlan,
      'membershipStatus': applicationData['membershipStatus'] ?? 'active',
      'membershipFeeExempt': applicationData['membershipFeeExempt'] == true,
      'membershipFeeExemptUntil': applicationData['membershipFeeExemptUntil'],
      'commissionExempt': applicationData['commissionExempt'] == true,
      'commissionExemptUntil': applicationData['commissionExemptUntil'],
      'sofrasofraCommissionRate': applicationData['sofrasofraCommissionRate'],
      'sofrasofraCommissionLabel': applicationData['sofrasofraCommissionLabel'],
      'paymentProvider': applicationData['paymentProvider'] ?? 'paytr',
      'paymentFeeRate': applicationData['paymentFeeRate'] ?? 0.0199,
      'paymentFeeLabel':
          applicationData['paymentFeeLabel'] ?? '%1,99 PAYTR İşlem Maliyeti',
    };
  }

  Future<void> _updateStatus({
    required BuildContext context,
    required String docId,
    required String status,
    required Map<String, dynamic> applicationData,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final applicationRef =
          firestore.collection('producer_applications').doc(docId);

      final applicationUpdate = <String, dynamic>{
        'status': status,
        'adminLastAction': status,
        'adminLastActionAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      final type = _stringValue(applicationData, 'type');
      final isletmeTipi = _stringValue(applicationData, 'isletmeTipi');
      final userId = _stringValue(applicationData, 'userId');
      final ownerUid = userId.isNotEmpty ? userId : docId;

      final shouldCreateEvSeller =
          status == 'approved' && type == 'ev_lezzetleri';

      final shouldCreateChefSeller = status == 'approved' &&
          type == 'profesyonel_isletme' &&
          isletmeTipi == 'usta_sef';

      final shouldCreateRestaurant = status == 'approved' &&
          type == 'profesyonel_isletme' &&
          isletmeTipi == 'restoran';

      final founderFields = _founderEntitlementFields(applicationData);

      if (shouldCreateEvSeller) {
        final sellerRef = firestore.collection('sellers').doc(ownerUid);

        final sellerName = _stringValue(
          applicationData,
          'mutfakAdi',
          fallback: _stringValue(
            applicationData,
            'adSoyad',
            fallback: 'Ev Lezzetleri',
          ),
        );

        batch.set(
          sellerRef,
          <String, dynamic>{
            'ownerUid': ownerUid,
            'userId': ownerUid,
            'applicationId': docId,
            'sellerType': 'ev_lezzetleri',
            'type': 'ev_lezzetleri',
            'category': 'Ev Lezzetleri',
            'name': sellerName,
            'title': sellerName,
            'storeName': sellerName,
            'mutfakAdi': sellerName,
            'ownerName': _stringValue(applicationData, 'adSoyad'),
            'phone': _stringValue(applicationData, 'telefon'),
            'city': _stringValue(applicationData, 'sehir'),
            'district': _stringValue(applicationData, 'ilce'),
            'description': _stringValue(applicationData, 'urunBilgisi'),
            'iban': _stringValue(applicationData, 'iban'),
            'isActive': true,
            'isApproved': true,
            'approvalStatus': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
            ...founderFields,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        applicationUpdate['sellerId'] = ownerUid;
        applicationUpdate['sellerType'] = 'ev_lezzetleri';
        applicationUpdate['sellerCreatedAt'] = FieldValue.serverTimestamp();
      }

      if (shouldCreateChefSeller) {
        final sellerRef = firestore.collection('sellers').doc(ownerUid);

        final sellerName = _stringValue(
          applicationData,
          'isletmeAdi',
          fallback: _stringValue(
            applicationData,
            'yetkiliKisi',
            fallback: 'Usta Şef',
          ),
        );

        batch.set(
          sellerRef,
          <String, dynamic>{
            'ownerUid': ownerUid,
            'userId': ownerUid,
            'applicationId': docId,
            'sellerType': 'chef_signature',
            'type': 'usta_sef',
            'category': 'Usta Şefler',
            'isletmeTipi': 'usta_sef',
            'name': sellerName,
            'title': sellerName,
            'storeName': sellerName,
            'isletmeAdi': sellerName,
            'ownerName': _stringValue(applicationData, 'yetkiliKisi'),
            'phone': _stringValue(applicationData, 'telefon'),
            'email': _stringValue(applicationData, 'email'),
            'city': _stringValue(applicationData, 'sehir'),
            'district': _stringValue(applicationData, 'ilce'),
            'description': _stringValue(applicationData, 'aciklama'),
            'iban': _stringValue(applicationData, 'iban'),
            'professionalStatus': applicationData['professionalStatus'],
            'requiresTaxCertificate': applicationData['requiresTaxCertificate'],
            'isActive': true,
            'isApproved': true,
            'approvalStatus': 'approved',
            'approvedAt': FieldValue.serverTimestamp(),
            ...founderFields,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        applicationUpdate['sellerId'] = ownerUid;
        applicationUpdate['sellerType'] = 'chef_signature';
        applicationUpdate['sellerCreatedAt'] = FieldValue.serverTimestamp();
      }

      if (shouldCreateRestaurant) {
        final restaurantId = ownerUid;
        final restaurantRef =
            firestore.collection('restaurants').doc(restaurantId);

        final restaurantName = _stringValue(
          applicationData,
          'isletmeAdi',
          fallback: 'Restoran',
        );

        batch.set(
          restaurantRef,
          <String, dynamic>{
            'ownerUid': ownerUid,
            'userId': ownerUid,
            'applicationId': docId,
            'sellerType': 'restaurant',
            'type': 'restaurant',
            'category': 'Restoran',
            'isletmeTipi': 'restoran',
            'name': restaurantName,
            'restaurantName': restaurantName,
            'title': restaurantName,
            'ownerName': _stringValue(applicationData, 'yetkiliKisi'),
            'phone': _stringValue(applicationData, 'telefon'),
            'email': _stringValue(applicationData, 'email'),
            'city': _stringValue(applicationData, 'sehir'),
            'district': _stringValue(applicationData, 'ilce'),
            'description': _stringValue(applicationData, 'aciklama'),
            'iban': _stringValue(applicationData, 'iban'),
            'professionalStatus': applicationData['professionalStatus'],
            'requiresTaxCertificate': applicationData['requiresTaxCertificate'],
            'cuisine': '',
            'isOpen': false,
            'isActive': true,
            'isApproved': true,
            'approvalStatus': 'approved',
            'isLaunchReady': false,
            'supportsGelAl': true,
            'supportsGotur': true,
            'approvedAt': FieldValue.serverTimestamp(),
            ...founderFields,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        applicationUpdate['restaurantId'] = restaurantId;
        applicationUpdate['sellerType'] = 'restaurant';
        applicationUpdate['restaurantCreatedAt'] = FieldValue.serverTimestamp();
      }

      batch.update(applicationRef, applicationUpdate);
      await batch.commit();

      if (!context.mounted) return;

      String successMessage;

      if (shouldCreateRestaurant) {
        successMessage = 'Başvuru onaylandı ve restoran hesabı oluşturuldu.';
      } else if (shouldCreateEvSeller) {
        successMessage =
            'Başvuru onaylandı ve Ev Lezzetleri satıcı hesabı oluşturuldu.';
      } else if (shouldCreateChefSeller) {
        successMessage =
            'Başvuru onaylandı ve Usta Şef satıcı hesabı oluşturuldu.';
      } else if (status == 'approved') {
        successMessage = 'Başvuru onaylandı.';
      } else {
        successMessage = 'Başvuru reddedildi.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor:
              status == 'approved' ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem başarısız: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Üretici Başvuruları Admin',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('producer_applications')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Başvurular yüklenemedi: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _gold),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz başvuru yok.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();

                final type = data['type']?.toString();
                final rawStatus = data['status']?.toString();
                final isletmeTipi = data['isletmeTipi']?.toString();
                final professionalStatus =
                    data['professionalStatus']?.toString();
                final requiresTaxCertificate = data['requiresTaxCertificate'];
                final tcknVkn = data['tcknVkn'];
                final tcKimlikVergiNo = data['tcKimlikVergiNo'];
                final iban = data['iban'];
                final vergiNotu = data['vergiNotu'];
                final aciklama = data['aciklama'];
                final billingInfo = data['billingInfo'];

                final status = switch (rawStatus) {
                  'pending' => 'submitted',
                  'new' => 'submitted',
                  'waiting' => 'submitted',
                  'approved' => 'approved',
                  'rejected' => 'rejected',
                  'reviewed' => 'reviewed',
                  _ => 'submitted',
                };

                final title = data['mutfakAdi']?.toString().trim().isNotEmpty ==
                        true
                    ? data['mutfakAdi'].toString()
                    : data['isletmeAdi']?.toString().trim().isNotEmpty == true
                        ? data['isletmeAdi'].toString()
                        : data['dukkanAdi']?.toString().trim().isNotEmpty ==
                                true
                            ? data['dukkanAdi'].toString()
                            : data['adSoyad']?.toString().trim().isNotEmpty ==
                                    true
                                ? data['adSoyad'].toString()
                                : data['yetkiliKisi']
                                            ?.toString()
                                            .trim()
                                            .isNotEmpty ==
                                        true
                                    ? data['yetkiliKisi'].toString()
                                    : _typeLabel(type);

                final ownerName = data['adSoyad']
                            ?.toString()
                            .trim()
                            .isNotEmpty ==
                        true
                    ? data['adSoyad'].toString()
                    : data['yetkiliKisi']?.toString().trim().isNotEmpty == true
                        ? data['yetkiliKisi'].toString()
                        : '';

                final phone = data['telefon']?.toString() ?? '';
                final email = data['email']?.toString() ?? '';
                final city = data['sehir']?.toString() ?? '';
                final district = data['ilce']?.toString() ?? '';

                final note =
                    data['uzmanlik']?.toString().trim().isNotEmpty == true
                        ? data['uzmanlik'].toString()
                        : data['aciklama']?.toString() ?? '';

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _statusColor(status),
                              ),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ownerName.isNotEmpty
                            ? '$ownerName • $title (${_typeLabel(type)})'
                            : '$title (${_typeLabel(type)})',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (ownerName.isNotEmpty) _info('Yetkili', ownerName),
                      if (phone.isNotEmpty) _info('Telefon', phone),
                      if (email.isNotEmpty) _info('E-posta', email),
                      if (city.isNotEmpty || district.isNotEmpty)
                        _info(
                          'Konum',
                          '$city ${district.isNotEmpty ? '/ $district' : ''}',
                        ),
                      _info(
                        'Başvuru Türü',
                        _typeLabel(type),
                      ),
                      if (type == 'profesyonel_isletme') ...[
                        _info(
                          'İşletme Tipi',
                          _businessTypeLabel(isletmeTipi),
                        ),
                        _info(
                          'Çalışma / Fatura Durumu',
                          _professionalStatusLabel(
                            professionalStatus,
                          ),
                        ),
                        _info(
                          'Vergi Levhası Gerekli mi?',
                          _yesNo(
                            requiresTaxCertificate,
                          ),
                        ),
                        _info(
                          'T.C. Kimlik / Vergi No',
                          _clean(tcknVkn),
                        ),
                        _info('IBAN', _clean(iban)),
                        _info(
                          'Vergi / Belge Notu',
                          _clean(vergiNotu),
                        ),
                        _info(
                          'Açıklama',
                          _clean(aciklama),
                        ),
                      ],
                      if (type == 'ev_lezzetleri') ...[
                        _info(
                          'T.C. Kimlik / Vergi No',
                          _clean(tcKimlikVergiNo),
                        ),
                        _info('IBAN', _clean(iban)),
                        _info(
                          'Fatura Bilgileri',
                          _clean(billingInfo),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (note.isNotEmpty) _info('Not', note),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: status == 'approved'
                                  ? null
                                  : () {
                                      _updateStatus(
                                        context: context,
                                        docId: doc.id,
                                        status: 'approved',
                                        applicationData: data,
                                      );
                                    },
                              icon: const Icon(
                                Icons.check_rounded,
                              ),
                              label: const Text('Onayla'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.black,
                                disabledBackgroundColor:
                                    Colors.greenAccent.withOpacity(0.25),
                                disabledForegroundColor: Colors.black45,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: status == 'rejected'
                                  ? null
                                  : () {
                                      _updateStatus(
                                        context: context,
                                        docId: doc.id,
                                        status: 'rejected',
                                        applicationData: data,
                                      );
                                    },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                              label: const Text('Reddet'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                ),
                                disabledForegroundColor:
                                    Colors.redAccent.withOpacity(0.35),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
