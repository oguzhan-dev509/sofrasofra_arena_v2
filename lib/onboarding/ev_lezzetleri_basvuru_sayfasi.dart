import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/services/campaign_service.dart';
import 'package:sofrasofra_arena_v2/modules/common/basvuru_alindi_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/billing_info_form_section.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EvLezzetleriBasvuruSayfasi extends StatefulWidget {
  const EvLezzetleriBasvuruSayfasi({super.key});

  @override
  State<EvLezzetleriBasvuruSayfasi> createState() =>
      _EvLezzetleriBasvuruSayfasiState();
}

class _EvLezzetleriBasvuruSayfasiState
    extends State<EvLezzetleriBasvuruSayfasi> {
  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _border = Color(0x44FFB300);

  final _formKey = GlobalKey<FormState>();

  final _adSoyadCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _sehirCtrl = TextEditingController();
  final _ilceCtrl = TextEditingController();
  final _mutfakAdiCtrl = TextEditingController();
  final _uzmanlikCtrl = TextEditingController();
  final _belgeNotuCtrl = TextEditingController();
  String _faturaTipi = 'bireysel';

  final _faturaUnvaniCtrl = TextEditingController();
  final _tcknVknCtrl = TextEditingController();
  final _vergiDairesiCtrl = TextEditingController();
  final _faturaAdresiCtrl = TextEditingController();
  final _faturaEmailCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _faturaUnvaniCtrl.dispose();
    _tcknVknCtrl.dispose();
    _vergiDairesiCtrl.dispose();
    _faturaAdresiCtrl.dispose();
    _faturaEmailCtrl.dispose();
    _adSoyadCtrl.dispose();
    _telefonCtrl.dispose();
    _ibanCtrl.dispose();
    _sehirCtrl.dispose();
    _ilceCtrl.dispose();
    _mutfakAdiCtrl.dispose();
    _uzmanlikCtrl.dispose();
    _belgeNotuCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    debugPrint('EV BASVURU SUBMIT BASILDI');
    final valid = _formKey.currentState?.validate() ?? false;
    debugPrint('EV BASVURU VALID=$valid');

    if (!valid) {
      _showSnack('Lütfen zorunlu alanları kontrol edin.', isError: true);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('EV BASVURU AUTH UID=${user?.uid}');
    debugPrint('EV BASVURU AUTH ANON=${user?.isAnonymous}');
    if (user == null) {
      _showSnack('Başvuru için önce giriş yapmalısınız.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      debugPrint('EV BASVURU FUNCTION CALL BASLIYOR');
      debugPrint(
        'EV BASVURU FIREBASE PROJECT=${Firebase.app().options.projectId}',
      );
      debugPrint('EV BASVURU USERID=${user.uid}');
      debugPrint('EV BASVURU AUTH ANON=${user.isAnonymous}');

      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('submitEvLezzetleriApplication');

      final result = await callable.call({
        'adSoyad': _adSoyadCtrl.text.trim(),
        'telefon': _telefonCtrl.text.trim(),
        'iban': _ibanCtrl.text.trim().replaceAll(' ', '').toUpperCase(),
        'sehir': _sehirCtrl.text.trim().toUpperCase(),
        'ilce': _ilceCtrl.text.trim().toUpperCase(),
        'mutfakAdi': _mutfakAdiCtrl.text.trim(),
        'urunBilgisi': _uzmanlikCtrl.text.trim(),
        'uzmanlik': _uzmanlikCtrl.text.trim(),
        'belgeNotu': _belgeNotuCtrl.text.trim(),
        'billingInfo': BillingInfoFormSection.buildBillingMap(
          faturaTipi: _faturaTipi,
          faturaUnvaniController: _faturaUnvaniCtrl,
          tcknVknController: _tcknVknCtrl,
          vergiDairesiController: _vergiDairesiCtrl,
          faturaAdresiController: _faturaAdresiCtrl,
          faturaEmailController: _faturaEmailCtrl,
          ibanController: _ibanCtrl,
        ),
      });

      debugPrint('EV BASVURU FUNCTION RESULT=${result.data}');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BasvuruAlindiSayfasi(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Başvuru kaydedilemedi: $e', isError: true);
      debugPrint('EV BASVURU FUNCTION HATA=$e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bu alan zorunlu.';
    }

    return null;
  }

  String? _ibanValidator(String? value) {
    final iban = (value ?? '').trim().replaceAll(' ', '').toUpperCase();

    if (iban.isEmpty) {
      return 'IBAN zorunlu.';
    }

    if (!iban.startsWith('TR')) {
      return 'IBAN TR ile başlamalı.';
    }

    if (iban.length != 26) {
      return 'IBAN 26 karakter olmalı.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Ev Lezzetleri Başvurusu',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Ev Lezzetleri Üretici Formu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Evde üreten bireysel üreticiler için ön başvuru formu. Onay sonrası ürün ekleme ve vitrine çıkma süreci açılır.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _section(
                    children: [
                      _field(
                        controller: _adSoyadCtrl,
                        label: 'Ad Soyad',
                        icon: Icons.person_rounded,
                        validator: _required,
                      ),
                      _field(
                        controller: _telefonCtrl,
                        label: 'Telefon / WhatsApp',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: _required,
                      ),
                      _field(
                        controller: _ibanCtrl,
                        label: 'IBAN',
                        hint: 'TR...',
                        icon: Icons.account_balance_rounded,
                        keyboardType: TextInputType.text,
                        validator: _ibanValidator,
                      ),
                      _field(
                        controller: _sehirCtrl,
                        label: 'Şehir',
                        icon: Icons.location_city_rounded,
                        validator: _required,
                      ),
                      _field(
                        controller: _ilceCtrl,
                        label: 'İlçe',
                        icon: Icons.place_rounded,
                        validator: _required,
                      ),
                      _field(
                        controller: _mutfakAdiCtrl,
                        label: 'Mutfak / Dükkan Adı',
                        icon: Icons.home_work_rounded,
                        validator: _required,
                      ),
                      _field(
                        controller: _uzmanlikCtrl,
                        label: 'Ne üretiyorsunuz?',
                        hint:
                            'Örn: Ev yemekleri, turşu-reçel, tatlı, süt ürünleri',
                        icon: Icons.restaurant_menu_rounded,
                        validator: _required,
                      ),
                      _field(
                        controller: _belgeNotuCtrl,
                        label: 'Belge Notu',
                        hint:
                            'Örn: E-devlet ikametgahım hazır / vergi muafiyet belgem var',
                        icon: Icons.verified_rounded,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 24),
                  BillingInfoFormSection(
                    faturaTipi: _faturaTipi,
                    onFaturaTipiChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _faturaTipi = value;
                      });
                    },
                    faturaUnvaniController: _faturaUnvaniCtrl,
                    tcknVknController: _tcknVknCtrl,
                    vergiDairesiController: _vergiDairesiCtrl,
                    faturaAdresiController: _faturaAdresiCtrl,
                    faturaEmailController: _faturaEmailCtrl,
                    ibanController: _ibanCtrl,
                  ),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _saving ? 'Kaydediliyor...' : 'Başvuruyu Gönder',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
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
    );
  }

  Widget _section({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: _gold),
          filled: true,
          fillColor: const Color(0xFF161616),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0x33FFFFFF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _gold),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
