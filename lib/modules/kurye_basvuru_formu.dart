import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KuryeBasvuruFormu extends StatefulWidget {
  const KuryeBasvuruFormu({super.key});

  @override
  State<KuryeBasvuruFormu> createState() => _KuryeBasvuruFormuState();
}

class _KuryeBasvuruFormuState extends State<KuryeBasvuruFormu> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _adSoyadController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _sehirController = TextEditingController();
  final TextEditingController _ilceController = TextEditingController();
  final TextEditingController _aracTipiController = TextEditingController();
  final TextEditingController _plakaController = TextEditingController();
  final TextEditingController _notController = TextEditingController();

  bool _gonderiliyor = false;

  static const Color _gold = Color(0xFFFFC107);
  static const Color _goldSoft = Color(0x33FFC107);
  static const Color _bg = Colors.black;
  static const Color _panel = Color(0xFF0D0D0D);
  static const Color _inputFill = Color(0xFF141414);

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

  Future<void> _basvuruGonder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _gonderiliyor = true;
    });

    try {
      await FirebaseFirestore.instance.collection('courier_applications').add({
        'adSoyad': _adSoyadController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'sehir': _sehirController.text.trim().toLowerCase(),
        'ilce': _ilceController.text.trim().toLowerCase(),
        'aracTipi': _aracTipiController.text.trim(),
        'plaka': _plakaController.text.trim(),
        'not': _notController.text.trim(),
        'status': 'pending',
        'reviewedAt': null,
        'reviewedBy': '',
        'redSebebi': '',
        'source': 'kurye_basvuru_formu',
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başvurunuz başarıyla alındı.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Başvuru gönderilemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _gonderiliyor = false;
        });
      }
    }
  }

  String? _zorunluKontrol(String? value, String alan) {
    if (value == null || value.trim().isEmpty) {
      return '$alan zorunludur';
    }
    return null;
  }

  Widget _alanBasligi(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: _gold,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      filled: true,
      fillColor: _inputFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade800),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: _goldSoft,
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.delivery_dining, color: _gold, size: 22),
              SizedBox(width: 8),
              Text(
                'Mahalle Kurye Başvurusu',
                style: TextStyle(
                  color: _gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Sofrasofra kurye ağına katılmak için formu doldurun. Hızlı başvuru, hızlı değerlendirme.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
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
          'KURYE BAŞVURU',
          style: TextStyle(
            color: _gold,
            letterSpacing: 1.0,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _ustKart(),
              const SizedBox(height: 18),
              _alanBasligi('Ad Soyad'),
              TextFormField(
                controller: _adSoyadController,
                style: const TextStyle(color: Colors.white),
                validator: (v) => _zorunluKontrol(v, 'Ad Soyad'),
                decoration: _inputDecoration('Örnek: Mehmet Kaya'),
              ),
              const SizedBox(height: 14),
              _alanBasligi('Telefon'),
              TextFormField(
                controller: _telefonController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                validator: (v) => _zorunluKontrol(v, 'Telefon'),
                decoration: _inputDecoration('0555 123 45 67'),
              ),
              const SizedBox(height: 14),
              _alanBasligi('Şehir'),
              TextFormField(
                controller: _sehirController,
                style: const TextStyle(color: Colors.white),
                validator: (v) => _zorunluKontrol(v, 'Şehir'),
                decoration: _inputDecoration('Örnek: İstanbul'),
              ),
              const SizedBox(height: 14),
              _alanBasligi('İlçe'),
              TextFormField(
                controller: _ilceController,
                style: const TextStyle(color: Colors.white),
                validator: (v) => _zorunluKontrol(v, 'İlçe'),
                decoration: _inputDecoration('Örnek: Kadıköy'),
              ),
              const SizedBox(height: 14),
              _alanBasligi('Araç Tipi'),
              TextFormField(
                controller: _aracTipiController,
                style: const TextStyle(color: Colors.white),
                validator: (v) => _zorunluKontrol(v, 'Araç Tipi'),
                decoration: _inputDecoration('Örnek: Motosiklet'),
              ),
              const SizedBox(height: 14),
              _alanBasligi('Plaka (Opsiyonel)'),
              TextFormField(
                controller: _plakaController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Örnek: 34 ABC 123'),
              ),
              const SizedBox(height: 14),
              _alanBasligi('Not (Opsiyonel)'),
              TextFormField(
                controller: _notController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(
                  'Çalışma saatlerinizi veya notunuzu yazabilirsiniz',
                ),
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
                      : const Icon(Icons.send),
                  label: Text(
                    _gonderiliyor ? 'Gönderiliyor...' : 'Başvuruyu Gönder',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    elevation: 6,
                    shadowColor: const Color(0x66FFC107),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
