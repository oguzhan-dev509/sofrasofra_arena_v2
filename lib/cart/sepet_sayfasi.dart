import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../orders/musteri_siparis_takip_sayfasi.dart';
import '../services/sepet_service.dart';

class SepetSayfasi extends StatefulWidget {
  const SepetSayfasi({super.key});

  @override
  State<SepetSayfasi> createState() => _SepetSayfasiState();
}

class _SepetSayfasiState extends State<SepetSayfasi> {
  final String userId = 'demo_user';
  bool _siparisOlusturuluyor = false;

  static const Color _bg = Color(0xFFF8F3EA);
  static const Color _card = Colors.white;
  static const Color _gold = Color(0xFFFFB300);
  static const Color _goldDark = Color(0xFF8A5A00);
  static const Color _textDark = Color(0xFF2D2215);
  static const Color _textMuted = Color(0xFF7A6A58);
  static const Color _border = Color(0xFFE7D6B8);
  static const Color _chipBg = Color(0xFFFFF8EC);

  Stream<QuerySnapshot<Map<String, dynamic>>> _sepetStream() {
    return FirebaseFirestore.instance
        .collection('sepetler')
        .doc(userId)
        .collection('items')
        .snapshots();
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _findDocByUrunId(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String urunId,
  ) {
    for (final doc in docs) {
      final data = doc.data();
      final currentId =
          (data['urunId'] ?? data['productId'] ?? data['id'] ?? doc.id)
              .toString();
      if (currentId == urunId) return doc;
    }
    return null;
  }

  Future<void> _adetArtir(
    String urunId,
    int mevcutAdet,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final targetDoc = _findDocByUrunId(docs, urunId);
    if (targetDoc == null) return;

    await FirebaseFirestore.instance
        .collection('sepetler')
        .doc(userId)
        .collection('items')
        .doc(targetDoc.id)
        .update({
      'adet': mevcutAdet + 1,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _adetAzalt(
    String urunId,
    int mevcutAdet,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final targetDoc = _findDocByUrunId(docs, urunId);
    if (targetDoc == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('sepetler')
        .doc(userId)
        .collection('items')
        .doc(targetDoc.id);

    if (mevcutAdet <= 1) {
      await docRef.delete();
    } else {
      await docRef.update({
        'adet': mevcutAdet - 1,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _urunuSil(
    String urunId,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final targetDoc = _findDocByUrunId(docs, urunId);
    if (targetDoc == null) return;

    await FirebaseFirestore.instance
        .collection('sepetler')
        .doc(userId)
        .collection('items')
        .doc(targetDoc.id)
        .delete();
  }

  Future<void> _sepetiTemizle(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> _siparisiTamamla(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (_siparisOlusturuluyor || docs.isEmpty) return;

    setState(() {
      _siparisOlusturuluyor = true;
    });

    try {
      final orderId = await SepetService.siparisiTamamla(
        musteriAd: 'Mehmet',
        musteriTelefon: '0555 555 55 55',
        teslimatAdresi: 'Kadıköy / İstanbul',
        sehir: 'istanbul',
        ilce: 'kadikoy',
        not: 'Sepet ekranından oluşturuldu',
        lat: 40.991,
        lng: 29.028,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _gold,
          content: Text(
            'Sipariş oluşturuldu: $orderId',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MusteriSiparisTakipSayfasi(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            'Sipariş oluşturulamadı: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _siparisOlusturuluyor = false;
        });
      }
    }
  }

  double _araToplamHesapla(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    double toplam = 0;

    for (final doc in docs) {
      final data = doc.data();
      final fiyat = _asDouble(
        data['fiyat'] ??
            data['price'] ??
            data['birimFiyat'] ??
            data['unitPrice'] ??
            0,
      );
      final adet = _asInt(
        data['adet'] ?? data['quantity'] ?? data['qty'] ?? 0,
      );

      toplam += fiyat * adet;
    }

    return toplam;
  }

  double _teslimatUcretiHesapla(double araToplam) {
    if (araToplam <= 0) return 0;
    return 25;
  }

  int _toplamUrunAdedi(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int toplam = 0;
    for (final doc in docs) {
      final data = doc.data();
      toplam += _asInt(data['adet'] ?? data['quantity'] ?? data['qty'] ?? 0);
    }
    return toplam;
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

  String _readString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _sortDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sorted = [...docs];
    sorted.sort((a, b) {
      final aData = a.data();
      final bData = b.data();

      final aTs = aData['addedAt'];
      final bTs = bData['addedAt'];

      DateTime aTime = DateTime.fromMillisecondsSinceEpoch(0);
      DateTime bTime = DateTime.fromMillisecondsSinceEpoch(0);

      if (aTs is Timestamp) aTime = aTs.toDate();
      if (bTs is Timestamp) bTime = bTs.toDate();

      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  String _price(double value) => '${value.toStringAsFixed(0)} ₺';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Sepetim',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        backgroundColor: _bg,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _textDark),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _sepetStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final err = snapshot.error?.toString() ?? 'Bilinmeyen hata';
            debugPrint('❌ SEPET STREAM ERROR: $err');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _cardDecoration(),
                  child: Text(
                    'Sepet yüklenirken hata oluştu.\n\n$err',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _gold,
              ),
            );
          }

          final docs = _sortDocs(snapshot.data?.docs ?? []);

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: _cardDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: _chipBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 40,
                          color: _goldDark,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Sepetiniz şu anda boş',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Beğendiğiniz ürünleri sepete eklediğinizde burada görüntülenecek.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final araToplam = _araToplamHesapla(docs);
          final teslimatUcreti = _teslimatUcretiHesapla(araToplam);
          final genelToplam = araToplam + teslimatUcreti;
          final toplamUrun = _toplamUrunAdedi(docs);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: _cardDecoration(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: _chipBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _border),
                        ),
                        child: Text(
                          '$toplamUrun ürün',
                          style: const TextStyle(
                            color: _goldDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Kapıda Ödeme',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = docs[index].data();

                    final urunId = _readString(
                      item,
                      ['urunId', 'productId', 'id'],
                      fallback: docs[index].id,
                    );

                    final urunAdi = _readString(
                      item,
                      ['urunAdi', 'ad', 'isim', 'title', 'name', 'yemekAdi'],
                      fallback: 'Ürün',
                    );

                    final dukkanAdi = _readString(
                      item,
                      [
                        'dukkanAdi',
                        'dukkan',
                        'saticiAdi',
                        'sellerName',
                        'magazaAdi',
                      ],
                    );

                    final kategori = _readString(
                      item,
                      ['kategori', 'category'],
                    );

                    final img = _readString(
                      item,
                      ['img', 'imageUrl', 'foto', 'gorselUrl'],
                    );

                    final fiyat = _asDouble(
                      item['fiyat'] ??
                          item['price'] ??
                          item['birimFiyat'] ??
                          item['unitPrice'] ??
                          0,
                    );

                    final adet = _asInt(
                      item['adet'] ?? item['quantity'] ?? item['qty'] ?? 1,
                    );

                    final satirToplami = fiyat * adet;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: _cardDecoration(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildSepetImage(img),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    urunAdi,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _textDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  if (dukkanAdi.isNotEmpty)
                                    Text(
                                      dukkanAdi,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _goldDark,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  if (kategori.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      kategori,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _miniChip(
                                        Icons.schedule,
                                        'Günlük hazırlanır',
                                      ),
                                      _miniChip(
                                        Icons.home_work_outlined,
                                        'Mahalle mutfağı',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        '${fiyat.toStringAsFixed(0)} ₺ x $adet',
                                        style: const TextStyle(
                                          color: _textMuted,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _price(satirToplami),
                                        style: const TextStyle(
                                          color: _textDark,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _adetButonu(
                                        icon: Icons.remove,
                                        onTap: () =>
                                            _adetAzalt(urunId, adet, docs),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                        ),
                                        child: Text(
                                          adet.toString(),
                                          style: const TextStyle(
                                            color: _textDark,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      _adetButonu(
                                        icon: Icons.add,
                                        onTap: () =>
                                            _adetArtir(urunId, adet, docs),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () => _urunuSil(urunId, docs),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF1F1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFFFFD1D1),
                                            ),
                                          ),
                                          child: const Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                                size: 18,
                                              ),
                                              SizedBox(width: 6),
                                              Text(
                                                'Sil',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: _cardDecoration(),
                        child: Column(
                          children: [
                            _ozetSatiri(
                              'Ara Toplam',
                              _price(araToplam),
                              valueColor: _textDark,
                            ),
                            const SizedBox(height: 10),
                            _ozetSatiri(
                              'Teslimat Ücreti',
                              _price(teslimatUcreti),
                              valueColor: _textMuted,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                color: _border,
                                height: 1,
                              ),
                            ),
                            _ozetSatiri(
                              'Genel Toplam',
                              _price(genelToplam),
                              isStrong: true,
                              valueColor: _goldDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _siparisOlusturuluyor
                              ? null
                              : () => _siparisiTamamla(docs),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey,
                            disabledForegroundColor: Colors.white70,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _siparisOlusturuluyor
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  'Siparişi Tamamla',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSepetImage(String img) {
    if (img.isNotEmpty) {
      return Image.network(
        img,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _imagePlaceholder();
        },
      );
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7E7BF),
            Color(0xFFE7C784),
          ],
        ),
      ),
      child: const Icon(
        Icons.restaurant_menu_rounded,
        color: _goldDark,
        size: 28,
      ),
    );
  }

  Widget _adetButonu({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _chipBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Icon(
          icon,
          color: _goldDark,
          size: 18,
        ),
      ),
    );
  }

  Widget _miniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _chipBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: _goldDark,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: _textDark,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozetSatiri(
    String label,
    String value, {
    bool isStrong = false,
    Color valueColor = _textDark,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isStrong ? _textDark : _textMuted,
            fontSize: isStrong ? 16 : 14,
            fontWeight: isStrong ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: isStrong ? 20 : 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}
