import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EvOrdersSayfasi extends StatelessWidget {
  final String sellerId;

  const EvOrdersSayfasi({
    super.key,
    required this.sellerId,
  });

  static const Color _bg = Color(0xFF0F0F10);
  static const Color _card = Color(0xFF17181C);
  static const Color _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Ev Siparişleri',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('ev_orders')
            .where('sellerId', isEqualTo: sellerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(
                'Hata: ${snap.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz sipariş yok',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final items = (data['items'] as List?) ?? [];
              final firstItem = items.isNotEmpty
                  ? Map<String, dynamic>.from(items.first)
                  : <String, dynamic>{};

              final String title = (firstItem['title'] ?? 'Ürün').toString();
              final int price = ((data['totalPrice'] ?? 0) as num).toInt();
              final String status = (data['orderStatus'] ?? '').toString();
              final String city = (data['city'] ?? '').toString();
              final String district = (data['district'] ?? '').toString();

              return _OrderCard(
                docId: doc.id,
                title: title,
                price: price,
                status: status,
                location: '$district / $city',
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String docId;
  final String title;
  final int price;
  final String status;
  final String location;

  const _OrderCard({
    required this.docId,
    required this.title,
    required this.price,
    required this.status,
    required this.location,
  });

  static const Color _card = Color(0xFF17181C);
  static const Color _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.trim().toLowerCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            location,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$price ₺',
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Durum: $status',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          if (normalizedStatus == 'pending_vendor_approval')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('ev_orders')
                          .doc(docId)
                          .update({
                        'orderStatus': 'approved',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Kabul Et'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('ev_orders')
                          .doc(docId)
                          .update({
                        'orderStatus': 'rejected',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reddet'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
