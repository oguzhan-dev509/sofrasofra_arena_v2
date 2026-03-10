import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/kurye_dispatch_engine.dart';
import '../services/ai_kurye_dagitim_motoru.dart';

class KuryePaneli extends StatefulWidget {
  const KuryePaneli({super.key});

  @override
  State<KuryePaneli> createState() => _KuryePaneliState();
}

class _KuryePaneliState extends State<KuryePaneli> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final KuryeDispatchEngine _dispatchEngine = KuryeDispatchEngine();
  final AiKuryeDagitimMotoru _aiDispatchEngine = AiKuryeDagitimMotoru();

  String _statusFilter = 'all';
  bool _onlyUnassigned = true;
  bool _isBusy = false;

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
    final assignedCourierId = (data['assignedCourierId'] ?? '').toString();
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

  double _calculateDistanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * pi / 180;

  Future<List<_CourierCandidate>> _findNearest3Couriers({
    required double orderLat,
    required double orderLng,
  }) async {
    final query = await _firestore
        .collection('couriers')
        .where('online', isEqualTo: true)
        .where('activeOrder', isEqualTo: false)
        .get();

    final List<_CourierCandidate> candidates = [];

    for (final doc in query.docs) {
      final data = doc.data();
      final lat = _toDouble(data['lat']);
      final lng = _toDouble(data['lng']);

      if (lat == null || lng == null) continue;

      final distanceKm = _calculateDistanceKm(orderLat, orderLng, lat, lng);

      candidates.add(
        _CourierCandidate(
          courierId: doc.id,
          name: _safeText(data['name'], fallback: 'Kurye'),
          phone: _safeText(data['phone']),
          lat: lat,
          lng: lng,
          distanceKm: distanceKm,
          raw: data,
        ),
      );
    }

    candidates.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return candidates.take(3).toList();
  }

  Future<void> _assignCourierManually({
    required String orderId,
    required _CourierCandidate candidate,
  }) async {
    try {
      setState(() => _isBusy = true);

      final orderRef = _firestore.collection('orders').doc(orderId);
      final courierRef =
          _firestore.collection('couriers').doc(candidate.courierId);
      final courierOrderRef = _firestore.collection('courier_orders').doc();

      await _firestore.runTransaction((tx) async {
        final orderSnap = await tx.get(orderRef);
        final courierSnap = await tx.get(courierRef);

        if (!orderSnap.exists) {
          throw Exception('Sipariş bulunamadı.');
        }
        if (!courierSnap.exists) {
          throw Exception('Kurye bulunamadı.');
        }

        final orderData = orderSnap.data() as Map<String, dynamic>? ?? {};
        final courierData = courierSnap.data() as Map<String, dynamic>? ?? {};

        final currentStatus = (orderData['status'] ?? '').toString();
        final alreadyAssigned =
            (orderData['assignedCourierId'] ?? '').toString().isNotEmpty;
        final online = courierData['online'] == true;
        final activeOrder = courierData['activeOrder'] == true;

        if (alreadyAssigned) {
          throw Exception('Bu siparişe zaten kurye atanmış.');
        }

        if (currentStatus.isNotEmpty &&
            currentStatus != 'pending' &&
            currentStatus != 'waiting_courier') {
          throw Exception(
              'Sipariş durumu atama için uygun değil: $currentStatus');
        }

        if (!online || activeOrder) {
          throw Exception('Seçilen kurye artık uygun değil.');
        }

        tx.update(orderRef, {
          'assignedCourierId': candidate.courierId,
          'assignedCourierName': candidate.name,
          'courierAssignedAt': FieldValue.serverTimestamp(),
          'courierDistanceKm': candidate.distanceKm,
          'status': 'courier_assigned',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.update(courierRef, {
          'activeOrder': true,
          'currentOrderId': orderId,
          'lastAssignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        tx.set(courierOrderRef, {
          'orderId': orderId,
          'courierId': candidate.courierId,
          'courierName': candidate.name,
          'status': 'assigned',
          'distanceKm': candidate.distanceKm,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            '${candidate.name} siparişe atandı (${candidate.distanceKm.toStringAsFixed(2)} km)',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Kurye atama hatası: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _showNearestCouriersForOrder({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) async {
    final orderLat = _toDouble(orderData['lat']);
    final orderLng = _toDouble(orderData['lng']);

    if (orderLat == null || orderLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          content: const Text(
            'Bu siparişte lat/lng eksik olduğu için en yakın kurye hesaplanamıyor.',
          ),
        ),
      );
      return;
    }

    try {
      setState(() => _isBusy = true);

      final nearest = await _findNearest3Couriers(
        orderLat: orderLat,
        orderLng: orderLng,
      );

      if (!mounted) return;

      if (nearest.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange.shade800,
            content: const Text('Uygun online kurye bulunamadı.'),
          ),
        );
        return;
      }

      showModalBottomSheet(
        context: context,
        backgroundColor: _card,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'En Yakın 3 Kurye',
                    style: TextStyle(
                      color: _gold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sipariş: $orderId',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ...nearest.map(
                    (candidate) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: _gold,
                            child: Icon(Icons.delivery_dining,
                                color: Colors.black),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  candidate.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mesafe: ${candidate.distanceKm.toStringAsFixed(2)} km',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  'Telefon: ${candidate.phone}',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isBusy
                                ? null
                                : () => _assignCourierManually(
                                      orderId: orderId,
                                      candidate: candidate,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Ata'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text('Kurye önerisi alınamadı: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
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
            'KURYE ATAMA MOTORU',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 0.5,
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

    final hasPrepTime = data['hazirlamaSuresiDakika'] != null ||
        data['restaurantPrepMinutes'] != null;

    final hasTraffic =
        data['trafikSeviyesi'] != null || data['trafficLevel'] != null;

    final aiScore = _toDouble(data['aiDispatchScore']);

    final dynamic rawAiMeta = data['aiDispatchMeta'];
    final Map<String, dynamic> aiMeta =
        rawAiMeta is Map ? Map<String, dynamic>.from(rawAiMeta) : {};

    final trafficUsed =
        (data['trafficLevelUsed'] ?? data['trafikSeviyesi'] ?? '-').toString();

    final prepUsed = (data['restaurantPrepMinutesUsed'] ??
            data['hazirlamaSuresiDakika'] ??
            '-')
        .toString();

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
            _infoRow(
              'AI Veri',
              (hasPrepTime && hasTraffic) ? 'hazır' : 'kısmi / eksik',
              valueColor: (hasPrepTime && hasTraffic)
                  ? Colors.greenAccent
                  : Colors.orangeAccent,
            ),
            if (aiScore != null) ...[
              const SizedBox(height: 10),
              _buildAiScoreBox(
                aiScore: aiScore,
                trafficUsed: trafficUsed,
                prepUsed: prepUsed,
                aiMeta: aiMeta,
                assignedCourier: assignedCourier,
              ),
            ],
            const SizedBox(height: 14),
            const SizedBox(height: 6),
            Text(
              _aiReasonText(aiMeta),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: (_isBusy || assigned || !hasLocation)
                      ? null
                      : () => _showNearestCouriersForOrder(
                            orderId: orderId,
                            orderData: data,
                          ),
                  icon: const Icon(Icons.location_on),
                  label: const Text('En Yakın 3 Kurye Öner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: (_isBusy || assigned || !hasLocation)
                      ? null
                      : () async {
                          try {
                            setState(() => _isBusy = true);

                            final ok = await _dispatchEngine
                                .assignNearestCourier(orderId: orderId);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: ok
                                    ? Colors.green.shade700
                                    : Colors.orange.shade800,
                                content: Text(
                                  ok
                                      ? 'En yakın kurye otomatik atandı.'
                                      : 'Atama yapılamadı. Uygun kurye veya konum bilgisi yok.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red.shade700,
                                content: Text('Otomatik atama hatası: $e'),
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _isBusy = false);
                          }
                        },
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Otomatik Ata'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gold,
                    side: const BorderSide(color: _gold),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: (_isBusy || assigned || !hasLocation)
                      ? null
                      : () async {
                          try {
                            setState(() => _isBusy = true);

                            final ok = await _aiDispatchEngine
                                .assignBestCourier(orderId: orderId);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: ok
                                    ? Colors.blue.shade700
                                    : Colors.orange.shade800,
                                content: Text(
                                  ok
                                      ? 'AI motoru en uygun kuryeyi başarıyla atadı.'
                                      : 'AI ataması yapılamadı. Veri eksik veya uygun kurye yok.',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.red.shade700,
                                content: Text('AI kurye atama hatası: $e'),
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _isBusy = false);
                          }
                        },
                  icon: const Icon(Icons.psychology),
                  label: const Text('AI ile Ata'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white10,
                    disabledForegroundColor: Colors.white38,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (!hasLocation) ...[
              const SizedBox(height: 10),
              const Text(
                'Not: Bu siparişte lat/lng olmadığı için kurye önerisi pasif kalır. Sipariş oluşturulurken konum bilgisini orders içine yazmalısın.',
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

  Widget _buildAiScoreBox({
    required double aiScore,
    required String trafficUsed,
    required String prepUsed,
    required Map<String, dynamic> aiMeta,
    required String assignedCourier,
  }) {
    final distanceScore = _toDouble(aiMeta['distanceScore']);
    final performanceScore = _toDouble(aiMeta['performanceScore']);
    final speedScore = _toDouble(aiMeta['speedScore']);
    final acceptanceScore = _toDouble(aiMeta['acceptanceScore']);
    final workloadScore = _toDouble(aiMeta['workloadScore']);
    final prepBonus = _toDouble(aiMeta['prepBonus']);
    final trafficPenalty = _toDouble(aiMeta['trafficPenalty']);

    Color scoreColor;
    if (aiScore >= 0.80) {
      scoreColor = Colors.greenAccent;
    } else if (aiScore >= 0.60) {
      scoreColor = Colors.amberAccent;
    } else {
      scoreColor = Colors.orangeAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.blueGrey.shade300.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.lightBlueAccent),
              const SizedBox(width: 8),
              Text(
                'AI Skor: ${aiScore.toStringAsFixed(3)}',
                style: TextStyle(
                  color: scoreColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  assignedCourier == '-' ? 'Kurye bekleniyor' : assignedCourier,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _miniMetricChip('Trafik', trafficUsed),
              _miniMetricChip('Hazırlama', '$prepUsed dk'),
              if (distanceScore != null)
                _miniMetricChip('Mesafe', distanceScore.toStringAsFixed(2)),
              if (performanceScore != null)
                _miniMetricChip(
                  'Performans',
                  performanceScore.toStringAsFixed(2),
                ),
              if (speedScore != null)
                _miniMetricChip('Hız', speedScore.toStringAsFixed(2)),
              if (acceptanceScore != null)
                _miniMetricChip('Kabul', acceptanceScore.toStringAsFixed(2)),
              if (workloadScore != null)
                _miniMetricChip('Yük', workloadScore.toStringAsFixed(2)),
              if (prepBonus != null)
                _miniMetricChip('Prep Bonus', prepBonus.toStringAsFixed(2)),
              if (trafficPenalty != null)
                _miniMetricChip(
                  'Trafik Ceza',
                  trafficPenalty.toStringAsFixed(2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _aiReasonText(Map<String, dynamic> aiMeta) {
    final distance = _toDouble(aiMeta['distanceScore']) ?? 0;
    final performance = _toDouble(aiMeta['performanceScore']) ?? 0;
    final speed = _toDouble(aiMeta['speedScore']) ?? 0;
    final acceptance = _toDouble(aiMeta['acceptanceScore']) ?? 0;
    final workload = _toDouble(aiMeta['workloadScore']) ?? 0;
    final prepBonus = _toDouble(aiMeta['prepBonus']) ?? 0;
    final trafficPenalty = _toDouble(aiMeta['trafficPenalty']) ?? 0;

    List<String> reasons = [];

    if (distance > 0.8) {
      reasons.add("çok yakın kurye");
    }

    if (performance > 0.8) {
      reasons.add("yüksek performans");
    }

    if (speed > 0.75) {
      reasons.add("hızlı teslimat geçmişi");
    }

    if (acceptance > 0.85) {
      reasons.add("yüksek kabul oranı");
    }

    if (workload > 0.7) {
      reasons.add("uygun iş yükü");
    }

    if (prepBonus > 0.05) {
      reasons.add("restoran hazırlama süresi ile uyumlu");
    }

    if (trafficPenalty > 0.1) {
      reasons.add("trafik koşulları dikkate alındı");
    }

    if (reasons.isEmpty) {
      return "AI dengeli kurye seçimi yaptı.";
    }

    return reasons.join(" • ");
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

class _CourierCandidate {
  final String courierId;
  final String name;
  final String phone;
  final double lat;
  final double lng;
  final double distanceKm;
  final Map<String, dynamic> raw;

  _CourierCandidate({
    required this.courierId,
    required this.name,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    required this.raw,
  });
}
