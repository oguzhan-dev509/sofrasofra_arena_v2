import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/membership_plan_service.dart';

class UyelikTestSayfasi extends StatefulWidget {
  const UyelikTestSayfasi({super.key});

  @override
  State<UyelikTestSayfasi> createState() => _UyelikTestSayfasiState();
}

class _UyelikTestSayfasiState extends State<UyelikTestSayfasi> {
  bool _loading = false;
  Map<String, dynamic>? _sellerData;
  String _selectedPlan = 'free';

  @override
  void initState() {
    super.initState();
    _loadSeller();
  }

  Future<void> _loadSeller() async {
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'demo_user';

      final doc =
          await FirebaseFirestore.instance.collection('sellers').doc(uid).get();

      final data = doc.data();

      if (!mounted) return;

      setState(() {
        _sellerData = data;
        _selectedPlan = (data?['membershipType'] ?? 'free').toString();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Seller verisi okunamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ensureSellerExists() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'demo_user';

    final ref = FirebaseFirestore.instance.collection('sellers').doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'uid': uid,
        'membershipType': 'free',
        'membershipStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...MembershipPlanService.buildSellerPlanFields('free'),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _applyPlan(String planType) async {
    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'demo_user';

      await _ensureSellerExists();

      final ref = FirebaseFirestore.instance.collection('sellers').doc(uid);

      await ref.set({
        'uid': uid,
        ...MembershipPlanService.buildSellerPlanFields(planType),
        'membershipStatus': 'active',
        'planStartAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Paket güncellendi: $planType')),
      );

      await _loadSeller();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Paket atanamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _sellerData ?? {};
    final membershipType = (data['membershipType'] ?? 'free').toString();
    final badgeType = (data['badgeType'] ?? 'none').toString();
    final featuredScope = (data['featuredScope'] ?? 'none').toString();
    final maxPhotoCount = (data['maxPhotoCount'] ?? 0).toString();
    final maxVideoCount = (data['maxVideoCount'] ?? 0).toString();
    final canUseYoutube = (data['canUseYoutube'] ?? false).toString();
    final priorityScore = (data['priorityScore'] ?? 0).toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Color(0xFFFFB300)),
        title: const Text(
          'ÜYELİK TEST MERKEZİ',
          style: TextStyle(
            color: Color(0xFFFFB300),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MEVCUT PAKET BİLGİSİ',
                          style: TextStyle(
                            color: Color(0xFFFFB300),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _infoRow('membershipType', membershipType),
                        _infoRow('badgeType', badgeType),
                        _infoRow('featuredScope', featuredScope),
                        _infoRow('maxPhotoCount', maxPhotoCount),
                        _infoRow('maxVideoCount', maxVideoCount),
                        _infoRow('canUseYoutube', canUseYoutube),
                        _infoRow('priorityScore', priorityScore),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedPlan,
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Free')),
                      DropdownMenuItem(value: 'pro', child: Text('Pro')),
                      DropdownMenuItem(
                          value: 'premium', child: Text('Premium')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _selectedPlan = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'YENİ PAKET',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFFFB300)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _applyPlan(_selectedPlan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB300),
                      ),
                      child: const Text(
                        'PAKETİ UYGULA',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadSeller,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFFB300)),
                    ),
                    child: const Text(
                      'YENİDEN YÜKLE',
                      style: TextStyle(color: Color(0xFFFFB300)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
