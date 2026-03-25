import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'kurye_harita.dart';
import '../services/kurye_konum_servisi.dart';

class KuryeCanliTakipSayfasi extends StatefulWidget {
  final String courierId;

  const KuryeCanliTakipSayfasi({
    super.key,
    required this.courierId,
  });

  @override
  State<KuryeCanliTakipSayfasi> createState() => _KuryeCanliTakipSayfasiState();
}

class _KuryeCanliTakipSayfasiState extends State<KuryeCanliTakipSayfasi> {
  bool _gpsBasladi = false;
  bool _islemde = false;

  @override
  void dispose() {
    KuryeKonumServisi.durdur();
    super.dispose();
  }

  Future<void> _tekSeferGonder() async {
    setState(() => _islemde = true);
    try {
      await KuryeKonumServisi.tekSeferGonder(
        courierId: widget.courierId,
      );
    } finally {
      if (mounted) {
        setState(() => _islemde = false);
      }
    }
  }

  Future<void> _canliGpsBaslat() async {
    setState(() => _islemde = true);
    try {
      await KuryeKonumServisi.baslat(
        courierId: widget.courierId,
      );
      if (mounted) {
        setState(() {
          _gpsBasladi = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _islemde = false);
      }
    }
  }

  Future<void> _canliGpsDurdur() async {
    setState(() => _islemde = true);
    try {
      await KuryeKonumServisi.durdur();
      if (mounted) {
        setState(() {
          _gpsBasladi = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _islemde = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('TAKIP SAYFASI ACILDI courierId=${widget.courierId}');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('couriers')
          .doc(widget.courierId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Canlı Kurye Takibi'),
            ),
            body: Center(
              child: Text('Kurye yükleniyor...\nDocId: ${widget.courierId}'),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint(
            'STREAM ERROR courierId=${widget.courierId} error=${snapshot.error}',
          );

          return Scaffold(
            appBar: AppBar(
              title: const Text('Canlı Kurye Takibi'),
            ),
            body: Center(
              child: Text(
                'Hata oluştu.\nDocId: ${widget.courierId}\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint('STREAM DOC YOK courierId=${widget.courierId}');

          return Scaffold(
            appBar: AppBar(
              title: const Text('Canlı Kurye Takibi'),
            ),
            body: Center(
              child: Text(
                'Kurye verisi bulunamadı.\nDocId: ${widget.courierId}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final data = snapshot.data!.data();

        if (data == null) {
          debugPrint('STREAM DATA NULL courierId=${widget.courierId}');

          return Scaffold(
            appBar: AppBar(
              title: const Text('Canlı Kurye Takibi'),
            ),
            body: Center(
              child: Text(
                'Kurye verisi boş geldi.\nDocId: ${widget.courierId}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final dynamic rawLat = data['lat'];
        final dynamic rawLng = data['lng'];

        final double? lat = _toDouble(rawLat);
        final double? lng = _toDouble(rawLng);
        final String name = (data['adSoyad'] ?? 'Kurye').toString();

        debugPrint(
          'STREAM DOC courierId=${widget.courierId} '
          'name=$name lat=$rawLat lng=$rawLng',
        );

        if (lat == null || lng == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Canlı Kurye Takibi'),
            ),
            body: Center(
              child: Text(
                'Geçersiz konum verisi.\n'
                'DocId: ${widget.courierId}\n'
                'Ad: $name\n'
                'lat=$rawLat\n'
                'lng=$rawLng',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Canlı Kurye Takibi'),
          ),
          body: Stack(
            children: [
              KuryeHarita(
                courierLat: lat,
                courierLng: lng,
                courierName: name,
                customerLat: 40.995,
                customerLng: 29.035,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: _islemde ? null : _tekSeferGonder,
                      child: const Text('Konumu 1 Kez Gönder'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          _islemde || _gpsBasladi ? null : _canliGpsBaslat,
                      child: const Text('Canlı GPS Başlat'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed:
                          _islemde || !_gpsBasladi ? null : _canliGpsDurdur,
                      child: const Text('Canlı GPS Durdur'),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'docId: ${widget.courierId}\n'
                    'ad: $name\n'
                    'lat: $lat\n'
                    'lng: $lng\n'
                    'gps: ${_gpsBasladi ? "aktif" : "kapalı"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
