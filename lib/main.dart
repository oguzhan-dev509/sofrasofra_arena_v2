import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'merchant/sef_yonetim_paneli.dart';
import 'modules/sef_itibar_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/user_reservations_page.dart';
import 'package:sofrasofra_arena_v2/modules/chef_table_reservations_page.dart';
import 'package:sofrasofra_arena_v2/modules/create_reservation_page.dart';
import 'services/auth_service.dart';
import 'package:sofrasofra_arena_v2/core/app_root.dart';
import 'modules/sef_akademi_dersleri.dart';
import 'package:sofrasofra_arena_v2/modules/kategori_sayfasi.dart';
import 'package:sofrasofra_arena_v2/services/chef_academy_bootstrap_service.dart';
import 'package:sofrasofra_arena_v2/services/academy_category_bootstrap_service.dart';
import 'package:sofrasofra_arena_v2/services/academy_category_normalize_service.dart';
import 'package:sofrasofra_arena_v2/modules/arena_entry_page.dart';
import 'package:sofrasofra_arena_v2/merchant/gastronomi_yonetim_merkezi.dart';
import 'merchant/merchant_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await AuthService.signInAnonymously();

    const runAcademyVideoBootstrapOnce = false;
    const runAcademyCategoryBootstrapOnce = false;
    const runAcademyCategoryNormalizeOnce = true;

    if (kDebugMode && runAcademyVideoBootstrapOnce) {
      await ChefAcademyBootstrapService.backfillAllCourseVideos();
    }

    if (kDebugMode && runAcademyCategoryBootstrapOnce) {
      await AcademyCategoryBootstrapService.bootstrapAcademyCategories(
        overwriteExisting: false,
      );
    }

    if (kDebugMode && runAcademyCategoryNormalizeOnce) {
      await AcademyCategoryNormalizeService.normalizeLessonCategories();
    }

    debugPrint('✅ CURRENT UID: ${FirebaseAuth.instance.currentUser?.uid}');
    debugPrint('✅ CURRENT UID: ${FirebaseAuth.instance.currentUser?.uid}');
  } catch (e, st) {
    debugPrint('❌ ANON LOGIN HATASI: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(const SofrasofraZirve());
}

class SofrasofraZirve extends StatelessWidget {
  const SofrasofraZirve({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sofrasofra Arena',
      theme: ThemeData.dark(),
      home: const ArenaEntryPage(),
    );
  }
}

class AnaSayfa extends StatelessWidget {
  const AnaSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sofrasofra Arena'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuCard(
            title: 'Şef Yönetim Paneli',
            subtitle: 'Şef tarafı içerik ve yönetim ekranı',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SefYonetimPaneli(
                    dukkanAdi: 'Mehmet Usta',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuCard(
            title: 'Şef İtibar Profili',
            subtitle: 'Vitrin sayfasını aç',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SefItibarSayfasi(
                    dukkanId: 'RhkyTCD5TgWJFdEzP50mvCOrz5a2',
                    isAdmin: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuCard(
            title: 'Şef Akademisi',
            subtitle: 'Eğitimleri keşfet',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SefAkademiDersleri(
                    chefId: 'RhkyTCD5TgWJFdEzP50mvCOrz5a2',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuCard(
            title: 'Rezervasyon Oluştur',
            subtitle: 'Test rezervasyonu oluştur',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateReservationPage(
                    chefId: 'RhkyTCD5TgWJFdEzP50mvCOrz5a2',
                    chefName: 'Ahmet Usta',
                    tableTitle: '8 Kişilik Özel Şef Masası Deneyimi',
                    concept: 'Tadım Menüsü',
                    capacity: '8 Kişi',
                    unitPrice: 1500,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuCard(
            title: 'Rezervasyonlarım',
            subtitle: 'Kullanıcı rezervasyon ekranı',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserReservationsPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _MenuCard(
            title: 'Şef Masası Rezervasyonları',
            subtitle: 'Şef rezervasyon yönetim ekranı',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChefTableReservationsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.03),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD54F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
