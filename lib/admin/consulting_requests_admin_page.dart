import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ConsultingRequestsAdminPage extends StatefulWidget {
  final String chefId;
  final String chefName;

  const ConsultingRequestsAdminPage({
    super.key,
    required this.chefId,
    required this.chefName,
  });

  @override
  State<ConsultingRequestsAdminPage> createState() =>
      _ConsultingRequestsAdminPageState();
}

class _ConsultingRequestsAdminPageState
    extends State<ConsultingRequestsAdminPage> {
  static const Color gold = Color(0xFFFFB300);
  static const Color bg = Color(0xFF050505);
  static const Color card = Color(0xFF121212);

  static const Map<String, String> _statusLabels = {
    'pending': 'Beklemede',
    'reviewing': 'İnceleniyor',
    'accepted': 'Kabul Edildi',
    'rejected': 'Reddedildi',
    'completed': 'Tamamlandı',
  };

  static const Map<String, String> _typeLabels = {
    'menu_consulting': 'Menü Danışmanlığı',
    'kitchen_setup': 'Mutfak Kurulum',
    'operational_review': 'Operasyon İncelemesi',
    'brand_positioning': 'Marka Konumlandırma',
    'training_program': 'Eğitim Programı',
  };

  static const Map<String, String> _businessTypeLabels = {
    'restaurant': 'Restoran',
    'cafe': 'Kafe',
    'home_producer': 'Ev Üretici',
    'boutique_kitchen': 'Butik Mutfak',
    'new_venture': 'Yeni Girişim',
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF1F8A70);
      case 'completed':
        return const Color(0xFF0E7C86);
      case 'rejected':
        return const Color(0xFF8B2E2E);
      case 'reviewing':
        return const Color(0xFF7A5A10);
      default:
        return const Color(0xFF3A3A3A);
    }
  }

  Future<void> _updateStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('consulting_requests')
          .doc(docId)
          .update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Talep durumu "${_statusLabels[newStatus] ?? newStatus}" olarak güncellendi.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Durum güncellenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _safeText(dynamic value, {String fallback = '-'}) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Widget _buildBadge({
    required String text,
    Color? textColor,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? gold.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? gold.withOpacity(0.30),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? gold,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gold.withOpacity(0.14),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.10)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.support_agent_rounded, color: gold, size: 18),
              SizedBox(width: 8),
              Text(
                'DANIŞMANLIK TALEPLERİ',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            widget.chefName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gelen danışmanlık taleplerini inceleyin, önceliklendirin ve durumlarını yönetin.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data();

    final name = _safeText(m['userName'], fallback: 'İsimsiz');
    final phone = _safeText(m['phone']);
    final city = _safeText(m['city'], fallback: '');
    final district = _safeText(m['district'], fallback: '');
    final details = _safeText(m['details']);
    final targetDate = _safeText(m['targetDate']);
    final budget = _safeText(m['budget']);
    final status = _safeText(m['status'], fallback: 'pending');
    final typeKey = _safeText(m['type'], fallback: '');
    final businessTypeKey = _safeText(m['businessType'], fallback: '');

    final typeLabel = _typeLabels[typeKey] ?? typeKey;
    final businessTypeLabel = _businessTypeLabels[businessTypeKey] ??
        _safeText(m['businessTypeLabel'], fallback: businessTypeKey);

    final location =
        [city, district].where((e) => e.trim().isNotEmpty).join(' / ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _buildBadge(
                text: _statusLabels[status] ?? status,
                textColor: _statusColor(status),
                borderColor: _statusColor(status),
                backgroundColor: _statusColor(status).withOpacity(0.16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (typeLabel.isNotEmpty) _buildBadge(text: typeLabel),
              if (businessTypeLabel.isNotEmpty)
                _buildBadge(text: businessTypeLabel),
              if (budget != '-') _buildBadge(text: '$budget TL'),
              if (targetDate != '-') _buildBadge(text: targetDate),
              if (location.isNotEmpty) _buildBadge(text: location),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            details,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.phone_rounded, color: gold, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF171717),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: status,
                dropdownColor: const Color(0xFF1A1A1A),
                iconEnabledColor: gold,
                style: const TextStyle(color: Colors.white),
                items: _statusLabels.entries
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null && value != status) {
                    _updateStatus(doc.id, value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('consulting_requests')
          .where('chefId', isEqualTo: widget.chefId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: gold),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Text(
                  'Danışmanlık talepleri yüklenemedi: ${snapshot.error}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: const Text(
                  'Henüz danışmanlık talebi görünmüyor.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          );
        }

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: docs.map(_buildRequestCard).toList(),
            ),
          ),
        );
      },
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
          'DANIŞMANLIK TALEPLERİ',
          style: TextStyle(
            color: gold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          _buildBody(),
        ],
      ),
    );
  }
}
