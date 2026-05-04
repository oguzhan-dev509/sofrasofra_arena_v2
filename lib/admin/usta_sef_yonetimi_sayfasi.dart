import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UstaSefYonetimiSayfasi extends StatelessWidget {
  const UstaSefYonetimiSayfasi({super.key});

  static const Color _bg = Color(0xFF080808);
  static const Color _panel = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _muted = Color(0xFFB6ADA0);

  Future<List<DocumentReference<Map<String, dynamic>>>> _collectUstaSefUrunRefs(
    String chefId,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final Map<String, DocumentReference<Map<String, dynamic>>> refs = {};

    Future<void> collect({
      required String field,
      required String value,
    }) async {
      final safeValue = value.trim();
      if (safeValue.isEmpty) return;

      final snap = await firestore
          .collection('urunler')
          .where(field, isEqualTo: safeValue)
          .where('tip', isEqualTo: 'Usta Sefler')
          .get();

      for (final doc in snap.docs) {
        refs[doc.id] = doc.reference;
      }
    }

    await collect(field: 'ownerId', value: chefId);
    await collect(field: 'dukkanId', value: chefId);
    await collect(field: 'chefId', value: chefId);
    await collect(field: 'saticiId', value: chefId);

    return refs.values.toList();
  }

  Future<void> _vitrineAlOrnekYap({
    required BuildContext context,
    required String chefId,
    required String chefName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Vitrine alınsın mı?',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '$chefName örnek Usta Şef profili olarak vitrinde gösterilecek.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Vitrine Al / Örnek Yap'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final chefRef = firestore.collection('chef_profiles').doc(chefId);
      final sellerRef = firestore.collection('sellers').doc(chefId);

      final activeData = <String, dynamic>{
        'aktifMi': true,
        'isActive': true,
        'isDeleted': false,
        'vitrindeGoster': true,
        'ornekProfil': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(chefRef, activeData, SetOptions(merge: true));
      batch.set(sellerRef, activeData, SetOptions(merge: true));

      final urunRefs = await _collectUstaSefUrunRefs(chefId);

      for (final ref in urunRefs) {
        batch.set(
          ref,
          {
            'isActive': true,
            'aktifMi': true,
            'isDeleted': false,
            'vitrindeGoster': true,
            'ornekProfil': true,
            'onayDurumu': 'onaylandi',
            'tip': 'Usta Sefler',
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            urunRefs.isEmpty
                ? '$chefName aktif yapıldı ancak urunler içinde Usta Şef vitrin kaydı bulunamadı.'
                : '$chefName örnek profil olarak vitrine alındı.',
          ),
          backgroundColor:
              urunRefs.isEmpty ? Colors.orange.shade800 : Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vitrine alma başarısız: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _vitrindenKaldir({
    required BuildContext context,
    required String chefId,
    required String chefName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Vitrinden kaldırılsın mı?',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '$chefName Usta Şef vitrinden kaldırılacak. Profil kaydı ve geçmiş işlemler silinmeyecek.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.visibility_off_rounded),
              label: const Text('Vitrinden Kaldır'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final chefRef = firestore.collection('chef_profiles').doc(chefId);
      final sellerRef = firestore.collection('sellers').doc(chefId);

      final passiveVitrineData = <String, dynamic>{
        'vitrindeGoster': false,
        'ornekProfil': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(chefRef, passiveVitrineData, SetOptions(merge: true));
      batch.set(sellerRef, passiveVitrineData, SetOptions(merge: true));

      final urunRefs = await _collectUstaSefUrunRefs(chefId);

      for (final ref in urunRefs) {
        batch.set(
          ref,
          {
            'vitrindeGoster': false,
            'ornekProfil': false,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$chefName vitrinden kaldırıldı.'),
          backgroundColor: Colors.orange.shade800,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vitrinden kaldırma başarısız: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _pasiflestirDemoSef({
    required BuildContext context,
    required String chefId,
    required String chefName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Usta Şef pasifleştirilsin mi?',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '$chefName adlı şef tamamen pasif/gizli yapılacak. Profil, seller kaydı, imza tabakları ve Usta Şef vitrin kayıtları pasif yapılacak. Geçmiş rezervasyon ve ödeme kayıtlarına dokunulmayacak.',
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Pasifleştir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final chefRef = firestore.collection('chef_profiles').doc(chefId);
      final sellerRef = firestore.collection('sellers').doc(chefId);

      final updateData = <String, dynamic>{
        'aktifMi': false,
        'isActive': false,
        'isDeleted': true,
        'vitrindeGoster': false,
        'ornekProfil': false,
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(chefRef, updateData, SetOptions(merge: true));
      batch.set(sellerRef, updateData, SetOptions(merge: true));

      final dishesSnap = await firestore
          .collection('chef_signature_dishes')
          .where('chefId', isEqualTo: chefId)
          .get();

      for (final doc in dishesSnap.docs) {
        batch.set(
          doc.reference,
          {
            'isActive': false,
            'aktifMi': false,
            'isDeleted': true,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      final urunRefs = await _collectUstaSefUrunRefs(chefId);

      for (final ref in urunRefs) {
        batch.set(
          ref,
          {
            'isActive': false,
            'aktifMi': false,
            'isDeleted': true,
            'vitrindeGoster': false,
            'ornekProfil': false,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$chefName pasifleştirildi ve vitrinden kaldırıldı.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pasifleştirme başarısız: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _tekrarAktifYap({
    required BuildContext context,
    required String chefId,
    required String chefName,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final chefRef = firestore.collection('chef_profiles').doc(chefId);
      final sellerRef = firestore.collection('sellers').doc(chefId);

      final updateData = <String, dynamic>{
        'aktifMi': true,
        'isActive': true,
        'isDeleted': false,
        'reactivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(chefRef, updateData, SetOptions(merge: true));
      batch.set(sellerRef, updateData, SetOptions(merge: true));

      await batch.commit();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$chefName tekrar aktif yapıldı.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aktifleştirme başarısız: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _chefName(Map<String, dynamic> data, String fallback) {
    return (data['displayName'] ??
            data['adSoyad'] ??
            data['ad'] ??
            data['chefName'] ??
            data['name'] ??
            fallback)
        .toString()
        .trim();
  }

  bool _isPassive(Map<String, dynamic> data) {
    return data['isDeleted'] == true ||
        data['isActive'] == false ||
        data['aktifMi'] == false;
  }

  bool _isInVitrine(Map<String, dynamic> data) {
    return data['vitrindeGoster'] == true;
  }

  bool _isSample(Map<String, dynamic> data) {
    return data['ornekProfil'] == true;
  }

  Widget _statusChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chefCard({
    required BuildContext context,
    required String chefId,
    required Map<String, dynamic> data,
  }) {
    final name = _chefName(data, chefId);
    final subtitle = (data['uzmanlik'] ??
            data['mutfakTarzi'] ??
            data['subtitle'] ??
            data['sehir'] ??
            '')
        .toString()
        .trim();

    final profileImage = (data['profileImageUrl'] ??
            data['profilFoto'] ??
            data['photoUrl'] ??
            '')
        .toString()
        .trim();

    final passive = _isPassive(data);
    final inVitrine = _isInVitrine(data);
    final sample = _isSample(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: passive
              ? Colors.redAccent.withValues(alpha: 0.28)
              : inVitrine
                  ? _gold.withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 760;

          final info = Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white10,
                backgroundImage:
                    profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                child: profileImage.isEmpty
                    ? const Icon(Icons.restaurant_menu_rounded, color: _gold)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.isNotEmpty ? subtitle : 'Usta Şef profili',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (passive)
                          _statusChip(
                            label: 'Pasif / Gizli',
                            color: Colors.redAccent,
                            icon: Icons.visibility_off_rounded,
                          )
                        else
                          _statusChip(
                            label: 'Aktif',
                            color: Colors.greenAccent,
                            icon: Icons.check_circle_rounded,
                          ),
                        if (inVitrine)
                          _statusChip(
                            label: 'Vitrinde',
                            color: _gold,
                            icon: Icons.storefront_rounded,
                          ),
                        if (sample)
                          _statusChip(
                            label: 'Örnek Profil',
                            color: Colors.lightBlueAccent,
                            icon: Icons.workspace_premium_rounded,
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'ID: $chefId',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = SizedBox(
            width: isNarrow ? double.infinity : 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _vitrineAlOrnekYap(
                    context: context,
                    chefId: chefId,
                    chefName: name,
                  ),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text('Vitrine Al / Örnek Yap'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _gold,
                    side: const BorderSide(color: _gold),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _vitrindenKaldir(
                    context: context,
                    chefId: chefId,
                    chefName: name,
                  ),
                  icon: const Icon(Icons.visibility_off_rounded, size: 18),
                  label: const Text('Vitrinden Kaldır'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    side: const BorderSide(color: Colors.orangeAccent),
                  ),
                ),
                const SizedBox(height: 8),
                if (passive)
                  OutlinedButton.icon(
                    onPressed: () => _tekrarAktifYap(
                      context: context,
                      chefId: chefId,
                      chefName: name,
                    ),
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text('Aktif Yap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.greenAccent,
                      side: const BorderSide(color: Colors.greenAccent),
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _pasiflestirDemoSef(
                      context: context,
                      chefId: chefId,
                      chefName: name,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Pasifleştir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                info,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: info),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream =
        FirebaseFirestore.instance.collection('chef_profiles').snapshots();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: _gold,
        title: const Text(
          'Usta Şef Yönetimi',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Şef listesi okunamadı: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz Usta Şef profili yok.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final sortedDocs = [...docs];
          sortedDocs.sort((a, b) {
            final aName = _chefName(a.data(), a.id).toLowerCase();
            final bName = _chefName(b.data(), b.id).toLowerCase();
            return aName.compareTo(bName);
          });

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withValues(alpha: 0.28)),
                ),
                child: const Text(
                  'Bu sayfa Usta Şef profillerini güvenli şekilde yönetir. “Vitrine Al / Örnek Yap” sadece seçilen örnek profilleri yayında gösterir. “Vitrinden Kaldır” profili silmeden müşteri vitrininden çıkarır. “Pasifleştir” ise profil, seller, imza tabakları ve Usta Şef vitrin kayıtlarını pasif/gizli yapar. Geçmiş ödeme ve rezervasyon kayıtlarına dokunulmaz.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...sortedDocs.map(
                (doc) => _chefCard(
                  context: context,
                  chefId: doc.id,
                  data: doc.data(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
