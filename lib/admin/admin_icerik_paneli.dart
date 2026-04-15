import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/services/score_service.dart';

class AdminIcerikPaneli extends StatelessWidget {
  const AdminIcerikPaneli({super.key});

  static const Color _bg = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          iconTheme: const IconThemeData(color: _gold),
          title: const Text(
            'ADMİN İÇERİK PANELİ',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Ürünleri normalize et',
              onPressed: () async {
                await _urunleriNormalizeEt();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ürün kayıtları normalize edildi'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.auto_fix_high, color: _gold),
            ),
            IconButton(
              tooltip: 'Score hesapla',
              onPressed: () async {
                await ScoreService.tumUrunScorelariniGuncelle();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ürün score değerleri güncellendi'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.auto_graph, color: _gold),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: _gold,
            labelColor: _gold,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Ürünler'),
              Tab(text: 'Mutfaklar'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UrunlerTab(),
            _MutfaklarTab(),
          ],
        ),
      ),
    );
  }
}

class _UrunlerTab extends StatelessWidget {
  const _UrunlerTab();

  static const Color _card = Color(0xFF1B1B1B);
  static const Color _gold = Color(0xFFFFB300);

  String _safe(dynamic v) => (v ?? '').toString().trim();

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      return double.tryParse(v.replaceAll(',', '.').trim()) ?? 0;
    }
    return 0;
  }

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');

  Timestamp? _asTimestamp(dynamic v) {
    if (v is Timestamp) return v;
    return null;
  }

  int _kalanGun(Timestamp? until) {
    if (until == null) return 0;

    final now = DateTime.now();
    final end = until.toDate();

    if (now.isAfter(end)) return 0;

    final diff = end.difference(now);
    final days = diff.inDays;

    // Aynı gün içindeyse 0 görünmesin, 1 gün gösterelim.
    if (days <= 0) return 1;
    return days;
  }

  bool _aktifVitrinMi(bool flag, Timestamp? until) {
    if (!flag) return false;
    if (until == null) return false;
    return DateTime.now().isBefore(until.toDate());
  }

  Future<void> _setOneCikanLevel({
    required String docId,
    required String fieldName,
    required String untilFieldName,
    required bool currentValue,
    required int? days,
  }) async {
    final ref = FirebaseFirestore.instance.collection('urunler').doc(docId);

    // Aktifse kapat
    if (currentValue) {
      await ref.update({
        fieldName: false,
        untilFieldName: null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    // Pasifse süre ile aç
    if (days == null || days <= 0) return;

    await ref.update({
      fieldName: true,
      untilFieldName: Timestamp.fromDate(
        DateTime.now().add(Duration(days: days)),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int?> _sureSecDialog(
    BuildContext context, {
    required String title,
  }) async {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sureSecenekTile(dialogContext, gun: 3, label: '3 Gün'),
              const SizedBox(height: 8),
              _sureSecenekTile(dialogContext, gun: 7, label: '7 Gün'),
              const SizedBox(height: 8),
              _sureSecenekTile(dialogContext, gun: 30, label: '30 Gün'),
            ],
          ),
        );
      },
    );
  }

  Widget _sureSecenekTile(
    BuildContext context, {
    required int gun,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          Navigator.of(context).pop(gun);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          side: const BorderSide(color: _gold),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _seviyeRozeti({
    required String text,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.75)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _oneCikanRozetleri({
    required bool ilceOneCikan,
    required bool sehirOneCikan,
    required bool ulkeOneCikan,
    required int ilceGun,
    required int sehirGun,
    required int ulkeGun,
  }) {
    final children = <Widget>[
      if (ilceOneCikan)
        _seviyeRozeti(
          text: 'İlçe • $ilceGun gün',
          icon: Icons.location_on_outlined,
          color: Colors.greenAccent,
        ),
      if (sehirOneCikan)
        _seviyeRozeti(
          text: 'Şehir • $sehirGun gün',
          icon: Icons.location_city_outlined,
          color: Colors.lightBlueAccent,
        ),
      if (ulkeOneCikan)
        _seviyeRozeti(
          text: 'Ülke • $ulkeGun gün',
          icon: Icons.public,
          color: Colors.purpleAccent,
        ),
    ];

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }

  Widget _seviyeButonu({
    required BuildContext context,
    required String docId,
    required String fieldName,
    required String untilFieldName,
    required bool value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return OutlinedButton.icon(
      onPressed: () async {
        if (value) {
          await _setOneCikanLevel(
            docId: docId,
            fieldName: fieldName,
            untilFieldName: untilFieldName,
            currentValue: value,
            days: null,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label öne çıkarma kapatıldı'),
              ),
            );
          }
          return;
        }

        final selectedDays = await _sureSecDialog(
          context,
          title: '$label vitrini süresi seç',
        );

        if (selectedDays == null) return;

        await _setOneCikanLevel(
          docId: docId,
          fieldName: fieldName,
          untilFieldName: untilFieldName,
          currentValue: value,
          days: selectedDays,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$label vitrini $selectedDays günlüğüne açıldı',
              ),
            ),
          );
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: value ? color.withValues(alpha: 0.12) : Colors.transparent,
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('urunler')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Hata: ${snap.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _gold),
          );
        }

        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'Henüz ürün yok.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final adRaw = data['ad'];
            final urunAdiRaw = data['urunAdi'];
            final dukkanRaw = data['dukkan'];
            final dukkanAdiRaw = data['dukkanAdi'];

            final urunAdi = _safe(
              _safe(adRaw).isNotEmpty ? adRaw : urunAdiRaw,
            );

            final dukkan = _safe(
              _safe(dukkanRaw).isNotEmpty ? dukkanRaw : dukkanAdiRaw,
            );

            final sehir = _safe(data['sehir']);
            final ilce = _safe(data['ilce']);
            final img = _safe(data['img']);
            final aciklama = _safe(data['aciklama']);
            final fiyat = _toDouble(data['fiyat']);
            final aktifMi = data['isActive'] == true;
            final kategori = _safe(data['kategori']);

            final rawIlceOneCikan = data['ilceOneCikan'] == true;
            final rawSehirOneCikan = data['sehirOneCikan'] == true;
            final rawUlkeOneCikan = data['ulkeOneCikan'] == true;

            final ilceUntil = _asTimestamp(data['ilceOneCikanUntil']);
            final sehirUntil = _asTimestamp(data['sehirOneCikanUntil']);
            final ulkeUntil = _asTimestamp(data['ulkeOneCikanUntil']);

            final ilceOneCikan = _aktifVitrinMi(rawIlceOneCikan, ilceUntil);
            final sehirOneCikan = _aktifVitrinMi(rawSehirOneCikan, sehirUntil);
            final ulkeOneCikan = _aktifVitrinMi(rawUlkeOneCikan, ulkeUntil);

            final ilceGun = _kalanGun(ilceUntil);
            final sehirGun = _kalanGun(sehirUntil);
            final ulkeGun = _kalanGun(ulkeUntil);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _isHttp(img)
                        ? Image.network(
                            img,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              urunAdi.isEmpty ? 'İsimsiz Ürün' : urunAdi,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            _durumRozeti(aktifMi),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dukkan.isEmpty ? 'Mutfak yok' : dukkan,
                          style: const TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ilce.toUpperCase()} / ${sehir.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (kategori.isNotEmpty) _miniBilgiChip(kategori),
                            _miniBilgiChip(
                              fiyat > 0
                                  ? '${fiyat.toStringAsFixed(0)} ₺'
                                  : 'Fiyat yok',
                            ),
                          ],
                        ),
                        if (aciklama.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            aciklama,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (ilceOneCikan || sehirOneCikan || ulkeOneCikan) ...[
                          const SizedBox(height: 10),
                          _oneCikanRozetleri(
                            ilceOneCikan: ilceOneCikan,
                            sehirOneCikan: sehirOneCikan,
                            ulkeOneCikan: ulkeOneCikan,
                            ilceGun: ilceGun,
                            sehirGun: sehirGun,
                            ulkeGun: ulkeGun,
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                _aktiflikDegistir(doc.id, !aktifMi);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: aktifMi
                                    ? Colors.orangeAccent
                                    : Colors.greenAccent,
                                side: BorderSide(
                                  color: aktifMi
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent,
                                ),
                              ),
                              icon: Icon(
                                aktifMi
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                              label: Text(
                                aktifMi ? 'Yayından Kaldır' : 'Yayına Al',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                _duzenleDialog(context, doc.id, data);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _gold,
                                side: const BorderSide(color: _gold),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Düzenle'),
                            ),
                            _seviyeButonu(
                              context: context,
                              docId: doc.id,
                              fieldName: 'ilceOneCikan',
                              untilFieldName: 'ilceOneCikanUntil',
                              value: ilceOneCikan,
                              label: 'İlçe',
                              icon: Icons.location_on_outlined,
                              color: Colors.greenAccent,
                            ),
                            _seviyeButonu(
                              context: context,
                              docId: doc.id,
                              fieldName: 'sehirOneCikan',
                              untilFieldName: 'sehirOneCikanUntil',
                              value: sehirOneCikan,
                              label: 'Şehir',
                              icon: Icons.location_city_outlined,
                              color: Colors.lightBlueAccent,
                            ),
                            _seviyeButonu(
                              context: context,
                              docId: doc.id,
                              fieldName: 'ulkeOneCikan',
                              untilFieldName: 'ulkeOneCikanUntil',
                              value: ulkeOneCikan,
                              label: 'Ülke',
                              icon: Icons.public,
                              color: Colors.purpleAccent,
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                _silDialog(context, doc.id, urunAdi);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(
                                  color: Colors.redAccent,
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('Sil'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

Future<void> _urunleriNormalizeEt() async {
  final query = await FirebaseFirestore.instance.collection('urunler').get();

  final batch = FirebaseFirestore.instance.batch();

  for (final doc in query.docs) {
    final data = doc.data();

    final String ad = (data['ad'] ?? '').toString().trim();
    final String urunAdi = (data['urunAdi'] ?? '').toString().trim();
    final String uzmanlik = (data['uzmanlik'] ?? '').toString().trim();

    final bool ilceOneCikan = data['ilceOneCikan'] == true;
    final bool sehirOneCikan = data['sehirOneCikan'] == true;
    final bool ulkeOneCikan = data['ulkeOneCikan'] == true;

    final Timestamp? ilceUntil = data['ilceOneCikanUntil'] is Timestamp
        ? data['ilceOneCikanUntil'] as Timestamp
        : null;

    final Timestamp? sehirUntil = data['sehirOneCikanUntil'] is Timestamp
        ? data['sehirOneCikanUntil'] as Timestamp
        : null;

    final Timestamp? ulkeUntil = data['ulkeOneCikanUntil'] is Timestamp
        ? data['ulkeOneCikanUntil'] as Timestamp
        : null;

    final String yeniAd = ad.isNotEmpty
        ? ad
        : (urunAdi.isNotEmpty
            ? urunAdi
            : (uzmanlik.isNotEmpty ? uzmanlik : 'İsimsiz Ürün'));

    final Map<String, dynamic> updateData = {
      'ad': yeniAd,
      'ilceOneCikan': ilceOneCikan,
      'ilceOneCikanUntil': ilceOneCikan ? ilceUntil : null,
      'sehirOneCikan': sehirOneCikan,
      'sehirOneCikanUntil': sehirOneCikan ? sehirUntil : null,
      'ulkeOneCikan': ulkeOneCikan,
      'ulkeOneCikanUntil': ulkeOneCikan ? ulkeUntil : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Süre yoksa true bırakma, false yap
    if (ilceOneCikan && ilceUntil == null) {
      updateData['ilceOneCikan'] = false;
      updateData['ilceOneCikanUntil'] = null;
    }

    if (sehirOneCikan && sehirUntil == null) {
      updateData['sehirOneCikan'] = false;
      updateData['sehirOneCikanUntil'] = null;
    }

    if (ulkeOneCikan && ulkeUntil == null) {
      updateData['ulkeOneCikan'] = false;
      updateData['ulkeOneCikanUntil'] = null;
    }

    batch.update(doc.reference, updateData);
  }

  await batch.commit();
}

Widget _imagePlaceholder() {
  return Container(
    width: 88,
    height: 88,
    color: Colors.grey.shade900,
    child: const Icon(
      Icons.image_outlined,
      color: Colors.white38,
      size: 28,
    ),
  );
}

Widget _durumRozeti(bool aktifMi) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: aktifMi
          ? Colors.greenAccent.withValues(alpha: 0.12)
          : Colors.orangeAccent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: aktifMi ? Colors.greenAccent : Colors.orangeAccent,
      ),
    ),
    child: Text(
      aktifMi ? 'AKTİF' : 'PASİF',
      style: TextStyle(
        color: aktifMi ? Colors.greenAccent : Colors.orangeAccent,
        fontWeight: FontWeight.w800,
        fontSize: 11,
      ),
    ),
  );
}

Widget _miniBilgiChip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white10),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Future<void> _aktiflikDegistir(String docId, bool yeniDurum) async {
  await FirebaseFirestore.instance.collection('urunler').doc(docId).update({
    'isActive': yeniDurum,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

Future<void> _silDialog(
  BuildContext context,
  String docId,
  String urunAdi,
) async {
  final onay = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Ürünü Sil'),
      content: Text(
        '${urunAdi.isEmpty ? 'Bu ürün' : urunAdi} silinsin mi?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sil'),
        ),
      ],
    ),
  );

  if (onay == true) {
    await FirebaseFirestore.instance.collection('urunler').doc(docId).delete();
  }
}

Future<void> _duzenleDialog(
  BuildContext context,
  String docId,
  Map<String, dynamic> data,
) async {
  final adController =
      TextEditingController(text: (data['ad'] ?? '').toString());
  final dukkanController =
      TextEditingController(text: (data['dukkan'] ?? '').toString());
  final fiyatController =
      TextEditingController(text: (data['fiyat'] ?? '').toString());
  final aciklamaController =
      TextEditingController(text: (data['aciklama'] ?? '').toString());
  final kategoriController =
      TextEditingController(text: (data['kategori'] ?? '').toString());
  final youtubeController =
      TextEditingController(text: (data['youtubeUrl'] ?? '').toString());

  final kaydet = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Ürünü Düzenle'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: adController,
              decoration: const InputDecoration(labelText: 'Ürün Adı'),
            ),
            TextField(
              controller: dukkanController,
              decoration: const InputDecoration(labelText: 'Mutfak'),
            ),
            TextField(
              controller: fiyatController,
              decoration: const InputDecoration(labelText: 'Fiyat'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: kategoriController,
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            TextField(
              controller: youtubeController,
              decoration: const InputDecoration(labelText: 'YouTube URL'),
            ),
            TextField(
              controller: aciklamaController,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );

  if (kaydet == true) {
    final fiyat =
        double.tryParse(fiyatController.text.trim().replaceAll(',', '.')) ?? 0;

    await FirebaseFirestore.instance.collection('urunler').doc(docId).update({
      'ad': adController.text.trim(),
      'dukkan': dukkanController.text.trim(),
      'fiyat': fiyat,
      'kategori': kategoriController.text.trim(),
      'youtubeUrl': youtubeController.text.trim(),
      'aciklama': aciklamaController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class _MutfaklarTab extends StatelessWidget {
  const _MutfaklarTab();

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('urunler').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Hata: ${snap.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _gold),
          );
        }

        final docs = snap.data?.docs ?? [];
        final Map<String, Map<String, String>> mutfaklar = {};

        for (final doc in docs) {
          final data = doc.data();
          final dukkan = (data['dukkan'] ?? '').toString().trim();
          if (dukkan.isEmpty) continue;

          mutfaklar[dukkan] = {
            'sehir': (data['sehir'] ?? '').toString(),
            'ilce': (data['ilce'] ?? '').toString(),
          };
        }

        final keys = mutfaklar.keys.toList();

        if (keys.isEmpty) {
          return const Center(
            child: Text(
              'Henüz mutfak yok.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final name = keys[index];
            final sehir = mutfaklar[name]!['sehir'] ?? '';
            final ilce = mutfaklar[name]!['ilce'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${ilce.toUpperCase()} / ${sehir.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Mutfak ürünlerini sil',
                    onPressed: () {
                      _mutfakSilDialog(context, name);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _mutfakSilDialog(BuildContext context, String dukkanAdi) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mutfak Sil'),
        content: Text(
          '$dukkanAdi adlı mutfağa ait tüm ürünler silinsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay == true) {
      final query = await FirebaseFirestore.instance
          .collection('urunler')
          .where('dukkan', isEqualTo: dukkanAdi)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
