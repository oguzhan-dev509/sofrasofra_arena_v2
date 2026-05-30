import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/legal_consent_checkbox.dart';

class KuryeBasvuruMerkeziSayfasi extends StatefulWidget {
  const KuryeBasvuruMerkeziSayfasi({super.key});

  @override
  State<KuryeBasvuruMerkeziSayfasi> createState() =>
      _KuryeBasvuruMerkeziSayfasiState();
}

class _KuryeBasvuruMerkeziSayfasiState
    extends State<KuryeBasvuruMerkeziSayfasi> {
  static const Color _bg = Color(0xFF0F0F10);
  static const Color _panel = Color(0xFF1A1A1D);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _text = Color(0xFFF7F3E9);
  static const Color _muted = Color(0xFFB8B2A7);
  static const Color _line = Color(0x33FFB300);
  static const Color _green = Color(0xFF35C759);
  static const Color _red = Color(0xFFFF5A5F);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _adSoyadController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _sehirController = TextEditingController();
  final TextEditingController _ilceController = TextEditingController();
  final TextEditingController _aracTipiController = TextEditingController();
  final TextEditingController _plakaController = TextEditingController();
  final TextEditingController _notController = TextEditingController();

  bool _gonderiliyor = false;
  bool _legalAccepted = false;
  @override
  void dispose() {
    _adSoyadController.dispose();
    _telefonController.dispose();
    _sehirController.dispose();
    _ilceController.dispose();
    _aracTipiController.dispose();
    _plakaController.dispose();
    _notController.dispose();
    super.dispose();
  }

  String? _zorunluKontrol(String? value, String alan) {
    if (value == null || value.trim().isEmpty) {
      return '$alan zorunludur.';
    }
    return null;
  }

  Future<void> _basvuruGonder() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_legalAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _red,
          content: Text(
            'Başvuruyu tamamlamak için kullanım koşulları ve KVKK metinlerini okuyup onaylamanız gerekir.',
          ),
        ),
      );
      return;
    }

    setState(() => _gonderiliyor = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('courier_applications').doc();

      await docRef.set({
        'adSoyad': _adSoyadController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'sehir': _sehirController.text.trim(),
        'ilce': _ilceController.text.trim(),
        'aracTipi': _aracTipiController.text.trim(),
        'plaka': _plakaController.text.trim(),
        'not': _notController.text.trim(),
        'durum': 'beklemede',
        'aktifMi': false,
        'uygunluk': 'Başvuru Aşaması',
        'toplamTeslimat': 0,
        'aktifSiparis': 0,
        'rating': 5,
        'source': 'public_kurye_basvuru_formu',
        'basvuruKanal': 'uygulama',
        'legalAccepted': true,
        'legalAcceptedAt': FieldValue.serverTimestamp(),
        'legalAcceptedAtClient': DateTime.now().toIso8601String(),
        'legalAcceptedVersion': 'v1.0',
        'legalAcceptedTexts': [
          'kullanim_kosullari',
          'kvkk_aydinlatma',
          'gizlilik_politikasi',
          'kurye_basvuru_sartlari',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _adSoyadController.clear();
      _telefonController.clear();
      _sehirController.clear();
      _ilceController.clear();
      _aracTipiController.clear();
      _plakaController.clear();
      _notController.clear();
      setState(() {
        _legalAccepted = false;
      });
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: _green,
          content: Text(
            'Başvurun başarıyla alındı. İnceleme sonrası seninle iletişime geçilecektir.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _red,
          content: Text('Başvuru gönderilemedi: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _gonderiliyor = false);
      }
    }
  }

  InputDecoration _inputStyle({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _gold),
      labelStyle: const TextStyle(color: _muted),
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF141416),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _red, width: 1.4),
      ),
    );
  }

  Widget _ozellikKutusu(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _gold, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FFB300),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining_rounded,
                  color: Colors.black, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kurye Başvuru Merkezi',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            'Sofrasofra Arena teslimat ağına katıl, bölgenizde sipariş taşıyarak kazanç elde et.',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniBadge(text: 'Hızlı Başvuru'),
              _MiniBadge(text: 'Bölgesel Çalışma'),
              _MiniBadge(text: 'Esnek Model'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_rounded, color: _gold),
                SizedBox(width: 10),
                Text(
                  'Başvuru Formu',
                  style: TextStyle(
                    color: _text,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _adSoyadController,
              style: const TextStyle(color: _text),
              decoration: _inputStyle(
                label: 'Ad Soyad',
                icon: Icons.person_outline_rounded,
                hint: 'Örn: Mehmet Kaya',
              ),
              validator: (v) => _zorunluKontrol(v, 'Ad Soyad'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _telefonController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: _text),
              decoration: _inputStyle(
                label: 'Telefon',
                icon: Icons.phone_outlined,
                hint: '05xx xxx xx xx',
              ),
              validator: (v) => _zorunluKontrol(v, 'Telefon'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sehirController,
                    style: const TextStyle(color: _text),
                    decoration: _inputStyle(
                      label: 'Şehir',
                      icon: Icons.location_city_outlined,
                      hint: 'İstanbul',
                    ),
                    validator: (v) => _zorunluKontrol(v, 'Şehir'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ilceController,
                    style: const TextStyle(color: _text),
                    decoration: _inputStyle(
                      label: 'İlçe',
                      icon: Icons.map_outlined,
                      hint: 'Kadıköy',
                    ),
                    validator: (v) => _zorunluKontrol(v, 'İlçe'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _aracTipiController,
              style: const TextStyle(color: _text),
              decoration: _inputStyle(
                label: 'Araç Tipi',
                icon: Icons.two_wheeler_rounded,
                hint: 'Motosiklet / Bisiklet / Araba',
              ),
              validator: (v) => _zorunluKontrol(v, 'Araç Tipi'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _plakaController,
              style: const TextStyle(color: _text),
              decoration: _inputStyle(
                label: 'Plaka',
                icon: Icons.pin_outlined,
                hint: 'Varsa yazın',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notController,
              style: const TextStyle(color: _text),
              maxLines: 4,
              decoration: _inputStyle(
                label: 'Ek Not',
                icon: Icons.edit_note_rounded,
                hint:
                    'Çalışma saatleri, bölge tercihi veya kısa not bırakabilirsiniz.',
              ),
            ),
            const SizedBox(height: 20),
            LegalConsentCheckbox(
              value: _legalAccepted,
              onChanged: (value) {
                setState(() {
                  _legalAccepted = value;
                });
              },
              title:
                  'Kullanım koşullarını, KVKK metinlerini ve Kurye Ağı başvuru şartlarını okudum, anladım ve onaylıyorum.',
              description:
                  'Başvuruyu göndererek Sofrasofra kullanım koşullarını, KVKK aydınlatma metnini, gizlilik politikasını ve Kurye Ağı başvuru/değerlendirme şartlarını kabul etmiş olursunuz.',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _gonderiliyor ? null : _basvuruGonder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _gonderiliyor
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _gonderiliyor ? 'Gönderiliyor...' : 'Başvuruyu Gönder',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          'Kurye Başvuru Merkezi',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    children: [
                      _heroCard(),
                      const SizedBox(height: 16),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _ozellikKutusu(
                                    Icons.flash_on_rounded,
                                    'Hızlı değerlendirme',
                                    'Başvurular yönetim merkezine düşer ve uygun adaylar hızlıca değerlendirilir.',
                                  ),
                                  const SizedBox(height: 12),
                                  _ozellikKutusu(
                                    Icons.place_outlined,
                                    'Bölgesel çalışma',
                                    'Şehir ve ilçe bazlı kurye eşleştirme yapısı ile yerel teslimat ağı güçlenir.',
                                  ),
                                  const SizedBox(height: 12),
                                  _ozellikKutusu(
                                    Icons.verified_user_outlined,
                                    'Operasyonel uyum',
                                    'Onaylanan kuryeler aktif hale alınarak teslimat akışına dahil edilir.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(flex: 2, child: _formPanel()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _ozellikKutusu(
                              Icons.flash_on_rounded,
                              'Hızlı değerlendirme',
                              'Başvurular yönetim merkezine düşer ve uygun adaylar hızlıca değerlendirilir.',
                            ),
                            const SizedBox(height: 12),
                            _ozellikKutusu(
                              Icons.place_outlined,
                              'Bölgesel çalışma',
                              'Şehir ve ilçe bazlı kurye eşleştirme yapısı ile yerel teslimat ağı güçlenir.',
                            ),
                            const SizedBox(height: 12),
                            _ozellikKutusu(
                              Icons.verified_user_outlined,
                              'Operasyonel uyum',
                              'Onaylanan kuryeler aktif hale alınarak teslimat akışına dahil edilir.',
                            ),
                            const SizedBox(height: 16),
                            _formPanel(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;

  const _MiniBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
