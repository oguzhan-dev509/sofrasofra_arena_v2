import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MusteriKuryeTakip extends StatefulWidget {
  final String orderId;

  const MusteriKuryeTakip({super.key, required this.orderId});

  @override
  State<MusteriKuryeTakip> createState() => _MusteriKuryeTakipState();
}

class _MusteriKuryeTakipState extends State<MusteriKuryeTakip> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sipariş Takibi")),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, orderSnap) {
          if (!orderSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = orderSnap.data!.data();
          if (order == null) {
            return const Center(child: Text("Sipariş bulunamadı"));
          }

          final courierId = order['assignedCourierId'];

          if (courierId == null) {
            return const Center(
              child: Text("Kurye henüz atanmadı"),
            );
          }

          final orderLat = (order['lat'] ?? 41.0).toDouble();
          final orderLng = (order['lng'] ?? 29.0).toDouble();

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('couriers')
                .doc(courierId)
                .snapshots(),
            builder: (context, courierSnap) {
              if (!courierSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final courier = courierSnap.data!.data();
              if (courier == null) {
                return const Center(child: Text("Kurye verisi yok"));
              }

              final courierLat = (courier['lat'] ?? 41.0).toDouble();
              final courierLng = (courier['lng'] ?? 29.0).toDouble();

              final courierPos = LatLng(courierLat, courierLng);
              final orderPos = LatLng(orderLat, orderLng);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.move(courierPos, 15);
              });

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: courierPos,
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: courierPos,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.delivery_dining,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                      Marker(
                        point: orderPos,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.home,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [courierPos, orderPos],
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
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
