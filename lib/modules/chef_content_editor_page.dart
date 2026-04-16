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
  static const gold = Color(0xFFFFB300);

  final _heroTaglineController = TextEditingController();
  final _heroDescriptionController = TextEditingController();

  final _summaryController = TextEditingController();
  final _highlightsController = TextEditingController();
  final _expertiseController = TextEditingController();

  final _timeline2024TitleController = TextEditingController();
  final _timeline2024SubtitleController = TextEditingController();
  final _timeline2021TitleController = TextEditingController();
  final _timeline2021SubtitleController = TextEditingController();
  final _timeline2018TitleController = TextEditingController();
  final _timeline2018SubtitleController = TextEditingController();
  final _timeline2013TitleController = TextEditingController();
  final _timeline2013SubtitleController = TextEditingController();

  final _awardsPressTextController = TextEditingController();
  final _brandCollaborationsTextController = TextEditingController();
  final _workshopStageTextController = TextEditingController();
  final _mediaKitTextController = TextEditingController();

  final _serviceConsultingController = TextEditingController();
  final _servicePrivateDiningController = TextEditingController();
  final _serviceWorkshopController = TextEditingController();
  final _serviceCateringController = TextEditingController();
  final _serviceSpeakingController = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _heroTaglineController.dispose();
    _heroDescriptionController.dispose();
    _summaryController.dispose();
    _highlightsController.dispose();
    _expertiseController.dispose();

    _timeline2024TitleController.dispose();
    _timeline2024SubtitleController.dispose();
    _timeline2021TitleController.dispose();
    _timeline2021SubtitleController.dispose();
    _timeline2018TitleController.dispose();
    _timeline2018SubtitleController.dispose();
    _timeline2013TitleController.dispose();
    _timeline2013SubtitleController.dispose();

    _awardsPressTextController.dispose();
    _brandCollaborationsTextController.dispose();
    _workshopStageTextController.dispose();
    _mediaKitTextController.dispose();

    _serviceConsultingController.dispose();
    _servicePrivateDiningController.dispose();
    _serviceWorkshopController.dispose();
    _serviceCateringController.dispose();
    _serviceSpeakingController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('chef_profiles')
        .doc(widget.chefId)
        .get();

    final data = doc.data();

    if (data != null) {
      _heroTaglineController.text = data['heroTagline'] ?? '';
      _heroDescriptionController.text = data['heroDescription'] ?? '';

      _summaryController.text = data['careerSummary'] ?? '';
      _highlightsController.text =
          (data['careerHighlights'] as List?)?.join(', ') ?? '';
      _expertiseController.text =
          (data['expertise'] as List?)?.join(', ') ?? '';

      _timeline2024TitleController.text = data['timeline2024Title'] ?? '';
      _timeline2024SubtitleController.text = data['timeline2024Subtitle'] ?? '';
      _timeline2021TitleController.text = data['timeline2021Title'] ?? '';
      _timeline2021SubtitleController.text = data['timeline2021Subtitle'] ?? '';
      _timeline2018TitleController.text = data['timeline2018Title'] ?? '';
      _timeline2018SubtitleController.text = data['timeline2018Subtitle'] ?? '';
      _timeline2013TitleController.text = data['timeline2013Title'] ?? '';
      _timeline2013SubtitleController.text = data['timeline2013Subtitle'] ?? '';

      _awardsPressTextController.text = data['awardsPressText'] ?? '';
      _brandCollaborationsTextController.text =
          data['brandCollaborationsText'] ?? '';
      _workshopStageTextController.text = data['workshopStageText'] ?? '';
      _mediaKitTextController.text = data['mediaKitText'] ?? '';

      _serviceConsultingController.text = data['serviceConsultingText'] ?? '';
      _servicePrivateDiningController.text =
          data['servicePrivateDiningText'] ?? '';
      _serviceWorkshopController.text = data['serviceWorkshopText'] ?? '';
      _serviceCateringController.text = data['serviceCateringText'] ?? '';
      _serviceSpeakingController.text = data['serviceSpeakingText'] ?? '';
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  List<String> _splitList(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    setState(() => isSaving = true);

    await FirebaseFirestore.instance
        .collection('chef_profiles')
        .doc(widget.chefId)
        .set({
      'heroTagline': _heroTaglineController.text.trim(),
      'heroDescription': _heroDescriptionController.text.trim(),
      'careerSummary': _summaryController.text.trim(),
      'careerHighlights': _splitList(_highlightsController.text),
      'expertise': _splitList(_expertiseController.text),
      'timeline2024Title': _timeline2024TitleController.text.trim(),
      'timeline2024Subtitle': _timeline2024SubtitleController.text.trim(),
      'timeline2021Title': _timeline2021TitleController.text.trim(),
      'timeline2021Subtitle': _timeline2021SubtitleController.text.trim(),
      'timeline2018Title': _timeline2018TitleController.text.trim(),
      'timeline2018Subtitle': _timeline2018SubtitleController.text.trim(),
      'timeline2013Title': _timeline2013TitleController.text.trim(),
      'timeline2013Subtitle': _timeline2013SubtitleController.text.trim(),
      'awardsPressText': _awardsPressTextController.text.trim(),
      'brandCollaborationsText': _brandCollaborationsTextController.text.trim(),
      'workshopStageText': _workshopStageTextController.text.trim(),
      'mediaKitText': _mediaKitTextController.text.trim(),
      'serviceConsultingText': _serviceConsultingController.text.trim(),
      'servicePrivateDiningText': _servicePrivateDiningController.text.trim(),
      'serviceWorkshopText': _serviceWorkshopController.text.trim(),
      'serviceCateringText': _serviceCateringController.text.trim(),
      'serviceSpeakingText': _serviceSpeakingController.text.trim(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kaydedildi')),
    );

    Navigator.pop(context);
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: gold,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _field(
    String title,
    TextEditingController controller, {
    int maxLines = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: title,
          labelStyle: const TextStyle(color: gold),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: gold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF050505),
        body: Center(child: CircularProgressIndicator(color: gold)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'İÇERİK DÜZENLE',
          style: TextStyle(color: gold, fontSize: 13),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _sectionTitle('Hero Alanı'),
            _field('Hero Tagline', _heroTaglineController),
            _field('Hero Açıklaması', _heroDescriptionController, maxLines: 4),
            _sectionTitle('Kariyer Özeti'),
            _field('Kariyer Özeti', _summaryController, maxLines: 8),
            _field('Highlight (virgül ile)', _highlightsController),
            _field('Uzmanlık (virgül ile)', _expertiseController, maxLines: 3),
            _sectionTitle('Kariyer Timeline'),
            _field('2024 Başlık', _timeline2024TitleController),
            _field('2024 Açıklama', _timeline2024SubtitleController,
                maxLines: 4),
            _field('2021 Başlık', _timeline2021TitleController),
            _field('2021 Açıklama', _timeline2021SubtitleController,
                maxLines: 4),
            _field('2018 Başlık', _timeline2018TitleController),
            _field('2018 Açıklama', _timeline2018SubtitleController,
                maxLines: 4),
            _field('2013 Başlık', _timeline2013TitleController),
            _field('2013 Açıklama', _timeline2013SubtitleController,
                maxLines: 4),
            _sectionTitle('Diğer Bölümler'),
            _field('Ödüller & Basın Metni', _awardsPressTextController,
                maxLines: 5),
            _field(
                'Marka İş Birlikleri Metni', _brandCollaborationsTextController,
                maxLines: 5),
            _field('Workshop & Sahne Gücü Metni', _workshopStageTextController,
                maxLines: 5),
            _field('Medya Kiti Metni', _mediaKitTextController, maxLines: 5),
            _sectionTitle('Premium Hizmetler'),
            _field('Danışmanlık Metni', _serviceConsultingController,
                maxLines: 5),
            _field('Private Dining Metni', _servicePrivateDiningController,
                maxLines: 4),
            _field('Workshop & Eğitim Metni', _serviceWorkshopController,
                maxLines: 4),
            _field(
                'Kurumsal Davet & Catering Metni', _serviceCateringController,
                maxLines: 4),
            _field('Konuşmacılık / Sahne Metni', _serviceSpeakingController,
                maxLines: 4),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                isSaving ? 'Kaydediliyor...' : 'Kaydet',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
