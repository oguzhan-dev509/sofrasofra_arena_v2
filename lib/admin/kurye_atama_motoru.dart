import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/kurye_mesafe_hesaplayici.dart';

class KuryeAtamaMotoru extends StatefulWidget {
  const KuryeAtamaMotoru({super.key});

  @override
  State<KuryeAtamaMotoru> createState() => _KuryeAtamaMotoruState();
}

class _KuryeAtamaMotoruState extends State<KuryeAtamaMotoru> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _durumFiltre = 'tum';
  bool _sadeceAtanmamislar = true;

  Stream<QuerySnapshot<Map<String, dynamic>>> _siparisStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('orders');

    if (_durumFiltre != 'tum') {
      query = query.where('status', isEqualTo: _durumFiltre);
    }

    return query.snapshots();
  }

  Future<List<Map<String, dynamic>>> _uygunKuryeleriGetir() async {
    final snapshot = await _firestore.collection('couriers').get();

    final uygunlar = snapshot.docs.where((doc) {
      final data = doc.data();

      final isActive = (data['isActive'] ?? false) == true;
      final uygunluk = (data['uygunlukDurumu'] ?? data['availability'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      final lat = _toDouble(data['lat']);
      final lng = _toDouble(data['lng']);

      final konumVar = lat != null && lng != null;
      final musait = uygunluk == 'musait' || uygunluk == 'available';

      return isActive && musait && konumVar;
    }).map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'ad': (data['ad'] ?? data['name'] ?? 'Kurye').toString(),
        'telefon': (data['telefon'] ?? data['phone'] ?? '').toString(),
        'lat': _toDouble(data['lat']),
        'lng': _toDouble(data['lng']),
        'sehir': (data['sehir'] ?? data['city'] ?? '').toString(),
        'ilce': (data['ilce'] ?? '').toString(),
        'aracTipi': (data['aracTipi'] ?? data['vehicleType'] ?? '').toString(),
      };
    }).toList();

    return uygunlar;
  }

  Future<List<KuryeMesafeSonucu>> _siparisIcinOneriler(
    Map<String, dynamic> siparisData,
  ) async {
    final siparisLat = _toDouble(siparisData['lat']);
    final siparisLng = _toDouble(siparisData['lng']);

    if (siparisLat == null || siparisLng == null) {
      return [];
    }

    final kuryeler = await _uygunKuryeleriGetir();

    return KuryeMesafeHesaplayici.ilkNEnYakinKurye(
      kuryeler: kuryeler,
      hedefLat: siparisLat,
      hedefLng: siparisLng,
      limit: 3,
    );
  }

  Future<Map<String, dynamic>?> _kuryeDetayGetir(String kuryeId) async {
    final doc = await _firestore.collection('couriers').doc(kuryeId).get();
    if (!doc.exists) return null;

    final data = doc.data() ?? {};
    return {
      'id': doc.id,
      'ad': (data['ad'] ?? data['name'] ?? 'Kurye').toString(),
      'telefon': (data['telefon'] ?? data['phone'] ?? '').toString(),
      'sehir': (data['sehir'] ?? data['city'] ?? '').toString(),
      'ilce': (data['ilce'] ?? '').toString(),
      'aracTipi': (data['aracTipi'] ?? data['vehicleType'] ?? '').toString(),
    };
  }

  Future<void> _kuryeAta({
    required String siparisId,
    required String kuryeId,
  }) async {
    try {
      final kurye = await _kuryeDetayGetir(kuryeId);

      if (kurye == null) {
        throw Exception('Kurye bulunamadı.');
      }

      await _firestore.collection('orders').doc(siparisId).update({
        'courierId': kurye['id'],
        'courierName': kurye['ad'],
        'courierPhone': kurye['telefon'],
        'courierAssignedAt': FieldValue.serverTimestamp(),
        'courierAssignmentType': 'manual_suggestion',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${kurye['ad']} siparişe atandı.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kurye atanamadı: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onerileriGoster({
    required String siparisId,
    required Map<String, dynamic> siparisData,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: FutureBuilder<List<KuryeMesafeSonucu>>(
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

              return Column(
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
                  const SizedBox(height: 14),
                  ...oneriler.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delivery_dining,
                              color: Color(0xFFFFB300),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.kuryeAdi,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mesafe: ${item.mesafeKm.toStringAsFixed(2)} km',
                                  style: const TextStyle(
                                    color: Color(0xFFFFB300),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB300),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _kuryeAta(
                                siparisId: siparisId,
                                kuryeId: item.kuryeId,
                              );
                            },
                            child: const Text('Ata'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        );
      },
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

                if (_sadeceAtanmamislar) {
                  docs = docs.where((doc) {
                    final data = doc.data();
                    final courierId =
                        (data['courierId'] ?? '').toString().trim();
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

                    final adres = (data['adres'] ?? '').toString();
                    final status = (data['status'] ?? '').toString();
                    final vendorName =
                        (data['vendorName'] ?? data['saticiAdi'] ?? '-')
                            .toString();
                    final courierName =
                        (data['courierName'] ?? '').toString().trim();

                    final lat = _toDouble(data['lat']);
                    final lng = _toDouble(data['lng']);

                    final konumHazir = lat != null && lng != null;

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
                                        .withOpacity(0.15),
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
                                        ? Colors.orange.withOpacity(0.18)
                                        : Colors.green.withOpacity(0.18),
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
                                  backgroundColor: konumHazir
                                      ? const Color(0xFFFFB300)
                                      : Colors.grey.shade700,
                                  foregroundColor:
                                      konumHazir ? Colors.black : Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: konumHazir
                                    ? () => _onerileriGoster(
                                          siparisId: doc.id,
                                          siparisData: data,
                                        )
                                    : null,
                                icon: const Icon(Icons.psychology),
                                label: const Text(
                                  'En Yakın 3 Kurye Öner',
                                  style: TextStyle(fontWeight: FontWeight.bold),
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
    final secili = _durumFiltre == value;

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
