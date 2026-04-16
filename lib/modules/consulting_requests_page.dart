import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ConsultingStatus {
  pending,
  inReview,
  contacted,
  completed,
}

class ConsultingRequestsPage extends StatefulWidget {
  final String chefId;
  final String chefName;
  final bool isAdmin;

  const ConsultingRequestsPage({
    super.key,
    required this.chefId,
    required this.chefName,
    this.isAdmin = false,
  });

  @override
  State<ConsultingRequestsPage> createState() => _ConsultingRequestsPageState();
}

class _ConsultingRequestsPageState extends State<ConsultingRequestsPage> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _targetDateController = TextEditingController();

  String _selectedType = 'menu_consulting';
  String _selectedBusinessType = 'restaurant';

  bool _submitting = false;
  bool _showSuccessMessage = false;

  static const Map<String, String> _businessTypeLabels = {
    'restaurant': 'Restoran',
    'cafe': 'Kafe',
    'home_producer': 'Ev Üretici',
    'boutique_kitchen': 'Butik Mutfak',
    'new_venture': 'Yeni Girişim',
  };

  static const Map<String, String> _typeLabels = {
    'menu_consulting': 'Menü Danışmanlığı',
    'kitchen_setup': 'Mutfak Kurulum',
    'operational_review': 'Operasyon İncelemesi',
    'brand_positioning': 'Marka Konumlandırma',
    'training_program': 'Eğitim Programı',
  };

  static const Map<String, String> _statusLabels = {
    'pending': 'Beklemede',
    'in_review': 'İnceleniyor',
    'contacted': 'İletişime Geçildi',
    'completed': 'Tamamlandı',
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_review':
        return Colors.blue;
      case 'contacted':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('consulting_requests')
        .doc(docId)
        .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _budgetController.dispose();
    _detailsController.dispose();
    _targetDateController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    debugPrint('🟡 SUBMIT CLICKED');

    if (!_formKey.currentState!.validate()) {
      debugPrint('🔴 VALIDATION FAILED');
      return;
    }

    debugPrint('🟢 VALIDATION PASSED');

    setState(() => _submitting = true);

    try {
      final now = Timestamp.now();
      final budgetText = _budgetController.text.trim();
      final budget = int.tryParse(budgetText) ?? 0;

      debugPrint('📦 DATA PREPARED:');
      debugPrint('name     = ${_nameController.text}');
      debugPrint('phone    = ${_phoneController.text}');
      debugPrint('city     = ${_cityController.text}');
      debugPrint('district = ${_districtController.text}');
      debugPrint('target   = ${_targetDateController.text}');
      debugPrint('budget   = $budgetText → $budget');
      debugPrint('details  = ${_detailsController.text}');
      debugPrint('type     = $_selectedType');

      await FirebaseFirestore.instance.collection('consulting_requests').add({
        'chefId': widget.chefId,
        'chefName': widget.chefName,
        'userId': 'guest_user',
        'userName': _nameController.text.trim(),
        'type': _selectedType,
        'businessType': _selectedBusinessType,
        'businessTypeLabel': _businessTypeLabels[_selectedBusinessType],
        'status': 'pending',
        'budget': budget,
        'details': _detailsController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'targetDate': _targetDateController.text.trim(),
        'createdAt': now,
        'updatedAt': now,
        'isActive': true,
      });

      debugPrint('✅ FIRESTORE WRITE SUCCESS');

      if (!mounted) return;

      _nameController.clear();
      _phoneController.clear();
      _cityController.clear();
      _districtController.clear();
      _budgetController.clear();
      _detailsController.clear();
      _targetDateController.clear();

      setState(() {
        _selectedType = 'menu_consulting';
        _selectedBusinessType = 'restaurant';
        _showSuccessMessage = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Danışmanlık talebiniz alındı.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ FIRESTORE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Talep gönderilemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF171717),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: gold),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gold.withOpacity(0.14),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.support_agent_rounded, color: gold, size: 18),
              SizedBox(width: 8),
              Text(
                'DANIŞMANLIK & KURULUM',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.chefName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Menü danışmanlığı, mutfak kurulum, operasyon planı ve premium marka desteği için talep oluşturun.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ConsultingPill(label: 'Menü Danışmanlığı'),
              _ConsultingPill(label: 'Kurulum'),
              _ConsultingPill(label: 'Operasyon'),
              _ConsultingPill(label: 'Premium Hizmet'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TALEP FORMU',
              style: TextStyle(
                color: gold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedType,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Danışmanlık Türü',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF171717),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: gold),
                ),
              ),
              items: _typeLabels.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedBusinessType,
              dropdownColor: const Color(0xFF1A1A1A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'İşletme Tipi',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF171717),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: gold),
                ),
              ),
              items: _businessTypeLabels.entries
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedBusinessType = value;
                    _showSuccessMessage = false;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              'Ad Soyad',
              _nameController,
              hint: 'Adınızı yazın',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ad soyad zorunlu';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              'Telefon',
              _phoneController,
              hint: '05xx xxx xx xx',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon zorunlu';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'Şehir',
                    _cityController,
                    hint: 'İstanbul',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    'İlçe',
                    _districtController,
                    hint: 'Kadıköy',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildField(
              'Hedef Tarih',
              _targetDateController,
              hint: 'Örn: 15 Mayıs 2026 / 2026-05-15',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Hedef tarih girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              'Bütçe (TL)',
              _budgetController,
              hint: '15000',
              keyboardType: TextInputType.number,
              validator: (value) {
                final parsed = int.tryParse((value ?? '').trim());
                if (parsed == null || parsed <= 0) {
                  return 'Geçerli bütçe girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildField(
              'İhtiyaç Detayı',
              _detailsController,
              hint: 'Nasıl bir danışmanlık istediğinizi yazın',
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().length < 10) {
                  return 'Biraz daha detay yazın';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _submitting ? 'Gönderiliyor...' : 'Danışmanlık Talebi Gönder',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final status = (data['status'] ?? 'pending').toString();

    final userName = (data['userName'] ?? '-').toString();
    final phone = (data['phone'] ?? '-').toString();
    final city = (data['city'] ?? '').toString();
    final district = (data['district'] ?? '').toString();
    final details = (data['details'] ?? '').toString();
    final budget = data['budget'];
    final targetDate = (data['targetDate'] ?? '').toString();
    final type = _typeLabels[(data['type'] ?? '').toString()] ??
        (data['type'] ?? '-').toString();
    final businessType =
        _businessTypeLabels[(data['businessType'] ?? '').toString()] ??
            (data['businessTypeLabel'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _statusColor(status).withOpacity(0.45),
                  ),
                ),
                child: Text(
                  _statusLabels[status] ?? status,
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Hizmet: $type',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'İşletme Tipi: $businessType',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Telefon: $phone',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          if (city.isNotEmpty || district.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Konum: ${city.isEmpty ? '-' : city}${district.isEmpty ? '' : ' / $district'}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if (targetDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Hedef Tarih: $targetDate',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if (budget != null) ...[
            const SizedBox(height: 6),
            Text(
              'Bütçe: ₺$budget',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              details,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
          if (widget.isAdmin) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusLabels.entries.map((entry) {
                final isSelected = entry.key == status;
                return OutlinedButton(
                  onPressed: isSelected
                      ? null
                      : () => _updateStatus(doc.id, entry.key),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isSelected ? Colors.black : _statusColor(entry.key),
                    backgroundColor: isSelected
                        ? _statusColor(entry.key)
                        : Colors.transparent,
                    side: BorderSide(color: _statusColor(entry.key)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestsSection() {
    final query = FirebaseFirestore.instance
        .collection('consulting_requests')
        .where('chefId', isEqualTo: widget.chefId)
        .orderBy('createdAt', descending: true);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isAdmin ? 'GELEN TALEPLER' : 'SON TALEPLER',
            style: const TextStyle(
              color: gold,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'Talepler yüklenirken hata oluştu.',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(color: gold),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Text(
                  widget.isAdmin
                      ? 'Henüz gelen danışmanlık talebi yok.'
                      : 'Henüz görüntülenecek danışmanlık talebi yok.',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                );
              }

              return Column(
                children: docs.map(_buildRequestCard).toList(),
              );
            },
          ),
        ],
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
        title: Text(
          widget.isAdmin ? 'DANIŞMANLIK TALEPLERİ' : 'DANIŞMANLIK & KURULUM',
          style: const TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildPublicHeader(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  _buildServiceCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Menü Danışmanlığı',
                    subtitle:
                        'Ürün seçimi, fiyat dengesi, kârlı menü kurulumu ve mutfak kimliği.',
                  ),
                  const SizedBox(height: 12),
                  _buildServiceCard(
                    icon: Icons.storefront_rounded,
                    title: 'Mutfak Kurulum',
                    subtitle:
                        'Ekipman, istasyon yerleşimi, operasyon akışı ve açılış hazırlığı.',
                  ),
                  const SizedBox(height: 12),
                  _buildServiceCard(
                    icon: Icons.insights_rounded,
                    title: 'Operasyon İncelemesi',
                    subtitle:
                        'Mevcut sistem analizi, darboğaz tespiti ve verim artırma önerileri.',
                  ),
                  const SizedBox(height: 16),
                  if (!widget.isAdmin) _buildFormSection(),
                  if (!widget.isAdmin && _showSuccessMessage)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E3B33),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1F8A70),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Talebiniz alındı',
                            style: TextStyle(
                              color: Color(0xFF8EF0D0),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Danışmanlık talebiniz sisteme kaydedildi. Ön değerlendirme sonrası sizinle iletişime geçilecektir.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildRequestsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsultingPill extends StatelessWidget {
  final String label;

  const _ConsultingPill({
    required this.label,
  });

  static const Color gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
