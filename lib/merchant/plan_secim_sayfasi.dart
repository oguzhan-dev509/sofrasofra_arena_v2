import 'package:flutter/material.dart';
import 'merchant_dashboard.dart';

class PlanSecimSayfasi extends StatelessWidget {
  const PlanSecimSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("ABONELİK PLANI SEÇİN",
                style: TextStyle(
                    color: Color(0xFFFFB300), fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MerchantDashboard())),
              child: const Text("GOLD PLAN İLE DEVAM ET"),
            ),
          ],
        ),
      ),
    );
  }
}
