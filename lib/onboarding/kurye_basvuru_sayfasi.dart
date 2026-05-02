import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/onboarding/kurye_form_sayfasi.dart';

class KuryeBasvuruSayfasi extends StatelessWidget {
  const KuryeBasvuruSayfasi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _panel = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Kurye Ol'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _gold.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kurucu Kurye Programı',
                style: TextStyle(
                  color: _gold,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'İlk 500 kurucu kurye için 3 ay %0 komisyon ve öncelikli sipariş avantajı.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('siteSettings')
                    .doc('campaign')
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final kalan = data?['kuryeKalan'] ?? 500;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$kalan Kurucu Kurye Hakkı Kaldı',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KuryeFormSayfasi(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.delivery_dining_rounded),
                  label: const Text('Kurye Başvuru Formunu Aç'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Başvuru formu bu sayfaya bağlanacak. İlk sürümde kurucu kurye kontenjanı ve avantaj mesajı görünür hale getirildi.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
