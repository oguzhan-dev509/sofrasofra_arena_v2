import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KuryeMobilPaneli extends StatefulWidget {
  const KuryeMobilPaneli({super.key});

  @override
  State<KuryeMobilPaneli> createState() => _KuryeMobilPaneliState();
}

class _KuryeMobilPaneliState extends State<KuryeMobilPaneli> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Şimdilik test için sabit kurye
  static const String _aktifKuryeId = 'ali_kurye';

  Stream<DocumentSnapshot<Map<String, dynamic>>> _kuryeStream() {
    return _firestore.collection('couriers').doc(_aktifKuryeId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _gorevlerStream() {
    return _firestore
        .collection('orders')
        .where('assignedCourierId', isEqualTo: _aktifKuryeId)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    if (text.isEmpty) return fallback;
    return text;
  }

  String _durumEtiketi(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Beklemede';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'on_the_way':
        return 'Yolda';
      case 'delivered':
        return 'Teslim Edildi';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  Color _durumRengi(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.deepOrange;
      case 'on_the_way':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _siparisDurumuGuncelle({
    required String orderId,
    required String yeniStatus,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': yeniStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sipariş durumu güncellendi: $yeniStatus'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncelleme hatası: $e'),
        ),
      );
    }
  }

  Future<void> _teslimEt({
    required String orderId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final orderRef = _firestore.collection('orders').doc(orderId);
        final courierRef = _firestore.collection('couriers').doc(_aktifKuryeId);

        final orderSnap = await transaction.get(orderRef);
        final courierSnap = await transaction.get(courierRef);

        if (!orderSnap.exists) {
          throw Exception('Sipariş bulunamadı.');
        }

        if (!courierSnap.exists) {
          throw Exception('Kurye bulunamadı.');
        }

        final orderData = orderSnap.data() as Map<String, dynamic>;
        final courierData = courierSnap.data() as Map<String, dynamic>;

        final assignmentStatus =
            (orderData['assignmentStatus'] ?? '').toString().toLowerCase();
        final status = (orderData['status'] ?? '').toString().toLowerCase();

        if (assignmentStatus == 'completed' || status == 'delivered') {
          throw Exception('Bu sipariş zaten tamamlanmış.');
        }

        final aktifSiparis = (courierData['aktifSiparis'] is int)
            ? courierData['aktifSiparis'] as int
            : int.tryParse('${courierData['aktifSiparis'] ?? 0}') ?? 0;

        final toplamTeslimat = (courierData['toplamTeslimat'] is int)
            ? courierData['toplamTeslimat'] as int
            : int.tryParse('${courierData['toplamTeslimat'] ?? 0}') ?? 0;

        transaction.update(orderRef, {
          'status': 'delivered',
          'assignmentStatus': 'completed',
          'deliveredAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(courierRef, {
          'aktifSiparis': aktifSiparis > 0 ? aktifSiparis - 1 : 0,
          'toplamTeslimat': toplamTeslimat + 1,
          'uygunluk': 'musait',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

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

  Widget _ustBilgiKarti({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFB300)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gorevKart(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    final status = _safeText(data['status'], fallback: '');
    final assignmentStatus = _safeText(data['assignmentStatus'], fallback: '');
    final musteriAdi = _safeText(data['customerName'] ?? data['musteriAdi'],
        fallback: 'Müşteri');
    final saticiAdi =
        _safeText(data['vendorName'] ?? data['saticiAdi'], fallback: 'Satıcı');
    final adres = _safeText(data['adres'], fallback: '-');
    final ilce = _safeText(data['ilce'], fallback: '-');
    final sehir = _safeText(data['sehir'], fallback: '-');

    final lat = _toDouble(data['lat']);
    final lng = _toDouble(data['lng']);

    final bool teslimEdildi = status.toLowerCase() == 'delivered' ||
        assignmentStatus.toLowerCase() == 'completed';
    final bool yolda = status.toLowerCase() == 'on_the_way';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x22FFB300),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFFFFB300),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sipariş: ${doc.id}',
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _durumRengi(status).withAlpha(35),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _durumRengi(status)),
                ),
                child: Text(
                  _durumEtiketi(status),
                  style: TextStyle(
                    color: _durumRengi(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Müşteri: $musteriAdi',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Satıcı: $saticiAdi',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Adres: $adres',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bölge: $ilce / $sehir',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lat != null && lng != null
                ? 'Konum: ${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}'
                : 'Konum: -',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: (!teslimEdildi && !yolda)
                    ? () => _siparisDurumuGuncelle(
                          orderId: doc.id,
                          yeniStatus: 'on_the_way',
                        )
                    : null,
                icon: const Icon(Icons.two_wheeler),
                label: const Text('Yola Çıktım'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: (yolda && !teslimEdildi)
                    ? () => _teslimEt(orderId: doc.id)
                    : null,
                icon: const Icon(Icons.check_circle),
                label: const Text('Teslim Ettim'),
              ),
            ],
          ),
        ],
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
          'KURYE MOBİL PANELİ',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _kuryeStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Text(
                      'Kurye bilgisi okunamadı: ${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: const Text(
                      'Kurye bilgisi bulunamadı.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final data = snapshot.data!.data() ?? {};
                final adSoyad = _safeText(data['adSoyad'], fallback: 'Kurye');
                final uygunluk = _safeText(data['uygunluk'], fallback: '-');
                final aktifSiparis = data['aktifSiparis'] ?? 0;
                final toplamTeslimat = data['toplamTeslimat'] ?? 0;

                return Column(
                  children: [
                    _ustBilgiKarti(
                      icon: Icons.person,
                      title: 'Kurye',
                      value: adSoyad,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ustBilgiKarti(
                            icon: Icons.route,
                            title: 'Uygunluk',
                            value: uygunluk,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ustBilgiKarti(
                            icon: Icons.shopping_bag,
                            title: 'Aktif Sipariş',
                            value: '$aktifSiparis',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ustBilgiKarti(
                      icon: Icons.check_circle,
                      title: 'Toplam Teslimat',
                      value: '$toplamTeslimat',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _gorevlerStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Görevler okunamadı: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
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

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade800),
                      ),
                      child: const Center(
                        child: Text(
                          'Şu anda bu kuryeye atanmış aktif görev yok.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      return _gorevKart(docs[index]);
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
