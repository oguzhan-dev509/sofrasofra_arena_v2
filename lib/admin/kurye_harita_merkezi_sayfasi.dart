import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/kurye_teslim_servisi.dart';
import '../services/otomatik_kurye_atama_servisi.dart';
import '../services/kurye_mesafe_hesaplayici.dart';

class KuryeHaritaMerkeziSayfasi extends StatefulWidget {
  const KuryeHaritaMerkeziSayfasi({super.key});

  @override
  State<KuryeHaritaMerkeziSayfasi> createState() =>
      _KuryeHaritaMerkeziSayfasiState();
}

class _KuryeHaritaMerkeziSayfasiState extends State<KuryeHaritaMerkeziSayfasi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _aktifSiparisId;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Future<String?> _ilkBekleyenSiparisIdGetir() async {
    final query = await _firestore
        .collection('orders')
        .where('deliveryMode', isEqualTo: 'platform_kurye')
        .where('status', isEqualTo: 'pending')
        .where('assignmentStatus', isEqualTo: 'unassigned')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.id;
  }

  Future<Map<String, dynamic>?> _siparisGetir() async {
    final aktifId = _aktifSiparisId ?? await _ilkBekleyenSiparisIdGetir();
    if (aktifId == null) return null;

    final doc = await _firestore.collection('orders').doc(aktifId).get();
    if (!doc.exists) return null;

    final data = doc.data() ?? {};

    final String deliveryMode =
        (data['deliveryMode'] ?? '').toString().trim().toLowerCase();

    final String status =
        (data['status'] ?? data['durum'] ?? '').toString().trim().toLowerCase();

    final String assignmentStatus =
        (data['assignmentStatus'] ?? '').toString().trim().toLowerCase();

    // Yalnızca platform kurye siparişlerini kabul et
    if (deliveryMode != 'platform_kurye') {
      _aktifSiparisId = null;
      return null;
    }

    // Tamamlanmış / iptal siparişleri haritadan çıkar
    if (status == 'delivered' || status == 'cancelled') {
      _aktifSiparisId = null;
      return null;
    }

    // Sadece atanmamış veya aktif atanmış sipariş mantığına izin ver
    final bool uygunAssignment =
        assignmentStatus == 'unassigned' || assignmentStatus == 'assigned';

    if (!uygunAssignment) {
      _aktifSiparisId = null;
      return null;
    }

    final lat = _toDouble(data['lat']);
    final lng = _toDouble(data['lng']);

    if (lat == null || lng == null) {
      _aktifSiparisId = null;
      return null;
    }

    _aktifSiparisId = aktifId;

    return {
      'id': doc.id,
      'lat': lat,
      'lng': lng,
      'status': status,
      'assignmentStatus': assignmentStatus,
      'assignedCourierId': (data['assignedCourierId'] ?? '').toString(),
      'deliveryMode': deliveryMode,
    };
  }

  Future<List<Map<String, dynamic>>> _tumKuryeleriGetir() async {
    final snapshot = await _firestore.collection('couriers').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'adSoyad': (data['adSoyad'] ?? 'Kurye').toString(),
        'telefon': (data['telefon'] ?? '').toString(),
        'aracTipi': (data['aracTipi'] ?? '').toString(),
        'uygunluk': (data['uygunluk'] ?? '').toString(),
        'lat': _toDouble(data['lat']),
        'lng': _toDouble(data['lng']),
        'aktifMi': data['aktifMi'] == true,
      };
    }).where((kurye) {
      return kurye['aktifMi'] == true &&
          kurye['lat'] != null &&
          kurye['lng'] != null;
    }).toList();
  }

  Future<_HaritaModeli> _veriyiHazirla() async {
    final siparis = await _siparisGetir();

    final kuryeler = await _tumKuryeleriGetir();

    if (siparis == null) {
      return _HaritaModeli(
        siparis: const {},
        kuryeler: kuryeler,
        enYakin: null,
        bekleyenSiparisYok: true,
      );
    }

    final musaitKuryeler = kuryeler.where((kurye) {
      final uygunluk = kurye['uygunluk'].toString().toLowerCase();
      return uygunluk == 'musait' || uygunluk == 'müsait';
    }).toList();

    final sonucListesi = KuryeMesafeHesaplayici.ilkNEnYakinKurye(
      kuryeler: musaitKuryeler,
      hedefLat: siparis['lat'] as double,
      hedefLng: siparis['lng'] as double,
      limit: 1,
    );

    KuryeMesafeSonucu? enYakin;
    if (sonucListesi.isNotEmpty) {
      enYakin = sonucListesi.first;
    }

    return _HaritaModeli(
      siparis: siparis,
      kuryeler: kuryeler,
      enYakin: enYakin,
      bekleyenSiparisYok: false,
    );
  }

  Future<void> _otomatikAta() async {
    try {
      final aktifId = _aktifSiparisId ?? await _ilkBekleyenSiparisIdGetir();

      if (aktifId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Atanacak bekleyen sipariş bulunamadı.'),
          ),
        );
        return;
      }
      final orderDoc = await _firestore.collection('orders').doc(aktifId).get();
      final orderData = orderDoc.data() ?? {};

      final String deliveryMode =
          (orderData['deliveryMode'] ?? '').toString().trim().toLowerCase();

      final String assignmentStatus =
          (orderData['assignmentStatus'] ?? '').toString().trim().toLowerCase();

      final String status = (orderData['status'] ?? orderData['durum'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      if (deliveryMode != 'platform_kurye') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu sipariş platform kurye teslimatına uygun değil.'),
          ),
        );
        return;
      }

      if (status == 'delivered' || status == 'cancelled') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tamamlanmış veya iptal edilmiş siparişe atama yapılamaz.'),
          ),
        );
        return;
      }

      if (assignmentStatus != 'unassigned') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu sipariş zaten atanmış veya kapatılmış.'),
          ),
        );
        return;
      }
      _aktifSiparisId = aktifId;

      final sonuc = await OtomatikKuryeAtamaServisi.sipariseKuryeAta(
        orderId: aktifId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sonuc ? 'Kurye otomatik atandı.' : 'Uygun kurye bulunamadı.',
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

  Future<void> _teslimEt() async {
    try {
      if (_aktifSiparisId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teslim edilecek aktif sipariş bulunamadı.'),
          ),
        );
        return;
      }

      await KuryeTeslimServisi.teslimEt(
        orderId: _aktifSiparisId!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş teslim edildi.'),
        ),
      );

      _aktifSiparisId = null;
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teslim hatası: $e'),
        ),
      );
    }
  }

  Marker _siparisMarker(double lat, double lng) {
    return Marker(
      point: LatLng(lat, lng),
      width: 80,
      height: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.location_on,
            color: Colors.red,
            size: 38,
          ),
          Text(
            'Sipariş',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Marker _kuryeMarker({
    required double lat,
    required double lng,
    required String ad,
    required String durum,
    required bool enYakinMi,
  }) {
    Color renk;

    final durumLower = durum.toLowerCase();

    if (enYakinMi) {
      renk = const Color(0xFFFFB300);
    } else if (durumLower == 'görevde' || durumLower == 'gorevde') {
      renk = Colors.orange;
    } else if (durumLower == 'müsait' || durumLower == 'musait') {
      renk = Colors.green;
    } else {
      renk = Colors.grey;
    }

    return Marker(
      point: LatLng(lat, lng),
      width: 90,
      height: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delivery_dining,
            color: renk,
            size: enYakinMi ? 38 : 34,
          ),
          Text(
            ad,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bosDurumEkrani() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFFFFB300),
              size: 44,
            ),
            SizedBox(height: 14),
            Text(
              'Bekleyen sipariş yok.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Yeni sipariş gelince burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          'KURYE HARİTA MERKEZİ',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('orders').snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.hasError) {
            return Center(
              child: Text(
                'Sipariş verisi okunamadı:\n${orderSnapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (orderSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFB300),
              ),
            );
          }

          return FutureBuilder<_HaritaModeli>(
            future: _veriyiHazirla(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Harita verisi okunamadı:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFB300),
                  ),
                );
              }

              final model = snapshot.data;
              if (model == null) {
                return const Center(
                  child: Text(
                    'Harita verisi bulunamadı.',
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              if (model.bekleyenSiparisYok) {
                return _bosDurumEkrani();
              }

              final siparis = model.siparis;
              final enYakin = model.enYakin;
              final siparisLat = siparis['lat'] as double;
              final siparisLng = siparis['lng'] as double;

              final musaitSayi = model.kuryeler.where((kurye) {
                final uygunluk = kurye['uygunluk'].toString().toLowerCase();
                return uygunluk == 'musait' || uygunluk == 'müsait';
              }).length;

              final gorevdeSayi = model.kuryeler.where((kurye) {
                final uygunluk = kurye['uygunluk'].toString().toLowerCase();
                return uygunluk == 'görevde' || uygunluk == 'gorevde';
              }).length;

              final markers = <Marker>[
                _siparisMarker(siparisLat, siparisLng),
                ...model.kuryeler.map((kurye) {
                  final bool enYakinMi = enYakin != null &&
                      kurye['id'].toString() == enYakin.kuryeId;

                  return _kuryeMarker(
                    lat: kurye['lat'] as double,
                    lng: kurye['lng'] as double,
                    ad: kurye['adSoyad'].toString(),
                    durum: kurye['uygunluk'].toString(),
                    enYakinMi: enYakinMi,
                  );
                }),
              ];

              final String assignmentStatus =
                  (siparis['assignmentStatus'] ?? '').toString().toLowerCase();

              final String status =
                  (siparis['status'] ?? '').toString().toLowerCase();

              final bool siparisZatenAtanmis = assignmentStatus == 'assigned' ||
                  assignmentStatus == 'completed';

              final bool siparisTamamlanmis =
                  assignmentStatus == 'completed' || status == 'delivered';

              final bool siparisTeslimeHazir =
                  status == 'on_the_way' && !siparisTamamlanmis;

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sipariş: ${siparis['id']}',
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${siparis['status']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assignment: ${siparis['assignmentStatus']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Müsait: $musaitSayi   Görevde: $gorevdeSayi',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        if (enYakin != null) ...[
                          Text(
                            'En Yakın Kurye: ${enYakin.kuryeAdi}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mesafe: ${enYakin.mesafeKm.toStringAsFixed(2)} km',
                            style: const TextStyle(
                              color: Color(0xFFFFB300),
                            ),
                          ),
                        ] else
                          const Text(
                            'Müsait kurye bulunamadı.',
                            style: TextStyle(color: Colors.white70),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(siparisLat, siparisLng),
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.uybattech.sofrasofra',
                            ),
                            MarkerLayer(markers: markers),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB300),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: (enYakin == null || siparisZatenAtanmis)
                                ? null
                                : _otomatikAta,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text(
                              'Otomatik Ata',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: siparisTeslimeHazir ? _teslimEt : null,
                            icon: const Icon(Icons.check),
                            label: const Text(
                              'Teslim Et',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey.shade700),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            label: const Text('Kapat'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HaritaModeli {
  final Map<String, dynamic> siparis;
  final List<Map<String, dynamic>> kuryeler;
  final KuryeMesafeSonucu? enYakin;
  final bool bekleyenSiparisYok;

  _HaritaModeli({
    required this.siparis,
    required this.kuryeler,
    required this.enYakin,
    this.bekleyenSiparisYok = false,
  });
}
