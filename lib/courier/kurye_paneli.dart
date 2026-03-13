import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/kurye_konum_servisi.dart';
import '../services/kurye_teslim_servisi.dart';

class KuryePaneli extends StatefulWidget {
  const KuryePaneli({super.key});

  @override
  State<KuryePaneli> createState() => _KuryePaneliState();
}

class _KuryePaneliState extends State<KuryePaneli> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Şimdilik test için sabit kurye
  final String aktifKuryeId = 'ali_kurye';
  final String aktifKuryeAdi = 'Ali Kurye';

  final Set<String> _gorulenSiparisIdleri = <String>{};
  bool _ilkSiparisYuklemeTamamlandi = false;
  bool _durumGuncelleniyor = false;

  @override
  void initState() {
    super.initState();
    _kuryeTakibiniBaslat();
  }

  @override
  void dispose() {
    KuryeKonumServisi.canliTakibiDurdur();
    super.dispose();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _kuryeStream() {
    return _firestore.collection('couriers').doc(aktifKuryeId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _siparislerStream() {
    return _firestore
        .collection('orders')
        .where('assignedCourierId', isEqualTo: aktifKuryeId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _kuryeTakibiniBaslat() async {
    try {
      await KuryeKonumServisi.canliTakibiBaslat(
        kuryeId: aktifKuryeId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Canlı konum başlatılamadı: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _tekSeferlikKonumYenile() async {
    try {
      await KuryeKonumServisi.tekSeferlikKonumGuncelle(
        kuryeId: aktifKuryeId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E1E1E),
          content: Text(
            'Kurye konumu güncellendi.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Konum güncellenemedi: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _kuryeDurumuGuncelle(String yeniDurum) async {
    if (_durumGuncelleniyor) return;

    setState(() {
      _durumGuncelleniyor = true;
    });

    try {
      await _firestore.collection('couriers').doc(aktifKuryeId).update({
        'uygunluk': yeniDurum,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E1E1E),
          content: Text(
            'Kurye durumu güncellendi: $yeniDurum',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Kurye durumu güncellenemedi: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _durumGuncelleniyor = false;
        });
      }
    }
  }

  void _yeniSiparisKontrolEt(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final aktifIdler = docs.map((e) => e.id).toSet();

    if (!_ilkSiparisYuklemeTamamlandi) {
      _gorulenSiparisIdleri
        ..clear()
        ..addAll(aktifIdler);
      _ilkSiparisYuklemeTamamlandi = true;
      return;
    }

    final yeniIdler = aktifIdler.difference(_gorulenSiparisIdleri);

    if (yeniIdler.isNotEmpty) {
      _gorulenSiparisIdleri.addAll(yeniIdler);
      _bildirimSesiCal();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E1E1E),
            content: Text(
              '🔔 Yeni kurye görevi geldi!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      });
    }

    _gorulenSiparisIdleri.removeWhere((id) => !aktifIdler.contains(id));
  }

  void _bildirimSesiCal() {
    try {
      final audio = html.AudioElement()
        ..src =
            'data:audio/wav;base64,UklGRlQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YTAAAAAAgICAf39/f4CAgH9/f3+AgIB/f39/gICAf39/f4CAgH9/f3+AgIB/f39/gICAf39/f4CAgA=='
        ..autoplay = true;
      audio.play();
    } catch (_) {}
  }

  bool _gosterilsin(String status, String assignmentStatus) {
    const aktifStatusler = {
      'pending',
      'on_the_way',
    };

    if (assignmentStatus.toLowerCase() == 'completed') return false;
    if (status.toLowerCase() == 'delivered' ||
        status.toLowerCase() == 'cancelled') {
      return false;
    }

    return aktifStatusler.contains(status.toLowerCase());
  }

  String _safeString(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    final t = value.toString().trim();
    return t.isEmpty ? fallback : t;
  }

  double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _kisaTarih(dynamic raw) {
    if (raw is Timestamp) {
      final dt = raw.toDate();
      return '${dt.day.toString().padLeft(2, '0')}.'
          '${dt.month.toString().padLeft(2, '0')}.'
          '${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  Color _durumRengi(String durum) {
    switch (durum.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'on_the_way':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  String _durumLabel(String durum) {
    switch (durum.toLowerCase()) {
      case 'pending':
        return 'Yeni Görev';
      case 'on_the_way':
        return 'Yolda';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal';
      default:
        return durum;
    }
  }

  Color _uygunlukRengi(String uygunluk) {
    final value = uygunluk.toLowerCase().trim();

    if (value == 'müsait' || value == 'musait') {
      return Colors.green;
    }
    if (value == 'görevde' || value == 'gorevde') {
      return Colors.orange;
    }
    if (value == 'çevrimdışı' || value == 'cevrimdisi') {
      return Colors.redAccent;
    }
    return Colors.white54;
  }

  void _telefonAra(String telefon) {
    final temiz = telefon.trim();
    if (temiz.isEmpty || temiz == '-') return;
    html.window.open('tel:$temiz', '_self');
  }

  void _whatsAppAc(String telefon) {
    final temiz = telefon.replaceAll(' ', '').trim();
    if (temiz.isEmpty || temiz == '-') return;

    String number = temiz;
    if (number.startsWith('0')) {
      number = '9${number.substring(1)}';
    } else if (!number.startsWith('9')) {
      number = '9$number';
    }

    final url = 'https://wa.me/$number';
    html.window.open(url, '_blank');
  }

  Future<void> _navigasyonSec({
    required double? lat,
    required double? lng,
  }) async {
    if (lat == null || lng == null) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Navigasyon Aç',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.map, color: Color(0xFFFFB300)),
                  title: const Text(
                    'Google Maps',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    final url =
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
                    html.window.open(url, '_blank');
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.alt_route, color: Color(0xFFFFB300)),
                  title: const Text(
                    'Yandex Maps',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    final url =
                        'https://yandex.com/maps/?rtext=~$lat,$lng&rtt=auto';
                    html.window.open(url, '_blank');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _teslimEt({
    required String orderId,
  }) async {
    try {
      await KuryeTeslimServisi.teslimEt(orderId: orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E1E1E),
          content: Text(
            'Sipariş teslim edildi.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Teslim işlemi başarısız: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _detayPanel({
    required String orderId,
    required Map<String, dynamic> data,
  }) async {
    final siparisNo = _safeString(data['siparisNo'], fallback: orderId);
    final musteriAd = _safeString(data['musteriAd']);
    final telefon = _safeString(data['musteriTelefon']);
    final adres = _safeString(data['teslimatAdresi'] ?? data['adres']);
    final durum =
        _safeString(data['status'] ?? data['durum'], fallback: 'pending');
    final dukkanAdi = _safeString(data['dukkanAdi'] ?? data['saticiAd']);
    final genelToplam = _asDouble(data['genelToplam']);
    final lat = data['lat'] is num ? (data['lat'] as num).toDouble() : null;
    final lng = data['lng'] is num ? (data['lng'] as num).toDouble() : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Text(
                  'Kurye Siparişi #$siparisNo',
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _infoSatiri('Müşteri', musteriAd),
                _infoSatiri('Telefon', telefon),
                _infoSatiri('Adres', adres),
                _infoSatiri('Satıcı', dukkanAdi),
                _infoSatiri('Durum', _durumLabel(durum)),
                _infoSatiri('Tutar', '₺${genelToplam.toStringAsFixed(0)}'),
                const Divider(color: Colors.white24, height: 28),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB300),
                        side: const BorderSide(color: Color(0xFFFFB300)),
                      ),
                      onPressed: () => _telefonAra(telefon),
                      icon: const Icon(Icons.phone),
                      label: const Text('Ara'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB300),
                        side: const BorderSide(color: Color(0xFFFFB300)),
                      ),
                      onPressed: () => _whatsAppAc(telefon),
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('WhatsApp'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB300),
                        side: const BorderSide(color: Color(0xFFFFB300)),
                      ),
                      onPressed: () => _navigasyonSec(lat: lat, lng: lng),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Navigasyon'),
                    ),
                    if (durum.toLowerCase() == 'on_the_way')
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _teslimEt(orderId: orderId);
                        },
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Teslim Et'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoSatiri(String label, String value) {
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
              text: value,
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

  Widget _profilKarti(Map<String, dynamic> kuryeData) {
    final adSoyad = _safeString(kuryeData['adSoyad'], fallback: aktifKuryeAdi);
    final telefon = _safeString(kuryeData['telefon']);
    final aracTipi = _safeString(kuryeData['aracTipi']);
    final plaka = _safeString(kuryeData['plaka']);
    final uygunluk = _safeString(kuryeData['uygunluk'], fallback: 'Bilinmiyor');
    final uygunlukLower = uygunluk.toLowerCase().trim();
    final aktifSiparis = _asInt(kuryeData['aktifSiparis']);
    final toplamTeslimat = _asInt(kuryeData['toplamTeslimat']);
    final rating = _asDouble(kuryeData['rating']);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33FFB300)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0x22FFB300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delivery_dining,
                  color: Color(0xFFFFB300),
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adSoyad,
                      style: const TextStyle(
                        color: Color(0xFFFFB300),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$aracTipi • $plaka',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      telefon,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _uygunlukRengi(uygunluk).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _uygunlukRengi(uygunluk)),
                ),
                child: Text(
                  uygunluk,
                  style: TextStyle(
                    color: _uygunlukRengi(uygunluk),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _istatistikMiniKart(
                  label: 'Aktif Görev',
                  value: aktifSiparis.toString(),
                  icon: Icons.assignment_turned_in,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _istatistikMiniKart(
                  label: 'Toplam Teslimat',
                  value: toplamTeslimat.toString(),
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _istatistikMiniKart(
                  label: 'Puan',
                  value: rating.toStringAsFixed(1),
                  icon: Icons.star,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFB300),
                side: const BorderSide(color: Color(0xFFFFB300)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _tekSeferlikKonumYenile,
              icon: const Icon(Icons.my_location),
              label: const Text('Konumu Güncelle'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (uygunlukLower == 'müsait' || uygunlukLower == 'musait')
                            ? Colors.green
                            : const Color(0xFF1F1F1F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _durumGuncelleniyor
                      ? null
                      : () => _kuryeDurumuGuncelle('Müsait'),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Müsait'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (uygunlukLower == 'çevrimdışı' ||
                            uygunlukLower == 'cevrimdisi')
                        ? Colors.redAccent
                        : const Color(0xFF1F1F1F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _durumGuncelleniyor
                      ? null
                      : () => _kuryeDurumuGuncelle('Çevrimdışı'),
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Çevrimdışı'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _istatistikMiniKart({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFFFB300), size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aksiyonlar({
    required String orderId,
    required String telefon,
    required double? lat,
    required double? lng,
    required String durum,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFB300),
            side: const BorderSide(color: Color(0xFFFFB300)),
          ),
          onPressed: () => _telefonAra(telefon),
          icon: const Icon(Icons.phone),
          label: const Text('Ara'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFB300),
            side: const BorderSide(color: Color(0xFFFFB300)),
          ),
          onPressed: () => _whatsAppAc(telefon),
          icon: const Icon(Icons.message_outlined),
          label: const Text('WhatsApp'),
        ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFB300),
            side: const BorderSide(color: Color(0xFFFFB300)),
          ),
          onPressed: () => _navigasyonSec(lat: lat, lng: lng),
          icon: const Icon(Icons.navigation_outlined),
          label: const Text('Navigasyon'),
        ),
        if (durum.toLowerCase() == 'on_the_way')
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _teslimEt(orderId: orderId),
            icon: const Icon(Icons.check_circle),
            label: const Text('Teslim Et'),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          'Kurye Paneli',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _kuryeStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0x33FFB300)),
                  ),
                  child: const Row(
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFFFFB300),
                      ),
                      SizedBox(width: 14),
                      Text(
                        'Kurye profili yükleniyor...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }

              final kuryeData = snapshot.data!.data() ?? {};
              return _profilKarti(kuryeData);
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _siparislerStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Kurye siparişleri okunamadı.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
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

                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs.where((doc) {
                  final data = doc.data();
                  final status = _safeString(
                    data['status'] ?? data['durum'],
                    fallback: '',
                  );
                  final assignmentStatus = _safeString(
                    data['assignmentStatus'],
                    fallback: '',
                  );
                  return _gosterilsin(status, assignmentStatus);
                }).toList();

                _yeniSiparisKontrolEt(docs);

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: const Color(0x22FFB300),
                              borderRadius: BorderRadius.circular(24),
                              border:
                                  Border.all(color: const Color(0x44FFB300)),
                            ),
                            child: const Icon(
                              Icons.delivery_dining,
                              size: 40,
                              color: Color(0xFFFFB300),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Aktif kurye görevi yok',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Size atanmış ve aktif olan teslimatlar burada listelenecek.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();

                    final orderId = doc.id;
                    final siparisNo =
                        _safeString(data['siparisNo'], fallback: orderId);
                    final musteriAd = _safeString(data['musteriAd']);
                    final telefon = _safeString(data['musteriTelefon']);
                    final adres = _safeString(
                      data['teslimatAdresi'] ?? data['adres'],
                    );
                    final dukkanAdi = _safeString(
                      data['dukkanAdi'] ?? data['saticiAd'],
                    );
                    final durum = _safeString(
                      data['status'] ?? data['durum'],
                      fallback: 'pending',
                    );
                    final createdAt = data['createdAt'];
                    final genelToplam = _asDouble(data['genelToplam']);
                    final lat = data['lat'] is num
                        ? (data['lat'] as num).toDouble()
                        : null;
                    final lng = data['lng'] is num
                        ? (data['lng'] as num).toDouble()
                        : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0x33FFB300)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _detayPanel(orderId: orderId, data: data),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color:
                                          _durumRengi(durum).withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.delivery_dining,
                                      color: _durumRengi(durum),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sipariş #$siparisNo',
                                          style: const TextStyle(
                                            color: Color(0xFFFFB300),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Müşteri: $musteriAd',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Satıcı: $dukkanAdi',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Telefon: $telefon',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tarih: ${_kisaTarih(createdAt)}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _durumRengi(durum)
                                              .withOpacity(0.18),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color: _durumRengi(durum),
                                          ),
                                        ),
                                        child: Text(
                                          _durumLabel(durum),
                                          style: TextStyle(
                                            color: _durumRengi(durum),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        '₺${genelToplam.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF171717),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFFFFB300),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        adres,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _aksiyonlar(
                                  orderId: orderId,
                                  telefon: telefon,
                                  lat: lat,
                                  lng: lng,
                                  durum: durum,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
