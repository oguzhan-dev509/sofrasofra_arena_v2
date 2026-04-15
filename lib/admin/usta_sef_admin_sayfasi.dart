import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sofrasofra_arena_v2/admin/chef_profile_admin_page.dart';

class UstaSefAdminSayfasi extends StatefulWidget {
  final String chefId;

  const UstaSefAdminSayfasi({
    super.key,
    required this.chefId,
  });

  @override
  State<UstaSefAdminSayfasi> createState() => _UstaSefAdminSayfasiState();
}

class _UstaSefAdminSayfasiState extends State<UstaSefAdminSayfasi>
    with SingleTickerProviderStateMixin {
  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Colors.black;
  static const Color _card = Color(0xFF171717);

  late final TabController _tabController;

  final _chefFormKey = GlobalKey<FormState>();
  final _lessonFormKey = GlobalKey<FormState>();

  final _chefIdController = TextEditingController();
  final _chefNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _expertiseController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _ratingController = TextEditingController(text: '5.0');
  final _profileImageController = TextEditingController();
  final _galleryController = TextEditingController();

  bool _academyEnabled = true;
  bool _consultingEnabled = true;
  bool _privateDiningEnabled = true;
  bool _isPremium = false;

  final _lessonChefIdController = TextEditingController();
  final _lessonTitleController = TextEditingController();
  final _lessonDurationController = TextEditingController();
  final _lessonCategoryController = TextEditingController();
  final _lessonLevelController = TextEditingController();
  final _lessonPriceController = TextEditingController();
  bool _lessonLocked = false;

  bool _savingChef = false;
  bool _savingLesson = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    _chefIdController.dispose();
    _chefNameController.dispose();
    _bioController.dispose();
    _expertiseController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _ratingController.dispose();
    _profileImageController.dispose();
    _galleryController.dispose();

    _lessonChefIdController.dispose();
    _lessonTitleController.dispose();
    _lessonDurationController.dispose();
    _lessonCategoryController.dispose();
    _lessonLevelController.dispose();
    _lessonPriceController.dispose();

    super.dispose();
  }

  String _safe(String value) => value.trim();

  String _slugifyChefId(String name) {
    final lower = name.trim().toLowerCase();
    final map = <String, String>{
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'İ': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };

    var out = lower;
    map.forEach((k, v) {
      out = out.replaceAll(k, v);
    });

    out = out.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    out = out.replaceAll(RegExp(r'_+'), '_');
    out = out.replaceAll(RegExp(r'^_+|_+$'), '');

    if (!out.startsWith('chef_')) {
      out = 'chef_$out';
    }
    return out;
  }

  List<String> _parseGallery(String raw) {
    return raw
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  double _parseRating(String raw) {
    return double.tryParse(raw.replaceAll(',', '.')) ?? 5.0;
  }

  Future<void> _saveChef() async {
    if (!_chefFormKey.currentState!.validate()) return;

    setState(() => _savingChef = true);

    try {
      final name = _safe(_chefNameController.text);
      final existingChefId = _safe(_chefIdController.text);

      final chefId =
          existingChefId.isNotEmpty ? existingChefId : _slugifyChefId(name);

      print('🔥 SAVE CHEF ID: $chefId');

      final payload = <String, dynamic>{
        'id': chefId,
        'name': name,
        'bio': _safe(_bioController.text),
        'expertise': _safe(_expertiseController.text),
        'city': _safe(_cityController.text),
        'district': _safe(_districtController.text),
        'rating': _parseRating(_ratingController.text),
        'isPremium': _isPremium,
        'academyChefId': chefId,
        'media': {
          'profileImage': _safe(_profileImageController.text),
          'gallery': _parseGallery(_galleryController.text),
        },
        'services': {
          'academy': _academyEnabled,
          'consulting': _consultingEnabled,
          'privateDining': _privateDiningEnabled,
        },
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('chefs')
          .doc(chefId)
          .set(payload, SetOptions(merge: true));

      if (!mounted) return;
      _chefIdController.text = chefId;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şef kaydedildi: $chefId')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şef kaydedilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingChef = false);
    }
  }

  Future<void> _saveLesson() async {
    if (!_lessonFormKey.currentState!.validate()) return;

    setState(() => _savingLesson = true);

    try {
      final chefId = _safe(_chefIdController.text);

      print('🔥 SAVE LESSON CHEF ID: $chefId');

      if (chefId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce şef kaydedilmeli.')),
        );
        setState(() => _savingLesson = false);
        return;
      }

      final payload = <String, dynamic>{
        'chefId': chefId,
        'baslik': _safe(_lessonTitleController.text),
        'sure': _safe(_lessonDurationController.text),
        'aciklama': _safe(_lessonCategoryController.text),
        'ucretsiz': !_lessonLocked,
        'videoCount': int.tryParse(_safe(_lessonPriceController.text)) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (chefId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Önce şef kaydedilmeli.')),
        );
        setState(() => _savingLesson = false);
        return;
      }

      await FirebaseFirestore.instance.collection('dersler').add(payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ders kaydedildi: ${payload['title']}')),
      );

      _lessonTitleController.clear();
      _lessonDurationController.clear();
      _lessonCategoryController.clear();
      _lessonLevelController.clear();
      _lessonPriceController.clear();
      setState(() => _lessonLocked = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ders kaydedilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingLesson = false);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Colors.white70),
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _gold),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: child,
    );
  }

  Widget _chefTab() {
    return Form(
      key: _chefFormKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Şef Kaydı',
                  style: TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _sectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Premium Şef Profili',
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Headline, uzmanlıklar, metrikler ve profil görsellerini düzenlemek için admin ekranını aç.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChefProfileAdminPage(
                                  chefId: widget.chefId,
                                ),
                              ),
                            );
                          },
                          child: const Text('Şef Profili (Premium) Aç'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _chefNameController,
                  label: 'Şef Adı',
                  hint: 'Şef Elif Nur',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Şef adı zorunlu'
                      : null,
                ),
                _field(
                  controller: _chefIdController,
                  label: 'chefId',
                  hint: 'Boş bırakırsan otomatik üretilir',
                ),
                _field(
                  controller: _bioController,
                  label: 'Biyografi',
                  maxLines: 3,
                ),
                _field(
                  controller: _expertiseController,
                  label: 'Uzmanlık',
                  hint: 'Pastacılık & Eğitim',
                ),
                _field(
                  controller: _cityController,
                  label: 'Şehir',
                  hint: 'Ankara',
                ),
                _field(
                  controller: _districtController,
                  label: 'İlçe',
                  hint: 'Çankaya',
                ),
                _field(
                  controller: _ratingController,
                  label: 'Puan',
                  hint: '5.0',
                ),
                _field(
                  controller: _profileImageController,
                  label: 'Profil Görsel URL',
                ),
                _field(
                  controller: _galleryController,
                  label: 'Galeri URL Listesi',
                  hint: 'Her satıra 1 URL',
                  maxLines: 4,
                ),
                SwitchListTile(
                  value: _academyEnabled,
                  onChanged: (v) => setState(() => _academyEnabled = v),
                  activeColor: _gold,
                  title: const Text(
                    'Akademi Aktif',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SwitchListTile(
                  value: _consultingEnabled,
                  onChanged: (v) => setState(() => _consultingEnabled = v),
                  activeColor: _gold,
                  title: const Text(
                    'Danışmanlık Aktif',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SwitchListTile(
                  value: _privateDiningEnabled,
                  onChanged: (v) => setState(() => _privateDiningEnabled = v),
                  activeColor: _gold,
                  title: const Text(
                    'Private Dining Aktif',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SwitchListTile(
                  value: _isPremium,
                  onChanged: (v) => setState(() => _isPremium = v),
                  activeColor: _gold,
                  title: const Text(
                    'Premium Profil',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingChef ? null : _saveChef,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _savingChef ? 'Kaydediliyor...' : 'Şefi Kaydet',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonTab() {
    return Form(
      key: _lessonFormKey,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Akademi Dersi',
                  style: TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _lessonChefIdController,
                  label: 'chefId',
                  hint: 'chef_elif_nur',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'chefId zorunlu' : null,
                ),
                _field(
                  controller: _lessonTitleController,
                  label: 'Ders Başlığı',
                  hint: 'Modern Pastacılık Temelleri',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ders başlığı zorunlu'
                      : null,
                ),
                _field(
                  controller: _lessonDurationController,
                  label: 'Süre',
                  hint: '100 dk',
                ),
                _field(
                  controller: _lessonCategoryController,
                  label: 'Kategori',
                  hint: 'Pastacılık',
                ),
                _field(
                  controller: _lessonLevelController,
                  label: 'Seviye',
                  hint: 'Başlangıç',
                ),
                _field(
                  controller: _lessonPriceController,
                  label: 'Ücret',
                  hint: '329 TL',
                ),
                SwitchListTile(
                  value: _lessonLocked,
                  onChanged: (v) => setState(() => _lessonLocked = v),
                  activeColor: _gold,
                  title: const Text(
                    'Ders Kilitli',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingLesson ? null : _saveLesson,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      _savingLesson ? 'Kaydediliyor...' : 'Dersi Kaydet',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
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
        backgroundColor: _bg,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'USTA ŞEF ADMİN',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _gold,
          labelColor: _gold,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Şef'),
            Tab(text: 'Ders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _chefTab(),
          _lessonTab(),
        ],
      ),
    );
  }
}

class SefTemizlikPaneli extends StatefulWidget {
  const SefTemizlikPaneli({super.key});

  @override
  State<SefTemizlikPaneli> createState() => _SefTemizlikPaneliState();
}

class _SefTemizlikPaneliState extends State<SefTemizlikPaneli> {
  bool loading = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> hataliDocs = [];

  Future<void> hataliSefleriGetir() async {
    setState(() => loading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('urunler')
        .where('tip', isEqualTo: 'Usta Sefler')
        .get();

    final docs = snapshot.docs;

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered = [];

    for (var doc in docs) {
      final data = doc.data();
      final ownerId = (data['ownerId'] ?? '').toString().trim();

      if (ownerId.isEmpty) {
        filtered.add(doc);
        continue;
      }

      final profile = await FirebaseFirestore.instance
          .collection('chef_profiles')
          .doc(ownerId)
          .get();

      if (!profile.exists) {
        filtered.add(doc);
      }
    }

    setState(() {
      hataliDocs = filtered;
      loading = false;
    });
  }

  Future<void> topluPasifYap() async {
    setState(() => loading = true);

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in hataliDocs) {
      batch.update(doc.reference, {'isActive': false});
    }

    await batch.commit();

    setState(() {
      loading = false;
      hataliDocs.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm hatalı şefler pasife alındı')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ŞEF TEMİZLİK PANELİ",
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: hataliSefleriGetir,
                child: const Text("Hatalı Şefleri Tara"),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: hataliDocs.isEmpty ? null : topluPasifYap,
                child: const Text("Toplu Pasife Al"),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading) const Center(child: CircularProgressIndicator()),
          if (!loading)
            Text(
              "Bulunan hatalı şef: ${hataliDocs.length}",
              style: const TextStyle(color: Colors.white70),
            ),
          const SizedBox(height: 10),
          if (!loading)
            ...hataliDocs.map((doc) {
              final data = doc.data();
              final ad = data['dukkan'] ?? 'İsimsiz';

              return ListTile(
                title: Text(ad, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  doc.id,
                  style: const TextStyle(color: Colors.white38),
                ),
              );
            }),
        ],
      ),
    );
  }
}
