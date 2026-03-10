import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SiparisYonetimi extends StatefulWidget {
  const SiparisYonetimi({super.key});

  @override
  State<SiparisYonetimi> createState() => _SiparisYonetimiState();
}

class _SiparisYonetimiState extends State<SiparisYonetimi> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _aramaController = TextEditingController();

  String _filtre = 'aktif';
  String _aramaMetni = '';

  final List<Map<String, String>> _filtreler = const [
    {'value': 'aktif', 'label': 'Aktif'},
    {'value': 'delivered', 'label': 'Teslim Edildi'},
    {'value': 'cancelled', 'label': 'İptal'},
    {'value': 'tum', 'label': 'Tümü'},
  ];

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _siparisStream() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  bool _aktifSiparisMi(String durum) {
    const aktifDurumlar = {
      'pending',
      'preparing',
      'on_the_way',
      'hazirlaniyor',
      'yolda',
      'beklemede',
      'onay_bekliyor',
    };
    return aktifDurumlar.contains(durum);
  }

  bool _teslimEdildiMi(String durum) {
    const durumlar = {
      'delivered',
      'teslim_edildi',
      'tamamlandi',
      'completed',
    };
    return durumlar.contains(durum);
  }

  bool _iptalMi(String durum) {
    const durumlar = {
      'cancelled',
      'iptal',
      'iptal_edildi',
      'rejected',
    };
    return durumlar.contains(durum);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filtrele(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var sonuc = docs.where((doc) {
      final data = doc.data();
      final durum = (data['status'] ?? data['durum'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      switch (_filtre) {
        case 'aktif':
          return _aktifSiparisMi(durum);
        case 'delivered':
          return _teslimEdildiMi(durum);
        case 'cancelled':
          return _iptalMi(durum);
        case 'tum':
        default:
          return true;
      }
    }).toList();

    if (_aramaMetni.trim().isNotEmpty) {
      final q = _aramaMetni.toLowerCase().trim();

      sonuc = sonuc.where((doc) {
        final data = doc.data();

        final siparisId = doc.id.toLowerCase();
        final musteri = (data['musteriAd'] ??
                data['customerName'] ??
                data['kullaniciAd'] ??
                '')
            .toString()
            .toLowerCase();
        final satici = (data['saticiAd'] ??
                data['merchantName'] ??
                data['dukkan'] ??
                data['dukkanAdi'] ??
                '')
            .toString()
            .toLowerCase();
        final durum =
            (data['status'] ?? data['durum'] ?? '').toString().toLowerCase();

        return siparisId.contains(q) ||
            musteri.contains(q) ||
            satici.contains(q) ||
            durum.contains(q);
      }).toList();
    }

    return sonuc;
  }

  double _parseTutar(Map<String, dynamic> data) {
    final adaylar = [
      data['totalAmount'],
      data['toplamTutar'],
      data['tutar'],
      data['genelToplam'],
      data['total'],
    ];

    for (final item in adaylar) {
      if (item is num) return item.toDouble();
      if (item is String) {
        final temiz = item.replaceAll(',', '.').trim();
        final val = double.tryParse(temiz);
        if (val != null) return val;
      }
    }
    return 0;
  }

  String _durumLabel(String durum) {
    switch (durum) {
      case 'pending':
      case 'beklemede':
      case 'onay_bekliyor':
        return 'Beklemede';
      case 'preparing':
      case 'hazirlaniyor':
        return 'Hazırlanıyor';
      case 'on_the_way':
      case 'yolda':
        return 'Yolda';
      case 'delivered':
      case 'teslim_edildi':
      case 'tamamlandi':
      case 'completed':
        return 'Teslim Edildi';
      case 'cancelled':
      case 'iptal':
      case 'iptal_edildi':
        return 'İptal';
      default:
        return durum.isEmpty ? '-' : durum;
    }
  }

  Color _durumRengi(String durum) {
    final d = durum.toLowerCase();
    if (_iptalMi(d)) return Colors.redAccent;
    if (_teslimEdildiMi(d)) return Colors.green;
    if (_aktifSiparisMi(d)) return Colors.orange;
    return Colors.white54;
  }

  Future<void> _durumGuncelle({
    required String siparisId,
    required String yeniDurum,
  }) async {
    try {
      await _firestore.collection('orders').doc(siparisId).update({
        'status': yeniDurum,
        'durum': yeniDurum,
        'updatedAt': FieldValue.serverTimestamp(),
        'adminLastActionAt': FieldValue.serverTimestamp(),
        'adminLastAction': 'status_update',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sipariş durumu güncellendi: $yeniDurum')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Durum güncellenemedi: $e')),
      );
    }
  }

  Future<void> _adminNotuDialog({
    required String siparisId,
    required String mevcutNot,
  }) async {
    final controller = TextEditingController(text: mevcutNot);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Admin Sipariş Notu',
            style: TextStyle(color: Color(0xFFFFB300)),
          ),
          content: TextField(
            controller: controller,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Sipariş notu giriniz...',
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
                  await _firestore.collection('orders').doc(siparisId).update({
                    'adminNotu': controller.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                    'adminLastActionAt': FieldValue.serverTimestamp(),
                    'adminLastAction': 'note_update',
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

  Future<void> _detayPanel({
    required String siparisId,
    required Map<String, dynamic> data,
  }) async {
    final musteri = (data['musteriAd'] ??
            data['customerName'] ??
            data['kullaniciAd'] ??
            '-')
        .toString();
    final satici = (data['saticiAd'] ??
            data['merchantName'] ??
            data['dukkan'] ??
            data['dukkanAdi'] ??
            '-')
        .toString();
    final adres =
        (data['adres'] ?? data['teslimatAdresi'] ?? data['address'] ?? '-')
            .toString();
    final telefon =
        (data['telefon'] ?? data['phone'] ?? data['musteriTelefon'] ?? '-')
            .toString();
    final durum =
        (data['status'] ?? data['durum'] ?? '').toString().trim().toLowerCase();
    final adminNotu = (data['adminNotu'] ?? '').toString();
    final notlar =
        (data['not'] ?? data['siparisNotu'] ?? data['customerNote'] ?? '-')
            .toString();
    final tutar = _parseTutar(data);

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
                  'Sipariş #$siparisId',
                  style: const TextStyle(
                    color: Color(0xFFFFB300),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _infoSatiri('Müşteri', musteri),
                _infoSatiri('Satıcı', satici),
                _infoSatiri('Telefon', telefon),
                _infoSatiri('Adres', adres),
                _infoSatiri('Durum', _durumLabel(durum)),
                _infoSatiri('Tutar', '₺${tutar.toStringAsFixed(0)}'),
                _infoSatiri('Müşteri Notu', notlar),
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
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _durumGuncelle(
                          siparisId: siparisId,
                          yeniDurum: 'preparing',
                        );
                      },
                      icon: const Icon(Icons.kitchen),
                      label: const Text('Hazırlanıyor'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _durumGuncelle(
                          siparisId: siparisId,
                          yeniDurum: 'on_the_way',
                        );
                      },
                      icon: const Icon(Icons.delivery_dining),
                      label: const Text('Yolda'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _durumGuncelle(
                          siparisId: siparisId,
                          yeniDurum: 'delivered',
                        );
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Teslim Edildi'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _durumGuncelle(
                          siparisId: siparisId,
                          yeniDurum: 'cancelled',
                        );
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('İptal Et'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFFB300),
                        side: const BorderSide(color: Color(0xFFFFB300)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _adminNotuDialog(
                          siparisId: siparisId,
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
          'SİPARİŞ YÖNETİMİ',
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
                    hintText: 'Sipariş, müşteri, satıcı ara...',
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
              stream: _siparisStream(),
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
                      'Gösterilecek sipariş bulunamadı',
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

                    final musteri = (data['musteriAd'] ??
                            data['customerName'] ??
                            data['kullaniciAd'] ??
                            'Müşteri')
                        .toString();
                    final satici = (data['saticiAd'] ??
                            data['merchantName'] ??
                            data['dukkan'] ??
                            data['dukkanAdi'] ??
                            'Satıcı')
                        .toString();
                    final durum = (data['status'] ?? data['durum'] ?? '')
                        .toString()
                        .trim()
                        .toLowerCase();
                    final tutar = _parseTutar(data);
                    final createdAt =
                        data['createdAt'] ?? data['siparisTarihi'];

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
                        onTap: () => _detayPanel(
                          siparisId: doc.id,
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
                                      color:
                                          _durumRengi(durum).withOpacity(0.16),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long,
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
                                          'Sipariş #${doc.id}',
                                          style: const TextStyle(
                                            color: Color(0xFFFFB300),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Müşteri: $musteri',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Satıcı: $satici',
                                          style: const TextStyle(
                                            color: Colors.white70,
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
                                        '₺${tutar.toStringAsFixed(0)}',
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
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _durumGuncelle(
                                      siparisId: doc.id,
                                      yeniDurum: 'on_the_way',
                                    ),
                                    icon: const Icon(Icons.delivery_dining),
                                    label: const Text('Yolda'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _durumGuncelle(
                                      siparisId: doc.id,
                                      yeniDurum: 'delivered',
                                    ),
                                    icon: const Icon(Icons.check_circle),
                                    label: const Text('Teslim Edildi'),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _durumGuncelle(
                                      siparisId: doc.id,
                                      yeniDurum: 'cancelled',
                                    ),
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('İptal'),
                                  ),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFFFB300),
                                      side: const BorderSide(
                                        color: Color(0xFFFFB300),
                                      ),
                                    ),
                                    onPressed: () => _adminNotuDialog(
                                      siparisId: doc.id,
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
