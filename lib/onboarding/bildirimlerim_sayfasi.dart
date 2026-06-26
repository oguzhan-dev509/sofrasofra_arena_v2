import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BildirimlerimSayfasi extends StatelessWidget {
  const BildirimlerimSayfasi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _border = Color(0x44FFB300);

  String _formatDate(dynamic value) {
    if (value is! Timestamp) return '';

    final date = value.toDate().toLocal();

    String two(int number) => number.toString().padLeft(2, '0');

    return '${two(date.day)}.${two(date.month)}.${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  IconData _notificationIcon(String? type) {
    switch (type) {
      case 'application_approved':
        return Icons.check_circle_rounded;
      case 'application_rejected':
        return Icons.info_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _notificationColor(String? type) {
    switch (type) {
      case 'application_approved':
        return Colors.greenAccent;
      case 'application_rejected':
        return Colors.orangeAccent;
      default:
        return _gold;
    }
  }

  Future<void> _markAsRead(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> data,
  ) async {
    if (data['isRead'] == true) return;

    await reference.update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
          'Bildirimlerim',
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
                  'Bildirimlerinizi görmek için giriş yapmalısınız.',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('user_notifications')
                    .where('userId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Bildirimler yüklenemedi: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: _gold),
                    );
                  }

                  final docs = [...?snapshot.data?.docs];

                  docs.sort((a, b) {
                    final aTimestamp = a.data()['createdAt'];
                    final bTimestamp = b.data()['createdAt'];

                    final aDate = aTimestamp is Timestamp
                        ? aTimestamp.toDate()
                        : DateTime.fromMillisecondsSinceEpoch(0);

                    final bDate = bTimestamp is Timestamp
                        ? bTimestamp.toDate()
                        : DateTime.fromMillisecondsSinceEpoch(0);

                    return bDate.compareTo(aDate);
                  });

                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Henüz bildiriminiz bulunmuyor.',
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
                      final doc = docs[index];
                      final data = doc.data();

                      final title =
                          data['title']?.toString().trim().isNotEmpty == true
                              ? data['title'].toString()
                              : 'Sofrasofra Bildirimi';

                      final message = data['message']?.toString().trim() ?? '';

                      final type = data['type']?.toString();
                      final isRead = data['isRead'] == true;
                      final dateText = _formatDate(data['createdAt']);
                      final color = _notificationColor(type);

                      return InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: () async {
                          try {
                            await _markAsRead(doc.reference, data);
                          } catch (e) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Bildirim güncellenemedi: $e',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isRead ? _card : const Color(0xFF171308),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isRead ? _border : color,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: color),
                                ),
                                child: Icon(
                                  _notificationIcon(type),
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 9,
                                            height: 9,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (message.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        message,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13.5,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    if (dateText.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        dateText,
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                    if (!isRead) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Okundu olarak işaretlemek için dokunun.',
                                        style: TextStyle(
                                          color: _gold,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
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
