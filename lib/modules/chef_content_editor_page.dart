import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChefContentEditorPage extends StatefulWidget {
  final String chefId;

  const ChefContentEditorPage({
    super.key,
    required this.chefId,
  });

  @override
  State<ChefContentEditorPage> createState() => _ChefContentEditorPageState();
}

class _ChefContentEditorPageState extends State<ChefContentEditorPage> {
  final _summaryController = TextEditingController();
  final _highlightsController = TextEditingController();
  final _expertiseController = TextEditingController();

  bool isLoading = true;

  static const gold = Color(0xFFFFB300);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('chef_profiles')
        .doc(widget.chefId)
        .get();

    final data = doc.data();

    if (data != null) {
      _summaryController.text = data['careerSummary'] ?? '';
      _highlightsController.text =
          (data['careerHighlights'] as List?)?.join(', ') ?? '';
      _expertiseController.text =
          (data['expertise'] as List?)?.join(', ') ?? '';
    }

    setState(() => isLoading = false);
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection('chef_profiles')
        .doc(widget.chefId)
        .set({
      'careerSummary': _summaryController.text,
      'careerHighlights':
          _highlightsController.text.split(',').map((e) => e.trim()).toList(),
      'expertise':
          _expertiseController.text.split(',').map((e) => e.trim()).toList(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kaydedildi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'İÇERİK DÜZENLE',
          style: TextStyle(color: gold, fontSize: 13),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _field('Kariyer Özeti', _summaryController),
            _field('Highlight (virgül ile)', _highlightsController),
            _field('Uzmanlık (virgül ile)', _expertiseController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
              ),
              child: const Text('Kaydet'),
            )
          ],
        ),
      ),
    );
  }

  Widget _field(String title, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: title == 'Kariyer Özeti' ? 5 : 2,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: title,
          labelStyle: const TextStyle(color: gold),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: gold),
          ),
        ),
      ),
    );
  }
}
