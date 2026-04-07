import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SefAkademiDersleri extends StatelessWidget {
  final String chefId;
  final String chefName;

  const SefAkademiDersleri({
    super.key,
    required this.chefId,
    this.chefName = 'Usta Şef',
  });

  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          "AKADEMİ DERS PROGRAMI",
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(6),
              border: Border(
                bottom: BorderSide(color: Colors.white.withAlpha(15)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chefName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Şef akademisine ait ders içerikleri aşağıda listelenir.",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('dersler')
                  .where('chefId', isEqualTo: chefId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: gold),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Dersler yüklenemedi: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Bu şef için henüz ders içeriği eklenmedi.",
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final m = docs[index].data();

                    final String baslik =
                        (m['baslik'] ?? "İsimsiz Eğitim").toString();
                    final String sure =
                        (m['sure'] ?? "Süre belirtilmedi").toString();
                    final String aciklama =
                        (m['aciklama'] ?? "Açıklama eklenmemiş").toString();
                    final bool ucretsiz = m['ucretsiz'] == true;
                    final int videoSayisi =
                        (m['videoCount'] as num?)?.toInt() ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x22FFB300)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: gold.withAlpha(22),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.play_lesson_rounded,
                                  color: gold,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  baslik.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: ucretsiz
                                      ? Colors.green.withAlpha(24)
                                      : Colors.white.withAlpha(10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: ucretsiz
                                        ? Colors.green.withAlpha(70)
                                        : Colors.white10,
                                  ),
                                ),
                                child: Text(
                                  ucretsiz ? 'ÜCRETSİZ' : 'PREMIUM',
                                  style: TextStyle(
                                    color: ucretsiz
                                        ? Colors.greenAccent
                                        : Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            aciklama,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: gold,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                sure,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.ondemand_video_rounded,
                                color: gold,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$videoSayisi video',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
