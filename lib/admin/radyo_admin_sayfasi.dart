import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _addItem() async {
    final title = _titleCtrl.text.trim();
    final url = _urlCtrl.text.trim();
    final order = int.tryParse(_orderCtrl.text.trim()) ?? 999;

    if (title.isEmpty || url.isEmpty) return;

    await FirebaseFirestore.instance.collection('radyo_yayinlari').add({
      'title': title,
      'audioUrl': url,
      'order': order,
      'aktifMi': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _titleCtrl.clear();
    _urlCtrl.clear();
    _orderCtrl.clear();
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
          // ➕ Yeni yayın ekleme
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Başlık',
                  ),
                ),
                TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Audio URL',
                  ),
                ),
                TextField(
                  controller: _orderCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Sıra (order)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addItem,
                  child: const Text('Yayın Ekle'),
                ),
              ],
            ),
          ),

          // 📻 Liste
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

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data();

                    final title = data['title'] ?? '';
                    final aktif = data['aktifMi'] ?? false;
                    final order = data['order'] ?? 0;

                    return ListTile(
                      tileColor: _card,
                      title: Text(
                        '$order - $title',
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: aktif,
                            onChanged: (_) => _toggleActive(doc.id, aktif),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.redAccent),
                            onPressed: () => _delete(doc.id),
                          ),
                        ],
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
