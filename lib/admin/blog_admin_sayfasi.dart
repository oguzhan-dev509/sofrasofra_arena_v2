import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BlogAdminSayfasi extends StatefulWidget {
  const BlogAdminSayfasi({super.key});

  @override
  State<BlogAdminSayfasi> createState() => _BlogAdminSayfasiState();
}

class _BlogAdminSayfasiState extends State<BlogAdminSayfasi> {
  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  final _titleCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();

  String _selectedKategori = 'genel';
  bool _featured = false;
  bool _saving = false;

  static const List<_BlogAdminCategory> _categories = [
    _BlogAdminCategory(label: 'Genel', value: 'genel'),
    _BlogAdminCategory(label: 'Ev Lezzetleri', value: 'ev_lezzetleri'),
    _BlogAdminCategory(label: 'Usta Şefler', value: 'usta_sefler'),
    _BlogAdminCategory(label: 'Restoranlar', value: 'restoranlar'),
    _BlogAdminCategory(label: 'Kurye', value: 'kurye'),
    _BlogAdminCategory(label: 'Teknik Rehber', value: 'teknik_rehber'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _slugCtrl.dispose();
    _summaryCtrl.dispose();
    _contentCtrl.dispose();
    _coverCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  String _slugify(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String _categoryLabel(String value) {
    for (final category in _categories) {
      if (category.value == value) return category.label;
    }

    return value.trim().isEmpty ? 'Genel' : value;
  }

  Future<void> _addPost() async {
    final title = _titleCtrl.text.trim();
    final summary = _summaryCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    final coverImage = _coverCtrl.text.trim();
    final order = int.tryParse(_orderCtrl.text.trim()) ?? 999;
    final slugInput = _slugCtrl.text.trim();
    final slug = slugInput.isNotEmpty ? _slugify(slugInput) : _slugify(title);

    if (title.isEmpty || summary.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlık, özet ve içerik zorunludur.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçerli bir slug oluşturulamadı.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('blog_yazilari').add({
        'title': title,
        'slug': slug,
        'summary': summary,
        'content': content,
        'kategori': _selectedKategori,
        'coverImage': coverImage,
        'order': order,
        'aktifMi': true,
        'featured': _featured,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _titleCtrl.clear();
      _slugCtrl.clear();
      _summaryCtrl.clear();
      _contentCtrl.clear();
      _coverCtrl.clear();
      _orderCtrl.clear();

      setState(() {
        _selectedKategori = 'genel';
        _featured = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blog yazısı eklendi.'),
          backgroundColor: Color(0xFF12351F),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blog yazısı eklenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleActive(String id, bool current) async {
    await FirebaseFirestore.instance
        .collection('blog_yazilari')
        .doc(id)
        .update({
      'aktifMi': !current,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleFeatured(String id, bool current) async {
    await FirebaseFirestore.instance
        .collection('blog_yazilari')
        .doc(id)
        .update({
      'featured': !current,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deletePost(String id) async {
    await FirebaseFirestore.instance
        .collection('blog_yazilari')
        .doc(id)
        .delete();
  }

  Future<void> _openEditDialog(
    String id,
    Map<String, dynamic> data,
  ) async {
    final titleCtrl = TextEditingController(
      text: (data['title'] ?? '').toString(),
    );
    final slugCtrl = TextEditingController(
      text: (data['slug'] ?? '').toString(),
    );
    final summaryCtrl = TextEditingController(
      text: (data['summary'] ?? '').toString(),
    );
    final contentCtrl = TextEditingController(
      text: (data['content'] ?? '').toString(),
    );
    final coverCtrl = TextEditingController(
      text: (data['coverImage'] ?? '').toString(),
    );
    final orderCtrl = TextEditingController(
      text: (data['order'] ?? 999).toString(),
    );

    var selectedKategori = (data['kategori'] ?? 'genel').toString();
    var featured = data['featured'] == true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _card,
              title: const Text(
                'Blog Yazısını Düzenle',
                style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _AdminTextField(
                        controller: titleCtrl,
                        label: 'Başlık',
                      ),
                      _AdminTextField(
                        controller: slugCtrl,
                        label: 'Slug',
                      ),
                      DropdownButtonFormField<String>(
                        value: _categories.any((category) =>
                                category.value == selectedKategori)
                            ? selectedKategori
                            : 'genel',
                        dropdownColor: _card,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        items: _categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category.value,
                                child: Text(category.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() {
                            selectedKategori = value;
                          });
                        },
                      ),
                      _AdminTextField(
                        controller: summaryCtrl,
                        label: 'Özet',
                        maxLines: 3,
                      ),
                      _AdminTextField(
                        controller: contentCtrl,
                        label: 'İçerik',
                        maxLines: 8,
                      ),
                      _AdminTextField(
                        controller: coverCtrl,
                        label: 'Kapak Görsel URL',
                      ),
                      _AdminTextField(
                        controller: orderCtrl,
                        label: 'Sıra / Order',
                        keyboardType: TextInputType.number,
                      ),
                      SwitchListTile(
                        value: featured,
                        activeColor: _gold,
                        title: const Text(
                          'Öne çıkar',
                          style: TextStyle(color: Colors.white),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            featured = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    final title = titleCtrl.text.trim();
                    final summary = summaryCtrl.text.trim();
                    final content = contentCtrl.text.trim();
                    final slugInput = slugCtrl.text.trim();
                    final slug = slugInput.isNotEmpty
                        ? _slugify(slugInput)
                        : _slugify(title);

                    if (title.isEmpty || summary.isEmpty || content.isEmpty) {
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('blog_yazilari')
                        .doc(id)
                        .update({
                      'title': title,
                      'slug': slug,
                      'summary': summary,
                      'content': content,
                      'kategori': selectedKategori,
                      'coverImage': coverCtrl.text.trim(),
                      'order': int.tryParse(orderCtrl.text.trim()) ?? 999,
                      'featured': featured,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    titleCtrl.dispose();
    slugCtrl.dispose();
    summaryCtrl.dispose();
    contentCtrl.dispose();
    coverCtrl.dispose();
    orderCtrl.dispose();
  }

  Widget _addForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFB300)),
      ),
      child: Column(
        children: [
          _AdminTextField(
            controller: _titleCtrl,
            label: 'Başlık',
          ),
          _AdminTextField(
            controller: _slugCtrl,
            label: 'Slug (boşsa başlıktan otomatik oluşur)',
          ),
          DropdownButtonFormField<String>(
            value: _selectedKategori,
            dropdownColor: _card,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Kategori',
              labelStyle: TextStyle(color: Colors.white70),
            ),
            items: _categories
                .map(
                  (category) => DropdownMenuItem<String>(
                    value: category.value,
                    child: Text(category.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedKategori = value;
              });
            },
          ),
          _AdminTextField(
            controller: _summaryCtrl,
            label: 'Özet',
            maxLines: 3,
          ),
          _AdminTextField(
            controller: _contentCtrl,
            label: 'İçerik',
            maxLines: 7,
          ),
          _AdminTextField(
            controller: _coverCtrl,
            label: 'Kapak Görsel URL',
          ),
          _AdminTextField(
            controller: _orderCtrl,
            label: 'Sıra / Order',
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            value: _featured,
            activeColor: _gold,
            title: const Text(
              'Öne çıkar',
              style: TextStyle(color: Colors.white),
            ),
            onChanged: (value) {
              setState(() {
                _featured = value;
              });
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _addPost,
              icon: const Icon(Icons.add_rounded),
              label: Text(_saving ? 'Kaydediliyor...' : 'Blog Yazısı Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _postList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('blog_yazilari')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white10),
            ),
            child: const Text(
              'Henüz blog yazısı yok. Müşteri sayfasında örnek yazılar gösteriliyor.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final title = (data['title'] ?? '').toString();
            final kategori = (data['kategori'] ?? 'genel').toString();
            final order = data['order'] ?? 999;
            final aktif = data['aktifMi'] != false;
            final featured = data['featured'] == true;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: ListTile(
                title: Text(
                  '$order - $title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  '${_categoryLabel(kategori)}${featured ? ' • Öne Çıkan' : ''}',
                  style: TextStyle(
                    color: featured ? _gold : Colors.white54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Switch(
                      value: aktif,
                      activeColor: _gold,
                      onChanged: (_) => _toggleActive(doc.id, aktif),
                    ),
                    IconButton(
                      tooltip: featured ? 'Öne çıkarmayı kaldır' : 'Öne çıkar',
                      icon: Icon(
                        featured
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: _gold,
                      ),
                      onPressed: () => _toggleFeatured(doc.id, featured),
                    ),
                    IconButton(
                      tooltip: 'Düzenle',
                      icon:
                          const Icon(Icons.edit_rounded, color: Colors.white70),
                      onPressed: () => _openEditDialog(doc.id, data),
                    ),
                    IconButton(
                      tooltip: 'Sil',
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () => _deletePost(doc.id),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
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
          'Blog ve Rehber Yönetimi',
          style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Blog yazısı ekle',
            style: TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _addForm(),
          const SizedBox(height: 18),
          const Text(
            'Yayınlanan / taslak yazılar',
            style: TextStyle(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _postList(),
        ],
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final TextInputType? keyboardType;

  const _AdminTextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFFFB300)),
          ),
        ),
      ),
    );
  }
}

class _BlogAdminCategory {
  final String label;
  final String value;

  const _BlogAdminCategory({
    required this.label,
    required this.value,
  });
}
