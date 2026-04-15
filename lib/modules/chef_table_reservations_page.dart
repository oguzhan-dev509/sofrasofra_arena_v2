import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum ReservationFilter {
  all,
  awaitingPayment,
  approved,
  completed,
  rejected,
}

class ChefTableReservationsPage extends StatefulWidget {
  final ReservationFilter initialFilter;

  const ChefTableReservationsPage({
    super.key,
    this.initialFilter = ReservationFilter.all,
  });

  @override
  State<ChefTableReservationsPage> createState() =>
      _ChefTableReservationsPageState();
}

class _ChefTableReservationsPageState extends State<ChefTableReservationsPage> {
  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Colors.black;
  static const Color _card = Color(0xFF171717);

  final String chefId = 'RhkyTCD5TgWJFdEzP50mvCOrz5a2';
  late ReservationFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  Timestamp? _asTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return null;
  }

  Future<void> _updateReservationStatus(
    BuildContext context, {
    required String docId,
    required String newStatus,
  }) async {
    try {
      final now = DateTime.now();

      final Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'approved') {
        updateData['paymentStatus'] = 'awaiting_payment';
        updateData['reservationFlowStatus'] = 'awaiting_payment';
        updateData['paymentProvider'] = 'iyzico';
        updateData['paymentExpireAt'] = Timestamp.fromDate(
          now.add(const Duration(minutes: 15)),
        );
      } else if (newStatus == 'rejected') {
        updateData['paymentStatus'] = 'not_required';
        updateData['reservationFlowStatus'] = 'rejected';
        updateData['paymentExpireAt'] = null;
      }

      await FirebaseFirestore.instance
          .collection('chef_table_reservations')
          .doc(docId)
          .update(updateData);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'approved'
                ? 'Rezervasyon onaylandı.'
                : 'Rezervasyon reddedildi.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellenemedi: $e'),
        ),
      );
    }
  }

  Future<void> _startOrOpenPayment(
    BuildContext context, {
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    try {
      String checkoutUrl = (data['iyzicoCheckoutUrl'] ?? '').toString().trim();

      final paymentStatus = (data['paymentStatus'] ?? '').toString();
      final status = (data['status'] ?? '').toString();

      if (status != 'approved' || paymentStatus != 'awaiting_payment') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu rezervasyon ödeme başlatma için uygun değil.'),
          ),
        );
        return;
      }

      final shouldReinitialize = true;

      if (shouldReinitialize) {
        final callable = FirebaseFunctions.instanceFor(
          region: 'europe-west1',
        ).httpsCallable('initializeChefTablePayment');

        final response = await callable.call(<String, dynamic>{
          'reservationId': docId,
        });

        final responseData = Map<String, dynamic>.from(response.data as Map);
        checkoutUrl = (responseData['checkoutUrl'] ?? '').toString().trim();

        if (checkoutUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yeni ödeme bağlantısı üretilemedi.'),
            ),
          );
          return;
        }
      }

      final uri = Uri.tryParse(checkoutUrl);

      if (uri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme bağlantısı geçersiz.'),
          ),
        );
        return;
      }

      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ödeme ekranı açılamadı.'),
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ödeme başlatılamadı: ${e.message ?? e.code}'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ödeme başlatılamadı: $e'),
        ),
      );
    }
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString();
    final paymentStatus = (data['paymentStatus'] ?? '').toString();
    final flowStatus = (data['reservationFlowStatus'] ?? '').toString();

    switch (_selectedFilter) {
      case ReservationFilter.all:
        return true;

      case ReservationFilter.awaitingPayment:
        return paymentStatus == 'awaiting_payment';

      case ReservationFilter.approved:
        return (status == 'approved' || flowStatus == 'awaiting_payment') &&
            paymentStatus != 'paid';

      case ReservationFilter.completed:
        return status == 'completed' ||
            flowStatus == 'completed' ||
            paymentStatus == 'paid' ||
            flowStatus == 'confirmed';

      case ReservationFilter.rejected:
        return status == 'rejected' ||
            status == 'cancelled' ||
            flowStatus == 'rejected';
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  String _formatPaymentStatus(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'awaiting_payment':
        return 'Ödeme bekleniyor';
      case 'paid':
        return 'Ödeme tamamlandı';
      case 'not_required':
        return 'Ödeme gerekmiyor';
      case 'expired':
        return 'Süresi doldu';
      default:
        return paymentStatus.isEmpty ? '-' : paymentStatus;
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';

    final dt = ts.toDate();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');

    return '$day.$month.$year  $hour:$minute';
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '-';

    if (value is int) return '$value TL';
    if (value is double) return '${value.toStringAsFixed(0)} TL';

    final parsed = int.tryParse(value.toString());
    if (parsed != null) return '$parsed TL';

    return value.toString();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
        return Colors.greenAccent;
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent;
      case 'pending':
      default:
        return Colors.orangeAccent;
    }
  }

  Color _paymentColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'paid':
        return Colors.greenAccent;
      case 'awaiting_payment':
        return _gold;
      case 'expired':
        return Colors.redAccent;
      case 'not_required':
      default:
        return Colors.white70;
    }
  }

  Widget _filterChip(String text, ReservationFilter filter) {
    final selected = _selectedFilter == filter;

    return GestureDetector(
      onTap: () {
        if (_selectedFilter == filter) return;
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _gold : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _gold : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip('Tümü', ReservationFilter.all),
          const SizedBox(width: 8),
          _filterChip('Ödeme Bekleyenler', ReservationFilter.awaitingPayment),
          const SizedBox(width: 8),
          _filterChip('Onaylananlar', ReservationFilter.approved),
          const SizedBox(width: 8),
          _filterChip('Tamamlananlar', ReservationFilter.completed),
          const SizedBox(width: 8),
          _filterChip('İptal / Reddedilenler', ReservationFilter.rejected),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight:
                    valueColor != null ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reservationCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final tableTitle = (data['tableTitle'] ?? 'Rezervasyon').toString();
    final concept = (data['concept'] ?? '').toString();
    final guestCount = data['guestCount'];
    final totalPrice = data['totalPrice'];
    final status = (data['status'] ?? '').toString();
    final paymentStatus = (data['paymentStatus'] ?? '').toString();
    final checkoutUrl = (data['iyzicoCheckoutUrl'] ?? '').toString();
    final hasCheckoutUrl = checkoutUrl.trim().isNotEmpty;
    final canOpenPayment = paymentStatus == 'awaiting_payment';
    final dateTs = _asTimestamp(data['date']);
    final createdAtTs = _asTimestamp(data['createdAt']);

    final isPending = status == 'pending';

    return Card(
      color: _card,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tableTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (concept.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                concept,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _infoLine(
              'Durum',
              _formatStatus(status),
              valueColor: _statusColor(status),
            ),
            _infoLine(
              'Ödeme',
              _formatPaymentStatus(paymentStatus),
              valueColor: _paymentColor(paymentStatus),
            ),
            _infoLine('Tarih', _formatDate(dateTs)),
            _infoLine('Oluşturulma', _formatDate(createdAtTs)),
            if (guestCount != null) _infoLine('Kişi sayısı', '$guestCount'),
            _infoLine('Toplam', _formatPrice(totalPrice)),
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _updateReservationStatus(
                          context,
                          docId: doc.id,
                          newStatus: 'approved',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Onayla'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _updateReservationStatus(
                          context,
                          docId: doc.id,
                          newStatus: 'rejected',
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: const Text('Reddet'),
                    ),
                  ),
                ],
              ),
            ],
            if (canOpenPayment) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: paymentStatus == 'awaiting_payment'
                      ? () {
                          _startOrOpenPayment(
                            context,
                            docId: doc.id,
                            data: data,
                          );
                        }
                      : null,
                  icon: Icon(
                    hasCheckoutUrl
                        ? Icons.open_in_new_rounded
                        : Icons.hourglass_top_rounded,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: Text(
                    paymentStatus == 'paid'
                        ? 'Ödeme tamamlandı'
                        : hasCheckoutUrl
                            ? 'Ödemeyi Tamamla'
                            : 'Ödeme Ekranı Hazırlanıyor',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Şef Masası Rezervasyonları'),
        backgroundColor: _bg,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chef_table_reservations')
            .where('chefId', isEqualTo: chefId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final filteredDocs =
              docs.where((doc) => _matchesFilter(doc.data())).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Rezervasyon yok',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: _buildFilterBar(),
              ),
              Expanded(
                child: filteredDocs.isEmpty
                    ? const Center(
                        child: Text(
                          'Bu filtrede kayıt bulunamadı.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          return _reservationCard(
                            context,
                            filteredDocs[index],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
