import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'kurye_service.dart';

class OrderItemInput {
  final String urunId;
  final String urunAdi;
  final String saticiId;
  final int adet;
  final double fiyat;
  final String? gorselUrl;
  final String? kategori;
  final Map<String, dynamic>? extra;

  const OrderItemInput({
    required this.urunId,
    required this.urunAdi,
    required this.saticiId,
    required this.adet,
    required this.fiyat,
    this.gorselUrl,
    this.kategori,
    this.extra,
  });

  double get toplam => _roundMoneyStatic(fiyat * adet);

  Map<String, dynamic> toMap() {
    return {
      'urunId': urunId,
      'urunAdi': urunAdi,
      'saticiId': saticiId,
      'adet': adet,
      'fiyat': fiyat,
      'toplam': toplam,
      if (gorselUrl != null) 'gorselUrl': gorselUrl,
      if (kategori != null) 'kategori': kategori,
    };
  }

  static OrderItemInput fromDynamic(dynamic raw) {
    if (raw is OrderItemInput) return raw;

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);

      final String urunId =
          _readString(map, ['urunId', 'id', 'productId'], fallback: '');

      final String urunAdi = _readString(
        map,
        ['urunAdi', 'ad', 'isim', 'title', 'yemekAdi', 'name'],
        fallback: 'Ürün',
      );

      final String saticiId = _readString(
        map,
        ['saticiId', 'sellerId', 'dukkanId', 'merchantId'],
        fallback: '',
      );

      final int adet = _readInt(
        map,
        ['adet', 'quantity', 'qty'],
        fallback: 1,
      );

      final double fiyat = _readDouble(
        map,
        ['fiyat', 'price', 'birimFiyat', 'unitPrice'],
        fallback: 0,
      );

      final String? gorselUrl =
          _readNullableString(map, ['gorselUrl', 'img', 'imageUrl', 'foto']);

      final String? kategori =
          _readNullableString(map, ['kategori', 'category']);

      return OrderItemInput(
        urunId: urunId.isEmpty ? 'unknown_product' : urunId,
        urunAdi: urunAdi,
        saticiId: saticiId.isEmpty ? 'unknown_seller' : saticiId,
        adet: adet <= 0 ? 1 : adet,
        fiyat: fiyat < 0 ? 0 : fiyat,
        gorselUrl: gorselUrl,
        kategori: kategori,
        extra: map,
      );
    }

    throw Exception('Desteklenmeyen item formatı: $raw');
  }

  static String _readString(
    Map<String, dynamic> map,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  static String? _readNullableString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  static int _readInt(
    Map<String, dynamic> map,
    List<String> keys, {
    required int fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  static double _readDouble(
    Map<String, dynamic> map,
    List<String> keys, {
    required double fallback,
  }) {
    for (final key in keys) {
      final value = map[key];
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is num) return value.toDouble();
      if (value is String) {
        final normalized = value.replaceAll(',', '.').trim();
        final parsed = double.tryParse(normalized);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  static double _roundMoneyStatic(num value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

class SellerOrderGroup {
  final String saticiId;
  final List<OrderItemInput> items;

  const SellerOrderGroup({
    required this.saticiId,
    required this.items,
  });

  double get araToplam {
    return items.fold<double>(
        0, (toplamDeger, item) => toplamDeger + item.toplam);
  }
}

class OrderService {
  OrderService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Şimdilik mevcut dosyayı kırmamak için isimleri koruyoruz.
  // İstersen sonra bunları siparisler / saticiSiparisleri olarak standardize ederiz.
  static const String _ordersCollection = 'orders';
  static const String _sellerOrdersCollection = 'sellerOrders';
  static const String _countersCollection = 'counters';
  static const String _siparisNoDoc = 'siparisNo';
  static const String _kuryeAtamaKuyruguCollection = 'kuryeAtamaKuyrugu';
  static Future<Map<String, dynamic>> siparisOlustur({
    dynamic kullaniciId,
    dynamic userId,
    dynamic musteriId,
    dynamic items,
    dynamic urunler,
    dynamic sepetUrunleri,
    dynamic sepet,
    dynamic teslimatUcreti,
    dynamic indirimTutari,
    dynamic odemeDurumu,
    dynamic paraBirimi,
    dynamic sellerDeliveryTypes,
    dynamic sellerCommissionRates,
    dynamic ekstraOrderMeta,
    dynamic toplamTutar,
    dynamic araToplam,
    dynamic adres,
    dynamic adresId,
    dynamic notlar,
    dynamic siparisNotu,
    dynamic odemeTipi,
    dynamic odemeYontemi,
    dynamic teslimatTipi,
    dynamic context,
  }) async {
    final service = OrderService();

    final dynamic rawItems = items ?? urunler ?? sepetUrunleri ?? sepet;
    final List<OrderItemInput> normalizedItems =
        service._normalizeItems(rawItems);

    final String finalKullaniciId =
        (kullaniciId ?? userId ?? musteriId ?? 'guest_user').toString();

    final Map<String, dynamic> meta = {
      if (adres != null) 'adres': adres,
      if (adresId != null) 'adresId': adresId,
      if (notlar != null) 'notlar': notlar,
      if (siparisNotu != null) 'siparisNotu': siparisNotu,
      if (odemeTipi != null) 'odemeTipi': odemeTipi,
      if (odemeYontemi != null) 'odemeYontemi': odemeYontemi,
      if (teslimatTipi != null) 'teslimatTipi': teslimatTipi,
      if (toplamTutar != null) 'legacyToplamTutar': toplamTutar,
      if (araToplam != null) 'legacyAraToplam': araToplam,
      if (ekstraOrderMeta is Map) ...Map<String, dynamic>.from(ekstraOrderMeta),
    };

    return service.createOrder(
      kullaniciId: finalKullaniciId,
      items: normalizedItems,
      teslimatUcreti: _toDouble(teslimatUcreti, 0),
      indirimTutari: _toDouble(indirimTutari, 0),
      odemeDurumu: (odemeDurumu ?? 'beklemede').toString(),
      paraBirimi: (paraBirimi ?? 'TRY').toString(),
      sellerDeliveryTypes: _toStringMap(sellerDeliveryTypes),
      sellerCommissionRates: _toDoubleMap(sellerCommissionRates),
      ekstraOrderMeta: meta.isEmpty ? null : meta,
    );
  }

  Future<String> generateSiparisNo() async {
    return _firestore.runTransaction<String>((transaction) async {
      return _generateSiparisNoInTransaction(transaction);
    });
  }

  double calculateCommission({
    required double araToplam,
    required double komisyonOrani,
  }) {
    final subtotal = _roundMoney(araToplam);
    final rate = komisyonOrani < 0 ? 0.0 : komisyonOrani;
    return _roundMoney(subtotal * rate / 100);
  }

  List<SellerOrderGroup> splitOrdersBySeller(List<OrderItemInput> items) {
    final Map<String, List<OrderItemInput>> grouped = {};

    for (final item in items) {
      grouped.putIfAbsent(item.saticiId, () => <OrderItemInput>[]);
      grouped[item.saticiId]!.add(item);
    }

    return grouped.entries
        .map(
          (entry) => SellerOrderGroup(
            saticiId: entry.key,
            items: entry.value,
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> createOrder({
    required String kullaniciId,
    required List<OrderItemInput> items,
    double teslimatUcreti = 0,
    double indirimTutari = 0,
    String odemeDurumu = 'beklemede',
    String paraBirimi = 'TRY',
    Map<String, String>? sellerDeliveryTypes,
    Map<String, double>? sellerCommissionRates,
    Map<String, dynamic>? ekstraOrderMeta,
  }) async {
    if (kullaniciId.trim().isEmpty) {
      throw Exception('kullaniciId boş olamaz.');
    }

    if (items.isEmpty) {
      throw Exception('Sipariş için en az 1 ürün gerekli.');
    }

    final List<OrderItemInput> cleanItems = items
        .map((e) => OrderItemInput(
              urunId: e.urunId,
              urunAdi: e.urunAdi,
              saticiId: e.saticiId,
              adet: e.adet <= 0 ? 1 : e.adet,
              fiyat: e.fiyat < 0 ? 0 : e.fiyat,
              gorselUrl: e.gorselUrl,
              kategori: e.kategori,
              extra: null,
            ))
        .toList();

    final sellerGroups = splitOrdersBySeller(cleanItems);

    try {
      debugPrint('🟡 createOrder başladı');
      debugPrint('🟡 kullaniciId: $kullaniciId');
      debugPrint('🟡 cleanItems: ${cleanItems.length}');
      debugPrint('🟡 sellerGroups: ${sellerGroups.length}');

      final result = await _firestore
          .runTransaction<Map<String, dynamic>>((transaction) async {
        final String siparisNo =
            await _generateSiparisNoInTransaction(transaction);

        final orderRef = _firestore.collection(_ordersCollection).doc();
        final List<String> sellerOrderIds = <String>[];
        final List<String> queueIds = <String>[];

        final double araToplam = _roundMoney(
          cleanItems.fold<double>(0, (sum, item) => sum + item.toplam),
        );

        final double normalizedTeslimatUcreti = _roundMoney(teslimatUcreti);
        final double normalizedIndirimTutari = _roundMoney(indirimTutari);
        final double toplamTutar = _roundMoney(
          araToplam + normalizedTeslimatUcreti - normalizedIndirimTutari,
        );

        transaction.set(orderRef, {
          'siparisNo': siparisNo,
          'kullaniciId': kullaniciId,
          'araToplam': araToplam,
          'teslimatUcreti': normalizedTeslimatUcreti,
          'indirimTutari': normalizedIndirimTutari,
          'toplamTutar': toplamTutar < 0 ? 0 : toplamTutar,
          'odemeDurumu': odemeDurumu,
          'status': 'pending',
          'statusUpdatedAt': FieldValue.serverTimestamp(),
          'paraBirimi': paraBirimi,
          'saticiSayisi': sellerGroups.length,
          'itemSayisi': cleanItems.length,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          if (ekstraOrderMeta != null) 'meta': ekstraOrderMeta,
        });

        final timelineRef = _firestore.collection('orderTimeline').doc();

        transaction.set(timelineRef, {
          'orderId': orderRef.id,
          'siparisNo': siparisNo,
          'status': 'pending',
          'actorType': 'system',
          'actorId': 'system',
          'note': 'Sipariş oluşturuldu',
          'createdAt': FieldValue.serverTimestamp(),
        });

        for (final item in cleanItems) {
          final itemRef = orderRef.collection('items').doc();
          transaction.set(itemRef, {
            ...item.toMap(),
            'orderId': orderRef.id,
            'siparisNo': siparisNo,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        debugPrint('🟢 main order hazır: ${orderRef.id}');
        debugPrint('🟢 main order items hazır: ${cleanItems.length}');

        for (final group in sellerGroups) {
          final String saticiId = group.saticiId;
          final double subAraToplam = _roundMoney(group.araToplam);

          final String finalTeslimatTipi =
              sellerDeliveryTypes?[saticiId] ?? 'standart';

          final double finalKomisyonOrani =
              sellerCommissionRates?[saticiId] ?? 0.0;

          final double komisyonTutari = calculateCommission(
            araToplam: subAraToplam,
            komisyonOrani: finalKomisyonOrani,
          );

          final double netKazanc = _roundMoney(subAraToplam - komisyonTutari);

          final sellerOrderRef =
              _firestore.collection(_sellerOrdersCollection).doc();

          sellerOrderIds.add(sellerOrderRef.id);

          transaction.set(sellerOrderRef, {
            'orderId': orderRef.id,
            'siparisNo': siparisNo,
            'kullaniciId': kullaniciId,
            'saticiId': saticiId,
            'teslimatTipi': finalTeslimatTipi,
            'komisyonOrani': finalKomisyonOrani,
            'komisyonTutari': komisyonTutari,
            'netKazanc': netKazanc,
            'araToplam': subAraToplam,
            'odemeDurumu': odemeDurumu,
            'paraBirimi': paraBirimi,
            'durum': 'olusturuldu',
            'status': 'pending',
            'statusUpdatedAt': FieldValue.serverTimestamp(),
            'itemSayisi': group.items.length,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          for (final item in group.items) {
            final sellerItemRef = sellerOrderRef.collection('items').doc();
            transaction.set(sellerItemRef, {
              ...item.toMap(),
              'orderId': orderRef.id,
              'sellerOrderId': sellerOrderRef.id,
              'siparisNo': siparisNo,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }

          final bool kuryeGerekli = finalTeslimatTipi == 'teslimat' ||
              finalTeslimatTipi == 'gel_al_ve_teslimat' ||
              finalTeslimatTipi == 'platform_teslimat' ||
              finalTeslimatTipi == 'kurye';

          if (kuryeGerekli) {
            final kuryeAtamaRef =
                _firestore.collection(_kuryeAtamaKuyruguCollection).doc();

            transaction.set(kuryeAtamaRef, {
              'orderId': orderRef.id,
              'sellerOrderId': sellerOrderRef.id,
              'siparisNo': siparisNo,
              'kullaniciId': kullaniciId,
              'saticiId': saticiId,
              'status': 'waiting_assignment',
              'durum': 'atama_bekliyor',
              'teslimatTipi': finalTeslimatTipi,
              'kuryeAtamaDurumu': 'beklemede',
              'kuryeId': null,
              'kuryeAdi': null,
              'atanmaZamani': null,
              'kabulZamani': null,
              'tamamlanmaZamani': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

            queueIds.add(kuryeAtamaRef.id);
          }
        }

        debugPrint('🟢 seller orders hazır: ${sellerOrderIds.length}');
        debugPrint('🟢 queue hazır: ${queueIds.length}');

        return {
          'success': true,
          'orderId': orderRef.id,
          'siparisNo': siparisNo,
          'sellerOrderIds': sellerOrderIds,
          'queueIds': queueIds,
        };
      });

      final List<String> queueIds =
          (result['queueIds'] as List<dynamic>? ?? <dynamic>[])
              .map((e) => e.toString())
              .toList();

      if (queueIds.isNotEmpty) {
        final kuryeService = KuryeService(firestore: _firestore);

        for (final queueId in queueIds) {
          try {
            await kuryeService.bekleyenKuryeAtamasiniOtomatikYap(
              queueId: queueId,
            );
          } catch (e) {
            debugPrint('⚠️ Kurye otomatik atama tetiklenemedi: $queueId - $e');
          }
        }
      }

      return result;
    } catch (e, st) {
      debugPrint('❌ OrderService.createOrder ERROR: $e');
      debugPrint('❌ OrderService.createOrder STACK: $st');
      rethrow;
    }
  }

  Future<String> _generateSiparisNoInTransaction(
    Transaction transaction,
  ) async {
    final counterRef =
        _firestore.collection(_countersCollection).doc(_siparisNoDoc);

    final counterSnap = await transaction.get(counterRef);

    if (!counterSnap.exists) {
      transaction.set(counterRef, {
        'value': 1001,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return 'SF-1001';
    }

    final data = counterSnap.data();
    final dynamic rawValue = data?['value'];

    if (rawValue == null || rawValue is! num) {
      throw Exception('counters/siparisNo/value sayısal olmalı.');
    }

    final int currentValue = rawValue.toInt();
    final int nextValue = currentValue + 1;

    transaction.update(counterRef, {
      'value': nextValue,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return 'SF-$nextValue';
  }

  List<OrderItemInput> _normalizeItems(dynamic rawItems) {
    if (rawItems == null) return <OrderItemInput>[];
    if (rawItems is List<OrderItemInput>) return rawItems;
    if (rawItems is List) {
      return rawItems.map((e) => OrderItemInput.fromDynamic(e)).toList();
    }
    throw Exception('Ürün listesi bekleniyordu.');
  }

  double _roundMoney(num value) {
    return double.parse(value.toStringAsFixed(2));
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '.').trim();
      return double.tryParse(normalized) ?? fallback;
    }
    return fallback;
  }

  static Map<String, String>? _toStringMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final result = <String, String>{};
      value.forEach((key, val) {
        result[key.toString()] = val.toString();
      });
      return result.isEmpty ? null : result;
    }
    return null;
  }

  static Map<String, double>? _toDoubleMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final result = <String, double>{};
      value.forEach((key, val) {
        result[key.toString()] = _toDouble(val, 0);
      });
      return result.isEmpty ? null : result;
    }
    return null;
  }
}
