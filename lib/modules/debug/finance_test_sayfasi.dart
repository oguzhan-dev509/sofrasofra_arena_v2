import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/finance/sofrasofra_finance_calculator.dart';
import 'package:sofrasofra_arena_v2/finance/sofrasofra_pricing_model.dart';

class FinanceTestSayfasi extends StatefulWidget {
  const FinanceTestSayfasi({super.key});

  @override
  State<FinanceTestSayfasi> createState() => _FinanceTestSayfasiState();
}

class _FinanceTestSayfasiState extends State<FinanceTestSayfasi> {
  UserType _userType = UserType.evLezzetleri;
  PlanType _plan = PlanType.free;

  double productTotal = 300;
  double deliveryFee = 50;

  String resultText = '';

  void _calculate() {
    final result = SofrasofraFinanceCalculator.calculate(
      productTotal: productTotal,
      deliveryFee: deliveryFee,
      userType: _userType,
      plan: _plan,
    );

    setState(() {
      resultText = '''
Müşteri Toplam: ${result.customerTotalPayment} TL

--- ÜRETİCİ ---
Komisyon: ${result.producerCommissionAmount} TL
Net: ${result.producerNetAmount} TL

--- KURYE ---
Komisyon: ${result.courierCommissionAmount} TL
Net: ${result.courierNetAmount} TL

--- SOFRASOFRA ---
Üretici Payı: ${result.platformProducerRevenue} TL
Kurye Payı: ${result.platformCourierRevenue} TL
Toplam Kazanç: ${result.platformTotalRevenue} TL

--- DİĞER ---
Ödeme İşlem Ücreti: ${result.paymentProcessingFee} TL
''';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Finance Test'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButton<UserType>(
              value: _userType,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              items: UserType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _userType = val!);
              },
            ),
            DropdownButton<PlanType>(
              value: _plan,
              dropdownColor: Colors.black,
              style: const TextStyle(color: Colors.white),
              items: PlanType.values.map((plan) {
                return DropdownMenuItem(
                  value: plan,
                  child: Text(plan.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _plan = val!);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _calculate,
              child: const Text('HESAPLA'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  resultText,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
