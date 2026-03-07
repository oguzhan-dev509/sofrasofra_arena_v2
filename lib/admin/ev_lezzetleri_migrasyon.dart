import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EvLezzetleriMigrasyonPage extends StatefulWidget {
  const EvLezzetleriMigrasyonPage({super.key});

  @override
  State<EvLezzetleriMigrasyonPage> createState() =>
      _EvLezzetleriMigrasyonPageState();
}

class _EvLezzetleriMigrasyonPageState extends State<EvLezzetleriMigrasyonPage> {
  bool _running = false;
  String _log = '';

  void _append(String s) => setState(() => _log = '$_log\n$s');

  Future<void> _run() async {
    setState(() {
      _running = true;
      _log = '';
    });

    try {
      final col = FirebaseFirestore.instance.collection('urunler');

      // Tipi ev lezzeti olabilecek kayıtları taramak için geniş liste
      final candidates = <String>{
        'Ev Lezzetleri',
        'EV LEZZETLERİ',
        'EvLezzetleri',
        'Ev',
        'EV',
      };

      int fixed = 0;

      // Basit tarama: tüm urunler (çok büyükse sonra daraltırız)
      final snap = await col.get();

      for (final doc in snap.docs) {
        final d = doc.data();
        final tip = (d['tip'] ?? '').toString().trim();

        // ev lezzeti adayları
        if (!candidates.contains(tip)) continue;

        final updates = <String, dynamic>{};

        // normalize tip
        updates['tip'] = 'Ev Lezzetleri';

        // normalize onayDurumu
        final onay = (d['onayDurumu'] ?? '').toString().trim().toLowerCase();
        if (onay.isEmpty ||
            onay == 'onaylandı' ||
            onay == 'onayli' ||
            onay == 'approved') {
          updates['onayDurumu'] = 'onaylandi';
        }

        // isActive yoksa true yap
        if (d['isActive'] == null) {
          updates['isActive'] = true;
        }

        if (updates.isNotEmpty) {
          await doc.reference.set(updates, SetOptions(merge: true));
          fixed++;
        }
      }

      _append('✅ Bitti. Düzeltilen kayıt: $fixed');
    } catch (e) {
      _append('❌ Hata: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ev Lezzetleri Migrasyon')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _running ? null : _run,
              child:
                  Text(_running ? 'Çalışıyor...' : 'Kayıtları Standartlaştır'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_log),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
