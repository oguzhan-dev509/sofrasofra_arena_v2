import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/legal_consent_checkbox.dart';

class MahalleMutfakKocuBasvuruSayfasi extends StatefulWidget {
  const MahalleMutfakKocuBasvuruSayfasi({super.key});

  @override
  State<MahalleMutfakKocuBasvuruSayfasi> createState() =>
      _MahalleMutfakKocuBasvuruSayfasiState();
}

class _MahalleMutfakKocuBasvuruSayfasiState
    extends State<MahalleMutfakKocuBasvuruSayfasi> {
  final _formKey = GlobalKey<FormState>();

  final _adSoyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _sehirController = TextEditingController();
  final _ilceController = TextEditingController();
  final _ibanController = TextEditingController();
  final _mahalleController = TextEditingController();
  final _evUreticisiController = TextEditingController();
  final _ustaSefController = TextEditingController();
  final _restoranController = TextEditingController();
  final _haftalikZamanController = TextEditingController();
  final _motivasyonController = TextEditingController();

  bool _gonderiliyor = false;
  bool _legalAccepted = false;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Colors.black;
  static const Color _panel = Color(0xFF111111);
  static const Color _inputFill = Color(0xFF171717);

  @override
  void dispose() {
    _adSoyadController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _sehirController.dispose();
    _ilceController.dispose();
    _ibanController.dispose();
    _mahalleController.dispose();
    _evUreticisiController.dispose();
    _ustaSefController.dispose();
    _restoranController.dispose();
    _haftalikZamanController.dispose();
    _motivasyonController.dispose();
    super.dispose();
  }

  String? _zorunluKontrol(String? value, String alan) {
    if (value == null || value.trim().isEmpty) {
      return '$alan zorunludur';
    }
    return null;
  }

  String? _emailKontrol(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return null;
    }

    if (!email.contains('@') || !email.contains('.')) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  String? _ibanKontrol(String? value) {
    final iban = (value ?? '').replaceAll(' ', '').toUpperCase();

    if (iban.isEmpty) {
      return 'IBAN zorunludur';
    }

    if (!iban.startsWith('TR')) {
      return 'IBAN TR ile başlamalıdır';
    }

    if (iban.length != 26) {
      return 'Türkiye IBAN numarası 26 karakter olmalıdır';
    }

    if (!RegExp(r'^TR[0-9]{24}$').hasMatch(iban)) {
      return 'Geçerli bir IBAN girin';
    }

    return null;
  }

  Future<void> _basvuruGonder() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_legalAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Başvuruyu tamamlamak için başvuru koşulları ve KVKK metinlerini onaylamanız gerekir.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _gonderiliyor = true);

    try {
      await FirebaseFirestore.instance
          .collection('neighborhood_coach_applications')
          .add({
        'fullName': _adSoyadController.text.trim(),
        'phone': _telefonController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'iban': _ibanController.text.replaceAll(' ', '').toUpperCase(),
        'city': _sehirController.text.trim(),
        'district': _ilceController.text.trim(),
        'neighborhood': _mahalleController.text.trim(),
        'estimatedHomeProducerCount': _evUreticisiController.text.trim(),
        'estimatedChefCount': _ustaSefController.text.trim(),
        'estimatedRestaurantCount': _restoranController.text.trim(),
        'weeklyAvailability': _haftalikZamanController.text.trim(),
        'motivation': _motivasyonController.text.trim(),
        'applicationType': 'neighborhood_coach',
        'status': 'pending',
        'source': 'mahalle_mutfak_kocu_basvuru_sayfasi',
        'reviewedAt': null,
        'reviewedBy': '',
        'rejectionReason': '',
        'legalAccepted': true,
        'legalAcceptedAt': FieldValue.serverTimestamp(),
        'legalAcceptedAtClient': DateTime.now().toIso8601String(),
        'legalAcceptedVersion': 'v1.0',
        'legalAcceptedTexts': [
          'kullanim_kosullari',
          'kvkk_aydinlatma',
          'gizlilik_politikasi',
          'basvuru_ve_is_ortakligi_aydinlatma',
          'mahalle_mutfak_kocu_basvuru_sartlari',
        ],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _adSoyadController.clear();
      _telefonController.clear();
      _emailController.clear();
      _sehirController.clear();
      _ilceController.clear();
      _mahalleController.clear();
      _evUreticisiController.clear();
      _ustaSefController.clear();
      _restoranController.clear();
      _haftalikZamanController.clear();
      _motivasyonController.clear();

      if (!mounted) return;

      setState(() => _legalAccepted = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Başvurunuz başarıyla alındı. Değerlendirme sonrası sizinle iletişime geçilecektir.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Başvuru gönderilemedi: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _gonderiliyor = false);
      }
    }
  }

  Widget _alanBasligi(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _gold, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _ustKart() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _gold.withValues(alpha: 0.55),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_rounded,
                color: _gold,
                size: 24,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mahalle Mutfak Koçu Ol',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Ev Lezzetleri üreticilerini, Usta Şefleri ve mahalle restoranlarını Sofrasofra’ya kazandır. İlk satışlarına destek olurken sen de gelir elde et.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.8,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RewardChip(text: 'Onaylı başvuru: 100 TL'),
              _RewardChip(text: 'İlk satış: +250 TL'),
              _RewardChip(text: 'Aylık bonuslar'),
              _RewardChip(text: 'İlçe liderliği fırsatı'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String title,
    required TextEditingController controller,
    required String hint,
    bool requiredField = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _alanBasligi(title),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          validator: validator ??
              (requiredField ? (value) => _zorunluKontrol(value, title) : null),
          decoration: _inputDecoration(hint),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _primKosullariKarti() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _gold.withValues(alpha: 0.38),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                color: _gold,
                size: 22,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'KAZANÇ MODELİ',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Text(
            '• Onaylanan her gerçek ve uygun başvuru için 100 TL prim\n'
            '• Yönlendirdiğin katılımcının ilk başarılı satışı için ek 250 TL\n'
            '• Aylık 5 onaylı katılımcı için 500 TL bonus\n'
            '• Aylık 10 onaylı katılımcı ve en az 10 başarılı sipariş için 1.500 TL bonus\n'
            '• Aylık 20 onaylı katılımcı ve en az 30 başarılı sipariş için 4.000 TL bonus\n'
            '• Mahallende 50 başarılı sipariş hedefine ulaştığında 5.000 TL özel başarı bonusu değerlendirmesi\n'
            '• Başarılı koçlara Kıdemli Mahalle Koçu, İlçe Mutfak Lideri veya Bölge Koordinatörü olma fırsatı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              height: 1.65,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 14),
          Divider(
            color: Colors.white12,
            height: 1,
          ),
          SizedBox(height: 12),
          Text(
            'Prim ve bonuslar; başvuruların gerçekliği, onay durumu, '
            'başarılı satışlar ve Sofrasofra hak ediş kontrolü '
            'sonrasında kesinleşir.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.8,
              height: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Mahalle Mutfak Koçu, Sofrasofra adına para toplamaz ve '
            'katılımcılardan komisyon almaz.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'MAHALLE MUTFAK KOÇU BAŞVURU',
          style: TextStyle(
            color: _gold,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.7,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _ustKart(),
              const SizedBox(height: 20),
              _textField(
                title: 'Ad Soyad',
                controller: _adSoyadController,
                hint: 'Örnek: Ayşe Yılmaz',
              ),
              _textField(
                title: 'Telefon / WhatsApp',
                controller: _telefonController,
                hint: '05XX XXX XX XX',
                keyboardType: TextInputType.phone,
              ),
              _textField(
                title: 'E-posta (Opsiyonel)',
                controller: _emailController,
                hint: 'ornek@email.com',
                requiredField: false,
                keyboardType: TextInputType.emailAddress,
                validator: _emailKontrol,
              ),
              _textField(
                title: 'IBAN',
                controller: _ibanController,
                hint: 'TR00 0000 0000 0000 0000 0000 00',
                keyboardType: TextInputType.text,
                validator: _ibanKontrol,
              ),
              _textField(
                title: 'Şehir',
                controller: _sehirController,
                hint: 'Örnek: İstanbul',
              ),
              _textField(
                title: 'İlçe',
                controller: _ilceController,
                hint: 'Örnek: Güngören',
              ),
              _textField(
                title: 'Mahalle',
                controller: _mahalleController,
                hint: 'Çalışmak istediğiniz mahalle',
              ),
              _textField(
                title: 'Ulaşabileceğiniz Ev Lezzetleri üreticisi sayısı',
                controller: _evUreticisiController,
                hint: 'Örnek: 5',
                keyboardType: TextInputType.number,
              ),
              _textField(
                title: 'Ulaşabileceğiniz Usta Şef sayısı',
                controller: _ustaSefController,
                hint: 'Örnek: 2',
                keyboardType: TextInputType.number,
              ),
              _textField(
                title: 'Ulaşabileceğiniz restoran sayısı',
                controller: _restoranController,
                hint: 'Örnek: 10',
                keyboardType: TextInputType.number,
              ),
              _textField(
                title: 'Haftalık ayırabileceğiniz zaman',
                controller: _haftalikZamanController,
                hint: 'Örnek: Haftada 10 saat',
              ),
              _textField(
                title: 'Neden Mahalle Mutfak Koçu olmak istiyorsunuz?',
                controller: _motivasyonController,
                hint:
                    'Kendinizi ve bölgenizdeki bağlantılarınızı kısaca anlatın',
                maxLines: 4,
              ),
              const SizedBox(height: 4),
              LegalConsentCheckbox(
                value: _legalAccepted,
                onChanged: (value) {
                  setState(() => _legalAccepted = value);
                },
                title:
                    'Kullanım koşullarını, KVKK metinlerini ve Mahalle Mutfak Koçu başvuru şartlarını okudum, anladım ve onaylıyorum.',
                description:
                    'Başvuruyu göndererek Sofrasofra kullanım koşullarını, KVKK aydınlatma metnini, gizlilik politikasını ve başvuru/değerlendirme şartlarını kabul etmiş olursunuz.',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _gonderiliyor ? null : _basvuruGonder,
                  icon: _gonderiliyor
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
                    _gonderiliyor ? 'Gönderiliyor...' : 'Başvuruyu Gönder',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _primKosullariKarti(),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.text,
  });

  final String text;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _gold.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
