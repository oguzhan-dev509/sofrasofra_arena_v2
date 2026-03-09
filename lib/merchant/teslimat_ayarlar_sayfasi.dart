import 'package:flutter/material.dart';

class TeslimatAyarlariSayfasi extends StatefulWidget {
  const TeslimatAyarlariSayfasi({super.key});

  @override
  State<TeslimatAyarlariSayfasi> createState() =>
      _TeslimatAyarlariSayfasiState();
}

class _TeslimatAyarlariSayfasiState extends State<TeslimatAyarlariSayfasi> {
  static const Color gold = Color(0xFFFFB300);

  String _teslimatTipi = 'gel_al_ve_teslimat';

  final TextEditingController _minSiparisController =
      TextEditingController(text: '100');
  final TextEditingController _teslimatUcretiController =
      TextEditingController(text: '25');
  final TextEditingController _teslimatYaricapiController =
      TextEditingController(text: '3');

  bool _saving = false;

  @override
  void dispose() {
    _minSiparisController.dispose();
    _teslimatUcretiController.dispose();
    _teslimatYaricapiController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _saving = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Teslimat ayarları yerel test modunda kaydedildi. Firestore bağlantısını sonra açacağız.',
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF111111),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: gold.withAlpha(60)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: gold),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'TESLİMAT AYARLARI',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TESLİMAT TİPİ',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  value: 'gel_al',
                  groupValue: _teslimatTipi,
                  activeColor: gold,
                  title: const Text(
                    'Sadece Gel-Al',
                    style: TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _teslimatTipi = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  value: 'sadece_teslimat',
                  groupValue: _teslimatTipi,
                  activeColor: gold,
                  title: const Text(
                    'Sadece Teslimat',
                    style: TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _teslimatTipi = value!;
                    });
                  },
                ),
                RadioListTile<String>(
                  value: 'gel_al_ve_teslimat',
                  groupValue: _teslimatTipi,
                  activeColor: gold,
                  title: const Text(
                    'Gel-Al ve Teslimat',
                    style: TextStyle(color: Colors.white),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _teslimatTipi = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withAlpha(60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TESLİMAT AYARLARI',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  label: 'Minimum Sipariş Tutarı',
                  controller: _minSiparisController,
                  suffix: 'TL',
                  hint: 'Örn: 100',
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  label: 'Teslimat Ücreti',
                  controller: _teslimatUcretiController,
                  suffix: 'TL',
                  hint: 'Örn: 25',
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  label: 'Teslimat Yarıçapı',
                  controller: _teslimatYaricapiController,
                  suffix: 'km',
                  hint: 'Örn: 3',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _saveData,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
