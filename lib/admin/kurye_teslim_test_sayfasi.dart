import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/kurye_teslim_servisi.dart';
import '../services/otomatik_yeniden_atama_servisi.dart';

class KuryeTeslimTestSayfasi extends StatefulWidget {
  const KuryeTeslimTestSayfasi({super.key});

  @override
  State<KuryeTeslimTestSayfasi> createState() => _KuryeTeslimTestSayfasiState();
}

class _KuryeTeslimTestSayfasiState extends State<KuryeTeslimTestSayfasi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _testOrderId = 'test_order_2';

  bool _assigning = false;
  bool _delivering = false;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _siparisStream() {
    return _firestore.collection('orders').doc(_testOrderId).snapshots();
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

  Future<void> _kuryeAtaVeyaYenidenDene() async {
    if (_assigning) return;

    setState(() {
      _assigning = true;
    });

    try {
      await OtomatikYenidenAtamaServisi().ilkAtamayiBaslat(
        orderId: _testOrderId,
      );

      await _firestore.collection('orders').doc(_testOrderId).set({
        'courierAssignmentTriggered': true,
        'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
        'courierAssignmentResult': 'manual_triggered_from_test_screen',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kurye atama / yeniden deneme tetiklendi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kurye atama hatası: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _assigning = false;
        });
      }
    }
  }

  Future<void> _teslimEt() async {
    if (_delivering) return;

    setState(() {
      _delivering = true;
    });

    try {
      await KuryeTeslimServisi.teslimEt(orderId: _testOrderId);

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
    } finally {
      if (mounted) {
        setState(() {
          _delivering = false;
        });
      }
    }
  }

  Color _statusColor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'assigned':
        return Colors.green;
      case 'offer_sent':
        return Colors.blue;
      case 'retry_scheduled':
        return Colors.orange;
      case 'manual_review_required':
        return Colors.red;
      case 'waiting_courier':
        return Colors.deepOrange;
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      case 'no_courier_found':
        return Colors.redAccent;
      default:
        return Colors.brown;
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        text.isEmpty ? '-' : text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
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
          final String retryStatus = (data['retryStatus'] ?? '').toString();
          final String assignmentResult =
              (data['courierAssignmentResult'] ?? '').toString();

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
                  Text(
                    'Test Siparişi: $_testOrderId',
                    style: const TextStyle(
                      color: Color(0xFFFFB300),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge(assignmentStatus, _statusColor(assignmentStatus)),
                      if (retryStatus.isNotEmpty)
                        _badge(retryStatus, _statusColor(retryStatus)),
                      if (status.isNotEmpty)
                        _badge(status, _statusColor(status)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _satir('Status', status),
                  _satir('Assignment Status', assignmentStatus),
                  _satir('Retry Status', retryStatus),
                  _satir('Assignment Result', assignmentResult),
                  _satir('Assigned Courier ID', assignedCourierId),
                  _satir('Assigned Courier Name', assignedCourierName),
                  _satir('Assignment Type', courierType),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _assigning ? Colors.grey.shade700 : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _assigning ? null : _kuryeAtaVeyaYenidenDene,
                      icon: _assigning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.local_shipping_outlined),
                      label: Text(
                        _assigning
                            ? 'Kurye Atama Çalışıyor...'
                            : 'Kurye Ata / Yeniden Dene',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teslimEdilebilir && !_delivering
                            ? Colors.green
                            : Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed:
                          teslimEdilebilir && !_delivering ? _teslimEt : null,
                      icon: _delivering
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _delivering ? 'Teslim Ediliyor...' : 'Teslim Et',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    teslimEdilebilir
                        ? 'Sipariş teslim edilmeye hazır.'
                        : 'Önce kurye atama yapılmalı. assignmentStatus = assigned olduğunda teslim açılır.',
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
