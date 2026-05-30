import 'package:flutter/material.dart';

class LegalConsentCheckbox extends StatelessWidget {
  const LegalConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.description,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String? title;
  final String? description;

  static const Color _card = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _border = Color(0x44FFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => onChanged(!value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              activeColor: _gold,
              checkColor: Colors.black,
              side: const BorderSide(color: _gold, width: 1.4),
              onChanged: (checked) => onChanged(checked ?? false),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ??
                          'Hukuki metinleri okudum, anladım ve onaylıyorum.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description ??
                          'Kullanım Koşulları, KVKK Aydınlatma Metni, Gizlilik Politikası ve ilgili başvuru şartlarını okuyup kabul ettiğimi beyan ederim.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.8,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
