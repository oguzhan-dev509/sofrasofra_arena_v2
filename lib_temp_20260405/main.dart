import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SofraApp());
}

class SofraApp extends StatelessWidget {
  const SofraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sofrasofra Arena',
      theme: ThemeData.dark(),
      home: const ReservationControlPage(),
    );
  }
}

class ReservationControlPage extends StatefulWidget {
  const ReservationControlPage({super.key});

  @override
  State<ReservationControlPage> createState() => _ReservationControlPageState();
}

class _ReservationControlPageState extends State<ReservationControlPage> {
  static const String reservationId = 'ccnNhoNC78SRAl55NwBI';

  bool _busy = false;
  String _message = '';

  DocumentReference<Map<String, dynamic>> get _ref => FirebaseFirestore.instance
      .collection('chef_table_reservations')
      .doc(reservationId);

  Future<void> _approveReservation() async {
    setState(() {
      _busy = true;
      _message = '';
    });

    try {
      final now = DateTime.now();

      await _ref.update({
        'status': 'approved',
        'paymentStatus': 'awaiting_payment',
        'reservationFlowStatus': 'awaiting_payment',
        'paymentProvider': 'iyzico',
        'paymentExpireAt': Timestamp.fromDate(
          now.add(const Duration(minutes: 15)),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _message = 'Rezervasyon onaylandı.';
      });
    } catch (e) {
      setState(() {
        _message = 'Onay hatası: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _generateFreshPaymentLink() async {
    setState(() {
      _busy = true;
      _message = '';
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('initializeChefTablePayment');

      final result = await callable.call(<String, dynamic>{
        'reservationId': reservationId,
      });

      setState(() {
        _message = 'Yeni ödeme linki üretildi.';
      });

      debugPrint('initializeChefTablePayment result: ${result.data}');
    } catch (e) {
      setState(() {
        _message = 'Ödeme linki üretilemedi: $e';
      });
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _openPayment(String? url) async {
    if (url == null || url.trim().isEmpty) {
      setState(() {
        _message = 'Ödeme linki bulunamadı.';
      });
      return;
    }

    final uri = Uri.parse(url);

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      setState(() {
        _message = 'Ödeme sayfası açılamadı.';
      });
    }
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value?.toString() ?? '-'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervasyon Kontrol'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _ref.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final checkoutUrl = data?['iyzicoCheckoutUrl']?.toString();
          final status = data?['status']?.toString();
          final paymentStatus = data?['paymentStatus']?.toString();
          final flowStatus = data?['reservationFlowStatus']?.toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aktif Rezervasyon',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _infoRow('Doc ID', reservationId),
                _infoRow('status', status),
                _infoRow('paymentStatus', paymentStatus),
                _infoRow('reservationFlowStatus', flowStatus),
                _infoRow('tableTitle', data?['tableTitle']),
                _infoRow('totalPrice', data?['totalPrice']),
                _infoRow('iyzicoCheckoutUrl', checkoutUrl),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: _busy ? null : _approveReservation,
                      child: const Text('Onayla'),
                    ),
                    ElevatedButton(
                      onPressed: _busy ? null : _generateFreshPaymentLink,
                      child: const Text('Yeni ödeme linki üret'),
                    ),
                    ElevatedButton(
                      onPressed: _busy ? null : () => _openPayment(checkoutUrl),
                      child: const Text('Ödemeyi Aç'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_busy) const CircularProgressIndicator(),
                if (_message.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_message),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
