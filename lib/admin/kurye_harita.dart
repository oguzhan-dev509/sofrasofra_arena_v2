import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class KuryeHarita extends StatefulWidget {
  const KuryeHarita({super.key});

  @override
  State<KuryeHarita> createState() => _KuryeHaritaState();
}

class _KuryeHaritaState extends State<KuryeHarita> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _filtre = 'tum';

  List<_KuryeHaritaModel> _filtrele(List<_KuryeHaritaModel> liste) {
    switch (_filtre) {
      case 'aktif':
        return liste.where((e) => e.isActive).toList();
      case 'pasif':
        return liste.where((e) => !e.isActive).toList();
      case 'musait':
        return liste.where((e) => e.uygunlukDurumu == 'musait').toList();
      case 'gorevde':
        return liste.where((e) => e.uygunlukDurumu == 'gorevde').toList();
      default:
        return liste;
    }
  }

  Color _durumRengi(_KuryeHaritaModel kurye) {
    if (!kurye.isActive) return Colors.redAccent;

    switch (kurye.uygunlukDurumu) {
      case 'musait':
        return Colors.green;
      case 'gorevde':
        return Colors.orange;
      case 'cevrimdisi':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  String _durumLabel(_KuryeHaritaModel kurye) {
    if (!kurye.isActive) return 'Pasif';

    switch (kurye.uygunlukDurumu) {
      case 'musait':
        return 'Müsait';
      case 'gorevde':
        return 'Görevde';
      case 'cevrimdisi':
        return 'Çevrimdışı';
      default:
        return kurye.uygunlukDurumu.isEmpty ? '-' : kurye.uygunlukDurumu;
    }
  }

  LatLng _merkezBelirle(List<_KuryeHaritaModel> kuryeler) {
    if (kuryeler.isNotEmpty) {
      return LatLng(kuryeler.first.lat, kuryeler.first.lng);
    }
    return const LatLng(41.0082, 28.9784);
  }

  void _kuryeDetayGoster(_KuryeHaritaModel kurye) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _durumRengi(kurye).withAlpha(46),
                    child: Icon(
                      Icons.delivery_dining,
                      color: _durumRengi(kurye),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      kurye.ad,
                      style: const TextStyle(
                        color: Color(0xFFFFB300),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _durumRengi(kurye).withAlpha(40),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _durumRengi(kurye)),
                    ),
                    child: Text(
                      _durumLabel(kurye),
                      style: TextStyle(
                        color: _durumRengi(kurye),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _detaySatiri('Kurye ID', kurye.id),
              _detaySatiri('Telefon', kurye.telefon),
              _detaySatiri('Şehir', kurye.sehir),
              _detaySatiri('İlçe', kurye.ilce),
              _detaySatiri('Araç Tipi', kurye.aracTipi),
              _detaySatiri('Aktiflik', kurye.isActive ? 'Aktif' : 'Pasif'),
              _detaySatiri('Uygunluk', _durumLabel(kurye)),
              _detaySatiri('Enlem', kurye.lat.toString()),
              _detaySatiri('Boylam', kurye.lng.toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _detaySatiri(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Colors.white),
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

  Widget _filtreChip(String value, String label) {
    final secili = _filtre == value;

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
          _filtre = value;
        });
      },
    );
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
          'KURYE HARİTA MERKEZİ',
          style: TextStyle(
            color: Color(0xFFFFB300),
            letterSpacing: 1.1,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('couriers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Harita verisi okunamadı: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
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

          final tumKuryeler = snapshot.data?.docs
                  .map((doc) => _KuryeHaritaModel.fromDoc(doc))
                  .where((kurye) => kurye.lat != 0 && kurye.lng != 0)
                  .toList() ??
              [];

          final kuryeler = _filtrele(tumKuryeler);
          final merkez = _merkezBelirle(kuryeler);

          return Column(
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
                            icon: Icons.delivery_dining,
                            label: 'Kurye',
                            value: '${kuryeler.length}',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ustKart(
                            icon: Icons.map,
                            label: 'Merkez',
                            value: kuryeler.isEmpty
                                ? 'Yok'
                                : '${kuryeler.first.sehir.isEmpty ? '-' : kuryeler.first.sehir}/${kuryeler.first.ilce.isEmpty ? '-' : kuryeler.first.ilce}',
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
                          _filtreChip('aktif', 'Aktif'),
                          const SizedBox(width: 8),
                          _filtreChip('pasif', 'Pasif'),
                          const SizedBox(width: 8),
                          _filtreChip('musait', 'Müsait'),
                          const SizedBox(width: 8),
                          _filtreChip('gorevde', 'Görevde'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: kuryeler.isEmpty
                    ? const Center(
                        child: Text(
                          'Haritada gösterilecek kurye bulunamadı.\nlat / lng alanlarını kontrol edin.',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : FlutterMap(
                        options: MapOptions(
                          initialCenter: merkez,
                          initialZoom: 12.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.uybattech.sofrasofra_arena',
                          ),
                          MarkerLayer(
                            markers: kuryeler.map((kurye) {
                              return Marker(
                                point: LatLng(kurye.lat, kurye.lng),
                                width: 120,
                                height: 70,
                                child: GestureDetector(
                                  onTap: () => _kuryeDetayGoster(kurye),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.delivery_dining,
                                        color: _durumRengi(kurye),
                                        size: 34,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _durumRengi(kurye),
                                          ),
                                        ),
                                        child: Text(
                                          kurye.ad,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KuryeHaritaModel {
  final String id;
  final String ad;
  final String telefon;
  final bool isActive;
  final String uygunlukDurumu;
  final double lat;
  final double lng;
  final String sehir;
  final String ilce;
  final String aracTipi;

  const _KuryeHaritaModel({
    required this.id,
    required this.ad,
    required this.telefon,
    required this.isActive,
    required this.uygunlukDurumu,
    required this.lat,
    required this.lng,
    required this.sehir,
    required this.ilce,
    required this.aracTipi,
  });

  factory _KuryeHaritaModel.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return _KuryeHaritaModel(
      id: doc.id,
      ad: (data['ad'] ?? data['name'] ?? 'Kurye').toString(),
      telefon: (data['telefon'] ?? data['phone'] ?? '-').toString(),
      isActive: (data['isActive'] ?? false) == true,
      uygunlukDurumu:
          (data['uygunlukDurumu'] ?? data['availability'] ?? 'musait')
              .toString()
              .trim()
              .toLowerCase(),
      lat: _toDouble(data['lat']) ?? 0,
      lng: _toDouble(data['lng']) ?? 0,
      sehir: (data['sehir'] ?? data['city'] ?? '').toString(),
      ilce: (data['ilce'] ?? '').toString(),
      aracTipi: (data['aracTipi'] ?? data['vehicleType'] ?? '-').toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
