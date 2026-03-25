import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/admin/kurye_harita.dart';

import 'kurye_atama_motoru.dart';

class KuryeYonetimi extends StatefulWidget {
  const KuryeYonetimi({super.key});

  @override
  State<KuryeYonetimi> createState() => _KuryeYonetimiState();
}

class _KuryeYonetimiState extends State<KuryeYonetimi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _aramaController = TextEditingController();

  String _filtre = 'tum';
  String _aramaMetni = '';

  final List<Map<String, String>> _filtreler = const [
    {'value': 'tum', 'label': 'Tümü'},
    {'value': 'aktif', 'label': 'Aktif'},
    {'value': 'pasif', 'label': 'Pasif'},
    {'value': 'musait', 'label': 'Müsait'},
    {'value': 'gorevde', 'label': 'Görevde'},
  ];

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _kuryeStream() {
    return _firestore
        .collection('couriers')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtrele(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var sonuc = docs.where((doc) {
      final data = doc.data();
      final isActive = (data['isActive'] ?? false) == true;
      final uygunluk =
          (data['uygunlukDurumu'] ?? data['availability'] ?? 'musait')
              .toString()
              .trim()
              .toLowerCase();

      switch (_filtre) {
        case 'aktif':
          return isActive;
        case 'pasif':
          return !isActive;
        case 'musait':
          return uygunluk == 'musait' || uygunluk == 'available';
        case 'gorevde':
          return uygunluk == 'gorevde' || uygunluk == 'busy';
        case 'tum':
        default:
          return true;
      }
    }).toList();

    if (_aramaMetni.trim().isNotEmpty) {
      final q = _aramaMetni.toLowerCase().trim();

      sonuc = sonuc.where((doc) {
        final data = doc.data();

        final ad = (data['ad'] ?? data['name'] ?? '').toString().toLowerCase();
        final telefon =
            (data['telefon'] ?? data['phone'] ?? '').toString().toLowerCase();
        final sehir =
            (data['sehir'] ?? data['city'] ?? '').toString().toLowerCase();
        final bolge = (data['bolge'] ?? data['zone'] ?? data['ilce'] ?? '')
            .toString()
            .toLowerCase();
        final plaka =
            (data['plaka'] ?? data['plate'] ?? '').toString().toLowerCase();

        return ad.contains(q) ||
            telefon.contains(q) ||
            sehir.contains(q) ||
            bolge.contains(q) ||
            plaka.contains(q) ||
            doc.id.toLowerCase().contains(q);
      }).toList();
    }

    return sonuc;
  }

  String _uygunlukLabel(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'available':
      case 'musait':
        return 'Müsait';
      case 'busy':
      case 'gorevde':
        return 'Görevde';
      case 'offline':
      case 'cevrimdisi':
        return 'Çevrimdışı';
      default:
        return raw.isEmpty ? '-' : raw;
    }
  }

  Color _uygunlukRengi(String raw) {
    final v = raw.trim().toLowerCase();
    switch (v) {
      case 'available':
      case 'musait':
        return Colors.green;
      case 'busy':
      case 'gorevde':
        return Colors.orange;
      case 'offline':
      case 'cevrimdisi':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  Future<void> _aktiflikGuncelle({
    required String kuryeId,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('couriers').doc(kuryeId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'adminLastActionAt': FieldValue.serverTimestamp(),
        'adminLastAction': 'active_toggle',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? 'Kurye aktif yapıldı' : 'Kurye pasif yapıldı',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktiflik güncellenemedi: $e')),
      );
    }
  }

  Future<void> _uygunlukGuncelle({
    required String kuryeId,
    required String yeniDurum,
  }) async {
    try {
      await _firestore.collection('couriers').doc(kuryeId).update({
        'uygunlukDurumu': yeniDurum,
        'availability': yeniDurum,
        'updatedAt': FieldValue.serverTimestamp(),
        'adminLastActionAt': FieldValue.serverTimestamp(),
        'adminLastAction': 'availability_update',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kurye durumu güncellendi: $yeniDurum')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Durum güncellenemedi: $e')),
      );
    }
  }

  Future<void> _adminNotuDialog({
    required String kuryeId,
    required String mevcutNot,
  }) async {
    final controller = TextEditingController(text: mevcutNot);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Kurye Admin Notu',
            style: TextStyle(color: Color(0xFFFFB300)),
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Not giriniz...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFFB300)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                try {
                  await _firestore.collection('couriers').doc(kuryeId).update({
                    'adminNotu': controller.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'adminLastActionAt': FieldValue.serverTimestamp(),
                    'adminLastAction': 'note_update',
                  });

                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin notu kaydedildi')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Not kaydedilemedi: $e')),
                  );
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  Future<void> _detayPanel({
    required String kuryeId,
    required Map<String, dynamic> data,
  }) async {
    final ad = (data['ad'] ?? data['name'] ?? '-').toString();
    final telefon = (data['telefon'] ?? data['phone'] ?? '-').toString();
    final sehir = (data['sehir'] ?? data['city'] ?? '-').toString();
    final bolge =
        (data['bolge'] ?? data['zone'] ?? data['ilce'] ?? '-').toString();
    final plaka = (data['plaka'] ?? data['plate'] ?? '-').toString();
    final aracTipi =
        (data['aracTipi'] ?? data['vehicleType'] ?? '-').toString();
    final uygunluk =
        (data['uygunlukDurumu'] ?? data['availability'] ?? 'musait').toString();
    final adminNotu = (data['adminNotu'] ?? '').toString();
    final isActive = (data['isActive'] ?? false) == true;

    final aktifSiparisSayisiRaw =
        data['aktifSiparisSayisi'] ?? data['activeOrderCount'];
    final aktifSiparisSayisi = aktifSiparisSayisiRaw is num
        ? aktifSiparisSayisiRaw.toInt()
        : int.tryParse(aktifSiparisSayisiRaw?.toString() ?? '') ?? 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111111),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text(
                      'Kurye Harita Merkezi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KuryeHarita(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.psychology),
                    label: const Text(
                      'Kurye Atama Motoru',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KuryeAtamaMotoru(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
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
                  ad,
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _infoSatiri('Kurye ID', kuryeId),
                _infoSatiri('Telefon', telefon),
                _infoSatiri('Şehir', sehir),
                _infoSatiri('Bölge', bolge),
                _infoSatiri('Araç Tipi', aracTipi),
                _infoSatiri('Plaka', plaka),
                _infoSatiri('Aktiflik', isActive ? 'Aktif' : 'Pasif'),
                _infoSatiri('Uygunluk', _uygunlukLabel(uygunluk)),
                _infoSatiri('Aktif Sipariş', aktifSiparisSayisi.toString()),
                _infoSatiri('Admin Notu', adminNotu.isEmpty ? '-' : adminNotu),
                const Divider(color: Colors.white24, height: 28),
                const Text(
                  'Admin Müdahalesi',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isActive ? Colors.orange : Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _aktiflikGuncelle(
                          kuryeId: kuryeId,
                          isActive: !isActive,
                        );
                      },
                      icon: Icon(isActive ? Icons.block : Icons.check_circle),
                      label: Text(isActive ? 'Pasife Al' : 'Aktife Al'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _uygunlukGuncelle(
                          kuryeId: kuryeId,
                          yeniDurum: 'musait',
                        );
                      },
                      icon: const Icon(Icons.done_all),
                      label: const Text('Müsait'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _uygunlukGuncelle(
                          kuryeId: kuryeId,
                          yeniDurum: 'gorevde',
                        );
                      },
                      icon: const Icon(Icons.delivery_dining),
                      label: const Text('Görevde'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _uygunlukGuncelle(
                          kuryeId: kuryeId,
                          yeniDurum: 'cevrimdisi',
                        );
                      },
                      icon: const Icon(Icons.wifi_off),
                      label: const Text('Çevrimdışı'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB300),
                        side: const BorderSide(color: Color(0xFFFFB300)),
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _adminNotuDialog(
                          kuryeId: kuryeId,
                          mevcutNot: adminNotu,
                        );
                      },
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Admin Notu'),
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

  String _kisaTarih(dynamic raw) {
    if (raw is Timestamp) {
      final dt = raw.toDate();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          'KURYE YÖNETİMİ',
          style: TextStyle(
            color: Color(0xFFFFB300),
            letterSpacing: 1.2,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            color: Colors.black,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text(
                      'Kurye Harita Merkezi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KuryeHarita(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.psychology),
                    label: const Text(
                      'Kurye Atama Motoru',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KuryeAtamaMotoru(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB300),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                TextField(
                  controller: _aramaController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _aramaMetni = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Kurye, telefon, şehir, bölge ara...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFFFFB300)),
                    filled: true,
                    fillColor: const Color(0xFF141414),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFFB300)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filtreler.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = _filtreler[index];
                      final secili = _filtre == item['value'];

                      return ChoiceChip(
                        label: Text(item['label']!),
                        selected: secili,
                        labelStyle: TextStyle(
                          color: secili ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        selectedColor: const Color(0xFFFFB300),
                        backgroundColor: const Color(0xFF181818),
                        side: BorderSide(
                          color: secili
                              ? const Color(0xFFFFB300)
                              : Colors.grey.shade800,
                        ),
                        onSelected: (_) {
                          setState(() {
                            _filtre = item['value']!;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _kuryeStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Veri okunamadı: ${snapshot.error}',
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

                final docs = snapshot.data?.docs ?? [];
                final filtreli = _filtrele(docs);

                if (filtreli.isEmpty) {
                  return const Center(
                    child: Text(
                      'Gösterilecek kurye bulunamadı',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  itemCount: filtreli.length,
                  itemBuilder: (context, index) {
                    final doc = filtreli[index];
                    final data = doc.data();

                    final ad =
                        (data['ad'] ?? data['name'] ?? 'Kurye').toString();
                    final telefon =
                        (data['telefon'] ?? data['phone'] ?? '-').toString();
                    final sehir =
                        (data['sehir'] ?? data['city'] ?? '-').toString();
                    final bolge =
                        (data['bolge'] ?? data['zone'] ?? data['ilce'] ?? '-')
                            .toString();
                    final plaka =
                        (data['plaka'] ?? data['plate'] ?? '-').toString();
                    final uygunluk = (data['uygunlukDurumu'] ??
                            data['availability'] ??
                            'musait')
                        .toString();
                    final isActive = (data['isActive'] ?? false) == true;
                    final createdAt = data['createdAt'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade800),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _detayPanel(
                          kuryeId: doc.id,
                          data: data,
                        ),
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
                                      color: _uygunlukRengi(uygunluk)
                                          .withAlpha(40),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.delivery_dining,
                                      color: _uygunlukRengi(uygunluk),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ad,
                                          style: const TextStyle(
                                            color: Color(0xFFFFB300),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Tel: $telefon',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$sehir / $bolge',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Plaka: $plaka • Kayıt: ${_kisaTarih(createdAt)}',
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
                                          color: _uygunlukRengi(uygunluk)
                                              .withAlpha(46),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color: _uygunlukRengi(uygunluk),
                                          ),
                                        ),
                                        child: Text(
                                          _uygunlukLabel(uygunluk),
                                          style: TextStyle(
                                            color: _uygunlukRengi(uygunluk),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.green.withAlpha(46)
                                              : Colors.red.withAlpha(46),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color: isActive
                                                ? Colors.green
                                                : Colors.redAccent,
                                          ),
                                        ),
                                        child: Text(
                                          isActive ? 'Aktif' : 'Pasif',
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.green
                                                : Colors.redAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _uygunlukGuncelle(
                                      kuryeId: doc.id,
                                      yeniDurum: 'musait',
                                    ),
                                    icon: const Icon(Icons.done_all),
                                    label: const Text('Müsait'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _uygunlukGuncelle(
                                      kuryeId: doc.id,
                                      yeniDurum: 'gorevde',
                                    ),
                                    icon: const Icon(Icons.delivery_dining),
                                    label: const Text('Görevde'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isActive
                                          ? Colors.redAccent
                                          : Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _aktiflikGuncelle(
                                      kuryeId: doc.id,
                                      isActive: !isActive,
                                    ),
                                    icon: Icon(
                                      isActive
                                          ? Icons.block
                                          : Icons.check_circle,
                                    ),
                                    label: Text(
                                      isActive ? 'Pasife Al' : 'Aktife Al',
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFFFB300),
                                      side: const BorderSide(
                                        color: Color(0xFFFFB300),
                                      ),
                                    ),
                                    onPressed: () => _adminNotuDialog(
                                      kuryeId: doc.id,
                                      mevcutNot:
                                          (data['adminNotu'] ?? '').toString(),
                                    ),
                                    icon: const Icon(Icons.note_alt_outlined),
                                    label: const Text('Not'),
                                  ),
                                ],
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
