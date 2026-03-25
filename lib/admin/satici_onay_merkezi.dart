import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SaticiOnayMerkezi extends StatefulWidget {
  const SaticiOnayMerkezi({super.key});

  @override
  State<SaticiOnayMerkezi> createState() => _SaticiOnayMerkeziState();
}

class _SaticiOnayMerkeziState extends State<SaticiOnayMerkezi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _aramaController = TextEditingController();

  String _durumFiltresi = 'beklemede';
  String _aramaMetni = '';

  final List<Map<String, String>> _durumlar = const [
    {'value': 'beklemede', 'label': 'Bekleyenler'},
    {'value': 'onaylandi', 'label': 'Onaylılar'},
    {'value': 'reddedildi', 'label': 'Reddedilenler'},
    {'value': 'tum', 'label': 'Tümü'},
  ];

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamSaticilar() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('ev_lezzetleri')
        .orderBy('createdAt', descending: true);

    if (_durumFiltresi != 'tum') {
      query = query.where('onayDurumu', isEqualTo: _durumFiltresi);
    }

    return query.snapshots();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtreleClientSide(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (_aramaMetni.trim().isEmpty) return docs;

    final q = _aramaMetni.toLowerCase().trim();

    return docs.where((doc) {
      final data = doc.data();

      final ad = (data['ad'] ?? '').toString().toLowerCase();
      final sehir = (data['sehir'] ?? '').toString().toLowerCase();
      final ilce = (data['ilce'] ?? '').toString().toLowerCase();
      final adres = (data['adres'] ?? '').toString().toLowerCase();
      final tip = (data['tip'] ?? '').toString().toLowerCase();
      final telefon = (data['telefon'] ?? '').toString().toLowerCase();

      return ad.contains(q) ||
          sehir.contains(q) ||
          ilce.contains(q) ||
          adres.contains(q) ||
          tip.contains(q) ||
          telefon.contains(q);
    }).toList();
  }

  Future<void> _onayDurumuGuncelle({
    required String docId,
    required String yeniDurum,
  }) async {
    try {
      await _firestore.collection('ev_lezzetleri').doc(docId).update({
        'onayDurumu': yeniDurum,
        'updatedAt': FieldValue.serverTimestamp(),
        'sonDenetimTarihi': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Onay durumu güncellendi: $yeniDurum')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız: $e')),
      );
    }
  }

  Future<void> _aktiflikGuncelle({
    required String docId,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('ev_lezzetleri').doc(docId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(isActive ? 'Satıcı aktif yapıldı' : 'Satıcı pasif yapıldı'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aktiflik güncellenemedi: $e')),
      );
    }
  }

  Future<void> _adminNotuDialog({
    required String docId,
    required String mevcutNot,
  }) async {
    final controller = TextEditingController(text: mevcutNot);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Admin Notu Düzenle',
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
              onPressed: () => Navigator.pop(context),
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
                  await _firestore
                      .collection('ev_lezzetleri')
                      .doc(docId)
                      .update({
                    'adminNotu': controller.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Admin notu kaydedildi')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Not kaydedilemedi: $e')),
                    );
                  }
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

  Future<void> _detayAltSheet({
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final String ad = (data['ad'] ?? '-').toString();
    final String sehir = (data['sehir'] ?? '-').toString();
    final String ilce = (data['ilce'] ?? '-').toString();
    final String adres = (data['adres'] ?? '-').toString();
    final String telefon = (data['telefon'] ?? '-').toString();
    final String tip = (data['tip'] ?? 'Ev Lezzetleri').toString();
    final String onayDurumu = (data['onayDurumu'] ?? 'beklemede').toString();
    final bool isActive = (data['isActive'] ?? false) == true;
    final String img = (data['img'] ?? '').toString();
    final String adminNotu = (data['adminNotu'] ?? '').toString();

    final dynamic aiRiskSkoruRaw = data['aiRiskSkoru'];
    final dynamic aiDenetimDurumuRaw = data['aiDenetimDurumu'];
    final dynamic aiDenetimNotuRaw = data['aiDenetimNotu'];

    final String aiRiskSkoru = aiRiskSkoruRaw?.toString() ?? '-';
    final String aiDenetimDurumu =
        aiDenetimDurumuRaw?.toString() ?? 'hazir_degil';
    final String aiDenetimNotu = aiDenetimNotuRaw?.toString() ?? '-';

    if (!mounted) return;

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
                  ad,
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (img.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      img,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        alignment: Alignment.center,
                        color: Colors.black26,
                        child: const Text(
                          'Görsel yüklenemedi',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _infoSatiri('Tip', tip),
                _infoSatiri('Şehir', sehir),
                _infoSatiri('İlçe', ilce),
                _infoSatiri('Adres', adres),
                _infoSatiri('Telefon', telefon),
                _infoSatiri('Onay Durumu', onayDurumu),
                _infoSatiri('Aktiflik', isActive ? 'Aktif' : 'Pasif'),
                const Divider(color: Colors.white24, height: 28),
                const Text(
                  'Admin Alanı',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _infoSatiri('Admin Notu', adminNotu.isEmpty ? '-' : adminNotu),
                const Divider(color: Colors.white24, height: 28),
                const Text(
                  'AI Denetim Alanları',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _infoSatiri('AI Risk Skoru', aiRiskSkoru),
                _infoSatiri('AI Denetim Durumu', aiDenetimDurumu),
                _infoSatiri('AI Denetim Notu', aiDenetimNotu),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _onayDurumuGuncelle(
                          docId: docId,
                          yeniDurum: 'onaylandi',
                        );
                      },
                      icon: const Icon(Icons.verified),
                      label: const Text('Onayla'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _onayDurumuGuncelle(
                          docId: docId,
                          yeniDurum: 'reddedildi',
                        );
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reddet'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _aktiflikGuncelle(
                          docId: docId,
                          isActive: !isActive,
                        );
                      },
                      icon: Icon(isActive ? Icons.toggle_off : Icons.toggle_on),
                      label: Text(isActive ? 'Pasife Al' : 'Aktife Al'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB300),
                        side: const BorderSide(color: Color(0xFFFFB300)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _adminNotuDialog(
                          docId: docId,
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

  Color _durumRengi(String durum) {
    switch (durum) {
      case 'onaylandi':
        return Colors.green;
      case 'reddedildi':
        return Colors.redAccent;
      case 'beklemede':
      default:
        return Colors.orange;
    }
  }

  String _durumLabel(String durum) {
    switch (durum) {
      case 'onaylandi':
        return 'Onaylı';
      case 'reddedildi':
        return 'Reddedildi';
      case 'beklemede':
      default:
        return 'Beklemede';
    }
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
          'SATICI ONAY MERKEZİ',
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
                TextField(
                  controller: _aramaController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _aramaMetni = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Satıcı, şehir, ilçe, adres ara...',
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
                    itemCount: _durumlar.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = _durumlar[index];
                      final secili = _durumFiltresi == item['value'];

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
                            _durumFiltresi = item['value']!;
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
              stream: _streamSaticilar(),
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
                final filtreliDocs = _filtreleClientSide(docs);

                if (filtreliDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Gösterilecek satıcı bulunamadı',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  itemCount: filtreliDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filtreliDocs[index];
                    final data = doc.data();

                    final String ad =
                        (data['ad'] ?? 'İsimsiz Satıcı').toString();
                    final String sehir = (data['sehir'] ?? '-').toString();
                    final String ilce = (data['ilce'] ?? '-').toString();
                    final String tip =
                        (data['tip'] ?? 'Ev Lezzetleri').toString();
                    final String telefon = (data['telefon'] ?? '-').toString();
                    final String onayDurumu =
                        (data['onayDurumu'] ?? 'beklemede').toString();
                    final String adminNotu =
                        (data['adminNotu'] ?? '').toString();
                    final bool isActive = (data['isActive'] ?? false) == true;
                    final String img = (data['img'] ?? '').toString();

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
                          )
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _detayAltSheet(docId: doc.id, data: data),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: img.isNotEmpty
                                        ? Image.network(
                                            img,
                                            width: 82,
                                            height: 82,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _bosGorsel(),
                                          )
                                        : _bosGorsel(),
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
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$sehir / $ilce',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tip: $tip',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tel: $telefon',
                                          style: const TextStyle(
                                            color: Colors.white70,
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
                                          color: _durumRengi(onayDurumu)
                                              .withOpacity(0.18),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color: _durumRengi(onayDurumu),
                                          ),
                                        ),
                                        child: Text(
                                          _durumLabel(onayDurumu),
                                          style: TextStyle(
                                            color: _durumRengi(onayDurumu),
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
                                              ? Colors.green.withOpacity(0.18)
                                              : Colors.red.withOpacity(0.18),
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
                              if (adminNotu.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black26,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  child: Text(
                                    'Admin Notu: $adminNotu',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
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
                                    onPressed: () => _onayDurumuGuncelle(
                                      docId: doc.id,
                                      yeniDurum: 'onaylandi',
                                    ),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Onayla'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _onayDurumuGuncelle(
                                      docId: doc.id,
                                      yeniDurum: 'reddedildi',
                                    ),
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Reddet'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isActive
                                          ? Colors.orange
                                          : Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _aktiflikGuncelle(
                                      docId: doc.id,
                                      isActive: !isActive,
                                    ),
                                    icon: Icon(
                                      isActive
                                          ? Icons.visibility_off
                                          : Icons.visibility,
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
                                      docId: doc.id,
                                      mevcutNot: adminNotu,
                                    ),
                                    icon: const Icon(Icons.note_alt_outlined),
                                    label: const Text('Admin Notu'),
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

  Widget _bosGorsel() {
    return Container(
      width: 82,
      height: 82,
      color: const Color(0xFF1C1C1C),
      child: const Icon(
        Icons.storefront,
        color: Color(0xFFFFB300),
        size: 34,
      ),
    );
  }
}
