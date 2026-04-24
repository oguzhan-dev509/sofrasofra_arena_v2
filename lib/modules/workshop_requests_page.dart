import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WorkshopRequestsPage extends StatefulWidget {
  final String chefId;
  final String chefName;

  const WorkshopRequestsPage({
    super.key,
    required this.chefId,
    required this.chefName,
  });

  @override
  State<WorkshopRequestsPage> createState() => _WorkshopRequestsPageState();
}

class _WorkshopRequestsPageState extends State<WorkshopRequestsPage> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('workshop_requests').add({
        'chefId': widget.chefId,
        'chefName': widget.chefName,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'note': _noteController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'chef_brand_career',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workshop talebiniz alındı.'),
          backgroundColor: Colors.black,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Talep gönderilemedi: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: gold),
      filled: true,
      fillColor: Colors.white.withOpacity(0.04),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: gold, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_rounded, color: gold, size: 18),
              SizedBox(width: 8),
              Text(
                'WORKSHOP TALEBİ',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.chefName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kurumsal eğitim, özel workshop, sahne sunumu veya uygulamalı gastronomi etkinliği için talep bırakabilirsiniz.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                label: 'Ad Soyad',
                icon: Icons.person_outline_rounded,
                hint: 'Adınızı girin',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ad soyad gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                label: 'Telefon',
                icon: Icons.phone_outlined,
                hint: '05xx xxx xx xx',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.emailAddress,
              decoration: _inputDecoration(
                label: 'E-posta',
                icon: Icons.mail_outline_rounded,
                hint: 'ornek@mail.com',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'E-posta gerekli';
                }
                if (!value.contains('@')) {
                  return 'Geçerli bir e-posta girin';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _noteController,
              style: const TextStyle(color: Colors.white),
              minLines: 4,
              maxLines: 6,
              decoration: _inputDecoration(
                label: 'Talep Notu',
                icon: Icons.edit_note_rounded,
                hint:
                    'Workshop konusu, kişi sayısı, şehir, tarih aralığı gibi detayları yazın',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Talep notu gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.black),
                label: Text(
                  _isSubmitting ? 'Gönderiliyor...' : 'Workshop Talebi Gönder',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: gold,
                  disabledBackgroundColor: const Color(0xFFFFB300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
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
        title: const Text(
          'Workshop Talebi',
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildFormCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
