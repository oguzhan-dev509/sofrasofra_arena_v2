import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sofrasofra_arena_v2/onboarding/uretici_basvuru_secim_sayfasi.dart';
import 'package:sofrasofra_arena_v2/merchant/uretici_yonetim_merkezi_sayfasi.dart';
import 'package:sofrasofra_arena_v2/merchant/gastronomi_yonetim_merkezi.dart';
import 'package:sofrasofra_arena_v2/modules/restoranlar/restoran_yonetim_paneli.dart';

class OnayliPanelYonlendirici extends StatelessWidget {
  const OnayliPanelYonlendirici({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const UreticiBasvuruSecimSayfasi();
    }

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('producer_applications')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'approved')
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFB300),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Onaylı panel bilgisi alınamadı: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const UreticiBasvuruSecimSayfasi();
        }

        final data = docs.first.data();

        final type = data['type']?.toString().trim() ?? '';
        final isletmeTipi =
            data['isletmeTipi']?.toString().trim().toLowerCase() ?? '';

        final restaurantId =
            data['restaurantId']?.toString().trim().isNotEmpty == true
                ? data['restaurantId'].toString().trim()
                : user.uid;

        if (type == 'ev_lezzetleri') {
          return const UreticiYonetimMerkeziSayfasi();
        }

        if (type == 'profesyonel_isletme' && isletmeTipi == 'restoran') {
          return RestoranYonetimPaneli(
            restaurantId: restaurantId,
          );
        }

        if (type == 'profesyonel_isletme') {
          return const GastronomiYonetimMerkezi();
        }

        return const UreticiBasvuruSecimSayfasi();
      },
    );
  }
}
