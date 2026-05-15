import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SefAkademiDersEkleSayfasi extends StatefulWidget {
  final String chefId;
  final String chefName;

  const SefAkademiDersEkleSayfasi({
    super.key,
    required this.chefId,
    required this.chefName,
  });

  @override
  State<SefAkademiDersEkleSayfasi> createState() =>
      _SefAkademiDersEkleSayfasiState();
}

class _SefAkademiDersEkleSayfasiState extends State<SefAkademiDersEkleSayfasi> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _videoTitleController = TextEditingController();

  bool _saving = false;
  bool _isPreview = true;

  String _selectedCategorySlug = 'dunya-mutfagi';

  final List<_AcademyCategoryOption> _categories = const [
    _AcademyCategoryOption(
      slug: 'genel-turk-mutfagi',
      title: 'Genel Türk Mutfağı',
    ),
    _AcademyCategoryOption(
      slug: 'osmanli-mutfagi',
      title: 'Osmanlı Mutfağı',
    ),
    _AcademyCategoryOption(
      slug: 'dunya-mutfagi',
      title: 'Dünya Mutfağı',
    ),
    _AcademyCategoryOption(
      slug: 'tabak-tasarim',
      title: 'Tabak Tasarım',
    ),
    _AcademyCategoryOption(
      slug: 'pastacilik',
      title: 'Pastacılık',
    ),
    _AcademyCategoryOption(
      slug: 'maliyet-isletme',
      title: 'Maliyet & İşletme',
    ),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeController.dispose();
    _videoTitleController.dispose();
    super.dispose();
  }

  _AcademyCategoryOption get _selectedCategory {
    return _categories.firstWhere(
      (item) => item.slug == _selectedCategorySlug,
      orElse: () => _categories.first,
    );
  }

  bool _isYoutubeUrl(String value) {
    final t = value.trim().toLowerCase();
    return t.contains('youtube.com') || t.contains('youtu.be');
  }

  Future<void> _saveLesson() async {
    debugPrint('AKADEMI DERS SAVE BASILDI | saving=$_saving');

    if (_saving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt işlemi devam ediyor, lütfen bekleyin.'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    final form = _formKey.currentState;

    if (form == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Form hazırlanamadı. Sayfayı yenileyip tekrar deneyin.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!form.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen ders başlığı, açıklama ve geçerli YouTube linki alanlarını kontrol edin.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final videoUrl = _youtubeController.text.trim();
    final videoTitle = _videoTitleController.text.trim().isEmpty
        ? title
        : _videoTitleController.text.trim();

    if (!_isYoutubeUrl(videoUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir YouTube linki giriniz.'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();
      final category = _selectedCategory;
      debugPrint(
        'AKADEMI DERS FIRESTORE YAZILIYOR | chefId=${widget.chefId} | kategori=${category.slug}',
      );
      final lessonRef = await db.collection('dersler').add({
        'chefId': widget.chefId,
        'chefName': widget.chefName,
        'title': title,
        'baslik': title,
        'description': description,
        'aciklama': description,
        'categorySlug': category.slug,
        'category': category.title,
        'kategori': category.title,
        'categoryTitle': category.title,
        'videoCount': 1,
        'isActive': true,
        'isPublished': true,
        'isFree': _isPreview,
        'ucretsiz': _isPreview,
        'price': 0,
        'level': 'Başlangıç',
        'order': DateTime.now().millisecondsSinceEpoch,
        'createdAt': now,
        'updatedAt': now,
      });

      await lessonRef.collection('videos').add({
        'title': videoTitle,
        'videoUrl': videoUrl,
        'order': 1,
        'durationSeconds': 0,
        'isPreview': _isPreview,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${category.title} dersi eklendi.'),
          backgroundColor: Colors.black,
        ),
      );
      debugPrint('AKADEMI DERS KAYIT BASARILI | lessonId=${lessonRef.id}');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ders eklenemedi: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: gold, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.055),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: gold, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: gold, size: 20),
              SizedBox(width: 8),
              Text(
                'ŞEF AKADEMİSİ',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Ders başlığı, kategori ve YouTube linki ekleyerek şef akademi içeriklerinizi yayınlayın.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategorySlug,
              dropdownColor: const Color(0xFF1B1B1B),
              iconEnabledColor: gold,
              decoration: _inputDecoration(
                label: 'Kategori',
                icon: Icons.category_rounded,
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              items: _categories.map((item) {
                return DropdownMenuItem<String>(
                  value: item.slug,
                  child: Text(item.title),
                );
              }).toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedCategorySlug = value;
                      });
                    },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Ders Başlığı',
                icon: Icons.title_rounded,
                hint: 'Örn: Dünya Mutfağına Giriş',
              ),
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Ders başlığı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              minLines: 3,
              maxLines: 5,
              decoration: _inputDecoration(
                label: 'Açıklama',
                icon: Icons.description_rounded,
                hint: 'Ders içeriğini kısa ve anlaşılır yazın',
              ),
              validator: (value) {
                if (value == null || value.trim().length < 8) {
                  return 'Kısa bir açıklama giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _videoTitleController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                label: 'Video Başlığı',
                icon: Icons.play_lesson_rounded,
                hint: 'Boş kalırsa ders başlığı kullanılır',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _youtubeController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.url,
              decoration: _inputDecoration(
                label: 'YouTube Linki',
                icon: Icons.ondemand_video_rounded,
                hint: 'https://www.youtube.com/watch?v=...',
              ),
              validator: (value) {
                final url = value?.trim() ?? '';
                if (url.isEmpty) {
                  return 'YouTube linki gerekli';
                }
                if (!_isYoutubeUrl(url)) {
                  return 'Geçerli bir YouTube linki giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeColor: gold,
              title: const Text(
                'Ön izleme videosu olarak yayınla',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              subtitle: const Text(
                'Açık olursa ziyaretçi bu videoyu ücretsiz açabilir.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              value: _isPreview,
              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _isPreview = value;
                      });
                    },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveLesson,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save_rounded,
                        color: Colors.black,
                      ),
                label: Text(
                  _saving ? 'Kaydediliyor...' : 'Dersi / Videoyu Kaydet',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  disabledBackgroundColor: gold.withValues(alpha: 0.55),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'Ders / Video Ekle',
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildFormCard(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _AcademyCategoryOption {
  final String slug;
  final String title;

  const _AcademyCategoryOption({
    required this.slug,
    required this.title,
  });
}
