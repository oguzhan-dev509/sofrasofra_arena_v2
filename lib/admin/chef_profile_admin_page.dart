import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChefProfileAdminPage extends StatefulWidget {
  final String chefId;

  const ChefProfileAdminPage({
    super.key,
    required this.chefId,
  });

  @override
  State<ChefProfileAdminPage> createState() => _ChefProfileAdminPageState();
}

class _ChefProfileAdminPageState extends State<ChefProfileAdminPage> {
  static const Color _bg = Colors.black;
  static const Color _panel = Color(0xFF111111);
  static const Color _panel2 = Color(0xFF171717);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _softText = Color(0xFFBDBDBD);
  static const Color _border = Color(0x22FFFFFF);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _coverImageController = TextEditingController();
  final TextEditingController _profileImageController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _specialtiesController = TextEditingController();
  final TextEditingController _experienceYearsController =
      TextEditingController();
  final TextEditingController _lessonCountController = TextEditingController();
  final TextEditingController _signatureDishCountController =
      TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _reviewCountController = TextEditingController();
  final TextEditingController _servedGuestCountController =
      TextEditingController();
  final TextEditingController _instagramUrlController = TextEditingController();
  final TextEditingController _websiteUrlController = TextEditingController();

  bool _verified = false;
  bool _featured = false;
  bool _isActive = true;

  bool _loading = true;
  bool _saving = false;
  bool _initialized = false;

  DocumentReference<Map<String, dynamic>> get _docRef =>
      FirebaseFirestore.instance.collection('chef_profiles').doc(widget.chefId);

  @override
  void dispose() {
    _displayNameController.dispose();
    _headlineController.dispose();
    _bioController.dispose();
    _coverImageController.dispose();
    _profileImageController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _specialtiesController.dispose();
    _experienceYearsController.dispose();
    _lessonCountController.dispose();
    _signatureDishCountController.dispose();
    _ratingController.dispose();
    _reviewCountController.dispose();
    _servedGuestCountController.dispose();
    _instagramUrlController.dispose();
    _websiteUrlController.dispose();
    super.dispose();
  }

  String _text(dynamic value, {String fallback = ''}) {
    final t = (value ?? '').toString().trim();
    return t.isEmpty ? fallback : t;
  }

  int _toInt(String value, {int fallback = 0}) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  double _toDouble(String value, {double fallback = 0}) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }

  bool _toBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    final raw = (value ?? '').toString().toLowerCase().trim();
    if (raw == 'true') return true;
    if (raw == 'false') return false;
    return fallback;
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  List<String> _parseSpecialties(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  void _fillForm(Map<String, dynamic> data) {
    _displayNameController.text =
        _text(data['displayName'] ?? data['adSoyad'], fallback: '');
    _headlineController.text = _text(data['headline']);
    _bioController.text = _text(data['bio']);
    _coverImageController.text = _text(data['coverImage']);
    _profileImageController.text = _text(data['profileImage']);
    _cityController.text = _text(data['city']);
    _countryController.text = _text(data['country'], fallback: 'Türkiye');
    _specialtiesController.text = _toStringList(data['specialties']).join(', ');
    _experienceYearsController.text =
        _text(data['experienceYears'], fallback: '');
    _lessonCountController.text = _text(data['lessonCount'], fallback: '');
    _signatureDishCountController.text =
        _text(data['signatureDishCount'], fallback: '');
    _ratingController.text = _text(data['rating'], fallback: '');
    _reviewCountController.text = _text(data['reviewCount'], fallback: '');
    _servedGuestCountController.text =
        _text(data['servedGuestCount'], fallback: '');
    _instagramUrlController.text = _text(data['instagramUrl']);
    _websiteUrlController.text = _text(data['websiteUrl']);

    _verified = _toBool(data['verified']);
    _featured = _toBool(data['featured']);
    _isActive = data['isActive'] == null ? true : _toBool(data['isActive']);
  }

  Future<void> _save() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen gerekli alanları kontrol edin.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = <String, dynamic>{
        'chefId': widget.chefId,
        'displayName': _displayNameController.text.trim(),
        'headline': _headlineController.text.trim(),
        'bio': _bioController.text.trim(),
        'coverImage': _coverImageController.text.trim(),
        'profileImage': _profileImageController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim().isEmpty
            ? 'Türkiye'
            : _countryController.text.trim(),
        'specialties': _parseSpecialties(_specialtiesController.text),
        'experienceYears': _toInt(_experienceYearsController.text),
        'lessonCount': _toInt(_lessonCountController.text),
        'signatureDishCount': _toInt(_signatureDishCountController.text),
        'rating': _toDouble(_ratingController.text, fallback: 0),
        'reviewCount': _toInt(_reviewCountController.text),
        'servedGuestCount': _toInt(_servedGuestCountController.text),
        'instagramUrl': _instagramUrlController.text.trim(),
        'websiteUrl': _websiteUrlController.text.trim(),
        'verified': _verified,
        'featured': _featured,
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final existing = await _docRef.get();

      if (!existing.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await _docRef.set(payload, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şef profili başarıyla kaydedildi.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt sırasında hata oluştu: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null && subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: _softText,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: _panel2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _gold),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _panel2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: _gold,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: _softText,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String title, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 170,
            width: double.infinity,
            color: _panel2,
            child: url.trim().isEmpty
                ? const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.white38,
                      size: 34,
                    ),
                  )
                : Image.network(
                    url.trim(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                        size: 34,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _docRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: Text(
                'Şef profili yüklenemedi.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data?.data() ?? <String, dynamic>{};

        if (!_initialized) {
          _fillForm(data);
          _initialized = true;
          _loading = false;
        }

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            centerTitle: false,
            title: const Text(
              'Şef Profil Admin',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: TextButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, color: Colors.black),
                  label: Text(
                    _saving ? 'Kaydediliyor' : 'Kaydet',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: _gold,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _buildPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              'Temel Profil Bilgileri',
                              subtitle:
                                  'Premium chef landing page üzerinde görünen ana metinler.',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              'Şef Adı / Display Name',
                              _displayNameController,
                              hint: 'Örn: Abdullah Sağlık',
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) {
                                  return 'Şef adı boş bırakılamaz';
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                              'Headline',
                              _headlineController,
                              maxLines: 2,
                              hint:
                                  'Örn: Modern sunum teknikleriyle güçlü Türk ve Osmanlı mutfağı deneyimi',
                            ),
                            _buildTextField(
                              'Bio',
                              _bioController,
                              maxLines: 5,
                              hint:
                                  'Şefin hikâyesi, yaklaşımı, mutfak çizgisi...',
                            ),
                            _buildTextField(
                              'Şehir',
                              _cityController,
                              hint: 'Örn: İstanbul',
                            ),
                            _buildTextField(
                              'Ülke',
                              _countryController,
                              hint: 'Örn: Türkiye',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              'Görseller',
                              subtitle:
                                  'Kapak ve profil görselleri premium ilk izlenimi belirler.',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              'Kapak Görsel URL',
                              _coverImageController,
                              hint: 'https://...',
                            ),
                            _buildImagePreview(
                              'Kapak Önizleme',
                              _coverImageController.text,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              'Profil Fotoğrafı URL',
                              _profileImageController,
                              hint: 'https://...',
                            ),
                            _buildImagePreview(
                              'Profil Fotoğrafı Önizleme',
                              _profileImageController.text,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              'Uzmanlık ve Metrikler',
                              subtitle:
                                  'Profilde güven ve kalite hissini güçlendiren veriler.',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              'Specialties',
                              _specialtiesController,
                              maxLines: 2,
                              hint:
                                  'Osmanlı Mutfağı, Tabak Tasarım, Özel Davet',
                            ),
                            _buildTextField(
                              'Deneyim Yılı',
                              _experienceYearsController,
                              keyboardType: TextInputType.number,
                              hint: '15',
                            ),
                            _buildTextField(
                              'Ders Sayısı',
                              _lessonCountController,
                              keyboardType: TextInputType.number,
                              hint: '24',
                            ),
                            _buildTextField(
                              'İmza Tabak Sayısı',
                              _signatureDishCountController,
                              keyboardType: TextInputType.number,
                              hint: '18',
                            ),
                            _buildTextField(
                              'Rating',
                              _ratingController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              hint: '4.9',
                              validator: (v) {
                                final raw = (v ?? '').trim();
                                if (raw.isEmpty) return null;
                                final parsed =
                                    double.tryParse(raw.replaceAll(',', '.'));
                                if (parsed == null) {
                                  return 'Geçerli bir puan girin';
                                }
                                if (parsed < 0 || parsed > 5) {
                                  return 'Puan 0 ile 5 arasında olmalı';
                                }
                                return null;
                              },
                            ),
                            _buildTextField(
                              'Yorum Sayısı',
                              _reviewCountController,
                              keyboardType: TextInputType.number,
                              hint: '124',
                            ),
                            _buildTextField(
                              'Hizmet Verilen Misafir Sayısı',
                              _servedGuestCountController,
                              keyboardType: TextInputType.number,
                              hint: '1800',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              'Linkler',
                              subtitle:
                                  'Şefin sosyal veya kurumsal dış bağlantıları.',
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              'Instagram URL',
                              _instagramUrlController,
                              hint: 'https://instagram.com/...',
                            ),
                            _buildTextField(
                              'Website URL',
                              _websiteUrlController,
                              hint: 'https://...',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(
                              'Profil Durumu',
                              subtitle: 'Rozetler ve görünürlük kontrolleri.',
                            ),
                            const SizedBox(height: 16),
                            _buildSwitchTile(
                              'Doğrulanmış Şef',
                              'Profilde güven rozeti gösterilir.',
                              _verified,
                              (v) => setState(() => _verified = v),
                            ),
                            _buildSwitchTile(
                              'Öne Çıkan Profil',
                              'Hero bölümünde öne çıkan profil rozeti gösterilir.',
                              _featured,
                              (v) => setState(() => _featured = v),
                            ),
                            _buildSwitchTile(
                              'Profil Aktif',
                              'Profilin aktif görünürlük durumu.',
                              _isActive,
                              (v) => setState(() => _isActive = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.save_rounded,
                                  color: Colors.black,
                                ),
                          label: Text(
                            _saving
                                ? 'Kaydediliyor...'
                                : 'Şef Profilini Kaydet',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
