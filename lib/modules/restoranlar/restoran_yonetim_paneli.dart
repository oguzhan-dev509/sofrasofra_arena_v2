import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RestoranYonetimPaneli extends StatelessWidget {
  const RestoranYonetimPaneli({
    super.key,
    required this.restaurantId,
  });

  final String restaurantId;

  static const Color _gold = Color(0xFFFFB300);
  static const Color _bg = Color(0xFF070707);
  static const Color _card = Color(0xFF141414);

  DocumentReference<Map<String, dynamic>> get _restaurantRef =>
      FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);

  Future<void> _updateOpenStatus({
    required BuildContext context,
    required bool isOpen,
  }) async {
    try {
      await _restaurantRef.update({
        'isOpen': isOpen,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOpen
                ? 'Restoran müşterilere açıldı.'
                : 'Restoran geçici olarak kapatıldı.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restoran durumu güncellenemedi: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'RESTORAN YÖNETİM PANELİ',
          style: TextStyle(
            color: _gold,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _restaurantRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Restoran bilgisi alınamadı: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: _gold),
            );
          }

          final document = snapshot.data!;

          if (!document.exists) {
            return const Center(
              child: Text(
                'Restoran kaydı bulunamadı.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final data = document.data() ?? const <String, dynamic>{};
          final restaurantName =
              (data['name'] ?? data['restaurantName'] ?? 'Restoran')
                  .toString()
                  .trim();
          final isOpen = data['isOpen'] == true;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                restaurantName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Restoranınızın çalışma durumunu buradan yönetebilirsiniz.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.28),
                  ),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: isOpen,
                  activeColor: _gold,
                  title: Text(
                    isOpen ? 'Restoran Açık' : 'Restoran Kapalı',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: Text(
                    isOpen
                        ? 'Müşteriler restoranınızı görebilir ve açık durumunu görebilir.'
                        : 'Restoran vitrinde görünür; ancak kapalı olarak işaretlenir.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  secondary: Icon(
                    isOpen ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isOpen ? _gold : Colors.white38,
                    size: 34,
                  ),
                  onChanged: (value) async {
                    await _updateOpenStatus(
                      context: context,
                      isOpen: value,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
