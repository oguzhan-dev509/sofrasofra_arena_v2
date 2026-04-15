import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/user_reservations_page.dart';

enum ReservationServiceType {
  chefsTable,
  corporateEvent,
  boutiqueCatering,
  privateInvitation,
  standard,
}

class CreateReservationPage extends StatefulWidget {
  const CreateReservationPage({
    super.key,
    this.chefId,
    this.chefName,
    this.tableTitle,
    this.concept,
    this.capacity,
    this.unitPrice,
  });

  final String? chefId;
  final String? chefName;
  final String? tableTitle;
  final String? concept;
  final String? capacity;
  final int? unitPrice;

  @override
  State<CreateReservationPage> createState() => _CreateReservationPageState();
}

class _CreateReservationPageState extends State<CreateReservationPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _guestCountController =
      TextEditingController(text: '2');
  final TextEditingController _noteController = TextEditingController();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _eventTypeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _serviceStyleController = TextEditingController();

  final TextEditingController _venueAddressController = TextEditingController();
  final TextEditingController _menuExpectationController =
      TextEditingController();
  final TextEditingController _serviceTypeController = TextEditingController();

  final TextEditingController _invitationConceptController =
      TextEditingController();
  final TextEditingController _occasionTypeController = TextEditingController();
  final TextEditingController _guestProfileController = TextEditingController();

  final TextEditingController _allergyNotesController = TextEditingController();
  final TextEditingController _seatingPreferenceController =
      TextEditingController();
  final TextEditingController _tastingPreferenceController =
      TextEditingController();

  bool _invoiceRequired = false;
  bool _equipmentNeeded = false;
  bool _isSpecialOccasion = false;

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _isSaving = false;

  static const Color _bg = Colors.black;
  static const Color _card = Color(0xFF141414);
  static const Color _cardSoft = Color(0xFF101010);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _goldSoft = Color(0xFFFFD54F);

  static const List<String> _timeSlots = [
    '18:00',
    '19:00',
    '20:00',
    '21:00',
  ];

  Map<String, dynamic> _routeArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      return args;
    }
    return <String, dynamic>{};
  }

  String? _resolveChefId(BuildContext context) {
    final args = _routeArgs(context);
    final value = widget.chefId ?? args['chefId'];
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _resolveChefName(BuildContext context) {
    final args = _routeArgs(context);
    final value = widget.chefName ?? args['chefName'] ?? 'Şef';
    return value.toString();
  }

  String _resolveTableTitle(BuildContext context) {
    final args = _routeArgs(context);
    final value = widget.tableTitle ??
        args['tableTitle'] ??
        '8 Kişilik Özel Şef Masası Deneyimi';
    return value.toString();
  }

  String _resolveConcept(BuildContext context) {
    final args = _routeArgs(context);
    final value = widget.concept ?? args['concept'] ?? 'Tadım Menüsü';
    return value.toString();
  }

  String _resolveCapacity(BuildContext context) {
    final args = _routeArgs(context);
    final value = widget.capacity ?? args['capacity'] ?? '8 Kişi';
    return value.toString();
  }

  int _resolveUnitPrice(BuildContext context) {
    final args = _routeArgs(context);
    final dynamic raw = widget.unitPrice ?? args['unitPrice'] ?? 1500;

    if (raw is int) return raw;
    if (raw is double) return raw.toInt();
    return int.tryParse(raw.toString()) ?? 1500;
  }

  ReservationServiceType _serviceType(BuildContext context) {
    final title = _resolveTableTitle(context).toLowerCase();
    final concept = _resolveConcept(context).toLowerCase();

    final source = '$title $concept';

    if (source.contains("chef's table") ||
        source.contains('chefs table') ||
        source.contains('şef masası')) {
      return ReservationServiceType.chefsTable;
    }
    if (source.contains('kurumsal')) {
      return ReservationServiceType.corporateEvent;
    }
    if (source.contains('catering')) {
      return ReservationServiceType.boutiqueCatering;
    }
    if (source.contains('özel davet') || source.contains('davet')) {
      return ReservationServiceType.privateInvitation;
    }
    return ReservationServiceType.standard;
  }

  String _serviceTypeName(BuildContext context) {
    switch (_serviceType(context)) {
      case ReservationServiceType.chefsTable:
        return 'chefs_table';
      case ReservationServiceType.corporateEvent:
        return 'corporate_event';
      case ReservationServiceType.boutiqueCatering:
        return 'boutique_catering';
      case ReservationServiceType.privateInvitation:
        return 'private_invitation';
      case ReservationServiceType.standard:
        return 'standard';
    }
  }

  String _pageHeadline(BuildContext context) {
    switch (_serviceType(context)) {
      case ReservationServiceType.corporateEvent:
        return 'Kurumsal Etkinlik Talebi';
      case ReservationServiceType.chefsTable:
        return "Chef's Table Rezervasyonu";
      case ReservationServiceType.boutiqueCatering:
        return 'Butik Catering Talebi';
      case ReservationServiceType.privateInvitation:
        return 'Özel Davet Rezervasyonu';
      case ReservationServiceType.standard:
        return 'Rezervasyon Oluştur';
    }
  }

  String _pageIntro(BuildContext context) {
    switch (_serviceType(context)) {
      case ReservationServiceType.corporateEvent:
        return 'Kurumsal organizasyonunuz için tarih, katılımcı bilgisi ve etkinlik detaylarını profesyonel biçimde planlayın.';
      case ReservationServiceType.chefsTable:
        return 'Premium şef deneyimi için tarih ve saat seçerek özel masanızı ayırtın.';
      case ReservationServiceType.boutiqueCatering:
        return 'Butik catering hizmeti için organizasyon kapsamını, servis yapısını ve operasyon detaylarını belirtin.';
      case ReservationServiceType.privateInvitation:
        return 'Özel davetiniz için konsept, misafir yapısı ve organizasyon beklentilerini paylaşın.';
      case ReservationServiceType.standard:
        return 'Tarih, saat ve katılımcı bilgileriyle rezervasyonunuzu oluşturun.';
    }
  }

  String _noteHint(BuildContext context) {
    switch (_serviceType(context)) {
      case ReservationServiceType.corporateEvent:
        return 'Ek operasyon notları, kurum talepleri veya servis beklentileri';
      case ReservationServiceType.chefsTable:
        return 'Alerji, özel gün, oturma tercihi veya ek notlar';
      case ReservationServiceType.boutiqueCatering:
        return 'Servis akışı, mutfak kurulumu, saha notları veya ek beklentiler';
      case ReservationServiceType.privateInvitation:
        return 'Davet akışı, stil beklentisi ve ek organizasyon notları';
      case ReservationServiceType.standard:
        return 'Notunuz';
    }
  }

  String _guestLabel(BuildContext context) {
    switch (_serviceType(context)) {
      case ReservationServiceType.corporateEvent:
        return 'Katılımcı sayısı';
      case ReservationServiceType.boutiqueCatering:
        return 'Servis verilecek kişi sayısı';
      default:
        return 'Kişi sayısı';
    }
  }

  String _capacityGuide(BuildContext context) {
    switch (_serviceType(context)) {
      case ReservationServiceType.corporateEvent:
        return 'Kurumsal etkinlikler için toplu katılım ve servis akışı ayrıca planlanabilir.';
      case ReservationServiceType.chefsTable:
        return 'Chef’s Table deneyimi sınırlı kontenjanla ve özel akışla sunulur.';
      case ReservationServiceType.boutiqueCatering:
        return 'Catering kapasitesi servis modeli, lokasyon ve ekip planına göre şekillenir.';
      case ReservationServiceType.privateInvitation:
        return 'Özel davet kapasitesi konsept, servis tarzı ve alan kullanımına göre planlanır.';
      case ReservationServiceType.standard:
        return 'Kapasite detayları rezervasyon tipine göre değişebilir.';
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (_serviceType(context)) {
        case ReservationServiceType.corporateEvent:
          _guestCountController.text = '20';
          break;
        case ReservationServiceType.chefsTable:
          _guestCountController.text = '2';
          break;
        case ReservationServiceType.boutiqueCatering:
          _guestCountController.text = '30';
          break;
        case ReservationServiceType.privateInvitation:
          _guestCountController.text = '6';
          break;
        case ReservationServiceType.standard:
          _guestCountController.text = '2';
          break;
      }

      setState(() {});
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
      );
      _selectedTimeSlot ??= _timeSlots.first;
    });
  }

  bool _validateServiceSpecificFields() {
    switch (_serviceType(context)) {
      case ReservationServiceType.corporateEvent:
        return _companyNameController.text.trim().isNotEmpty &&
            _eventTypeController.text.trim().isNotEmpty &&
            _locationController.text.trim().isNotEmpty;

      case ReservationServiceType.boutiqueCatering:
        return _venueAddressController.text.trim().isNotEmpty &&
            _serviceTypeController.text.trim().isNotEmpty;

      case ReservationServiceType.privateInvitation:
        return _invitationConceptController.text.trim().isNotEmpty &&
            _occasionTypeController.text.trim().isNotEmpty;

      case ReservationServiceType.chefsTable:
      case ReservationServiceType.standard:
        return true;
    }
  }

  Map<String, dynamic> _buildServiceDetailsMap() {
    switch (_serviceType(context)) {
      case ReservationServiceType.corporateEvent:
        return {
          'companyName': _companyNameController.text.trim(),
          'eventType': _eventTypeController.text.trim(),
          'location': _locationController.text.trim(),
          'serviceStyle': _serviceStyleController.text.trim(),
          'invoiceRequired': _invoiceRequired,
        };

      case ReservationServiceType.boutiqueCatering:
        return {
          'venueAddress': _venueAddressController.text.trim(),
          'serviceType': _serviceTypeController.text.trim(),
          'menuExpectation': _menuExpectationController.text.trim(),
          'equipmentNeeded': _equipmentNeeded,
        };

      case ReservationServiceType.privateInvitation:
        return {
          'invitationConcept': _invitationConceptController.text.trim(),
          'occasionType': _occasionTypeController.text.trim(),
          'guestProfile': _guestProfileController.text.trim(),
        };

      case ReservationServiceType.chefsTable:
        return {
          'isSpecialOccasion': _isSpecialOccasion,
          'allergyNotes': _allergyNotesController.text.trim(),
          'seatingPreference': _seatingPreferenceController.text.trim(),
          'tastingPreference': _tastingPreferenceController.text.trim(),
        };

      case ReservationServiceType.standard:
        return {};
    }
  }

  String _serviceValidationMessage() {
    switch (_serviceType(context)) {
      case ReservationServiceType.corporateEvent:
        return 'Şirket adı, etkinlik türü ve lokasyon alanlarını doldurun.';
      case ReservationServiceType.boutiqueCatering:
        return 'Lokasyon ve servis tipi alanlarını doldurun.';
      case ReservationServiceType.privateInvitation:
        return 'Davet konsepti ve organizasyon türü alanlarını doldurun.';
      case ReservationServiceType.chefsTable:
      case ReservationServiceType.standard:
        return 'Lütfen gerekli alanları doldurun.';
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final user = FirebaseAuth.instance.currentUser;
    final chefId = _resolveChefId(context);

    if (!_formKey.currentState!.validate()) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı oturumu bulunamadı.')),
      );
      return;
    }

    if (chefId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şef bilgisi eksik. Bu ekran chefId ile açılmalı.'),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen önce tarih seçin.')),
      );
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir saat seçin.')),
      );
      return;
    }

    if (!_validateServiceSpecificFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_serviceValidationMessage())),
      );
      return;
    }

    final guestCount = int.tryParse(_guestCountController.text.trim()) ?? 1;
    final unitPrice = _resolveUnitPrice(context);
    final totalPrice = guestCount * unitPrice;

    final parts = _selectedTimeSlot!.split(':');
    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('chef_table_reservations')
          .add({
        'chefId': chefId,
        'chefName': _resolveChefName(context),
        'userId': user.uid,
        'status': 'approved',
        'paymentStatus': 'awaiting_payment',
        'reservationFlowStatus': 'awaiting_payment',
        'paymentProvider': 'iyzico',
        'paymentExpireAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 15)),
        ),
        'tableTitle': _resolveTableTitle(context),
        'concept': _resolveConcept(context),
        'capacity': _resolveCapacity(context),
        'serviceType': _serviceTypeName(context),
        'serviceDetails': _buildServiceDetailsMap(),
        'guestCount': guestCount,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'date': Timestamp.fromDate(selectedDateTime),
        'timeSlot': _selectedTimeSlot,
        'note': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervasyon gönderildi.')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserReservationsPage(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rezervasyon oluşturulamadı: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildServiceSpecificFields() {
    switch (_serviceType(context)) {
      case ReservationServiceType.corporateEvent:
        return _buildCorporateFields();
      case ReservationServiceType.boutiqueCatering:
        return _buildBoutiqueCateringFields();
      case ReservationServiceType.privateInvitation:
        return _buildPrivateInvitationFields();
      case ReservationServiceType.chefsTable:
        return _buildChefsTableFields();
      case ReservationServiceType.standard:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCorporateFields() {
    return Column(
      children: [
        _sectionCaption(
          'Kurumsal Etkinlik Detayları',
          'Kurumsal planlama için operasyonel bilgileri girin.',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _companyNameController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Şirket adı *'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _eventTypeController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Etkinlik türü *'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _locationController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Lokasyon *'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _serviceStyleController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Servis şekli'),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          value: _invoiceRequired,
          onChanged: (value) {
            setState(() {
              _invoiceRequired = value;
            });
          },
          activeColor: _gold,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Fatura talebi var',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Kurumsal faturalandırma ihtiyacını belirtin.',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      ],
    );
  }

  Widget _buildBoutiqueCateringFields() {
    return Column(
      children: [
        _sectionCaption(
          'Catering Operasyon Bilgileri',
          'Servis lokasyonu ve saha ihtiyaçlarını tanımlayın.',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _venueAddressController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Etkinlik adresi / lokasyon *'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _serviceTypeController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Servis tipi *'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _menuExpectationController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: _inputDecoration('Menü beklentisi'),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          value: _equipmentNeeded,
          onChanged: (value) {
            setState(() {
              _equipmentNeeded = value;
            });
          },
          activeColor: _gold,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Ek ekipman ihtiyacı var',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Kurulum veya saha ekipmanı gereksinimini işaretleyin.',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivateInvitationFields() {
    return Column(
      children: [
        _sectionCaption(
          'Davet Kurgusu',
          'Özel davetin karakterini ve deneyim beklentisini paylaşın.',
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _invitationConceptController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Davet konsepti *'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _occasionTypeController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Organizasyon türü *'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _guestProfileController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Misafir profili'),
        ),
      ],
    );
  }

  Widget _buildChefsTableFields() {
    return Column(
      children: [
        _sectionCaption(
          "Chef's Table Detayları",
          'Deneyimi daha rafine hale getirecek tercihleri paylaşın.',
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          value: _isSpecialOccasion,
          onChanged: (value) {
            setState(() {
              _isSpecialOccasion = value;
            });
          },
          activeColor: _gold,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Özel gün rezervasyonu',
            style: TextStyle(color: Colors.white),
          ),
          subtitle: const Text(
            'Doğum günü, yıldönümü veya benzeri özel bir deneyim.',
            style: TextStyle(color: Colors.white60),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _allergyNotesController,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          decoration: _inputDecoration('Alerji / hassasiyet bilgisi'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _seatingPreferenceController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Oturma tercihi'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _tastingPreferenceController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Tadım tercihi'),
        ),
      ],
    );
  }

  Widget _sectionCaption(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _gold, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }

  String _priceText(int amount) {
    return '₺${amount.toString()}';
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    IconData? icon,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? const Color(0x14FFB300) : _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight ? const Color(0x55FFB300) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: highlight ? _goldSoft : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: highlight ? _goldSoft : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotChip(String slot) {
    final isSelected = _selectedTimeSlot == slot;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeSlot = slot;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _gold : const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _goldSoft : Colors.white12,
          ),
        ),
        child: Text(
          slot,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chefName = _resolveChefName(context);
    final tableTitle = _resolveTableTitle(context);
    final concept = _resolveConcept(context);
    final capacity = _resolveCapacity(context);
    final unitPrice = _resolveUnitPrice(context);
    final guestCount = int.tryParse(_guestCountController.text.trim()) ?? 1;
    final totalPrice = guestCount * unitPrice;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _pageHeadline(context),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x1AFFD54F),
                      Color(0x0DFFB300),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  color: _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x33FFB300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pageHeadline(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _pageIntro(context),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildInfoCard(
                      title: 'Şef',
                      value: chefName,
                      icon: Icons.person_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      title: 'Deneyim',
                      value: tableTitle,
                      icon: Icons.workspace_premium_rounded,
                      highlight: true,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      title: 'Konsept',
                      value: concept,
                      icon: Icons.restaurant_menu_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      title: 'Kapasite',
                      value: capacity,
                      icon: Icons.groups_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _sectionCaption(
                'Rezervasyon Bilgileri',
                _capacityGuide(context),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _guestCountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration(_guestLabel(context)),
                validator: (value) {
                  final count = int.tryParse((value ?? '').trim());
                  if (count == null || count <= 0) {
                    return 'Geçerli bir kişi sayısı girin.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _inputDecoration(_noteHint(context)),
              ),
              const SizedBox(height: 18),
              _buildServiceSpecificFields(),
              const SizedBox(height: 18),
              _sectionCaption(
                'Tarih ve Saat',
                'Uygun günü seçin ve rezervasyon slotunu netleştirin.',
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: _goldSoft,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedDate == null
                              ? 'Tarih seçin'
                              : _formatDate(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.white38
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _timeSlots.map(_buildTimeSlotChip).toList(),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Şef', chefName),
                    _buildSummaryRow('Hizmet', tableTitle),
                    _buildSummaryRow('Kişi', '$guestCount'),
                    _buildSummaryRow('Birim fiyat', _priceText(unitPrice)),
                    const Divider(color: Colors.white12, height: 22),
                    _buildSummaryRow('Toplam', _priceText(totalPrice)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0x66FFB300),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Rezervasyonu Oluştur',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Rezervasyon gönderildikten sonra ödeme ve onay süreci ilgili akışta devam eder.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _guestCountController.dispose();
    _noteController.dispose();

    _companyNameController.dispose();
    _eventTypeController.dispose();
    _locationController.dispose();
    _serviceStyleController.dispose();

    _venueAddressController.dispose();
    _menuExpectationController.dispose();
    _serviceTypeController.dispose();

    _invitationConceptController.dispose();
    _occasionTypeController.dispose();
    _guestProfileController.dispose();

    _allergyNotesController.dispose();
    _seatingPreferenceController.dispose();
    _tastingPreferenceController.dispose();

    super.dispose();
  }
}
