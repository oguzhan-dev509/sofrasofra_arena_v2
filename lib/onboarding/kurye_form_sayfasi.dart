import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KuryeFormSayfasi extends StatefulWidget {
  const KuryeFormSayfasi({super.key});

  @override
  State<KuryeFormSayfasi> createState() => _KuryeFormSayfasiState();
}

class _KuryeFormSayfasiState extends State<KuryeFormSayfasi> {
  final _adSoyadController = TextEditingController();
  final _telefonController = TextEditingController();
  final _sehirController = TextEditingController();
  final _ilceController = TextEditingController();
  final _plakaController = TextEditingController();
  final _ehliyetController = TextEditingController();
  final _ibanController = TextEditingController();
  final _notController = TextEditingController();

  String _aracTipi = 'Motosiklet';
  String _calismaTercihi = 'Tam zamanlı';
  bool _loading = false;

  static const Color _bg = Color(0xFF090909);
  static const Color _panel = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  void dispose() {
    _adSoyadController.dispose();
    _telefonController.dispose();
    _sehirController.dispose();
    _ilceController.dispose();
    _plakaController.dispose();
    _ehliyetController.dispose();
    _ibanController.dispose();
    _notController.dispose();
    super.dispose();
  }

  Future<void> _basvur() async {
    if (_adSoyadController.text.trim().isEmpty ||
        _telefonController.text.trim().isEmpty ||
        _sehirController.text.trim().isEmpty ||
        _ilceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen zorunlu alanları doldurun.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection('courier_applications').add({
        'adSoyad': _adSoyadController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'sehir': _sehirController.text.trim(),
        'ilce': _ilceController.text.trim(),
        'aracTipi': _aracTipi,
        'plaka': _plakaController.text.trim(),
        'ehliyetSinifi': _ehliyetController.text.trim(),
        'iban': _ibanController.text.trim(),
        'calismaTercihi': _calismaTercihi,
        'not': _notController.text.trim(),
        'status': 'pending',
        'source': 'kurucu_kurye_programi',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kurye başvurunuz alındı.')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Başvuru gönderilemedi: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _gold),
      ),
    );
  }

  Widget _counterBadge() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('siteSettings')
          .doc('campaign')
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final kalan = data?['kuryeKalan'] ?? 500;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: _gold.withValues(alpha: 0.55)),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Sadece İlk 500 Kurucu Kurye',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$kalan Kurucu Kurye Hakkı Kaldı',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: const Text('Kurye Başvuru'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _gold.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kurucu Kurye Başvuru Formu',
                style: TextStyle(
                  color: _gold,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              _counterBadge(),
              const SizedBox(height: 14),
              const Text(
                'Başvurunuz ön incelemeye alınır. Onay sonrası kurye paneli ve görev akışı aktif edilir.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 20),
              _textField(
                controller: _adSoyadController,
                label: 'Ad Soyad *',
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _telefonController,
                label: 'Telefon *',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _sehirController,
                label: 'Şehir *',
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _ilceController,
                label: 'İlçe *',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _aracTipi,
                dropdownColor: _panel,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Araç Tipi'),
                items: const [
                  DropdownMenuItem(
                    value: 'Motosiklet',
                    child: Text('Motosiklet'),
                  ),
                  DropdownMenuItem(
                    value: 'Araba',
                    child: Text('Araba'),
                  ),
                  DropdownMenuItem(
                    value: 'Bisiklet',
                    child: Text('Bisiklet'),
                  ),
                  DropdownMenuItem(
                    value: 'Yaya',
                    child: Text('Yaya'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _aracTipi = value);
                },
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _plakaController,
                label: 'Plaka',
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _ehliyetController,
                label: 'Ehliyet Sınıfı',
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _ibanController,
                label: 'IBAN',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _calismaTercihi,
                dropdownColor: _panel,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration('Çalışma Tercihi'),
                items: const [
                  DropdownMenuItem(
                    value: 'Tam zamanlı',
                    child: Text('Tam zamanlı'),
                  ),
                  DropdownMenuItem(
                    value: 'Yarı zamanlı',
                    child: Text('Yarı zamanlı'),
                  ),
                  DropdownMenuItem(
                    value: 'Hafta sonu',
                    child: Text('Hafta sonu'),
                  ),
                  DropdownMenuItem(
                    value: 'Esnek',
                    child: Text('Esnek'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _calismaTercihi = value);
                },
              ),
              const SizedBox(height: 14),
              _textField(
                controller: _notController,
                label: 'Ek Not',
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _basvur,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(
                    _loading ? 'Gönderiliyor...' : 'Başvuruyu Gönder',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
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
    );
  }
}
