import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class KuryeHarita extends StatefulWidget {
  final double courierLat;
  final double courierLng;
  final String? courierName;

  final double? customerLat;
  final double? customerLng;

  const KuryeHarita({
    super.key,
    required this.courierLat,
    required this.courierLng,
    this.courierName,
    this.customerLat,
    this.customerLng,
  });

  @override
  State<KuryeHarita> createState() => _KuryeHaritaState();
}

class _KuryeHaritaState extends State<KuryeHarita> {
  final MapController _mapController = MapController();

  late LatLng _animatedPosition;
  int _animationToken = 0;

  @override
  void initState() {
    super.initState();
    _animatedPosition = LatLng(widget.courierLat, widget.courierLng);

    debugPrint(
      'INIT KuryeHarita lat=${widget.courierLat}, lng=${widget.courierLng}',
    );
  }

  @override
  void didUpdateWidget(covariant KuryeHarita oldWidget) {
    super.didUpdateWidget(oldWidget);

    debugPrint(
      'UPDATE old=(${oldWidget.courierLat}, ${oldWidget.courierLng}) '
      'new=(${widget.courierLat}, ${widget.courierLng})',
    );

    final bool sameLat = oldWidget.courierLat == widget.courierLat;
    final bool sameLng = oldWidget.courierLng == widget.courierLng;

    if (sameLat && sameLng) return;

    final from = _animatedPosition;
    final to = LatLng(widget.courierLat, widget.courierLng);

    _animateCourierTo(from, to);
  }

  Future<void> _animateCourierTo(LatLng from, LatLng to) async {
    _animationToken++;
    final int myToken = _animationToken;

    const int steps = 30;
    const Duration delay = Duration(milliseconds: 40);

    for (int i = 1; i <= steps; i++) {
      if (!mounted) return;
      if (myToken != _animationToken) return;

      final double t = i / steps;
      final double lat = from.latitude + ((to.latitude - from.latitude) * t);
      final double lng = from.longitude + ((to.longitude - from.longitude) * t);
      final next = LatLng(lat, lng);

      setState(() {
        _animatedPosition = next;
      });

      try {
        _mapController.move(next, _mapController.camera.zoom);
      } catch (_) {}

      await Future.delayed(delay);
    }

    if (!mounted) return;
    if (myToken != _animationToken) return;

    setState(() {
      _animatedPosition = to;
    });

    try {
      _mapController.move(to, _mapController.camera.zoom);
    } catch (_) {}
  }

  // 📏 MESAFE (km)
  double _mesafeKm(LatLng a, LatLng b) {
    const R = 6371;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;

    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;

    final aHarita = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLng / 2) * sin(dLng / 2) * cos(lat1) * cos(lat2);

    final c = 2 * atan2(sqrt(aHarita), sqrt(1 - aHarita));

    return R * c;
  }

  // ⏱️ ETA
  String _etaDakika(double km) {
    const hiz = 30.0; // km/h
    final dakika = (km / hiz * 60).round();
    return '$dakika dk';
  }

  @override
  Widget build(BuildContext context) {
    final position = _animatedPosition;

    LatLng? musteri;
    double? km;
    String? eta;

    if (widget.customerLat != null && widget.customerLng != null) {
      musteri = LatLng(widget.customerLat!, widget.customerLng!);
      km = _mesafeKm(position, musteri);
      eta = _etaDakika(km);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courierName ?? 'Kurye Harita'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: position,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sofrasofra.app',
              ),

              // 🔵 MÜŞTERİ
              if (musteri != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: musteri,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),

              // ➖ ROTA
              if (musteri != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [position, musteri],
                      strokeWidth: 4,
                      color: Colors.orange,
                    ),
                  ],
                ),

              // 🟠 KURYE
              MarkerLayer(
                markers: [
                  Marker(
                    point: position,
                    width: 56,
                    height: 56,
                    child: const Icon(
                      Icons.motorcycle,
                      size: 42,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 📊 ÜST PANEL
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Kurye: ${widget.courierName ?? 'Bilinmiyor'}\n'
                'lat: ${widget.courierLat}\n'
                'lng: ${widget.courierLng}'
                '${km != null ? '\nMesafe: ${km.toStringAsFixed(2)} km' : ''}'
                '${eta != null ? '\nETA: $eta' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
