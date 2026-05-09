import 'package:flutter/material.dart';

import 'sofrasofra_hukuki_metinler.dart';

class SofrasofraHukukiDetaySayfasi extends StatelessWidget {
  final SofrasofraHukukiMetin metin;

  const SofrasofraHukukiDetaySayfasi({
    super.key,
    required this.metin,
  });

  static const Color _bg = Color(0xFF0E0E0E);
  static const Color _card = Color(0xFF171717);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _textMuted = Color(0xFFB8B8B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          metin.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _gold.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.gavel_rounded,
                    color: _gold,
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    metin.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    metin.summary,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 13.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: SelectableText(
                metin.content.trim(),
                style: const TextStyle(
                  color: Color(0xFF1B1B1B),
                  fontSize: 14.2,
                  height: 1.62,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Not: Bu metinler kurumsal yayına hazırlık amacıyla hazırlanmıştır. '
              'Yayından önce hukuk danışmanı kontrolü önerilir.',
              style: TextStyle(
                color: _textMuted,
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
