import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/otomatik_kurye_atama_servisi.dart';
import '../services/kurye_mesafe_hesaplayici.dart';

class KuryeAtamaMotoru extends StatefulWidget {
  const KuryeAtamaMotoru({super.key});

  @override
  State<KuryeAtamaMotoru> createState() => _KuryeAtamaMotoruState();
}

class _KuryeAtamaMotoruState extends State<KuryeAtamaMotoru> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _durumFiltre = 'tum';
  bool _sadeceAtanmamislar = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _siparisStream() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> _uygunKuryeleriGetir() async {
    final snapshot = await _firestore.collection('couriers').get();

    final uygunlar = snapshot.docs.where((doc) {
      final data = doc.data();

      final bool aktifMi =
          (data['aktifMi'] == true) || (data['isActive'] == true);

      final String uygunluk = (data['uygunluk'] ??
              data['uygunlukDurumu'] ??
              data['availability'] ??
              '')
          .toString()
          .trim()
          .toLowerCase();

      final double? lat = _toDouble(data['lat']);
      final double? lng = _toDouble(data['lng']);

      final bool konumVar = lat != null && lng != null;
      final bool musait = uygunluk == 'musait' ||
          uygunluk == 'müsait' ||
          uygunluk == 'available';

      return aktifMi && musait && konumVar;
    }).map((doc) {
      final data = doc.data();

      final int aktifSiparis = (data['aktifSiparis'] is int)
          ? data['aktifSiparis'] as int
          : int.tryParse('${data['aktifSiparis'] ?? 0}') ?? 0;

      int maxAktifSiparis = (data['maxAktifSiparis'] is int)
          ? data['maxAktifSiparis'] as int
          : int.tryParse('${data['maxAktifSiparis'] ?? 1}') ?? 1;

      if (maxAktifSiparis <= 0) {
        maxAktifSiparis = 1;
      }

      return {
        'id': doc.id,
        'ad': (data['adSoyad'] ?? data['ad'] ?? data['name'] ?? 'Kurye')
            .toString(),
        'telefon': (data['telefon'] ?? data['phone'] ?? '').toString(),
        'lat': _toDouble(data['lat']),
        'lng': _toDouble(data['lng']),
        'sehir': (data['sehir'] ?? data['city'] ?? '').toString(),
        'ilce': (data['ilce'] ?? '').toString(),
        'aracTipi': (data['aracTipi'] ?? data['vehicleType'] ?? '').toString(),
        'rating': _toDouble(data['rating']) ?? 0,
        'aktifSiparis': aktifSiparis,
        'maxAktifSiparis': maxAktifSiparis,
        'uygunluk':
            (data['uygunluk'] ?? data['uygunlukDurumu'] ?? 'Müsait').toString(),
      };
    }).toList();

    return uygunlar;
  }

  Future<List<_KuryeOneriModel>> _siparisIcinOneriler(
    Map<String, dynamic> siparisData,
  ) async {
    final double? siparisLat = _toDouble(siparisData['lat']);
    final double? siparisLng = _toDouble(siparisData['lng']);

    if (siparisLat == null || siparisLng == null) {
      return [];
    }

    // 1) Önce varsa yeni servis metodunu dene.
    try {
      final dynamic servis = OtomatikKuryeAtamaServisi();

      final dynamic servisSonucu = await servis.enYakinKuryeleriGetir(
        hedefLat: siparisLat,
        hedefLng: siparisLng,
        limit: 3,
      );

      if (servisSonucu is List) {
        final list = servisSonucu
            .map((e) => _KuryeOneriModel.fromDynamicMap(e))
            .whereType<_KuryeOneriModel>()
            .toList();

        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (_) {
      // Sessiz fallback: servis henüz bu metodu içermiyorsa aşağıdaki mevcut yapı çalışır.
    }

    // 2) Fallback: mevcut mesafe hesabı ile Top 3 çıkar.
    final kuryeler = await _uygunKuryeleriGetir();

    final yakinlar = KuryeMesafeHesaplayici.ilkNEnYakinKurye(
      kuryeler: kuryeler,
      hedefLat: siparisLat,
      hedefLng: siparisLng,
      limit: 3,
    );

    return yakinlar.map((item) {
      final Map<String, dynamic> kaynak = kuryeler.firstWhere(
        (k) => (k['id'] ?? '').toString() == item.kuryeId,
        orElse: () => <String, dynamic>{},
      );

      final double rating = _toDouble(kaynak['rating']) ?? 0;
      final int aktifSiparis = (kaynak['aktifSiparis'] is int)
          ? kaynak['aktifSiparis'] as int
          : int.tryParse('${kaynak['aktifSiparis'] ?? 0}') ?? 0;
      final int maxAktifSiparis = (kaynak['maxAktifSiparis'] is int)
          ? kaynak['maxAktifSiparis'] as int
          : int.tryParse('${kaynak['maxAktifSiparis'] ?? 1}') ?? 1;

      return _KuryeOneriModel(
        kuryeId: item.kuryeId,
        kuryeAdi: item.kuryeAdi,
        telefon: (kaynak['telefon'] ?? '').toString(),
        aracTipi: (kaynak['aracTipi'] ?? '').toString(),
        sehir: (kaynak['sehir'] ?? '').toString(),
        ilce: (kaynak['ilce'] ?? '').toString(),
        uygunluk: (kaynak['uygunluk'] ?? 'Müsait').toString(),
        mesafeKm: item.mesafeKm,
        rating: rating,
        aktifSiparis: aktifSiparis,
        maxAktifSiparis: maxAktifSiparis,
        skor: _skorHesapla(
          mesafeKm: item.mesafeKm,
          rating: rating,
          aktifSiparis: aktifSiparis,
          maxAktifSiparis: maxAktifSiparis,
        ),
      );
    }).toList()
      ..sort((a, b) => b.skor.compareTo(a.skor));
  }

  double _skorHesapla({
    required double mesafeKm,
    required double rating,
    required int aktifSiparis,
    required int maxAktifSiparis,
  }) {
    final double mesafePuani = (100 - (mesafeKm * 12)).clamp(0, 100).toDouble();
    final double ratingPuani = (rating.clamp(0, 5) * 20).toDouble();

    double kapasitePuani;
    if (maxAktifSiparis <= 0) {
      kapasitePuani = 0;
    } else {
      final oran = (aktifSiparis / maxAktifSiparis).clamp(0, 1);
      kapasitePuani = (100 - (oran * 100)).toDouble();
    }

    final double skor =
        (mesafePuani * 0.55) + (ratingPuani * 0.25) + (kapasitePuani * 0.20);

    return skor.clamp(0, 100).toDouble();
  }

  String _skorEtiketi(double skor) {
    if (skor >= 80) return 'Çok Uygun';
    if (skor >= 60) return 'Uygun';
    if (skor >= 40) return 'Orta';
    return 'Zayıf';
  }

  Color _skorRengi(double skor) {
    if (skor >= 80) return Colors.green;
    if (skor >= 60) return Colors.lightGreen;
    if (skor >= 40) return Colors.orange;
    return Colors.redAccent;
  }

  Future<void> _kuryeAta({
    required String siparisId,
    required String kuryeId,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc(siparisId);
      final courierRef = _firestore.collection('couriers').doc(kuryeId);

      await _firestore.runTransaction((transaction) async {
        final orderSnap = await transaction.get(orderRef);
        final courierSnap = await transaction.get(courierRef);

        if (!orderSnap.exists) {
          throw Exception('Sipariş bulunamadı.');
        }

        if (!courierSnap.exists) {
          throw Exception('Kurye bulunamadı.');
        }

        final orderData = orderSnap.data() as Map<String, dynamic>;
        final courierData = courierSnap.data() as Map<String, dynamic>;

        final String mevcutAssignmentStatus =
            (orderData['assignmentStatus'] ?? '')
                .toString()
                .trim()
                .toLowerCase();

        if (mevcutAssignmentStatus == 'assigned') {
          throw Exception('Bu sipariş zaten atanmış.');
        }

        if (mevcutAssignmentStatus == 'completed') {
          throw Exception('Bu sipariş zaten tamamlanmış.');
        }

        final int aktifSiparis = (courierData['aktifSiparis'] is int)
            ? courierData['aktifSiparis'] as int
            : int.tryParse('${courierData['aktifSiparis'] ?? 0}') ?? 0;

        final String kuryeAdi =
            (courierData['adSoyad'] ?? courierData['ad'] ?? 'Kurye')
                .toString()
                .trim();

        final String kuryeTelefon =
            (courierData['telefon'] ?? '').toString().trim();

        transaction.update(orderRef, {
          'assignedCourierId': kuryeId,
          'assignedCourierName': kuryeAdi,
          'courierPhone': kuryeTelefon,
          'assignmentAt': FieldValue.serverTimestamp(),
          'assignmentStatus': 'assigned',
          'courierAssignmentType': 'manual_suggestion',
          'status': 'on_the_way',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(courierRef, {
          'aktifSiparis': aktifSiparis + 1,
          'uygunluk': 'Görevde',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kurye başarıyla atandı.'),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kurye atama hatası: $e'),
        ),
      );
    }
  }

  Future<void> _otomatikAta({
    required String siparisId,
    required Map<String, dynamic> siparisData,
  }) async {
    try {
      final oneriler = await _siparisIcinOneriler(siparisData);

      if (oneriler.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uygun kurye bulunamadı.'),
          ),
        );
        return;
      }

      final enIyiKurye = oneriler.first;

      await _kuryeAta(
        siparisId: siparisId,
        kuryeId: enIyiKurye.kuryeId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Otomatik atama yapıldı: ${enIyiKurye.kuryeAdi}',
          ),
        ),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Otomatik atama hatası: $e'),
        ),
      );
    }
  }

  Future<void> _onerileriGoster({
    required String siparisId,
    required Map<String, dynamic> siparisData,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: FutureBuilder<List<_KuryeOneriModel>>(
            future: _siparisIcinOneriler(siparisData),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SizedBox(
                  height: 220,
                  child: Center(
                    child: Text(
                      'Kurye önerileri alınamadı:\n${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 220,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFB300),
                    ),
                  ),
                );
              }

              final oneriler = snapshot.data ?? [];

              if (oneriler.isEmpty) {
                return const SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      'Bu sipariş için uygun kurye önerisi bulunamadı.\nSiparişte lat/lng ve kuryelerde lat/lng alanlarını kontrol edin.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const Text(
                        'En Yakın Kurye Önerileri',
                        style: TextStyle(
                          color: Color(0xFFFFB300),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Mesafe + puan + kapasite bazlı Top 3 öneri',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...List.generate(oneriler.length, (index) {
                        final item = oneriler[index];
                        final Color skorRengi = _skorRengi(item.skor);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181818),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade800),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB300)
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '#${index + 1}',
                                        style: const TextStyle(
                                          color: Color(0xFFFFB300),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.kuryeAdi,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.ilce.isEmpty ? "-" : item.ilce} / ${item.sehir.isEmpty ? "-" : item.sehir}',
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: skorRengi.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: skorRengi),
                                    ),
                                    child: Text(
                                      _skorEtiketi(item.skor),
                                      style: TextStyle(
                                        color: skorRengi,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _miniBilgiKutusu(
                                      'Mesafe',
                                      '${item.mesafeKm.toStringAsFixed(2)} km',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _miniBilgiKutusu(
                                      'Skor',
                                      item.skor.toStringAsFixed(1),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _miniBilgiKutusu(
                                      'Rating',
                                      item.rating.toStringAsFixed(1),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _miniBilgiKutusu(
                                      'Aktif Sipariş',
                                      '${item.aktifSiparis}/${item.maxAktifSiparis}',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _miniBilgiKutusu(
                                      'Araç',
                                      item.aracTipi.isEmpty
                                          ? '-'
                                          : item.aracTipi,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _miniBilgiKutusu(
                                      'Uygunluk',
                                      item.uygunluk.isEmpty
                                          ? '-'
                                          : item.uygunluk,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.telefon.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Telefon: ${item.telefon}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade900,
                                        foregroundColor:
                                            const Color(0xFFFFB300),
                                        side: const BorderSide(
                                          color: Color(0xFFFFB300),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () async {
                                        Navigator.of(sheetContext).pop();
                                        await _otomatikAta(
                                          siparisId: siparisId,
                                          siparisData: siparisData,
                                        );
                                      },
                                      child: const Text('Otomatik Ata'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFFFB300),
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () async {
                                        Navigator.of(sheetContext).pop();
                                        await _kuryeAta(
                                          siparisId: siparisId,
                                          kuryeId: item.kuryeId,
                                        );
                                      },
                                      child: const Text(
                                        'Bu Kuryeyi Ata',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _miniBilgiKutusu(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ustKart({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFB300)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bilgiSatiri(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: value.isEmpty ? '-' : value,
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

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  bool _durumaUyuyor(Map<String, dynamic> data) {
    if (_durumFiltre == 'tum') return true;

    final status = (data['status'] ?? '').toString().trim().toLowerCase();

    if (_durumFiltre == 'hazirlaniyor') {
      return status == 'hazirlaniyor' || status == 'preparing';
    }

    if (_durumFiltre == 'yolda') {
      return status == 'yolda' || status == 'on_the_way';
    }

    return status == _durumFiltre;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          'KURYE ATAMA MOTORU',
          style: TextStyle(
            color: Color(0xFFFFB300),
            letterSpacing: 1.1,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            color: Colors.black,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ustKart(
                        icon: Icons.local_shipping,
                        label: 'Filtre',
                        value: _durumFiltre == 'tum' ? 'Tümü' : _durumFiltre,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ustKart(
                        icon: Icons.assignment_turned_in,
                        label: 'Görünüm',
                        value: _sadeceAtanmamislar ? 'Atanmamış' : 'Tümü',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filtreChip('tum', 'Tümü'),
                      const SizedBox(width: 8),
                      _filtreChip('pending', 'pending'),
                      const SizedBox(width: 8),
                      _filtreChip('hazirlaniyor', 'hazırlanıyor'),
                      const SizedBox(width: 8),
                      _filtreChip('yolda', 'yolda'),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Sadece atanmamış'),
                        selected: _sadeceAtanmamislar,
                        labelStyle: TextStyle(
                          color:
                              _sadeceAtanmamislar ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: const Color(0xFFFFB300),
                        backgroundColor: const Color(0xFF181818),
                        side: BorderSide(color: Colors.grey.shade800),
                        onSelected: (value) {
                          setState(() {
                            _sadeceAtanmamislar = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _siparisStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Siparişler okunamadı: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFB300),
                    ),
                  );
                }

                var docs = snapshot.data?.docs ?? [];

                docs = docs.where((doc) => _durumaUyuyor(doc.data())).toList();

                if (_sadeceAtanmamislar) {
                  docs = docs.where((doc) {
                    final data = doc.data();
                    final courierId =
                        (data['assignedCourierId'] ?? '').toString().trim();
                    return courierId.isEmpty;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Gösterilecek sipariş bulunamadı.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final String adres = (data['adres'] ?? '').toString();
                    final String status = (data['status'] ?? '').toString();
                    final String vendorName = (data['vendorName'] ??
                            data['saticiAd'] ??
                            data['dukkanAdi'] ??
                            '-')
                        .toString();
                    final String courierName =
                        (data['assignedCourierName'] ?? '').toString().trim();

                    final double? lat = _toDouble(data['lat']);
                    final double? lng = _toDouble(data['lng']);
                    final bool konumHazir = lat != null && lng != null;
                    final bool zatenAtanmis = courierName.isNotEmpty;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade800),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB300)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long,
                                    color: Color(0xFFFFB300),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sipariş: ${doc.id}',
                                        style: const TextStyle(
                                          color: Color(0xFFFFB300),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Satıcı: $vendorName',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Durum: ${status.isEmpty ? "-" : status}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: courierName.isEmpty
                                        ? Colors.orange.withValues(alpha: 0.18)
                                        : Colors.green.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: courierName.isEmpty
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                  child: Text(
                                    courierName.isEmpty ? 'Atanmadı' : 'Atandı',
                                    style: TextStyle(
                                      color: courierName.isEmpty
                                          ? Colors.orange
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _bilgiSatiri('Adres', adres),
                            _bilgiSatiri(
                              'Kurye',
                              courierName.isEmpty ? '-' : courierName,
                            ),
                            _bilgiSatiri(
                              'Konum',
                              konumHazir
                                  ? '${lat.toString()}, ${lng.toString()}'
                                  : 'lat/lng eksik',
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (konumHazir && !zatenAtanmis)
                                      ? const Color(0xFFFFB300)
                                      : Colors.grey.shade700,
                                  foregroundColor: (konumHazir && !zatenAtanmis)
                                      ? Colors.black
                                      : Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: (konumHazir && !zatenAtanmis)
                                    ? () => _onerileriGoster(
                                          siparisId: doc.id,
                                          siparisData: data,
                                        )
                                    : null,
                                icon: Icon(zatenAtanmis
                                    ? Icons.check_circle
                                    : Icons.psychology),
                                label: Text(
                                  zatenAtanmis
                                      ? 'Kurye Zaten Atandı'
                                      : 'En Yakın 3 Kurye Öner',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtreChip(String value, String label) {
    final bool secili = _durumFiltre == value;

    return ChoiceChip(
      label: Text(label),
      selected: secili,
      labelStyle: TextStyle(
        color: secili ? Colors.black : Colors.white,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: const Color(0xFFFFB300),
      backgroundColor: const Color(0xFF181818),
      side: BorderSide(
        color: secili ? const Color(0xFFFFB300) : Colors.grey.shade800,
      ),
      onSelected: (_) {
        setState(() {
          _durumFiltre = value;
        });
      },
    );
  }
}

class _KuryeOneriModel {
  final String kuryeId;
  final String kuryeAdi;
  final String telefon;
  final String aracTipi;
  final String sehir;
  final String ilce;
  final String uygunluk;
  final double mesafeKm;
  final double skor;
  final double rating;
  final int aktifSiparis;
  final int maxAktifSiparis;

  const _KuryeOneriModel({
    required this.kuryeId,
    required this.kuryeAdi,
    required this.telefon,
    required this.aracTipi,
    required this.sehir,
    required this.ilce,
    required this.uygunluk,
    required this.mesafeKm,
    required this.skor,
    required this.rating,
    required this.aktifSiparis,
    required this.maxAktifSiparis,
  });

  static _KuryeOneriModel? fromDynamicMap(dynamic raw) {
    if (raw is! Map) return null;

    double parseDouble(dynamic v) {
      if (v == null) return 0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    return _KuryeOneriModel(
      kuryeId: (raw['kuryeId'] ?? raw['id'] ?? '').toString(),
      kuryeAdi:
          (raw['kuryeAdi'] ?? raw['ad'] ?? raw['name'] ?? 'Kurye').toString(),
      telefon: (raw['telefon'] ?? raw['phone'] ?? '').toString(),
      aracTipi: (raw['aracTipi'] ?? raw['vehicleType'] ?? '').toString(),
      sehir: (raw['sehir'] ?? raw['city'] ?? '').toString(),
      ilce: (raw['ilce'] ?? '').toString(),
      uygunluk:
          (raw['uygunluk'] ?? raw['uygunlukDurumu'] ?? 'Müsait').toString(),
      mesafeKm: parseDouble(raw['mesafeKm'] ?? raw['distanceKm']),
      skor: parseDouble(raw['skor'] ?? raw['score']),
      rating: parseDouble(raw['rating']),
      aktifSiparis: parseInt(raw['aktifSiparis']),
      maxAktifSiparis: parseInt(raw['maxAktifSiparis'] ?? 1),
    );
  }
}
