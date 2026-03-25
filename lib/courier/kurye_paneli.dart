import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/kurye_teslim_servisi.dart';
import '../services/kurye_yanit_servisi.dart';
import '../services/otomatik_kurye_atama_servisi.dart';

class KuryePaneli extends StatefulWidget {
  const KuryePaneli({super.key});

  @override
  State<KuryePaneli> createState() => _KuryePaneliState();
}

class _KuryePaneliState extends State<KuryePaneli>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _courierId = 'ali_kurye';

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF0F0F0F);
  static const Color _card = Color(0xFF1A1A1A);

  late final TabController _tabController;
  void _startTimeoutWatcher() {
    Future.doWhile(() async {
      try {
        await OtomatikKuryeAtamaServisi().timeoutKontrolVeYenidenAta(
          timeout: const Duration(seconds: 20),
        );
      } catch (_) {}

      await Future.delayed(const Duration(seconds: 5));
      return mounted;
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _startTimeoutWatcher();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _aktifSiparislerStream() {
    return _firestore
        .collection('orders')
        .where('assignedCourierId', isEqualTo: _courierId)
        .where('status', whereIn: [
      'assigned',
      'accepted',
      'on_the_way',
      'ready'
    ]).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _gecmisTeslimatlarStream() {
    return _firestore
        .collection('orders')
        .where('assignedCourierId', isEqualTo: _courierId)
        .where('status', isEqualTo: 'delivered')
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _kuryeStream() {
    return _firestore.collection('couriers').doc(_courierId).snapshots();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Hazır';
      case 'assigned':
        return 'Kurye Atandı';
      case 'accepted':
        return 'Kabul edildi';
      case 'rejected':
        return 'Reddedildi';
      case 'on_the_way':
        return 'Yolda';
      case 'delivered':
        return 'Teslim edildi';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orangeAccent;
      case 'preparing':
        return Colors.lightBlueAccent;
      case 'ready':
        return Colors.amberAccent;
      case 'assigned':
        return Colors.deepPurpleAccent;
      case 'accepted':
        return Colors.deepPurpleAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'on_the_way':
        return Colors.cyanAccent;
      case 'delivered':
        return Colors.greenAccent;
      default:
        return Colors.white70;
    }
  }

  String _offerStatusLabel(String offerStatus) {
    switch (offerStatus) {
      case 'pending':
        return 'Teklif Bekliyor';
      case 'accepted':
        return 'Kabul Edildi';
      case 'rejected':
        return 'Reddedildi';
      case 'expired':
        return 'Süresi Doldu';
      default:
        return offerStatus.isEmpty ? '-' : offerStatus;
    }
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final dt = value.toDate().toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
    }
    return '-';
  }

  Future<void> _goreviKabulEt(String orderId) async {
    try {
      await KuryeYanitServisi.kabulEt(
        orderId: orderId,
        courierId: _courierId,
      );

      final timelineRef = _firestore.collection('orderTimeline').doc();

      await timelineRef.set({
        'orderId': orderId,
        'status': 'accepted',
        'actorType': 'courier',
        'actorId': _courierId,
        'note': 'Kurye görevi kabul etti',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görev kabul edildi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev kabul hatası: $e'),
        ),
      );
    }
  }

  Future<void> _goreviReddet(String orderId) async {
    try {
      await KuryeYanitServisi.reddet(
        orderId: orderId,
        courierId: _courierId,
        reason: 'Kurye panelinden reddedildi',
      );

      final timelineRef = _firestore.collection('orderTimeline').doc();

      await timelineRef.set({
        'orderId': orderId,
        'status': 'rejected',
        'actorType': 'courier',
        'actorId': _courierId,
        'note': 'Kurye görevi reddetti',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görev reddedildi. Yeni kurye aranıyor.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görev reddetme hatası: $e'),
        ),
      );
    }
  }

  Future<void> _yolaCiktiYap(String orderId) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        throw Exception('Sipariş bulunamadı.');
      }

      final data = orderSnap.data() ?? {};
      final currentStatus = (data['status'] ?? '').toString().trim();

      if (currentStatus == 'on_the_way') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sipariş zaten yolda görünüyor.')),
        );
        return;
      }

      if (currentStatus == 'delivered') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teslim edilmiş sipariş tekrar güncellenemez.'),
          ),
        );
        return;
      }

      if (currentStatus != 'accepted' && currentStatus != 'ready') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Önce görevi kabul etmelisiniz.'),
          ),
        );
        return;
      }

      await orderRef.set({
        'status': 'on_the_way',
        'durum': 'on_the_way',
        'assignmentStatus': 'assigned',
        'courierOfferStatus': 'accepted',
        'courierRespondedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş yola çıktı olarak güncellendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _haritadaAc(Map<String, dynamic> data) async {
    final lat = _toDouble(data['lat']);
    final lng = _toDouble(data['lng']);

    if (lat == null || lng == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu siparişte konum bilgisi yok.')),
      );
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Harita açılamadı');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harita açma hatası: $e')),
      );
    }
  }

  Future<void> _teslimEt(String orderId) async {
    try {
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderSnap = await orderRef.get();

      if (!orderSnap.exists) {
        throw Exception('Sipariş bulunamadı.');
      }

      final data = orderSnap.data() ?? {};
      final currentStatus = (data['status'] ?? '').toString().trim();

      if (currentStatus != 'on_the_way') {
        throw Exception('Teslim etmek için sipariş yolda olmalıdır.');
      }

      await KuryeTeslimServisi.teslimEt(orderId: orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş teslim edildi.'),
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

  Widget _ustBilgiKarti({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: _gold),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bilgiSatiri(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: _gold,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: valueColor ?? Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _kuryeStream(),
      builder: (context, kuryeSnapshot) {
        final data = kuryeSnapshot.data?.data() ?? {};
        final adSoyad = _safeText(data['adSoyad'], fallback: 'Kurye');
        final toplamTeslimat = _toInt(data['toplamTeslimat']);
        final uygunluk = _safeText(data['uygunluk'], fallback: 'Bilinmiyor');

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _aktifSiparislerStream(),
          builder: (context, aktifSnapshot) {
            final aktifSiparis = aktifSnapshot.data?.docs.length ?? 0;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ustBilgiKarti(
                        icon: Icons.person,
                        label: 'Kurye',
                        value: adSoyad,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ustBilgiKarti(
                        icon: Icons.assignment,
                        label: 'Aktif Görev',
                        value: aktifSiparis.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ustBilgiKarti(
                        icon: Icons.verified,
                        label: 'Durum',
                        value: uygunluk,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ustBilgiKarti(
                        icon: Icons.done_all,
                        label: 'Teslimat',
                        value: toplamTeslimat.toString(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAktifOrderCard(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final orderId = doc.id;

    final status = _safeText(data['status'], fallback: 'pending');
    final assignmentStatus =
        _safeText(data['assignmentStatus'], fallback: 'waiting_courier');
    final offerStatus = _safeText(data['courierOfferStatus'], fallback: '');
    final musteriAd = _safeText(data['musteriAd'] ?? data['kullaniciAdi']);
    final musteriTelefon =
        _safeText(data['musteriTelefon'] ?? data['kullaniciTelefon']);
    final saticiAd = _safeText(
      data['saticiAd'] ?? data['dukkanAdi'] ?? data['sellerName'],
    );
    final adres = _safeText(
      data['teslimatAdresi'] ?? data['adres'] ?? data['address'],
    );
    final toplam =
        data['genelToplam'] ?? data['toplamTutar'] ?? data['araToplam'];
    final lat = _toDouble(data['lat']);
    final lng = _toDouble(data['lng']);
    final konumHazir = lat != null && lng != null;

    final assignedCourierId =
        _safeText(data['assignedCourierId'], fallback: '').trim();

    final banaAtanmis = assignedCourierId == _courierId;

    final offerStatusNormalized = offerStatus.trim().toLowerCase();
    final statusNormalized = status.trim().toLowerCase();
    final assignmentStatusNormalized = assignmentStatus.trim().toLowerCase();

    final kabulRedAktif = banaAtanmis &&
        assignmentStatusNormalized == 'assigned' &&
        (offerStatusNormalized.isEmpty || offerStatusNormalized == 'pending') &&
        (statusNormalized == 'ready' ||
            statusNormalized == 'assigned' ||
            statusNormalized == 'accepted');

    final yolaCikAktif = banaAtanmis &&
        (statusNormalized == 'accepted' || statusNormalized == 'ready');

    final teslimAktif = banaAtanmis && statusNormalized == 'on_the_way';

    final kabulButonDisabled = !kabulRedAktif;
    final redButonDisabled = !kabulRedAktif;
    final yolaCikButonDisabled = !yolaCikAktif;
    final teslimButonDisabled = !teslimAktif;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: _gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sipariş: $orderId',
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _statusColor(status)),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (offerStatus.isNotEmpty)
              _bilgiSatiri(
                'Teklif',
                _offerStatusLabel(offerStatus),
                valueColor: offerStatus == 'pending'
                    ? Colors.orangeAccent
                    : offerStatus == 'accepted'
                        ? Colors.greenAccent
                        : offerStatus == 'rejected'
                            ? Colors.redAccent
                            : Colors.white70,
              ),
            const SizedBox(height: 8),
            _bilgiSatiri('Satıcı', saticiAd),
            _bilgiSatiri('Müşteri', musteriAd),
            _bilgiSatiri('Telefon', musteriTelefon),
            _bilgiSatiri('Adres', adres),
            _bilgiSatiri('Tutar', toplam.toString()),
            _bilgiSatiri(
              'Konum',
              konumHazir
                  ? '${lat.toString()}, ${lng.toString()}'
                  : 'lat/lng eksik',
              valueColor: konumHazir ? Colors.greenAccent : Colors.orangeAccent,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: kabulButonDisabled
                        ? null
                        : () => _goreviKabulEt(orderId),
                    icon: const Icon(Icons.task_alt),
                    label: const Text('Görevi Kabul Et'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        redButonDisabled ? null : () => _goreviReddet(orderId),
                    icon: const Icon(Icons.close),
                    label: const Text('Reddet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: konumHazir ? () => _haritadaAc(data) : null,
                    icon: const Icon(Icons.map),
                    label: const Text('Haritada Aç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: konumHazir ? _gold : Colors.white10,
                      foregroundColor:
                          konumHazir ? Colors.black : Colors.white38,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: yolaCikButonDisabled
                        ? null
                        : () => _yolaCiktiYap(orderId),
                    icon: const Icon(Icons.route),
                    label: const Text('Yola Çıktım'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    teslimButonDisabled ? null : () => _teslimEt(orderId),
                icon: const Icon(Icons.check_circle),
                label: const Text('Teslim Ettim'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGecmisOrderCard(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final orderId = doc.id;

    final musteriAd = _safeText(data['musteriAd'] ?? data['kullaniciAdi']);
    final saticiAd = _safeText(
      data['saticiAd'] ?? data['dukkanAdi'] ?? data['sellerName'],
    );
    final adres = _safeText(
      data['teslimatAdresi'] ?? data['adres'] ?? data['address'],
    );
    final toplam =
        data['genelToplam'] ?? data['toplamTutar'] ?? data['araToplam'];
    final deliveredAt = _formatTimestamp(data['deliveredAt']);
    final lat = _toDouble(data['lat']);
    final lng = _toDouble(data['lng']);
    final konumHazir = lat != null && lng != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: _gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Teslimat: $orderId',
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: const Text(
                    'Teslim edildi',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _bilgiSatiri('Satıcı', saticiAd),
            _bilgiSatiri('Müşteri', musteriAd),
            _bilgiSatiri('Adres', adres),
            _bilgiSatiri('Tutar', toplam.toString()),
            _bilgiSatiri('Teslim Saati', deliveredAt),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: konumHazir ? () => _haritadaAc(data) : null,
                icon: const Icon(Icons.map),
                label: const Text('Teslimat Konumunu Aç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: konumHazir ? _gold : Colors.white10,
                  foregroundColor: konumHazir ? Colors.black : Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiparisListesi({
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    required bool gecmisMi,
    required String emptyText,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
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

        if (docs.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (gecmisMi) {
          docs.sort((a, b) {
            final aTs = a.data()['deliveredAt'];
            final bTs = b.data()['deliveredAt'];

            DateTime aDate = DateTime.fromMillisecondsSinceEpoch(0);
            DateTime bDate = DateTime.fromMillisecondsSinceEpoch(0);

            if (aTs is Timestamp) aDate = aTs.toDate();
            if (bTs is Timestamp) bDate = bTs.toDate();

            return bDate.compareTo(aDate);
          });
        } else {
          docs.sort((a, b) {
            final aTs = a.data()['createdAt'];
            final bTs = b.data()['createdAt'];

            DateTime aDate = DateTime.fromMillisecondsSinceEpoch(0);
            DateTime bDate = DateTime.fromMillisecondsSinceEpoch(0);

            if (aTs is Timestamp) aDate = aTs.toDate();
            if (bTs is Timestamp) bDate = bTs.toDate();

            return bDate.compareTo(aDate);
          });
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return gecmisMi
                ? _buildGecmisOrderCard(docs[index])
                : _buildAktifOrderCard(docs[index]);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Kurye Paneli',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _aktifSiparislerStream(),
            builder: (context, aktifSnapshot) {
              final aktifCount = aktifSnapshot.data?.docs.length ?? 0;

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _gecmisTeslimatlarStream(),
                builder: (context, gecmisSnapshot) {
                  final gecmisCount = gecmisSnapshot.data?.docs.length ?? 0;

                  return TabBar(
                    controller: _tabController,
                    indicatorColor: _gold,
                    labelColor: _gold,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(text: 'Aktif Görevler ($aktifCount)'),
                      Tab(text: 'Geçmiş Teslimatlar ($gecmisCount)'),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTopPanel(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSiparisListesi(
                    stream: _aktifSiparislerStream(),
                    gecmisMi: false,
                    emptyText:
                        'Şu anda aktif teslimat yok.\nYeni siparişler burada görünecek.',
                  ),
                  _buildSiparisListesi(
                    stream: _gecmisTeslimatlarStream(),
                    gecmisMi: true,
                    emptyText: 'Henüz teslim edilmiş sipariş kaydı yok.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
