import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BillingInfoFormSection extends StatelessWidget {
  final String faturaTipi;
  final ValueChanged<String?> onFaturaTipiChanged;

  final TextEditingController faturaUnvaniController;
  final TextEditingController tcknVknController;
  final TextEditingController vergiDairesiController;
  final TextEditingController faturaAdresiController;
  final TextEditingController faturaEmailController;
  final TextEditingController ibanController;

  const BillingInfoFormSection({
    super.key,
    required this.faturaTipi,
    required this.onFaturaTipiChanged,
    required this.faturaUnvaniController,
    required this.tcknVknController,
    required this.vergiDairesiController,
    required this.faturaAdresiController,
    required this.faturaEmailController,
    required this.ibanController,
  });

  static const Color _gold = Color(0xFFFFB300);
  static const Color _card = Color(0xFF111111);
  static const Color _border = Color(0x44FFB300);

  static const List<DropdownMenuItem<String>> _faturaTipleri = [
    DropdownMenuItem(
      value: 'bireysel',
      child: Text('Bireysel / Gerçek Kişi'),
    ),
    DropdownMenuItem(
      value: 'sahis',
      child: Text('Şahıs İşletmesi'),
    ),
    DropdownMenuItem(
      value: 'sirket',
      child: Text('Limited / Anonim Şirket'),
    ),
  ];

  static String? requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunlu.';
    }
    return null;
  }

  static String? tcknVknValidator(String? value) {
    final clean = (value ?? '').replaceAll(RegExp(r'\D'), '');

    if (clean.isEmpty) {
      return 'T.C. Kimlik / Vergi No zorunlu.';
    }

    if (clean.length != 10 && clean.length != 11) {
      return '10 haneli VKN veya 11 haneli TCKN girin.';
    }

    return null;
  }

  static String? emailValidator(String? value) {
    final clean = (value ?? '').trim();

    if (clean.isEmpty) {
      return 'Fatura e-posta zorunlu.';
    }

    if (!clean.contains('@') || !clean.contains('.')) {
      return 'Geçerli bir e-posta girin.';
    }

    return null;
  }

  static String? ibanValidator(String? value) {
    final clean = (value ?? '').replaceAll(' ', '').toUpperCase();

    if (clean.isEmpty) {
      return 'IBAN zorunlu.';
    }

    if (!clean.startsWith('TR') || clean.length < 24) {
      return 'Geçerli bir TR IBAN girin.';
    }

    return null;
  }

  static Map<String, dynamic> buildBillingMap({
    required String faturaTipi,
    required TextEditingController faturaUnvaniController,
    required TextEditingController tcknVknController,
    required TextEditingController vergiDairesiController,
    required TextEditingController faturaAdresiController,
    required TextEditingController faturaEmailController,
    required TextEditingController ibanController,
  }) {
    final tcknVkn = tcknVknController.text.replaceAll(RegExp(r'\D'), '');
    final iban = ibanController.text.replaceAll(' ', '').toUpperCase();

    return {
      'faturaTipi': faturaTipi.trim(),
      'faturaUnvani': faturaUnvaniController.text.trim(),
      'tcknVkn': tcknVkn,
      'vergiDairesi': vergiDairesiController.text.trim(),
      'faturaAdresi': faturaAdresiController.text.trim(),
      'faturaEmail': faturaEmailController.text.trim().toLowerCase(),
      'iban': iban,
      'faturaBilgileriTamMi': true,
      'billingInfoVersion': 1,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: _gold,
                size: 22,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fatura Bilgileri',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sofrasofra’nın komisyon / platform hizmet bedeli faturası için gereklidir. Müşteriye ürün fiş/faturasını üretici düzenler.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            value: faturaTipi,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1A1A),
            decoration: _inputDecoration(
              label: 'Fatura Tipi',
              icon: Icons.badge_rounded,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            items: _faturaTipleri,
            onChanged: onFaturaTipiChanged,
            validator: requiredValidator,
          ),
          const SizedBox(height: 14),
          _field(
            controller: faturaUnvaniController,
            label: 'Ad Soyad / Şirket Unvanı',
            icon: Icons.person_rounded,
            validator: requiredValidator,
          ),
          const SizedBox(height: 14),
          _field(
            controller: tcknVknController,
            label: 'T.C. Kimlik / Vergi No',
            icon: Icons.numbers_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: tcknVknValidator,
          ),
          const SizedBox(height: 14),
          _field(
            controller: vergiDairesiController,
            label: 'Vergi Dairesi',
            icon: Icons.account_balance_rounded,
            validator: requiredValidator,
          ),
          const SizedBox(height: 14),
          _field(
            controller: faturaAdresiController,
            label: 'Fatura Adresi',
            icon: Icons.location_on_rounded,
            maxLines: 3,
            validator: requiredValidator,
          ),
          const SizedBox(height: 14),
          _field(
            controller: faturaEmailController,
            label: 'Fatura E-posta',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: emailValidator,
          ),
          const SizedBox(height: 14),
          _field(
            controller: ibanController,
            label: 'IBAN',
            hint: 'TR...',
            icon: Icons.credit_card_rounded,
            textCapitalization: TextCapitalization.characters,
            validator: ibanValidator,
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _gold),
      labelStyle: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF090909),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        hint: hint,
      ),
    );
  }
}
