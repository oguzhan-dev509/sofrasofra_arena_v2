import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'musteri_canli_kurye_takip_haritasi.dart';

class MusteriCanliKuryeTakipHaritasi extends StatelessWidget {
  final String orderId;

  const MusteriCanliKuryeTakipHaritasi({
    super.key,
    required this.orderId,
  });

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Widget _loading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFFFB300),
      ),
    );
  }

  Widget _error(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _empty(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  String _safeString(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'on_the_way':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Hazırlık / Atama';
      case 'on_the_way':
        return 'Kurye Yolda';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal';
      default:
        return status;
    }
  }

  Marker _siparisMarker({
    required double lat,
    required double lng,
  }) {
    return Marker(
      point: LatLng(lat, lng),
      width: 90,
      height: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.location_on,
            color: Colors.red,
            size: 38,
          ),
          Text(
            'Teslimat Noktası',
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
    required String kuryeAdi,
  }) {
    return Marker(
      point: LatLng(lat, lng),
      width: 90,
      height: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.delivery_dining,
            color: Color(0xFFFFB300),
            size: 36,
          ),
          Text(
            kuryeAdi,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
          'CANLI KURYE TAKİBİ',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('orders').doc(orderId).snapshots(),
        builder: (context, orderSnapshot) {
          if (orderSnapshot.hasError) {
            return _error('Sipariş verisi okunamadı.');
          }

          if (!orderSnapshot.hasData) {
            return _loading();
          }

          final orderDoc = orderSnapshot.data!;
          if (!orderDoc.exists) {
            return _empty('Sipariş bulunamadı.');
          }

          final orderData = orderDoc.data() ?? {};

          final double? siparisLat = _toDouble(orderData['lat']);
          final double? siparisLng = _toDouble(orderData['lng']);

          if (siparisLat == null || siparisLng == null) {
            return _empty('Sipariş konumu bulunamadı.');
          }

          final String status = _safeString(
              orderData['status'] ?? orderData['durum'],
              fallback: 'pending');

          final String musteriAd =
              _safeString(orderData['musteriAd'], fallback: 'Müşteri');

          final String adres = _safeString(
            orderData['teslimatAdresi'] ?? orderData['adres'],
            fallback: 'Adres yok',
          );

          final String kuryeId =
              _safeString(orderData['assignedCourierId'], fallback: '');

          final String kuryeAdi = _safeString(
            orderData['assignedCourierName'],
            fallback: 'Kurye',
          );

          if (kuryeId.isEmpty) {
            return Column(
              children: [
                Container(
                  width: double.infinity,
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
                      const Text(
                        'Sipariş Bilgisi',
                        style: TextStyle(
                          color: Color(0xFFFFB300),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Müşteri: $musteriAd',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Durum: ${_statusLabel(status)}',
                        style: TextStyle(color: _statusColor(status)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Adres: $adres',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
                          MarkerLayer(
                            markers: [
                              _siparisMarker(lat: siparisLat, lng: siparisLng),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33FFB300)),
                  ),
                  child: const Text(
                    'Kurye henüz atanmadı. Atama yapıldığında canlı takip başlayacak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            );
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('couriers').doc(kuryeId).snapshots(),
            builder: (context, courierSnapshot) {
              if (courierSnapshot.hasError) {
                return _error('Kurye verisi okunamadı.');
              }

              if (!courierSnapshot.hasData) {
                return _loading();
              }

              final courierDoc = courierSnapshot.data!;
              if (!courierDoc.exists) {
                return _empty('Kurye kaydı bulunamadı.');
              }

              final courierData = courierDoc.data() ?? {};

              final double? kuryeLat = _toDouble(courierData['lat']);
              final double? kuryeLng = _toDouble(courierData['lng']);

              final String telefon =
                  _safeString(courierData['telefon'], fallback: '-');

              final String uygunluk =
                  _safeString(courierData['uygunluk'], fallback: 'Bilinmiyor');

              final markers = <Marker>[
                _siparisMarker(lat: siparisLat, lng: siparisLng),
              ];

              if (kuryeLat != null && kuryeLng != null) {
                markers.add(
                  _kuryeMarker(
                    lat: kuryeLat,
                    lng: kuryeLng,
                    kuryeAdi: kuryeAdi,
                  ),
                );
              }

              final centerLat = kuryeLat ?? siparisLat;
              final centerLng = kuryeLng ?? siparisLng;

              return Column(
                children: [
                  Container(
                    width: double.infinity,
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
                        const Text(
                          'Canlı Takip Bilgisi',
                          style: TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Müşteri: $musteriAd',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kurye: $kuryeAdi',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kurye Telefon: $telefon',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kurye Durumu: $uygunluk',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sipariş Durumu: ${_statusLabel(status)}',
                          style: TextStyle(color: _statusColor(status)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Teslimat Adresi: $adres',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(centerLat, centerLng),
                            initialZoom: 14.5,
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
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x33FFB300)),
                    ),
                    child: const Text(
                      'Haritadaki kırmızı işaret teslimat noktasını, sarı kurye işareti ise canlı kurye konumunu gösterir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
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
