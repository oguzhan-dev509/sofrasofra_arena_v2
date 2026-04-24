import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WorkshopRequestsAdminPage extends StatelessWidget {
  final String chefId;
  final String chefName;

  const WorkshopRequestsAdminPage({
    super.key,
    required this.chefId,
    required this.chefName,
  });

  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  Color _statusColor(String status) {
    switch (status) {
      case 'contacted':
        return const Color(0xFF29B6F6);
      case 'completed':
        return const Color(0xFF66BB6A);
      case 'cancelled':
        return const Color(0xFFEF5350);
      case 'pending':
      default:
        return gold;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'contacted':
        return 'İletişime Geçildi';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal';
      case 'pending':
      default:
        return 'Bekliyor';
    }
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return 'Tarih yok';
    final dt = ts.toDate().toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year • $hour:$minute';
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: gold),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final name = (data['name'] ?? '-').toString();
    final phone = (data['phone'] ?? '-').toString();
    final email = (data['email'] ?? '-').toString();
    final note = (data['note'] ?? '').toString().trim();
    final status = (data['status'] ?? 'pending').toString();
    final createdAt = data['createdAt'] as Timestamp?;

    final badgeColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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
                  color: badgeColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: badgeColor.withOpacity(0.28),
                  ),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Telefon',
            value: phone,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.mail_outline_rounded,
            label: 'E-posta',
            value: email,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.schedule_rounded,
            label: 'Tarih',
            value: _formatDate(createdAt),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.07)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 16, color: gold),
                      SizedBox(width: 8),
                      Text(
                        'Talep Notu',
                        style: TextStyle(
                          color: gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                'WORKSHOP TALEPLERİ',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            chefName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Workshop başvuruları burada listelenir. Yeni gelen talepler üstte görünür.',
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

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('workshop_requests')
        .where('chefId', isEqualTo: chefId)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: gold),
        title: const Text(
          'Workshop Talepleri',
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
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
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Text(
                    'Workshop talepleri yüklenemedi:\n${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Henüz workshop talebi yok.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Yeni workshop talepleri geldiğinde burada listelenecek.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...docs.map(_buildRequestCard),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
