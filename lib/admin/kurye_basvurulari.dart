import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'kurye_harita_merkezi_sayfasi.dart';
import 'kurye_atama_motoru.dart';

class KuryeBasvurulariSayfasi extends StatefulWidget {
  const KuryeBasvurulariSayfasi({super.key});

  @override
  State<KuryeBasvurulariSayfasi> createState() =>
      _KuryeBasvurulariSayfasiState();
}

class _KuryeBasvurulariSayfasiState extends State<KuryeBasvurulariSayfasi> {
  final TextEditingController _aramaController = TextEditingController();

  String _aramaMetni = '';
  String _aktifFiltre = 'Tümü';
  String? _seciliBasvuruId;

  final List<String> _filtreler = const [
    'Tümü',
    'Beklemede',
    'Onaylandı',
    'Reddedildi',
  ];

  Stream<QuerySnapshot<Map<String, dynamic>>> _basvurularStream() {
    return FirebaseFirestore.instance
        .collection('courier_applications')
        .snapshots();
  }

  String _safeText(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    if (text.isEmpty) return '-';
    return text;
  }

  String _adSoyad(Map<String, dynamic> data) => _safeText(data['adSoyad']);

  String _telefon(Map<String, dynamic> data) => _safeText(data['telefon']);

  String _sehir(Map<String, dynamic> data) => _safeText(data['sehir']);

  String _ilce(Map<String, dynamic> data) => _safeText(data['ilce']);

  String _aracTipi(Map<String, dynamic> data) {
    return _safeText(data['aracTipi'] ?? data['aracTip']);
  }

  String _plaka(Map<String, dynamic> data) => _safeText(data['plaka']);

  String _not(Map<String, dynamic> data) => _safeText(data['not']);

  String _source(Map<String, dynamic> data) => _safeText(data['source']);

  String _durum(Map<String, dynamic> data) {
    final raw = _safeText(data['durum'] ?? 'beklemede').toLowerCase();
    switch (raw) {
      case 'onaylandi':
        return 'Onaylandı';
      case 'reddedildi':
        return 'Reddedildi';
      case 'beklemede':
      default:
        return 'Beklemede';
    }
  }

  String _uygunluk(Map<String, dynamic> data) {
    return _safeText(data['uygunluk'] ?? 'Başvuru Aşaması');
  }

  String _aktiflik(Map<String, dynamic> data) {
    final aktifMi = data['aktifMi'];
    if (aktifMi == true) return 'Aktif';
    if (aktifMi == false) return 'Pasif';
    return 'Pasif';
  }

  int _aktifSiparis(Map<String, dynamic> data) {
    final value = data['aktifSiparis'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  DateTime _extractCreatedAt(Map<String, dynamic> data) {
    final value = data['createdAt'];
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Color _durumRengi(String durum) {
    switch (durum.toLowerCase()) {
      case 'onaylandı':
        return const Color(0xFF4CD964);
      case 'reddedildi':
        return const Color(0xFFFF5A5F);
      case 'beklemede':
      default:
        return const Color(0xFFFFB300);
    }
  }

  Color _uygunlukRengi(String uygunluk) {
    switch (uygunluk.toLowerCase()) {
      case 'müsait':
        return const Color(0xFF4CD964);
      case 'görevde':
        return const Color(0xFFFFB300);
      case 'çevrimdışı':
      case 'cevrimdisi':
        return const Color(0xFFFF5A5F);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  Future<void> _durumGuncelle(String docId, String yeniDurum) async {
    await FirebaseFirestore.instance
        .collection('courier_applications')
        .doc(docId)
        .update({
      'durum': yeniDurum,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _adminAlanlariGuncelle(
    String docId, {
    bool? aktifMi,
    String? uygunluk,
    String? adminNotu,
  }) async {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (aktifMi != null) payload['aktifMi'] = aktifMi;
    if (uygunluk != null) payload['uygunluk'] = uygunluk;
    if (adminNotu != null) payload['adminNotu'] = adminNotu;

    await FirebaseFirestore.instance
        .collection('courier_applications')
        .doc(docId)
        .update(payload);
  }

  Future<void> _courierKaydiOlusturVeyaGuncelle({
    required String applicationId,
    required Map<String, dynamic> data,
  }) async {
    final couriers = FirebaseFirestore.instance.collection('couriers');

    final mevcut = await couriers
        .where('kaynakBasvuruId', isEqualTo: applicationId)
        .limit(1)
        .get();

    final kayit = <String, dynamic>{
      'adSoyad': _adSoyad(data),
      'telefon': _telefon(data),
      'sehir': _sehir(data),
      'ilce': _ilce(data),
      'aracTipi': _aracTipi(data),
      'plaka': _plaka(data) == '-' ? '' : _plaka(data),
      'not': _not(data) == '-' ? '' : _not(data),
      'aktifMi': true,
      'uygunluk': 'Müsait',
      'aktifSiparis': 0,
      'adminNotu': _safeText(data['adminNotu']) == '-'
          ? 'Başvuru onaylandı.'
          : _safeText(data['adminNotu']),
      'kaynakBasvuruId': applicationId,
      'source': 'kurye_basvurulari_onay',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (mevcut.docs.isEmpty) {
      kayit['createdAt'] = FieldValue.serverTimestamp();
      await couriers.add(kayit);
    } else {
      await couriers.doc(mevcut.docs.first.id).update(kayit);
    }
  }

  Future<void> _onaylaBasvuru({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    await FirebaseFirestore.instance
        .collection('courier_applications')
        .doc(docId)
        .update({
      'durum': 'onaylandi',
      'aktifMi': true,
      'uygunluk': 'Müsait',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _courierKaydiOlusturVeyaGuncelle(
      applicationId: docId,
      data: data,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Başvuru onaylandı ve couriers koleksiyonuna aktarıldı.'),
      ),
    );
  }

  Future<void> _reddetBasvuru(
    BuildContext context,
    String docId,
  ) async {
    await _durumGuncelle(docId, 'reddedildi');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Başvuru reddedildi.')),
    );
  }

  Future<void> _adminNotuDialogAc({
    required BuildContext context,
    required String docId,
    required String mevcutNot,
  }) async {
    final controller = TextEditingController(
      text: mevcutNot == '-' ? '' : mevcutNot,
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161616),
          title: const Text(
            'Admin Notu',
            style: TextStyle(color: Color(0xFFFFB300)),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Kurye hakkında not yaz...',
              hintStyle: const TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFFFFB300).withOpacity(0.35),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFFFB300)),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _adminAlanlariGuncelle(
                  docId,
                  adminNotu: controller.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin notu güncellendi.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black,
              ),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtreliBasvurular(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sonuc = docs.where((doc) {
      final data = doc.data();

      final metin =
          '${_adSoyad(data)} ${_telefon(data)} ${_sehir(data)} ${_ilce(data)} ${_aracTipi(data)}'
              .toLowerCase();

      final aramaUygun = _aramaMetni.trim().isEmpty ||
          metin.contains(_aramaMetni.toLowerCase());

      final durum = _durum(data);

      bool filtreUygun = true;
      if (_aktifFiltre == 'Beklemede') {
        filtreUygun = durum == 'Beklemede';
      } else if (_aktifFiltre == 'Onaylandı') {
        filtreUygun = durum == 'Onaylandı';
      } else if (_aktifFiltre == 'Reddedildi') {
        filtreUygun = durum == 'Reddedildi';
      }

      return aramaUygun && filtreUygun;
    }).toList();

    sonuc.sort((a, b) {
      final aDate = _extractCreatedAt(a.data());
      final bDate = _extractCreatedAt(b.data());
      return bDate.compareTo(aDate);
    });

    return sonuc;
  }

  Widget _topActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFFB300),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB300).withOpacity(0.22),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final secili = _aktifFiltre == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _aktifFiltre = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: secili ? const Color(0xFFFFB300) : const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: secili ? const Color(0xFFFFB300) : const Color(0xFF3B3B3B),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (secili) ...[
              const Icon(Icons.check, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: secili ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _solListeKart({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required bool secili,
  }) {
    final data = doc.data();

    return GestureDetector(
      onTap: () {
        setState(() {
          _seciliBasvuruId = doc.id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: secili ? const Color(0xFF1E1A12) : const Color(0xFF141414),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: secili ? const Color(0xFFFFB300) : const Color(0x33FFB300),
            width: secili ? 1.4 : 1,
          ),
          boxShadow: secili
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withOpacity(0.12),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0x22FFB300),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.delivery_dining,
                color: Color(0xFFFFB300),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _adSoyad(data),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tel: ${_telefon(data)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_sehir(data)} / ${_ilce(data)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Araç: ${_aracTipi(data)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _statChip(
                    text: _durum(data),
                    color: _durumRengi(_durum(data)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFB300), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      color: Color(0xFFFFD36A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required Color color,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _outlinedGoldButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFF171717),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFB300), width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFFFFB300), size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFFFFD36A),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bosDetayPaneli() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33FFB300)),
      ),
      child: const Center(
        child: Text(
          'Detay görmek için soldan bir başvuru seç.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _detayPaneli(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final adSoyad = _adSoyad(data);
    final telefon = _telefon(data);
    final sehir = _sehir(data);
    final ilce = _ilce(data);
    final aracTipi = _aracTipi(data);
    final plaka = _plaka(data);
    final not = _not(data);
    final source = _source(data);
    final durum = _durum(data);
    final adminNotu = _safeText(data['adminNotu']);
    final uygunluk = _uygunluk(data);
    final aktiflik = _aktiflik(data);
    final aktifSiparis = _aktifSiparis(data);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x33FFB300)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  adSoyad,
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                _statChip(
                  text: durum,
                  color: _durumRengi(durum),
                  icon: Icons.verified_user,
                ),
                _statChip(
                  text: uygunluk,
                  color: _uygunlukRengi(uygunluk),
                  icon: Icons.local_shipping,
                ),
                _statChip(
                  text: aktiflik,
                  color: aktiflik == 'Aktif'
                      ? const Color(0xFF4CD964)
                      : const Color(0xFF8E8E93),
                  icon: Icons.power_settings_new,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _infoRow(
              icon: Icons.badge,
              label: 'Başvuru ID',
              value: doc.id,
            ),
            _infoRow(
              icon: Icons.phone,
              label: 'Telefon',
              value: telefon,
            ),
            _infoRow(
              icon: Icons.location_city,
              label: 'Şehir',
              value: sehir,
            ),
            _infoRow(
              icon: Icons.map,
              label: 'İlçe',
              value: ilce,
            ),
            _infoRow(
              icon: Icons.two_wheeler,
              label: 'Araç Tipi',
              value: aracTipi,
            ),
            _infoRow(
              icon: Icons.pin,
              label: 'Plaka',
              value: plaka,
            ),
            _infoRow(
              icon: Icons.fact_check,
              label: 'Durum',
              value: durum,
            ),
            _infoRow(
              icon: Icons.route,
              label: 'Uygunluk',
              value: uygunluk,
            ),
            _infoRow(
              icon: Icons.shopping_bag,
              label: 'Aktif Sipariş',
              value: aktifSiparis.toString(),
            ),
            _infoRow(
              icon: Icons.note,
              label: 'Başvuru Notu',
              value: not,
            ),
            _infoRow(
              icon: Icons.admin_panel_settings,
              label: 'Admin Notu',
              value: adminNotu,
            ),
            _infoRow(
              icon: Icons.source,
              label: 'Kaynak',
              value: source,
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 1,
              color: Colors.white24,
            ),
            const Text(
              'Admin Müdahalesi',
              style: TextStyle(
                color: Color(0xFFFFB300),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _actionButton(
                  color: const Color(0xFF4CD964),
                  icon: Icons.check_circle,
                  text: 'Onayla',
                  onTap: () async {
                    try {
                      await _onaylaBasvuru(
                        context: context,
                        docId: doc.id,
                        data: data,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Onay hatası: $e')),
                      );
                    }
                  },
                ),
                _actionButton(
                  color: const Color(0xFFFF5A5F),
                  icon: Icons.close,
                  text: 'Reddet',
                  onTap: () async {
                    try {
                      await _reddetBasvuru(context, doc.id);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Red hatası: $e')),
                      );
                    }
                  },
                ),
                _actionButton(
                  color: const Color(0xFF56CCF2),
                  icon: Icons.bolt,
                  text: 'Aktife Al',
                  onTap: () async {
                    try {
                      await _adminAlanlariGuncelle(doc.id, aktifMi: true);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kurye aktif yapıldı.')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Aktifleştirme hatası: $e')),
                      );
                    }
                  },
                ),
                _actionButton(
                  color: const Color(0xFF4CD964),
                  icon: Icons.done_all,
                  text: 'Müsait',
                  onTap: () async {
                    try {
                      await _adminAlanlariGuncelle(doc.id, uygunluk: 'Müsait');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Uygunluk: Müsait')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Güncelleme hatası: $e')),
                      );
                    }
                  },
                ),
                _actionButton(
                  color: const Color(0xFFFFB300),
                  icon: Icons.delivery_dining,
                  text: 'Görevde',
                  onTap: () async {
                    try {
                      await _adminAlanlariGuncelle(doc.id, uygunluk: 'Görevde');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Uygunluk: Görevde')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Güncelleme hatası: $e')),
                      );
                    }
                  },
                ),
                _actionButton(
                  color: const Color(0xFFFF5A5F),
                  icon: Icons.wifi_off,
                  text: 'Çevrimdışı',
                  onTap: () async {
                    try {
                      await _adminAlanlariGuncelle(
                        doc.id,
                        uygunluk: 'Çevrimdışı',
                        aktifMi: false,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Kurye çevrimdışı yapıldı.')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Güncelleme hatası: $e')),
                      );
                    }
                  },
                ),
                _outlinedGoldButton(
                  icon: Icons.edit_note,
                  text: 'Admin Notu',
                  onTap: () {
                    _adminNotuDialogAc(
                      context: context,
                      docId: doc.id,
                      mevcutNot: adminNotu,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLikeLayout(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    QueryDocumentSnapshot<Map<String, dynamic>>? seciliDoc,
  ) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 370,
            child: Column(
              children: [
                Expanded(
                  child: docs.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0x33FFB300),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Bu filtrede başvuru bulunamadı.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            return _solListeKart(
                              doc: doc,
                              secili: doc.id == _seciliBasvuruId,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child:
                seciliDoc == null ? _bosDetayPaneli() : _detayPaneli(seciliDoc),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    QueryDocumentSnapshot<Map<String, dynamic>>? seciliDoc,
  ) {
    return Expanded(
      child: ListView(
        children: [
          if (docs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x33FFB300)),
              ),
              child: const Center(
                child: Text(
                  'Bu filtrede başvuru bulunamadı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ...docs.map(
              (doc) => _solListeKart(
                doc: doc,
                secili: doc.id == _seciliBasvuruId,
              ),
            ),
          const SizedBox(height: 12),
          seciliDoc == null ? _bosDetayPaneli() : _detayPaneli(seciliDoc),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          'Kurye Başvuruları',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _basvurularStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Veri okunurken hata oluştu:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                    ),
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

            final rawDocs = snapshot.data?.docs ?? [];
            final docs = _filtreliBasvurular(rawDocs);

            if (docs.isNotEmpty) {
              final seciliHalaVar =
                  docs.any((element) => element.id == _seciliBasvuruId);

              if (!seciliHalaVar) {
                _seciliBasvuruId = docs.first.id;
              }
            } else {
              _seciliBasvuruId = null;
            }

            QueryDocumentSnapshot<Map<String, dynamic>>? seciliDoc;
            if (_seciliBasvuruId != null) {
              for (final doc in docs) {
                if (doc.id == _seciliBasvuruId) {
                  seciliDoc = doc;
                  break;
                }
              }
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0x33FFB300),
                          ),
                        ),
                        child: Column(
                          children: [
                            if (isWide)
                              Row(
                                children: [
                                  Expanded(
                                    child: _topActionButton(
                                      icon: Icons.map_outlined,
                                      title: 'Kurye Harita Merkezi',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const KuryeHaritaMerkeziSayfasi(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _topActionButton(
                                      icon: Icons.settings_input_component,
                                      title: 'Kurye Atama Motoru',
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const KuryeAtamaMotoru(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _topActionButton(
                                    icon: Icons.map_outlined,
                                    title: 'Kurye Harita Merkezi',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const KuryeHaritaMerkeziSayfasi(),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _topActionButton(
                                    icon: Icons.settings_input_component,
                                    title: 'Kurye Atama Motoru',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const KuryeAtamaMotoru(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F0F),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0x33FFB300),
                                ),
                              ),
                              child: TextField(
                                controller: _aramaController,
                                onChanged: (value) {
                                  setState(() {
                                    _aramaMetni = value.trim();
                                  });
                                },
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Kurye, telefon, şehir, ilçe veya araç tipi ara',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Color(0xFFFFB300),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _filtreler
                                    .map(
                                      (e) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 10,
                                        ),
                                        child: _filterChip(e),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      isWide
                          ? _buildDesktopLikeLayout(docs, seciliDoc)
                          : _buildMobileLayout(docs, seciliDoc),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
