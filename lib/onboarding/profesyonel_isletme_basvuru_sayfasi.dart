import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/services/campaign_service.dart';

class ProfesyonelIsletmeBasvuruSayfasi extends StatefulWidget {
  const ProfesyonelIsletmeBasvuruSayfasi({super.key});

  @override
  State<ProfesyonelIsletmeBasvuruSayfasi> createState() =>
      _ProfesyonelIsletmeBasvuruSayfasiState();
}

class _ProfesyonelIsletmeBasvuruSayfasiState
    extends State<ProfesyonelIsletmeBasvuruSayfasi> {
  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _border = Color(0x44FFB300);

  final _formKey = GlobalKey<FormState>();

  final _isletmeAdiCtrl = TextEditingController();
  final _yetkiliKisiCtrl = TextEditingController();
  final _telefonCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _sehirCtrl = TextEditingController();
  final _ilceCtrl = TextEditingController();
  final _vergiNotuCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();

  String _isletmeTipi = 'usta_sef';
  bool _saving = false;

  @override
  void dispose() {
    _isletmeAdiCtrl.dispose();
    _yetkiliKisiCtrl.dispose();
    _telefonCtrl.dispose();
    _emailCtrl.dispose();
    _sehirCtrl.dispose();
    _ilceCtrl.dispose();
    _vergiNotuCtrl.dispose();
    _ibanCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showSnack('Başvuru için önce giriş yapmalısınız.', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('producer_applications').add({
        'userId': user.uid,
        'type': 'profesyonel_isletme',
        'status': 'submitted',
        'aiReviewStatus': 'not_started',
        'riskLevel': 'unknown',
        'isletmeTipi': _isletmeTipi,
        'isletmeAdi': _isletmeAdiCtrl.text.trim(),
        'yetkiliKisi': _yetkiliKisiCtrl.text.trim(),
        'telefon': _telefonCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'sehir': _sehirCtrl.text.trim().toUpperCase(),
        'ilce': _ilceCtrl.text.trim().toUpperCase(),
        'vergiNotu': _vergiNotuCtrl.text.trim(),
        'iban': _ibanCtrl.text.trim(),
        'aciklama': _aciklamaCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await CampaignService.decreaseQuota('sef');

      if (!mounted) return;
      _showSnack('Usta Şef / Restoran başvurunuz alındı.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Başvuru kaydedilemedi: $e', isError: true);
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

  String? _emailValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Bu alan zorunlu.';
    if (!text.contains('@')) return 'Geçerli bir e-posta girin.';
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
          'Usta Şef / Restoran Başvurusu',
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
                    'Profesyonel İşletme Formu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Usta şefler, restoranlar, kafeler ve profesyonel mutfaklar için ön başvuru formu. Onay sonrası yönetim paneli ve vitrin erişimi açılır.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _section(
                    children: [
                      _typeSelector(),
                      const SizedBox(height: 14),
                      _field(
                        controller: _isletmeAdiCtrl,
                        label: 'İşletme / Marka Adı',
                        icon: Icons.storefront_rounded,
                        validator: _required,
                      ),
                      _field(
                        controller: _yetkiliKisiCtrl,
                        label: 'Yetkili Kişi',
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
                        controller: _emailCtrl,
                        label: 'E-posta',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: _emailValidator,
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
                        controller: _vergiNotuCtrl,
                        label: 'Vergi Levhası / Belge Notu',
                        hint:
                            'Örn: Vergi levham hazır, belgeyi panelden yükleyeceğim',
                        icon: Icons.verified_rounded,
                        maxLines: 3,
                      ),
                      _field(
                        controller: _ibanCtrl,
                        label: 'IBAN',
                        hint: 'TR...',
                        icon: Icons.account_balance_rounded,
                        validator: _required,
                      ),
                      _field(
                        controller: _aciklamaCtrl,
                        label: 'Kısa Açıklama',
                        hint:
                            'Örn: Şef masası, catering, özel davet, restoran vitrini...',
                        icon: Icons.notes_rounded,
                        maxLines: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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

  Widget _typeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Başvuru Tipi',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _typeChip('usta_sef', 'Usta Şef'),
            _typeChip('restoran', 'Restoran'),
            _typeChip('kafe', 'Kafe'),
            _typeChip('catering', 'Catering'),
          ],
        ),
      ],
    );
  }

  Widget _typeChip(String value, String label) {
    final selected = _isletmeTipi == value;

    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) {
        setState(() => _isletmeTipi = value);
      },
      selectedColor: _gold,
      backgroundColor: const Color(0xFF161616),
      labelStyle: TextStyle(
        color: selected ? Colors.black : Colors.white70,
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
        color: selected ? _gold : const Color(0x33FFFFFF),
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
