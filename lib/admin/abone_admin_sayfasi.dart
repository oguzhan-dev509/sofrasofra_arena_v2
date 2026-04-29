import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AboneAdminSayfasi extends StatefulWidget {
  const AboneAdminSayfasi({super.key});

  @override
  State<AboneAdminSayfasi> createState() => _AboneAdminSayfasiState();
}

class _AboneAdminSayfasiState extends State<AboneAdminSayfasi> {
  static const Color _bg = Color(0xFF0B0B0B);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _busy = false;

  CollectionReference<Map<String, dynamic>> get _subscribers =>
      FirebaseFirestore.instance.collection('subscribers');

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _cleanEmail(String value) {
    return value.trim().toLowerCase();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _addSubscriber() async {
    final email = _cleanEmail(_emailController.text);
    final name = _nameController.text.trim();

    if (!_isValidEmail(email)) {
      _showMessage('Geçerli bir e-posta gir.');
      return;
    }

    setState(() => _busy = true);

    try {
      final existing =
          await _subscribers.where('email', isEqualTo: email).limit(1).get();

      if (existing.docs.isNotEmpty) {
        _showMessage('Bu e-posta zaten kayıtlı.');
        return;
      }

      await _subscribers.add({
        'email': email,
        'name': name,
        'aktifMi': true,
        'source': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _emailController.clear();
      _nameController.clear();

      _showMessage('Abone eklendi.');
    } catch (e) {
      _showMessage('Abone eklenemedi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleActive({
    required String docId,
    required bool currentValue,
  }) async {
    try {
      await _subscribers.doc(docId).update({
        'aktifMi': !currentValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showMessage('Durum güncellenemedi: $e');
    }
  }

  Future<void> _deleteSubscriber(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Aboneyi sil?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bu işlem abone kaydını tamamen siler.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _subscribers.doc(docId).delete();
      _showMessage('Abone silindi.');
    } catch (e) {
      _showMessage('Silinemedi: $e');
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: const Color(0xFF222222),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Abone Admin',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAddPanel(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _subscribers
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Hata: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _gold),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Henüz abone yok.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();

                      final email = (data['email'] ?? '').toString();
                      final name = (data['name'] ?? '').toString();
                      final aktifMi = data['aktifMi'] == true;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x22FFFFFF)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  aktifMi ? _gold : const Color(0xFF333333),
                              child: Icon(
                                aktifMi
                                    ? Icons.mark_email_read_rounded
                                    : Icons.mark_email_unread_outlined,
                                color: aktifMi ? Colors.black : Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (name.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 5),
                                  Text(
                                    aktifMi ? 'Aktif abone' : 'Pasif abone',
                                    style: TextStyle(
                                      color: aktifMi ? _gold : Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: aktifMi ? 'Pasif yap' : 'Aktif yap',
                              onPressed: () => _toggleActive(
                                docId: doc.id,
                                currentValue: aktifMi,
                              ),
                              icon: Icon(
                                aktifMi
                                    ? Icons.toggle_on_rounded
                                    : Icons.toggle_off_rounded,
                                color: aktifMi ? _gold : Colors.white38,
                                size: 34,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Sil',
                              onPressed: () => _deleteSubscriber(doc.id),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
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
      ),
    );
  }

  Widget _buildAddPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x33FFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yeni Abone Ekle',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('E-posta'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Ad / Not opsiyonel'),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _addSubscriber,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(_busy ? 'Ekleniyor...' : 'Abone Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF0F0F0F),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x22FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _gold),
      ),
    );
  }
}
