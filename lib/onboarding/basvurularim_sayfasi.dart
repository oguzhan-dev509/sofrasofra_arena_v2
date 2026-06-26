import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BasvurularimSayfasi extends StatelessWidget {
  const BasvurularimSayfasi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _border = Color(0x44FFB300);

  String _typeLabel(String? type) {
    switch (type) {
      case 'ev_lezzetleri':
        return 'Ev Lezzetleri';
      case 'profesyonel_isletme':
        return 'Usta Şef / Restoran';
      default:
        return 'Başvuru';
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'submitted':
        return 'İncelemede';
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      case 'draft':
        return 'Taslak';
      default:
        return 'İncelemede';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      case 'draft':
        return Colors.orangeAccent;
      default:
        return _gold;
    }
  }

  String _statusMessage(String? status) {
    switch (status) {
      case 'approved':
        return 'Başvurunuz onaylandı. Yönetim paneliniz kullanıma hazır.';
      case 'rejected':
        return 'Başvurunuz şu aşamada onaylanmadı. Ayrıntılı bilgi için Sofrasofra ile iletişime geçebilirsiniz.';
      case 'draft':
        return 'Başvurunuz henüz tamamlanmamış taslak durumundadır.';
      default:
        return 'Başvurunuz inceleme sürecindedir. Onay sonrası ilgili paneliniz açılacaktır.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Başvurularım',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: user == null
            ? const Center(
                child: Text(
                  'Başvurularınızı görmek için giriş yapmalısınız.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('producer_applications')
                    .where('userId', isEqualTo: user.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Başvurular yüklenemedi: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _gold),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Henüz başvurunuz bulunmuyor.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();

                      final type = data['type']?.toString();
                      final status = data['status']?.toString();

                      final title = data['mutfakAdi']
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                          ? data['mutfakAdi'].toString()
                          : data['isletmeAdi']?.toString().trim().isNotEmpty ==
                                  true
                              ? data['isletmeAdi'].toString()
                              : _typeLabel(type);

                      final city = data['sehir']?.toString() ?? '';
                      final district = data['ilce']?.toString() ?? '';

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _statusColor(status).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _statusColor(status),
                                    ),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _typeLabel(type),
                              style: const TextStyle(
                                color: _gold,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (city.isNotEmpty || district.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '$city ${district.isNotEmpty ? '/ $district' : ''}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              _statusMessage(status),
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
