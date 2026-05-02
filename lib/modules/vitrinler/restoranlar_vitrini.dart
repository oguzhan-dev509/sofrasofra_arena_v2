import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RestoranlarVitrini extends StatefulWidget {
  const RestoranlarVitrini({super.key});

  @override
  State<RestoranlarVitrini> createState() => _RestoranlarVitriniState();
}

class _RestoranlarVitriniState extends State<RestoranlarVitrini> {
  static const Color _gold = Color(0xFFFFB300);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _openWaitlistDialog() async {
    _nameController.clear();
    _phoneController.clear();

    await showDialog(
      context: context,
      barrierDismissible: !_isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final name = _nameController.text.trim();
              final phone = _phoneController.text.trim();

              if (name.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                );
                return;
              }

              // 📱 normalize
              String normalized = phone.replaceAll(RegExp(r'\D'), '');
              if (normalized.startsWith('0')) {
                normalized = '9$normalized';
              }

              setState(() => _isSaving = true);

              try {
                final docRef = FirebaseFirestore.instance
                    .collection('restaurant_waitlist')
                    .doc(normalized);

                final doc = await docRef.get();

                if (doc.exists) {
                  // ❌ duplicate
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu numara zaten kayıtlı 👍'),
                    ),
                  );
                  setState(() => _isSaving = false);
                  return;
                }

                // ✅ yeni kayıt
                await docRef.set({
                  'name': name,
                  'phone': phone,
                  'normalizedPhone': normalized,
                  'source': 'restoran_vitrini',
                  'platform': 'web',
                  'city': 'İstanbul',
                  'district': 'Kadıköy',
                  'isContacted': false,
                  'isConverted': false,
                  'notes': '',
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                final campaignRef = FirebaseFirestore.instance
                    .collection('siteSettings')
                    .doc('campaign');

                await FirebaseFirestore.instance
                    .runTransaction((transaction) async {
                  final campaignSnap = await transaction.get(campaignRef);
                  final campaignData = campaignSnap.data();

                  final current = campaignData?['restoranKalan'];
                  final kalan = current is int ? current : 100;

                  final yeniKalan = kalan > 0 ? kalan - 1 : 0;

                  transaction.set(
                    campaignRef,
                    {
                      'restoranKalan': yeniKalan,
                      'updatedAt': FieldValue.serverTimestamp(),
                    },
                    SetOptions(merge: true),
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kaydınız alındı 🚀'),
                  ),
                );

                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }

              setState(() => _isSaving = false);
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF171717),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Kurucu Restoran Üyeliği',
                style: TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'İlk 100 kurucu restoran arasına katılın, 1 yıl ücretsiz avantaj ve erken görünürlük fırsatını yakalayın.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ad Soyad',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _gold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Telefon',
                        labelStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _gold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Vazgeç',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Kaydol',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'RESTORANLAR',
          style: TextStyle(
            color: _gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/restoranlar_kurye_lansman.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.low,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.30),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.92, -0.18),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(34, 24, 24, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Text(
                              'İlk 100 Kurucu Restoran',
                              style: TextStyle(
                                color: _gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('siteSettings')
                                .doc('campaign')
                                .snapshots(),
                            builder: (context, snapshot) {
                              final data = snapshot.data?.data();
                              final kalan = data?['restoranKalan'] ?? 100;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _gold,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '$kalan Kaldı',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Restoranlar Çok Yakında Sofrasofra’da',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.12,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ürün sizin, emek sizin, kazanç sizin.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          height: 1.25,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Kurucu restoranlar için 1 yıl ücretsiz avantaj ve erken görünürlük fırsatı.',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _openWaitlistDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.45),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Text(
                              '1 Yıl Ücretsiz Katıl',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
