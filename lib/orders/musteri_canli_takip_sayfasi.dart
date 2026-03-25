import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MusteriCanliTakipSayfasi extends StatelessWidget {
  final String orderId;

  const MusteriCanliTakipSayfasi({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Takibi'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, orderSnap) {
          if (!orderSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orderData = orderSnap.data!.data();

          if (orderData == null) {
            return const Center(child: Text('Sipariş bulunamadı'));
          }

          final courierId = (orderData['assignedCourierId'] ?? '').toString();

          return Column(
            children: [
              _buildOrderInfo(orderData),
              const SizedBox(height: 10),
              if (courierId.isNotEmpty)
                Expanded(
                  child: _buildCourierMap(courierId),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Henüz kurye atanmadı'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderInfo(Map<String, dynamic> data) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sipariş No: ${data['siparisNo'] ?? ''}'),
              Text('Durum: ${data['status'] ?? ''}'),
              Text('Adres: ${data['adres'] ?? ''}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourierMap(String courierId) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('couriers')
          .doc(courierId)
          .snapshots(),
      builder: (context, courierSnap) {
        if (!courierSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final courierData = courierSnap.data!.data();

        if (courierData == null) {
          return const Center(child: Text('Kurye verisi yok'));
        }

        final lat = courierData['lat'];
        final lng = courierData['lng'];

        if (lat == null || lng == null) {
          return const Center(child: Text('Kurye konumu bekleniyor'));
        }

        final pos = LatLng(
          (lat is int) ? lat.toDouble() : lat,
          (lng is int) ? lng.toDouble() : lng,
        );

        return FlutterMap(
          options: MapOptions(
            initialCenter: pos,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pos,
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
        );
      },
    );
  }
}
