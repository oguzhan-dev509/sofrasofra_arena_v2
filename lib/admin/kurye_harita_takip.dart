import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class KuryeHaritaTakipSistemi extends StatefulWidget {
  const KuryeHaritaTakipSistemi({super.key});

  @override
  State<KuryeHaritaTakipSistemi> createState() =>
      _KuryeHaritaTakipSistemiState();
}

class _KuryeHaritaTakipSistemiState extends State<KuryeHaritaTakipSistemi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapController _mapController = MapController();

  String _filtre = 'tum';

  final List<Map<String, String>> _filtreler = const [
    {'value': 'tum', 'label': 'Tümü'},
    {'value': 'musait', 'label': 'Müsait'},
    {'value': 'gorevde', 'label': 'Görevde'},
    {'value': 'cevrimdisi', 'label': 'Çevrimdışı'},
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> _kuryeStream() {
    return _firestore.collection('couriers').snapshots();
  }

  bool _filtreUyarMi(String uygunluk) {
    final v = uygunluk.trim().toLowerCase();

    if (_filtre == 'tum') return true;
    if (_filtre == 'musait') return v == 'musait' || v == 'available';
    if (_filtre == 'gorevde') return v == 'gorevde' || v == 'busy';
    if (_filtre == 'cevrimdisi') return v == 'cevrimdisi' || v == 'offline';
    return true;
  }

  String _uygunlukLabel(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'available':
      case 'musait':
        return 'Müsait';
      case 'busy':
      case 'gorevde':
        return 'Görevde';
      case 'offline':
      case 'cevrimdisi':
        return 'Çevrimdışı';
      default:
        return raw.isEmpty ? '-' : raw;
    }
  }

  Color _uygunlukRengi(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'available':
      case 'musait':
        return Colors.green;
      case 'busy':
      case 'gorevde':
        return Colors.orange;
      case 'offline':
      case 'cevrimdisi':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  void _kuryeDetayDialog({
    required Map<String, dynamic> data,
    required String kuryeId,
  }) {
    final ad = (data['ad'] ?? data['name'] ?? 'Kurye').toString();
    final telefon = (data['telefon'] ?? data['phone'] ?? '-').toString();
    final sehir = (data['sehir'] ?? data['city'] ?? '-').toString();
    final bolge = (data['bolge'] ?? data['zone'] ?? '-').toString();
    final plaka = (data['plaka'] ?? data['plate'] ?? '-').toString();
    final aracTipi =
        (data['aracTipi'] ?? data['vehicleType'] ?? '-').toString();
    final uygunluk =
        (data['uygunlukDurumu'] ?? data['availability'] ?? 'musait').toString();
    final isActive = (data['isActive'] ?? false) == true;
    final aktifSiparisSayisi = (data['aktifSiparisSayisi'] ?? 0).toString();
    final lat = _toDouble(data['konumLat']);
    final lng = _toDouble(data['konumLng']);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Text(
                  ad,
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                _bilgi('Kurye ID', kuryeId),
                _bilgi('Telefon', telefon),
                _bilgi('Şehir', sehir),
                _bilgi('Bölge', bolge),
                _bilgi('Plaka', plaka),
                _bilgi('Araç Tipi', aracTipi),
                _bilgi('Uygunluk', _uygunlukLabel(uygunluk)),
                _bilgi('Aktiflik', isActive ? 'Aktif' : 'Pasif'),
                _bilgi('Aktif Sipariş', aktifSiparisSayisi),
                _bilgi(
                  'Konum',
                  (lat != null && lng != null)
                      ? '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                      : '-',
                ),
                const SizedBox(height: 16),
                if (lat != null && lng != null)
                  SizedBox(
                    height: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(lat, lng),
                          initialZoom: 14,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.drag |
                                InteractiveFlag.pinchZoom,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.uybattech.sofrasofra',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat, lng),
                                width: 60,
                                height: 60,
                                child: Icon(
                                  Icons.location_on,
                                  size: 42,
                                  color: _uygunlukRengi(uygunluk),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bilgi(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFFFFB300),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _altListe(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) {
      return const Center(
        child: Text(
          'Haritada gösterilecek kurye bulunamadı',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xCC0E0E0E),
        border: Border(
          top: BorderSide(color: Color(0x22FFFFFF)),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: docs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final doc = docs[index];
          final data = doc.data();

          final ad = (data['ad'] ?? data['name'] ?? 'Kurye').toString();
          final telefon = (data['telefon'] ?? data['phone'] ?? '-').toString();
          final bolge = (data['bolge'] ?? data['zone'] ?? '-').toString();
          final uygunluk =
              (data['uygunlukDurumu'] ?? data['availability'] ?? 'musait')
                  .toString();

          final lat = _toDouble(data['konumLat']);
          final lng = _toDouble(data['konumLng']);

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (lat != null && lng != null) {
                _mapController.move(LatLng(lat, lng), 15);
              }
              _kuryeDetayDialog(data: data, kuryeId: doc.id);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x22FFB300)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _uygunlukRengi(uygunluk).withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delivery_dining,
                      color: _uygunlukRengi(uygunluk),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad,
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$telefon • $bolge',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _uygunlukRengi(uygunluk).withOpacity(0.16),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: _uygunlukRengi(uygunluk)),
                    ),
                    child: Text(
                      _uygunlukLabel(uygunluk),
                      style: TextStyle(
                        color: _uygunlukRengi(uygunluk),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
          'KURYE HARİTA TAKİP',
          style: TextStyle(
            color: Color(0xFFFFB300),
            letterSpacing: 1.2,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filtreler.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = _filtreler[index];
                  final secili = _filtre == item['value'];

                  return ChoiceChip(
                    label: Text(item['label']!),
                    selected: secili,
                    labelStyle: TextStyle(
                      color: secili ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: const Color(0xFFFFB300),
                    backgroundColor: const Color(0xFF181818),
                    side: BorderSide(
                      color: secili
                          ? const Color(0xFFFFB300)
                          : Colors.grey.shade800,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _filtre = item['value']!;
                      });
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _kuryeStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Veri okunamadı: ${snapshot.error}',
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

                final tumDocs = snapshot.data?.docs ?? [];

                final docs = tumDocs.where((doc) {
                  final data = doc.data();
                  final uygunluk = (data['uygunlukDurumu'] ??
                          data['availability'] ??
                          'musait')
                      .toString();
                  final lat = _toDouble(data['konumLat']);
                  final lng = _toDouble(data['konumLng']);

                  return _filtreUyarMi(uygunluk) && lat != null && lng != null;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Harita için konumlu kurye bulunamadı',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final firstData = docs.first.data();
                final firstLat = _toDouble(firstData['konumLat'])!;
                final firstLng = _toDouble(firstData['konumLng'])!;

                final markers = docs.map((doc) {
                  final data = doc.data();
                  final ad = (data['ad'] ?? data['name'] ?? 'Kurye').toString();
                  final uygunluk = (data['uygunlukDurumu'] ??
                          data['availability'] ??
                          'musait')
                      .toString();
                  final lat = _toDouble(data['konumLat'])!;
                  final lng = _toDouble(data['konumLng'])!;

                  return Marker(
                    point: LatLng(lat, lng),
                    width: 90,
                    height: 90,
                    child: GestureDetector(
                      onTap: () {
                        _kuryeDetayDialog(data: data, kuryeId: doc.id);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 42,
                            color: _uygunlukRengi(uygunluk),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xDD111111),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0x33FFB300),
                              ),
                            ),
                            child: Text(
                              ad,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList();

                return Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: LatLng(firstLat, firstLng),
                          initialZoom: 12,
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
                    Expanded(
                      flex: 4,
                      child: _altListe(docs),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
