import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class KuryeHaritaWidget extends StatelessWidget {
  final String courierId;

  const KuryeHaritaWidget({
    super.key,
    required this.courierId,
  });

  @override
  Widget build(BuildContext context) {
    // Kurye yoksa hiçbir şey gösterme
    if (courierId.isEmpty) {
      return const SizedBox();
    }

    return SizedBox(
      height: 250,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('couriers')
            .doc(courierId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();

          if (data == null) {
            return const Center(child: Text('Kurye verisi yok'));
          }

          final lat = data['lat'];
          final lng = data['lng'];

          if (lat == null || lng == null) {
            return const Center(child: Text('Kurye konumu bekleniyor'));
          }

          final position = LatLng(
            (lat is int) ? lat.toDouble() : lat,
            (lng is int) ? lng.toDouble() : lng,
          );

          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: position,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 50,
                      height: 50,
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
          );
        },
      ),
    );
  }
}
