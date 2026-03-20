import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class KuryeHarita extends StatefulWidget {
  final String courierId;

  const KuryeHarita({super.key, required this.courierId});

  @override
  State<KuryeHarita> createState() => _KuryeHaritaState();
}

class _KuryeHaritaState extends State<KuryeHarita> {
  final MapController _mapController = MapController();
  double _currentZoom = 15;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kurye Takip")),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('couriers')
            .doc(widget.courierId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(
              child: Text("Kurye verisi bulunamadı"),
            );
          }

          final lat = (data['lat'] ?? 41.0).toDouble();
          final lng = (data['lng'] ?? 29.0).toDouble();
          final position = LatLng(lat, lng);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            try {
              _mapController.move(position, _currentZoom);
            } catch (_) {}
          });

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: position,
                  initialZoom: _currentZoom,
                  onPositionChanged: (camera, hasGesture) {
                    _currentZoom = camera.zoom;
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: position,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'lat: ${lat.toStringAsFixed(6)}\nlng: ${lng.toStringAsFixed(6)}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
