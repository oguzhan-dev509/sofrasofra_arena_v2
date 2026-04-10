import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SefAkademiVideoListesi extends StatelessWidget {
  final String dersId;

  const SefAkademiVideoListesi({
    super.key,
    required this.dersId,
  });

  static const Color gold = Color(0xFFFFB300);

  Future<void> _openVideo(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'DERS VİDEOLARI',
          style: TextStyle(color: gold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('dersler')
            .doc(dersId)
            .collection('videos')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: gold),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Video bulunamadı',
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();

              final String title = (data['title'] ?? '').toString();
              final String url = (data['videoUrl'] ?? '').toString();
              final bool isPreview = data['isPreview'] == true;

              return ListTile(
                leading: Icon(
                  isPreview ? Icons.play_circle : Icons.lock,
                  color: isPreview ? gold : Colors.white38,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: isPreview ? Colors.white : Colors.white38,
                  ),
                ),
                subtitle: Text(
                  isPreview ? 'Ücretsiz izlenebilir' : 'Satın alım gerekli',
                  style: const TextStyle(color: Colors.white54),
                ),
                onTap: isPreview
                    ? () => _openVideo(url)
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bu içerik kilitli 🔒'),
                          ),
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}
