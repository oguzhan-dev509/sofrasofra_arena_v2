import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'package:sofrasofra_arena_v2/modules/arena_entry_page.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/global_radio_mini_player.dart';
import 'package:sofrasofra_arena_v2/services/sofrasofra_radio_service.dart';
import 'package:sofrasofra_arena_v2/services/app_auth_service.dart';
import 'package:sofrasofra_arena_v2/modules/orders/order_success_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppAuthService.ensureGuestSession();

  debugPrint(
    'AUTH READY uid=${AppAuthService.currentUid} anonymous=${AppAuthService.isAnonymous}',
  );
  // Mini player'ın boş kalmaması için radyo servisini uygulama açılışında hazırla.
  SofrasofraRadioService.instance.prepare();

  runApp(const SofrasofraZirve());
}

class SofrasofraZirve extends StatelessWidget {
  const SofrasofraZirve({super.key});
  Widget _initialHome() {
    final uri = Uri.base;
    final fullUrl = uri.toString().toLowerCase();
    final path = uri.path.toLowerCase();
    final fragment = uri.fragment.toLowerCase();

    final orderId = uri.queryParameters['orderId'] ??
        Uri.tryParse(fragment)?.queryParameters['orderId'] ??
        '';

    debugPrint(
      'ROUTE DEBUG uri=$uri path=$path fragment=$fragment orderId=$orderId',
    );

    final isOrderSuccess = path == '/order-success' ||
        path.endsWith('/order-success') ||
        fragment.startsWith('/order-success') ||
        fragment.contains('order-success') ||
        fullUrl.contains('/order-success');

    if (isOrderSuccess) {
      return OrderSuccessPage(orderId: orderId);
    }

    return const ArenaEntryPage();
  }

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
      home: _initialHome(),
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const Positioned(
              right: 0,
              bottom: 0,
              child: GlobalRadioMiniPlayer(),
            ),
          ],
        );
      },
    );
  }
}
