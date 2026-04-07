import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  DateTime? _selectedDate;
  bool _isSaving = false;

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
    return value.toString().trim().isEmpty ? null : value.toString().trim();
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

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Tarih seçilmedi';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day.$month.$year  $hour:$minute';
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
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
          content: Text('chefId bulunamadı. Bu ekran şef bilgisiyle açılmalı.'),
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen rezervasyon tarihi seçin.')),
      );
      return;
    }

    final guestCount = int.tryParse(_guestCountController.text.trim()) ?? 1;
    final unitPrice = _resolveUnitPrice(context);
    final totalPrice = guestCount * unitPrice;

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('✅ LOGIN UID: ${user.uid}');
      debugPrint('✅ CREATE RESERVATION userId: ${user.uid}');
      debugPrint('✅ CREATE RESERVATION chefId: $chefId');

      final docRef = await FirebaseFirestore.instance
          .collection('chef_table_reservations')
          .add({
        'chefId': chefId,
        'chefName': _resolveChefName(context),
        'userId': user.uid,
        'status': 'pending',
        'paymentStatus': 'not_required',
        'reservationFlowStatus': 'pending',
        'paymentProvider': 'iyzico',
        'paymentExpireAt': null,
        'tableTitle': _resolveTableTitle(context),
        'concept': _resolveConcept(context),
        'capacity': _resolveCapacity(context),
        'guestCount': guestCount,
        'unitPrice': unitPrice,
        'totalPrice': totalPrice,
        'date': Timestamp.fromDate(_selectedDate!),
        'note': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('🟢 REZERVASYON OLUŞTU: ${docRef.id}');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervasyon gönderildi.')),
      );

      Navigator.pop(context);
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

  @override
  void dispose() {
    _guestCountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chefId = _resolveChefId(context);
    final chefName = _resolveChefName(context);
    final tableTitle = _resolveTableTitle(context);
    final concept = _resolveConcept(context);
    final capacity = _resolveCapacity(context);
    final unitPrice = _resolveUnitPrice(context);

    final guestCount = int.tryParse(_guestCountController.text.trim()) ?? 1;
    final totalPrice = guestCount * unitPrice;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Rezervasyon Oluştur'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Şef Masası Bilgileri',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _infoRow('Şef', chefName),
                    _infoRow('chefId', chefId ?? 'YOK'),
                    _infoRow('Masa', tableTitle),
                    _infoRow('Konsept', concept),
                    _infoRow('Kapasite', capacity),
                    _infoRow('Birim Fiyat', '$unitPrice TL'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rezervasyon Detayı',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _guestCountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Kişi sayısı'),
                      validator: (value) {
                        final count = int.tryParse((value ?? '').trim());
                        if (count == null || count <= 0) {
                          return 'Geçerli bir kişi sayısı girin';
                        }
                        return null;
                      },
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Notunuz'),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Text(
                          _formatDateTime(_selectedDate),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam Tutar: $totalPrice TL',
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Not: Rezervasyon önce şef onayına düşer. Onay sonrası ödeme akışı başlar.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _isSaving ? 'Kaydediliyor...' : 'Rezervasyonu Gönder',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.black,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
