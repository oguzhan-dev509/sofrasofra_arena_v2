import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/platform_admin_service.dart';

class MahalleKocuBasvurulariAdminSayfasi extends StatefulWidget {
  const MahalleKocuBasvurulariAdminSayfasi({super.key});

  @override
  State<MahalleKocuBasvurulariAdminSayfasi> createState() =>
      _MahalleKocuBasvurulariAdminSayfasiState();
}

class _MahalleKocuBasvurulariAdminSayfasiState
    extends State<MahalleKocuBasvurulariAdminSayfasi> {
  static const Color _gold = Color(0xFFFFB300);
  static const Color _background = Colors.black;
  static const Color _cardColor = Color(0xFF111111);

  String _selectedStatus = 'pending';
  final Set<String> _processingIds = <String>{};

  Stream<QuerySnapshot<Map<String, dynamic>>> get _applicationsStream {
    return FirebaseFirestore.instance
        .collection('neighborhood_coach_applications')
        .snapshots();
  }

  String _safe(dynamic value) {
    return (value ?? '').toString().trim();
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  String _formatDate(dynamic value) {
    final date = _toDateTime(value);

    if (date == null) {
      return 'Tarih bekleniyor';
    }

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Bekliyor';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.greenAccent;
      case 'rejected':
        return Colors.redAccent;
      default:
        return _gold;
    }
  }

  Future<void> _approveApplication(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Başvuruyu Onayla',
            style: TextStyle(color: _gold),
          ),
          content: const Text(
            'Bu Mahalle Mutfak Koçu başvurusu onaylanacak.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Onayla'),
            ),
          ],
        );
      },
    );

    if (approved != true) return;

    await _updateApplication(
      reference: reference,
      status: 'approved',
      rejectionReason: '',
    );
  }

  Future<void> _rejectApplication(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Başvuruyu Reddet',
            style: TextStyle(color: Colors.redAccent),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Ret gerekçesi',
              labelStyle: TextStyle(color: Colors.white60),
              hintText: 'Başvurunun neden reddedildiğini yazın',
              hintStyle: TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _gold),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Ret gerekçesi zorunludur.'),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reddet'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null || reason.isEmpty) return;

    await _updateApplication(
      reference: reference,
      status: 'rejected',
      rejectionReason: reason,
    );
  }

  Future<void> _returnToPending(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    await _updateApplication(
      reference: reference,
      status: 'pending',
      rejectionReason: '',
    );
  }

  Future<void> _updateApplication({
    required DocumentReference<Map<String, dynamic>> reference,
    required String status,
    required String rejectionReason,
  }) async {
    if (_processingIds.contains(reference.id)) return;

    setState(() {
      _processingIds.add(reference.id);
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      await reference.update({
        'status': status,
        'reviewedAt': status == 'pending' ? null : FieldValue.serverTimestamp(),
        'reviewedBy': status == 'pending' ? '' : (user?.uid ?? ''),
        'rejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'approved'
                ? 'Başvuru onaylandı.'
                : status == 'rejected'
                    ? 'Başvuru reddedildi.'
                    : 'Başvuru yeniden beklemeye alındı.',
          ),
          backgroundColor:
              status == 'rejected' ? Colors.redAccent : Colors.green,
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Başvuru güncellenemedi: ${error.message ?? error.code}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Başvuru güncellenemedi: $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingIds.remove(reference.id);
        });
      }
    }
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredDocuments(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final documents = snapshot.docs.where((document) {
      final status = _safe(document.data()['status']).toLowerCase();
      return status == _selectedStatus;
    }).toList();

    documents.sort((first, second) {
      final firstDate = _toDateTime(first.data()['createdAt']);
      final secondDate = _toDateTime(second.data()['createdAt']);

      if (firstDate == null && secondDate == null) return 0;
      if (firstDate == null) return 1;
      if (secondDate == null) return -1;

      return secondDate.compareTo(firstDate);
    });

    return documents;
  }

  Widget _filterChip({
    required String status,
    required String label,
    required int count,
  }) {
    final selected = _selectedStatus == status;
    final color = _statusColor(status);

    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedStatus = status;
        });
      },
      backgroundColor: const Color(0xFF181818),
      selectedColor: color.withValues(alpha: 0.20),
      side: BorderSide(
        color: selected ? color : Colors.white12,
      ),
      label: Text(
        '$label ($count)',
        style: TextStyle(
          color: selected ? color : Colors.white70,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _informationRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _gold,
            size: 18,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final status = _safe(data['status']).toLowerCase();
    final statusColor = _statusColor(status);
    final processing = _processingIds.contains(document.id);

    final city = _safe(data['city']);
    final district = _safe(data['district']);
    final neighborhood = _safe(data['neighborhood']);

    final location = [
      neighborhood,
      district,
      city,
    ].where((value) => value.isNotEmpty).join(' / ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: _gold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _safe(data['fullName']).isEmpty
                          ? 'İsimsiz başvuru'
                          : _safe(data['fullName']),
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(data['createdAt']),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _informationRow(
            icon: Icons.phone_rounded,
            label: 'Telefon',
            value: _safe(data['phone']),
          ),
          _informationRow(
            icon: Icons.email_outlined,
            label: 'E-posta',
            value: _safe(data['email']),
          ),
          _informationRow(
            icon: Icons.location_on_outlined,
            label: 'Bölge',
            value: location,
          ),
          _informationRow(
            icon: Icons.account_balance_outlined,
            label: 'IBAN',
            value: _safe(data['iban']),
          ),
          _informationRow(
            icon: Icons.home_work_outlined,
            label: 'Ev üreticisi',
            value: _safe(data['estimatedHomeProducerCount']),
          ),
          _informationRow(
            icon: Icons.restaurant_menu_rounded,
            label: 'Usta Şef',
            value: _safe(data['estimatedChefCount']),
          ),
          _informationRow(
            icon: Icons.storefront_outlined,
            label: 'Restoran',
            value: _safe(data['estimatedRestaurantCount']),
          ),
          _informationRow(
            icon: Icons.schedule_rounded,
            label: 'Haftalık zaman',
            value: _safe(data['weeklyAvailability']),
          ),
          _informationRow(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Motivasyon',
            value: _safe(data['motivation']),
          ),
          if (_safe(data['rejectionReason']).isNotEmpty)
            _informationRow(
              icon: Icons.report_gmailerrorred_rounded,
              label: 'Ret gerekçesi',
              value: _safe(data['rejectionReason']),
            ),
          if (status != 'pending') ...[
            const Divider(
              color: Colors.white12,
              height: 24,
            ),
            _informationRow(
              icon: Icons.admin_panel_settings_outlined,
              label: 'İnceleyen UID',
              value: _safe(data['reviewedBy']),
            ),
            _informationRow(
              icon: Icons.history_rounded,
              label: 'İnceleme tarihi',
              value: _formatDate(data['reviewedAt']),
            ),
          ],
          const SizedBox(height: 8),
          if (processing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  color: _gold,
                ),
              ),
            )
          else if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectApplication(document.reference),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reddet'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(
                        color: Colors.redAccent,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveApplication(document.reference),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Onayla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _returnToPending(document.reference),
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Yeniden Beklemeye Al'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _gold,
                  side: const BorderSide(color: _gold),
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _authorizedBody() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _applicationsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Başvurular okunamadı:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  height: 1.5,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _gold),
          );
        }

        final allDocuments = snapshot.data?.docs ?? [];

        int countFor(String status) {
          return allDocuments.where((document) {
            return _safe(
                  document.data()['status'],
                ).toLowerCase() ==
                status;
          }).length;
        }

        final filteredDocuments = snapshot.data == null
            ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
            : _filteredDocuments(snapshot.data!);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  status: 'pending',
                  label: 'Bekleyen',
                  count: countFor('pending'),
                ),
                _filterChip(
                  status: 'approved',
                  label: 'Onaylanan',
                  count: countFor('approved'),
                ),
                _filterChip(
                  status: 'rejected',
                  label: 'Reddedilen',
                  count: countFor('rejected'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (filteredDocuments.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedStatus == 'pending'
                          ? Icons.task_alt_rounded
                          : Icons.inbox_outlined,
                      color: _gold,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedStatus == 'pending'
                          ? 'Bekleyen Mahalle Koçu başvurusu yok.'
                          : 'Bu durumda başvuru bulunmuyor.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredDocuments.map(_applicationCard),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: PlatformAdminService.isCurrentUserPlatformAdmin(),
      builder: (context, snapshot) {
        return Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            backgroundColor: _background,
            elevation: 0,
            iconTheme: const IconThemeData(color: _gold),
            title: const Text(
              'MAHALLE KOÇU BAŞVURULARI',
              style: TextStyle(
                color: _gold,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(
                  child: CircularProgressIndicator(color: _gold),
                )
              : snapshot.data == true
                  ? _authorizedBody()
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: Colors.redAccent,
                              size: 52,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Bu sayfaya yalnızca platform yöneticisi erişebilir.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                height: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
        );
      },
    );
  }
}
