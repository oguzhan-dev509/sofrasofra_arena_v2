import 'package:flutter/material.dart';

class OrderStatusTimeline extends StatelessWidget {
  final String orderStatus;
  final String deliveryStatus;

  const OrderStatusTimeline({
    super.key,
    required this.orderStatus,
    required this.deliveryStatus,
  });

  static const _gold = Color(0xFFFFB300);
  static const _inactive = Color(0xFF555555);

  int _getStepIndex() {
    if (deliveryStatus == 'delivered') return 4;
    if (deliveryStatus == 'on_the_way') return 3;

    if (orderStatus == 'ready') return 2;
    if (orderStatus == 'preparing' || orderStatus == 'approved') return 1;

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _getStepIndex();

    final steps = [
      'Alındı',
      'Hazırlanıyor',
      'Hazır',
      'Kurye Yolda',
      'Teslim',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(steps.length, (i) {
          final active = i <= current;

          return Row(
            children: [
              Icon(
                Icons.circle,
                size: 12,
                color: active ? _gold : _inactive,
              ),
              const SizedBox(width: 10),
              Text(
                steps[i],
                style: TextStyle(
                  color: active ? Colors.white : _inactive,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
