import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sofrasofra_arena_v2/dev/academy_master_tools.dart';
import 'package:sofrasofra_arena_v2/dev/academy_demo_content_seed.dart';

class AcademyMasterRunnerPage extends StatefulWidget {
  const AcademyMasterRunnerPage({super.key});

  @override
  State<AcademyMasterRunnerPage> createState() =>
      _AcademyMasterRunnerPageState();
}

class _AcademyMasterRunnerPageState extends State<AcademyMasterRunnerPage> {
  static const Color _bg = Color(0xFF050505);
  static const Color _card = Color(0xFF121212);
  static const Color _gold = Color(0xFFFFB300);

  final TextEditingController _chefIdController =
      TextEditingController(text: 'gmRQ6eKx6WZ0fqDDFytHEgi88RH3');
  final TextEditingController _expertiseController =
      TextEditingController(text: 'Osmanlı, Fine Dining, Danışmanlık');
  final TextEditingController _academyCategoriesController =
      TextEditingController(text: 'osmanli, sunum, danismanlik');
  final TextEditingController _servicesController =
      TextEditingController(text: 'chef_table, catering, consulting');

  final TextEditingController _consultingChefIdController =
      TextEditingController(text: 'gmRQ6eKx6WZ0fqDDFytHEgi88RH3');
  final TextEditingController _consultingChefNameController =
      TextEditingController(text: 'Ahmet Usta');
  final TextEditingController _consultingUserIdController =
      TextEditingController(text: 'test_user_001');
  final TextEditingController _consultingUserNameController =
      TextEditingController(text: 'Mehmet');
  final TextEditingController _consultingTypeController =
      TextEditingController(text: 'menu_consulting');
  final TextEditingController _consultingBudgetController =
      TextEditingController(text: '15000');
  final TextEditingController _consultingDetailsController =
      TextEditingController(
    text: 'Yeni restoran açılışı için menü danışmanlığı talebi.',
  );
  final TextEditingController _consultingCityController =
      TextEditingController(text: 'İstanbul');
  final TextEditingController _consultingDistrictController =
      TextEditingController(text: 'Kadıköy');
  final TextEditingController _consultingPhoneController =
      TextEditingController(text: '');

  bool _busy = false;
  String _log = 'Hazır.';

  @override
  void dispose() {
    _chefIdController.dispose();
    _expertiseController.dispose();
    _academyCategoriesController.dispose();
    _servicesController.dispose();

    _consultingChefIdController.dispose();
    _consultingChefNameController.dispose();
    _consultingUserIdController.dispose();
    _consultingUserNameController.dispose();
    _consultingTypeController.dispose();
    _consultingBudgetController.dispose();
    _consultingDetailsController.dispose();
    _consultingCityController.dispose();
    _consultingDistrictController.dispose();
    _consultingPhoneController.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _runTask(
    String label,
    Future<void> Function() task,
  ) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _log = '$label başlatıldı...';
    });

    try {
      await task();
      if (!mounted) return;
      setState(() {
        _log = '$label tamamlandı.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label tamamlandı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _log = '$label hata verdi: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label hata verdi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  Future<void> _seedDemoAcademyContent() async {
    await AcademyDemoContentSeed.seedAll();
  }

  Future<void> _seedCategories() async {
    await AcademyMasterTools.seedAcademyCategories();
  }

  Future<void> _normalizeLessons() async {
    await AcademyMasterTools.normalizeLessons();
  }

  Future<void> _patchChefProfile() async {
    final chefId = _chefIdController.text.trim();
    if (chefId.isEmpty) {
      throw Exception('chefId boş olamaz.');
    }

    await AcademyMasterTools.patchChefProfileForAcademy(
      chefId: chefId,
      expertise: _splitCsv(_expertiseController.text),
      academyCategories: _splitCsv(_academyCategoriesController.text),
      services: _splitCsv(_servicesController.text),
    );
  }

  Future<void> _createConsultingRequest() async {
    final budget = int.tryParse(_consultingBudgetController.text.trim()) ?? 0;
    if (budget <= 0) {
      throw Exception('Bütçe geçersiz.');
    }

    final payload = AcademyMasterTools.buildConsultingRequestPayload(
      chefId: _consultingChefIdController.text.trim(),
      chefName: _consultingChefNameController.text.trim(),
      userId: _consultingUserIdController.text.trim(),
      userName: _consultingUserNameController.text.trim(),
      type: _consultingTypeController.text.trim(),
      budget: budget,
      details: _consultingDetailsController.text.trim(),
      city: _consultingCityController.text.trim(),
      district: _consultingDistrictController.text.trim(),
      phone: _consultingPhoneController.text.trim(),
    );

    await AcademyMasterTools.createConsultingRequest(payload: payload);
  }

  Future<void> _runAll() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _log = 'Toplu akademi kurulumu başlatıldı...';
    });

    try {
      setState(() => _log = '1/4 academy_categories seed ediliyor...');
      await AcademyMasterTools.seedAcademyCategories();

      setState(() => _log = '2/4 dersler normalize ediliyor...');
      await AcademyMasterTools.normalizeLessons();

      final chefId = _chefIdController.text.trim();
      if (chefId.isNotEmpty) {
        setState(() => _log = '3/4 chef_profiles patch atılıyor...');
        await AcademyMasterTools.patchChefProfileForAcademy(
          chefId: chefId,
          expertise: _splitCsv(_expertiseController.text),
          academyCategories: _splitCsv(_academyCategoriesController.text),
          services: _splitCsv(_servicesController.text),
        );
      }

      setState(() => _log = '4/4 test danışmanlık talebi oluşturuluyor...');
      final budget = int.tryParse(_consultingBudgetController.text.trim()) ?? 0;
      if (budget > 0) {
        final payload = AcademyMasterTools.buildConsultingRequestPayload(
          chefId: _consultingChefIdController.text.trim(),
          chefName: _consultingChefNameController.text.trim(),
          userId: _consultingUserIdController.text.trim(),
          userName: _consultingUserNameController.text.trim(),
          type: _consultingTypeController.text.trim(),
          budget: budget,
          details: _consultingDetailsController.text.trim(),
          city: _consultingCityController.text.trim(),
          district: _consultingDistrictController.text.trim(),
          phone: _consultingPhoneController.text.trim(),
        );
        await AcademyMasterTools.createConsultingRequest(payload: payload);
      }

      if (!mounted) return;
      setState(() {
        _log = 'Toplu akademi kurulumu başarıyla tamamlandı.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toplu akademi kurulumu tamamlandı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _log = 'Toplu akademi kurulumu hata verdi: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Toplu akademi kurulumu hata verdi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _busy = false;
      });
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF171717),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _gold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool primary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? _gold : const Color(0xFF1A1A1A),
          foregroundColor: primary ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: primary
                ? BorderSide.none
                : BorderSide(color: Colors.white.withOpacity(0.10)),
          ),
        ),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
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
          'AKADEMİ MASTER RUNNER',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      _gold.withOpacity(0.14),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'AKADEMİ FİNAL KURULUM PANELİ',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Seed, normalize, chef profile patch ve danışmanlık test talebi işlemlerini tek ekrandan yönetir.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '1. Academy Categories Seed',
                subtitle:
                    '8 ana kategori yapısını academy_categories koleksiyonuna yazar.',
                children: [
                  _buildActionButton(
                    label: 'academy_categories seed et',
                    icon: Icons.category_rounded,
                    onPressed: _busy
                        ? null
                        : () => _runTask(
                              'academy_categories seed',
                              _seedCategories,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '1B. Demo Academy Content Seed',
                subtitle:
                    '8 kategori, demo dersler, video alt koleksiyonları, chef profile patch ve örnek danışmanlık talebi oluşturur.',
                children: [
                  _buildActionButton(
                    label: 'demo akademi içeriğini doldur',
                    icon: Icons.auto_awesome_rounded,
                    onPressed: _busy
                        ? null
                        : () => _runTask(
                              'demo academy content seed',
                              _seedDemoAcademyContent,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '2. Dersler Normalize',
                subtitle:
                    'Mevcut dersleri yeni field standardına geçirir ve geri uyumu korur.',
                children: [
                  _buildActionButton(
                    label: 'dersleri normalize et',
                    icon: Icons.auto_fix_high_rounded,
                    onPressed: _busy
                        ? null
                        : () => _runTask(
                              'dersler normalize',
                              _normalizeLessons,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '3. Chef Profile Patch',
                subtitle:
                    'Seçili chef_profiles dokümanına akademi ve danışmanlık alanlarını ekler.',
                children: [
                  _buildTextField('Chef ID', _chefIdController),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Expertise (virgülle ayır)',
                    _expertiseController,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Academy Categories (virgülle ayır)',
                    _academyCategoriesController,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Services (virgülle ayır)',
                    _servicesController,
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    label: 'chef profile patch uygula',
                    icon: Icons.person_pin_circle_rounded,
                    onPressed: _busy
                        ? null
                        : () => _runTask(
                              'chef profile patch',
                              _patchChefProfile,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '4. Test Consulting Request',
                subtitle:
                    'consulting_requests içine örnek danışmanlık talebi oluşturur.',
                children: [
                  _buildTextField('Chef ID', _consultingChefIdController),
                  const SizedBox(height: 12),
                  _buildTextField('Chef Name', _consultingChefNameController),
                  const SizedBox(height: 12),
                  _buildTextField('User ID', _consultingUserIdController),
                  const SizedBox(height: 12),
                  _buildTextField('User Name', _consultingUserNameController),
                  const SizedBox(height: 12),
                  _buildTextField('Type', _consultingTypeController),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Budget',
                    _consultingBudgetController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    'Details',
                    _consultingDetailsController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField('City', _consultingCityController),
                  const SizedBox(height: 12),
                  _buildTextField('District', _consultingDistrictController),
                  const SizedBox(height: 12),
                  _buildTextField('Phone', _consultingPhoneController),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    label: 'test danışmanlık talebi oluştur',
                    icon: Icons.support_agent_rounded,
                    onPressed: _busy
                        ? null
                        : () => _runTask(
                              'consulting request create',
                              _createConsultingRequest,
                            ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: '5. Tek Tık Toplu Kurulum',
                subtitle:
                    'Seed + normalize + chef patch + test consulting işlemlerini sırayla çalıştırır.',
                children: [
                  _buildActionButton(
                    label: 'tüm akademi master kurulumu çalıştır',
                    icon: Icons.rocket_launch_rounded,
                    primary: true,
                    onPressed: _busy ? null : _runAll,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF101010),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'İŞLEM GÜNLÜĞÜ',
                      style: TextStyle(
                        color: _gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _log,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(color: _gold),
              ),
            ),
        ],
      ),
    );
  }
}
