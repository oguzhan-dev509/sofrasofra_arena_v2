import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'kurye_atama_motoru.dart';

class KuryePaneli extends StatefulWidget {
  const KuryePaneli({super.key});

  @override
  State<KuryePaneli> createState() => _KuryePaneliState();
}

class _KuryePaneliState extends State<KuryePaneli> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _statusFilter = 'all';
  bool _onlyUnassigned = true;

  static const Color _gold = Color(0xFFFFA726);
  static const Color _bg = Color(0xFF111111);
  static const Color _card = Color(0xFF1A1A1A);

  Stream<QuerySnapshot<Map<String, dynamic>>> _ordersStream() {
    Query<Map<String, dynamic>> query =
        _firestore.collection('orders').orderBy('createdAt', descending: true);

    if (_statusFilter != 'all') {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    return query.snapshots();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  bool _isAssigned(Map<String, dynamic> data) {
    final assignedCourierId =
        (data['assignedCourierId'] ?? '').toString().trim();
    return assignedCourierId.isNotEmpty;
  }

  bool _hasLocation(Map<String, dynamic> data) {
    final lat = _toDouble(data['lat']);
    final lng = _toDouble(data['lng']);
    return lat != null && lng != null;
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'courier_assigned':
        return Colors.amber;
      case 'courier_accepted':
        return Colors.lightGreenAccent;
      case 'preparing':
      case 'hazirlaniyor':
        return Colors.blueAccent;
      case 'on_the_way':
      case 'yolda':
        return Colors.cyanAccent;
      case 'delivered':
      case 'teslim_edildi':
        return Colors.greenAccent;
      case 'cancelled':
      case 'iptal':
        return Colors.redAccent;
      default:
        return Colors.white70;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'pending';
      case 'courier_assigned':
        return 'kurye atandı';
      case 'courier_accepted':
        return 'kurye kabul etti';
      case 'preparing':
      case 'hazirlaniyor':
        return 'hazırlanıyor';
      case 'on_the_way':
      case 'yolda':
        return 'yolda';
      case 'delivered':
      case 'teslim_edildi':
        return 'teslim edildi';
      case 'cancelled':
      case 'iptal':
        return 'iptal';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  List<DocumentSnapshot<Map<String, dynamic>>> _applyClientSideFilters(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var filtered = docs;

    if (_onlyUnassigned) {
      filtered = filtered.where((doc) {
        final data = doc.data() ?? {};
        return !_isAssigned(data);
      }).toList();
    }

    return filtered;
  }

  void _openKuryeAtamaMotoru() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const KuryeAtamaMotoru(),
      ),
    );
  }

  Widget _buildTopBar() {
    final filters = ['all', 'pending', 'hazirlaniyor', 'yolda'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KURYE PANELİ',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openKuryeAtamaMotoru,
              icon: const Icon(Icons.local_shipping),
              label: const Text('Kurye Atama Motorunu Aç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            runSpacing: 10,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Filtre:',
                style: TextStyle(color: Colors.white70),
              ),
              ...filters.map(
                (f) => ChoiceChip(
                  label: Text(
                    f == 'all' ? 'Tümü' : f,
                    style: TextStyle(
                      color: _statusFilter == f ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  selected: _statusFilter == f,
                  onSelected: (_) {
                    setState(() => _statusFilter = f);
                  },
                  selectedColor: _gold,
                  backgroundColor: Colors.black26,
                  side: const BorderSide(color: Colors.white10),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  _onlyUnassigned ? 'Görünüm: Atanmamış' : 'Görünüm: Tümü',
                  style: TextStyle(
                    color: _onlyUnassigned ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                selected: _onlyUnassigned,
                selectedColor: _gold,
                backgroundColor: Colors.black26,
                side: const BorderSide(color: Colors.white10),
                onSelected: (value) {
                  setState(() => _onlyUnassigned = value);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: _gold,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final orderId = doc.id;
    final status = _safeText(data['status'], fallback: 'pending');
    final sellerName = _safeText(
      data['sellerName'] ?? data['dukkan'] ?? data['storeName'],
    );
    final address = _safeText(
      data['adres'] ?? data['deliveryAddress'] ?? data['address'],
    );
    final assignedCourier = _safeText(data['assignedCourierName']);
    final hasLocation = _hasLocation(data);
    final assigned = _isAssigned(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: _gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sipariş: $orderId',
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: assigned ? _gold : Colors.orange,
                    ),
                  ),
                  child: Text(
                    assigned ? 'Atandı' : 'Atanmadı',
                    style: TextStyle(
                      color: assigned ? _gold : Colors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow('Satıcı', sellerName),
            _infoRow(
              'Durum',
              _statusLabel(status),
              valueColor: _statusColor(status),
            ),
            _infoRow('Adres', address),
            _infoRow('Kurye', assignedCourier),
            _infoRow(
              'Konum',
              hasLocation ? 'lat/lng hazır' : 'lat/lng eksik',
              valueColor:
                  hasLocation ? Colors.greenAccent : Colors.orangeAccent,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !hasLocation ? null : _openKuryeAtamaMotoru,
                icon: const Icon(Icons.local_shipping),
                label: const Text('Kurye Atama Motorunda Aç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasLocation ? _gold : Colors.white10,
                  foregroundColor: hasLocation ? Colors.black : Colors.white38,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            if (!hasLocation) ...[
              const SizedBox(height: 10),
              const Text(
                'Not: Bu siparişte lat/lng olmadığı için kurye önerisi pasif kalır.',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
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
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Kurye Paneli',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: _gold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _ordersStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Hata: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _gold),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = _applyClientSideFilters(docs);

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Gösterilecek sipariş yok.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(filteredDocs[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
