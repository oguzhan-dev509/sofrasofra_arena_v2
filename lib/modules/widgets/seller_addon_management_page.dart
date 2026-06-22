import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SellerAddonManagementPage extends StatelessWidget {
  const SellerAddonManagementPage({
    super.key,
    required this.sellerId,
    this.title = 'Yan Ürünler Yönetimi',
  });

  final String sellerId;
  final String title;
  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF070707);
  static const Color _card = Color(0xFF141414);

  CollectionReference<Map<String, dynamic>> get _addonRef =>
      FirebaseFirestore.instance
          .collection('sellers')
          .doc(sellerId)
          .collection('addon_items');

  static const List<String> _categories = [
    'İçecekler',
    'Tatlılar',
    'Ekstra',
  ];

  static const List<Map<String, String>> _stockStatuses = [
    {'value': 'in_stock', 'label': 'Stokta'},
    {'value': 'sold_out', 'label': 'Stok tükendi'},
    {'value': 'temporarily_off', 'label': 'Geçici pasif'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _addonRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessageBox(
              icon: Icons.error_outline_rounded,
              title: 'Yan ürünler okunamadı',
              message: '${snapshot.error}',
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aOrder = _safeInt(a.data()['sortOrder'], 999);
              final bOrder = _safeInt(b.data()['sortOrder'], 999);
              return aOrder.compareTo(bOrder);
            });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(
                onAddDrink: () => _showAddonDialog(
                  context,
                  initialCategory: 'İçecekler',
                ),
                onAddDessert: () => _showAddonDialog(
                  context,
                  initialCategory: 'Tatlılar',
                ),
                onAddExtra: () => _showAddonDialog(
                  context,
                  initialCategory: 'Ekstra',
                ),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                const _MessageBox(
                  icon: Icons.local_dining_rounded,
                  title: 'Henüz yan ürün yok',
                  message:
                      'İçecek, tatlı veya ekstra ürün ekleyerek sepet ortalamasını artırabilirsiniz.',
                )
              else
                ...docs.map(
                  (doc) => _AddonCard(
                    doc: doc,
                    onEdit: () => _showAddonDialog(context, doc: doc),
                    onActiveChanged: (value) async {
                      await doc.reference.update({
                        'isActive': value,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    },
                    onStockChanged: (value) async {
                      if (value == null) return;

                      await doc.reference.update({
                        'stockStatus': value,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    },
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAddonDialog(
    BuildContext context, {
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
    String? initialCategory,
  }) async {
    final data = doc?.data() ?? <String, dynamic>{};

    final nameController = TextEditingController(
      text: (data['name'] ?? '').toString(),
    );
    final descriptionController = TextEditingController(
      text: (data['description'] ?? '').toString(),
    );
    final priceController = TextEditingController(
      text: data['price'] == null ? '' : data['price'].toString(),
    );
    final sortOrderController = TextEditingController(
      text: data['sortOrder'] == null ? '' : data['sortOrder'].toString(),
    );

    var category =
        (data['category'] ?? initialCategory ?? 'İçecekler').toString().trim();

    if (!_categories.contains(category)) {
      category = 'İçecekler';
    }

    var stockStatus = (data['stockStatus'] ?? 'in_stock').toString().trim();

    if (!_stockStatuses.any((item) => item['value'] == stockStatus)) {
      stockStatus = 'in_stock';
    }

    final isEditing = doc != null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: _card,
              title: Text(
                isEditing ? 'Yan Ürünü Düzenle' : 'Yeni Yan Ürün Ekle',
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogTextField(
                      controller: nameController,
                      label: 'Ürün adı',
                      hint: 'Ayran',
                    ),
                    const SizedBox(height: 12),
                    _dialogTextField(
                      controller: descriptionController,
                      label: 'Açıklama',
                      hint: 'Soğuk içecek',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _dialogTextField(
                      controller: priceController,
                      label: 'Fiyat',
                      hint: '15',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _dialogTextField(
                      controller: sortOrderController,
                      label: 'Sıralama',
                      hint: '1',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: _card,
                      decoration: _inputDecoration('Kategori'),
                      items: _categories
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(
                                item,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => category = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: stockStatus,
                      dropdownColor: _card,
                      decoration: _inputDecoration('Stok durumu'),
                      items: _stockStatuses
                          .map(
                            (item) => DropdownMenuItem(
                              value: item['value'],
                              child: Text(
                                item['label']!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => stockStatus = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Vazgeç'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Kaydet'),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final description = descriptionController.text.trim();
                    final price = num.tryParse(
                      priceController.text.trim().replaceAll(',', '.'),
                    );
                    final sortOrder = int.tryParse(
                      sortOrderController.text.trim(),
                    );

                    if (name.isEmpty || price == null || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Ürün adı ve geçerli fiyat zorunludur.'),
                        ),
                      );
                      return;
                    }

                    final docId = isEditing ? doc.id : _slugify(name);

                    final payload = <String, dynamic>{
                      'name': name,
                      'description': description,
                      'price': price,
                      'isActive': data['isActive'] ?? true,
                      'stockStatus': stockStatus,
                      'sortOrder': sortOrder ?? 999,
                      'category': category,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    if (!isEditing) {
                      payload['createdAt'] = FieldValue.serverTimestamp();
                    }

                    await _addonRef.doc(docId).set(
                          payload,
                          SetOptions(merge: true),
                        );

                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  static InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _gold),
      ),
    );
  }

  static Widget _dialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label).copyWith(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
      ),
    );
  }

  static int _safeInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static String _slugify(String value) {
    var text = value.trim().toLowerCase();

    text = text
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');

    text = text.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');
    text = text.replaceAll(RegExp(r'^_|_$'), '');

    if (text.isEmpty) {
      return 'yan_urun_${DateTime.now().millisecondsSinceEpoch}';
    }

    return text;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.onAddDrink,
    required this.onAddDessert,
    required this.onAddExtra,
  });

  final VoidCallback onAddDrink;
  final VoidCallback onAddDessert;
  final VoidCallback onAddExtra;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yan Ürünler / İçecekler / Tatlılar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sepet ortalamasını artırmak için içecek, tatlı ve ekstra ürünlerinizi buradan yönetin.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
                onPressed: onAddDrink,
                icon: const Icon(Icons.local_drink_rounded),
                label: const Text('İçecek ekle'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                ),
                onPressed: onAddDessert,
                icon: const Icon(Icons.cake_rounded),
                label: const Text('Tatlı ekle'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                ),
                onPressed: onAddExtra,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Ekstra ekle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddonCard extends StatelessWidget {
  const _AddonCard({
    required this.doc,
    required this.onEdit,
    required this.onActiveChanged,
    required this.onStockChanged,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onEdit;
  final ValueChanged<bool> onActiveChanged;
  final ValueChanged<String?> onStockChanged;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final data = doc.data();

    final name = (data['name'] ?? '').toString().trim();
    final description = (data['description'] ?? '').toString().trim();
    final category = (data['category'] ?? '').toString().trim();
    final price = data['price'];
    final isActive = data['isActive'] == true;
    final stockStatus = (data['stockStatus'] ?? 'in_stock').toString().trim();

    final priceText = price is num
        ? price % 1 == 0
            ? price.toStringAsFixed(0)
            : price.toStringAsFixed(2)
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? Colors.white12
              : Colors.redAccent.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _categoryIcon(category),
                color: _gold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name.isEmpty ? doc.id : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$priceText TL',
                style: const TextStyle(
                  color: _gold,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                tooltip: 'Düzenle',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          if (category.isNotEmpty || description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [
                if (category.isNotEmpty) category,
                if (description.isNotEmpty) description,
              ].join(' • '),
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SwitchListTile(
            value: isActive,
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _gold,
            title: const Text(
              'Aktif',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              isActive
                  ? 'Müşteri ekranında görünebilir.'
                  : 'Müşteri ekranında gizlenir.',
              style: const TextStyle(color: Colors.white54),
            ),
            onChanged: onActiveChanged,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _normalizeStockStatus(stockStatus),
            dropdownColor: const Color(0xFF141414),
            decoration: InputDecoration(
              labelText: 'Stok durumu',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _gold),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'in_stock',
                child: Text(
                  'Stokta',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DropdownMenuItem(
                value: 'sold_out',
                child: Text(
                  'Stok tükendi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DropdownMenuItem(
                value: 'temporarily_off',
                child: Text(
                  'Geçici pasif',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
            onChanged: onStockChanged,
          ),
        ],
      ),
    );
  }

  static String _normalizeStockStatus(String value) {
    if (value == 'sold_out' || value == 'temporarily_off') {
      return value;
    }

    return 'in_stock';
  }

  static IconData _categoryIcon(String category) {
    if (category == 'Tatlılar') return Icons.cake_rounded;
    if (category == 'Ekstra') return Icons.add_circle_outline_rounded;
    return Icons.local_drink_rounded;
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 38),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
