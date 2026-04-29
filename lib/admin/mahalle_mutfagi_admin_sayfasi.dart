import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MahalleMutfagiAdminSayfasi extends StatefulWidget {
  const MahalleMutfagiAdminSayfasi({super.key});

  @override
  State<MahalleMutfagiAdminSayfasi> createState() =>
      _MahalleMutfagiAdminSayfasiState();
}

class _MahalleMutfagiAdminSayfasiState
    extends State<MahalleMutfagiAdminSayfasi> {
  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  CollectionReference<Map<String, dynamic>> get _urunler =>
      FirebaseFirestore.instance.collection('urunler');

  Future<void> _setActive(_KitchenGroup kitchen, bool value) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in kitchen.docs) {
      batch.update(doc.reference, {
        'aktifMi': value,
        'isActive': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> _setFeatured(_KitchenGroup kitchen, bool value) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in kitchen.docs) {
      batch.update(doc.reference, {
        'oneCikanMutfak': value,
        'featuredMahalle': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> _deleteKitchen(_KitchenGroup kitchen) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Mutfağı sil?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '${kitchen.name} mutfağına ait ${kitchen.docs.length} ürün kaydı silinecek.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final docs = kitchen.docs;
    for (var i = 0; i < docs.length; i += 450) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = docs.skip(i).take(450);
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${kitchen.name} silindi.')),
    );
  }

  List<_KitchenGroup> _buildGroups(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final map = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

    for (final doc in docs) {
      final data = doc.data();
      final tip = (data['tip'] ?? '').toString().toLowerCase();

      if (!tip.contains('ev lezzetleri')) continue;

      final key = (data['dukkanId'] ??
              data['sellerId'] ??
              data['ownerId'] ??
              data['dukkan'] ??
              doc.id)
          .toString();

      map.putIfAbsent(key, () => []).add(doc);
    }

    final groups = map.entries.map((entry) {
      final first = entry.value.first.data();

      return _KitchenGroup(
        id: entry.key,
        name: (first['dukkan'] ??
                first['dukkanAdi'] ??
                first['satici'] ??
                'İsimsiz Mutfak')
            .toString(),
        category: (first['kategori'] ?? 'Ev Lezzetleri').toString(),
        district: (first['ilce'] ?? '').toString(),
        city: (first['sehir'] ?? '').toString(),
        imageUrl: (first['img'] ??
                ((first['images'] is List &&
                        (first['images'] as List).isNotEmpty)
                    ? (first['images'] as List).first
                    : ''))
            .toString(),
        active: entry.value.any((d) {
          final data = d.data();
          return data['aktifMi'] == true || data['isActive'] == true;
        }),
        featured: entry.value.any((d) {
          final data = d.data();
          return data['oneCikanMutfak'] == true ||
              data['featuredMahalle'] == true;
        }),
        docs: entry.value,
      );
    }).toList();

    groups.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
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
          'Mahalle Mutfağı Admin',
          style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _urunler.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final kitchens = _buildGroups(snapshot.data!.docs);

          if (kitchens.isEmpty) {
            return const Center(
              child: Text(
                'Mahalle Mutfağı kaydı yok.',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: kitchens.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final kitchen = kitchens[index];

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x22FFFFFF)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: kitchen.imageUrl.isEmpty
                            ? const ColoredBox(
                                color: Color(0xFF222222),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white38,
                                ),
                              )
                            : Image.network(
                                kitchen.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: Color(0xFF222222),
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kitchen.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${kitchen.category} • ${kitchen.district} / ${kitchen.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white60),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${kitchen.docs.length} ürün kaydı',
                            style: const TextStyle(
                              color: _gold,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: kitchen.featured
                          ? 'Öne çıkarmayı kaldır'
                          : 'Öne çıkar',
                      onPressed: () => _setFeatured(kitchen, !kitchen.featured),
                      icon: Icon(
                        kitchen.featured
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: kitchen.featured ? _gold : Colors.white38,
                      ),
                    ),
                    IconButton(
                      tooltip: kitchen.active ? 'Pasif yap' : 'Aktif yap',
                      onPressed: () => _setActive(kitchen, !kitchen.active),
                      icon: Icon(
                        kitchen.active
                            ? Icons.toggle_on_rounded
                            : Icons.toggle_off_rounded,
                        color: kitchen.active ? _gold : Colors.white38,
                        size: 34,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sil',
                      onPressed: () => _deleteKitchen(kitchen),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _KitchenGroup {
  final String id;
  final String name;
  final String category;
  final String district;
  final String city;
  final String imageUrl;
  final bool active;
  final bool featured;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  const _KitchenGroup({
    required this.id,
    required this.name,
    required this.category,
    required this.district,
    required this.city,
    required this.imageUrl,
    required this.active,
    required this.featured,
    required this.docs,
  });
}
