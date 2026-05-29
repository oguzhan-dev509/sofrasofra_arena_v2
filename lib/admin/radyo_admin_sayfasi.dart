import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RadyoAdminSayfasi extends StatefulWidget {
  const RadyoAdminSayfasi({super.key});

  @override
  State<RadyoAdminSayfasi> createState() => _RadyoAdminSayfasiState();
}

class _RadyoAdminSayfasiState extends State<RadyoAdminSayfasi> {
  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _orderCtrl = TextEditingController();

  String _selectedKategori = 'genel';

  static const List<_RadioAdminCategory> _categories = [
    _RadioAdminCategory(label: 'Genel Yayın', value: 'genel'),
    _RadioAdminCategory(label: 'Ev Lezzetleri', value: 'ev_lezzetleri'),
    _RadioAdminCategory(label: 'Usta Şefler', value: 'usta_sefler'),
    _RadioAdminCategory(label: 'Restoranlar', value: 'restoranlar'),
    _RadioAdminCategory(label: 'Kurye', value: 'kurye'),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _orderCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final title = _titleCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    final order = int.tryParse(_orderCtrl.text.trim()) ?? 999;

    if (title.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Başlık ve Audio URL zorunludur.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('radyo_yayinlari').add({
      'title': title,
      'audioUrl': url,
      'kategori': _selectedKategori,
      'order': order,
      'aktifMi': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _titleCtrl.clear();
    _urlCtrl.clear();
    _orderCtrl.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Radyo yayını eklendi.'),
        backgroundColor: Color(0xFF12351F),
      ),
    );
  }

  Future<void> _toggleActive(String id, bool current) async {
    await FirebaseFirestore.instance
        .collection('radyo_yayinlari')
        .doc(id)
        .update({'aktifMi': !current});
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance
        .collection('radyo_yayinlari')
        .doc(id)
        .delete();
  }

  String _categoryLabel(String value) {
    for (final category in _categories) {
      if (category.value == value) {
        return category.label;
      }
    }

    return value.trim().isEmpty ? 'Genel Yayın' : value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text(
          'Radyo Yönetimi',
          style: TextStyle(color: _gold, fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x22FFB300)),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Başlık',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Audio URL',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedKategori,
                    dropdownColor: _card,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Kategori',
                      hintStyle: TextStyle(color: Colors.white54),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _orderCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Sıra (order)',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yayın Ekle'),
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
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('radyo_yayinlari')
                  .orderBy('order')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Henüz radyo yayını yok.',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();

                    final title = (data['title'] ?? '').toString();
                    final aktif = data['aktifMi'] == true;
                    final order = data['order'] ?? 0;
                    final kategori = (data['kategori'] ?? 'genel').toString();

                    return Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: ListTile(
                        title: Text(
                          '$order - $title',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          _categoryLabel(kategori),
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: aktif,
                              activeColor: _gold,
                              onChanged: (_) => _toggleActive(doc.id, aktif),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _delete(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioAdminCategory {
  final String label;
  final String value;

  const _RadioAdminCategory({
    required this.label,
    required this.value,
  });
}
