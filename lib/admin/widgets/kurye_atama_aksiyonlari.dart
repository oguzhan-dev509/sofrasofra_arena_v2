import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/otomatik_yeniden_atama_servisi.dart';

class KuryeAtamaAksiyonlari extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> orderData;

  const KuryeAtamaAksiyonlari({
    super.key,
    required this.orderId,
    required this.orderData,
  });

  @override
  State<KuryeAtamaAksiyonlari> createState() => _KuryeAtamaAksiyonlariState();
}

class _KuryeAtamaAksiyonlariState extends State<KuryeAtamaAksiyonlari> {
  bool _loading = false;

  String get _assignmentStatus =>
      (widget.orderData['assignmentStatus'] ?? '').toString().trim();

  String get _assignedCourierName =>
      (widget.orderData['assignedCourierName'] ?? '').toString().trim();

  String get _retryStatus =>
      (widget.orderData['retryStatus'] ?? '').toString().trim();

  Future<void> _kuryeAtaVeyaYenidenDene() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    try {
      await OtomatikYenidenAtamaServisi().ilkAtamayiBaslat(
        orderId: widget.orderId,
      );

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .set({
        'courierAssignmentTriggered': true,
        'courierAssignmentCheckedAt': FieldValue.serverTimestamp(),
        'courierAssignmentResult': 'manual_triggered_from_admin',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kurye atama denemesi başlatıldı.'),
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
          _loading = false;
        });
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
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
        return Colors.green;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.brown;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'assigned':
        return 'Kurye Atandı';
      case 'offer_sent':
        return 'Teklif Gönderildi';
      case 'retry_scheduled':
        return 'Retry Planlandı';
      case 'manual_review_required':
        return 'Manuel Müdahale';
      case 'waiting_courier':
        return 'Kurye Bekleniyor';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      case 'no_courier_found':
        return 'Kurye Bulunamadı';
      default:
        return status.isEmpty ? 'Bilinmiyor' : status;
    }
  }

  Color _retryColor(String retryStatus) {
    switch (retryStatus) {
      case 'scheduled':
        return Colors.orange;
      case 'retrying':
        return Colors.blue;
      case 'idle':
        return Colors.green;
      case 'exhausted':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _retryLabel(String retryStatus) {
    switch (retryStatus) {
      case 'scheduled':
        return 'Retry Scheduled';
      case 'retrying':
        return 'Retrying';
      case 'idle':
        return 'Retry Idle';
      case 'exhausted':
        return 'Retry Exhausted';
      default:
        return retryStatus.isEmpty ? 'Retry Yok' : retryStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _assignmentStatus;
    final retryStatus = _retryStatus;
    final courierName = _assignedCourierName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border:
                    Border.all(color: _statusColor(status).withOpacity(0.35)),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                  color: _statusColor(status),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            if (retryStatus.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _retryColor(retryStatus).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: _retryColor(retryStatus).withOpacity(0.35)),
                ),
                child: Text(
                  _retryLabel(retryStatus),
                  style: TextStyle(
                    color: _retryColor(retryStatus),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (courierName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Atanan Kurye: $courierName',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _kuryeAtaVeyaYenidenDene,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.local_shipping_outlined),
              label:
                  Text(_loading ? 'Çalışıyor...' : 'Kurye Ata / Yeniden Dene'),
            ),
          ],
        ),
      ],
    );
  }
}
