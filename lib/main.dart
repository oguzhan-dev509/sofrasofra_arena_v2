import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sofrasofra_arena_v2/modules/arena_entry_page.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/global_radio_mini_player.dart';
import 'package:sofrasofra_arena_v2/services/sofrasofra_radio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  debugPrint('AUTH READY uid=${FirebaseAuth.instance.currentUser?.uid}');
  // Mini player'ın boş kalmaması için radyo servisini uygulama açılışında hazırla.
  SofrasofraRadioService.instance.prepare();

  runApp(const SofrasofraZirve());
}

class SofrasofraZirve extends StatelessWidget {
  const SofrasofraZirve({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sofrasofra Arena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const ArenaEntryPage(),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const GlobalRadioMiniPlayer(),
          ],
        );
      },
    );
  }
}
