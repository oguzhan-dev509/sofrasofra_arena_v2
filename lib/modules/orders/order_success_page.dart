import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/arena_entry_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final String orderId;

  const OrderSuccessPage({
    super.key,
    required this.orderId,
  });

  static const Color _bg = Color(0xFF090909);
  static const Color _panel = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _muted = Color(0xFFCCCCCC);

  @override
  Widget build(BuildContext context) {
    final safeOrderId = orderId.trim();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _green.withValues(alpha: 0.38),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _green.withValues(alpha: 0.55),
                        ),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: _green,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Ödeme Başarılı',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Siparişiniz başarıyla alındı. Hazırlık ve teslimat süreci Sofrasofra üzerinden takip edilecektir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                    ),
                    if (safeOrderId.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Sipariş No',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              safeOrderId,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const ArenaEntryPage(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Ana Sayfaya Dön'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
