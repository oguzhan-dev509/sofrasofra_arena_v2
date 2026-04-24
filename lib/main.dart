import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/firebase_options.dart';
import 'package:sofrasofra_arena_v2/modules/arena_entry_page.dart';
import 'package:sofrasofra_arena_v2/dev/academy_brand_kariyer_seed.dart';

const bool shouldRunAcademyBrandCareerBootstrap = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    if (FirebaseAuth.instance.currentUser == null) {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      debugPrint('AUTH READY uid=${credential.user?.uid}');
    } else {
      debugPrint(
          'AUTH READY existing uid=${FirebaseAuth.instance.currentUser?.uid}');
    }
  } catch (e, st) {
    debugPrint('AUTH INIT ERROR => $e');
    debugPrintStack(stackTrace: st);
  }

  if (shouldRunAcademyBrandCareerBootstrap) {
    await runAcademyBrandCareerBootstrapOnce(
      chefId: 'demo_chef_ahmet_usta',
      chefName: 'Ahmet Usta',
    );
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
