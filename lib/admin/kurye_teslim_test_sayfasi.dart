import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/kurye_teslim_servisi.dart';

class KuryeTeslimTestSayfasi extends StatefulWidget {
  const KuryeTeslimTestSayfasi({super.key});

  @override
  State<KuryeTeslimTestSayfasi> createState() => _KuryeTeslimTestSayfasiState();
}

class _KuryeTeslimTestSayfasiState extends State<KuryeTeslimTestSayfasi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _siparisStream() {
    return _firestore.collection('orders').doc('test_order_2').snapshots();
  }

  Widget _satir(String label, String value) {
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
              text: value.isEmpty ? '-' : value,
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

  Future<void> _teslimEt() async {
    try {
      await KuryeTeslimServisi.teslimEt(orderId: 'test_order_2');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş teslim edildi, kurye serbest bırakıldı.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teslim hatası: $e'),
        ),
      );
    }
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
          'KURYE TESLİM TEST',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 14,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _siparisStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Sipariş okunamadı: ${snapshot.error}',
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

          final doc = snapshot.data;

          if (doc == null || !doc.exists) {
            return const Center(
              child: Text(
                'test_order_2 bulunamadı.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = doc.data() ?? {};

          final String assignmentStatus =
              (data['assignmentStatus'] ?? '').toString();
          final String status = (data['status'] ?? '').toString();
          final String assignedCourierId =
              (data['assignedCourierId'] ?? '').toString();
          final String assignedCourierName =
              (data['assignedCourierName'] ?? '').toString();
          final String courierType =
              (data['courierAssignmentType'] ?? '').toString();

          final bool teslimEdilebilir =
              assignmentStatus.toLowerCase() == 'assigned';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Siparişi: test_order_2',
                    style: TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _satir('Status', status),
                  _satir('Assignment Status', assignmentStatus),
                  _satir('Assigned Courier ID', assignedCourierId),
                  _satir('Assigned Courier Name', assignedCourierName),
                  _satir('Assignment Type', courierType),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teslimEdilebilir
                            ? Colors.green
                            : Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: teslimEdilebilir ? _teslimEt : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text(
                        'Teslim Et',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    teslimEdilebilir
                        ? 'Sipariş teslim edilmeye hazır.'
                        : 'Teslim işlemi için assignmentStatus = assigned olmalı.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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
}
