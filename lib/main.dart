import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'package:sofrasofra_arena_v2/admin/usta_sef_admin_sayfasi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SofrasofraZirve());
}

class SofrasofraZirve extends StatelessWidget {
  const SofrasofraZirve({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sofrasofra Arena',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFFFB300),
      ),
      home: const UstaSefAdminSayfasi(),
    );
  }
}
