import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/admin/producer_applications_admin_sayfasi.dart';
import 'package:sofrasofra_arena_v2/admin/siparis_yonetimi.dart';
import 'package:sofrasofra_arena_v2/modules/chef_table_reservations_page.dart';
import 'package:sofrasofra_arena_v2/admin/kurye_yonetimi.dart';

class PlatformOperasyonMerkezi extends StatelessWidget {
  const PlatformOperasyonMerkezi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Platform Operasyon Merkezi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          StreamBuilder<List<_AlarmResult>>(
            stream: _globalAlarmStream(),
            initialData: const [],
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }

              final alarms = snapshot.data ?? const <_AlarmResult>[];

              if (alarms.isEmpty) {
                return const SizedBox.shrink();
              }

              return _AlarmBanner(
                alarms: alarms,
              );
            },
          ),
          const Text(
            'Canlı Aksiyon Paneli',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Başvurular, siparişler, ödemeler ve kurye hareketleri tek merkezden takip edilir.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 22),
          _LiveCounterCard(
            title: 'Bekleyen Başvurular',
            subtitle: 'Ev Lezzetleri, Usta Şef ve profesyonel kayıt talepleri',
            icon: Icons.assignment_turned_in_outlined,
            collection: 'producer_applications',
            statusField: 'status',
            statusValue: 'submitted',
          ),
          const SizedBox(height: 14),
          _LiveCounterCard(
            title: 'Bekleyen Siparişler',
            subtitle: 'Satıcı onayı veya hazırlık bekleyen siparişler',
            icon: Icons.receipt_long_outlined,
            collection: 'orders',
            statusField: 'orderStatus',
            statusValue: 'pending_vendor_approval',
          ),
          const SizedBox(height: 14),
          _LiveCounterCard(
            title: 'Ödeme Bekleyen Rezervasyonlar',
            subtitle:
                'İyzico ödeme süreci tamamlanmamış şef masası rezervasyonları',
            icon: Icons.payment_outlined,
            collection: 'chef_table_reservations',
            statusField: 'paymentStatus',
            statusValue: 'awaiting_payment',
          ),
          const SizedBox(height: 14),
          _LiveCounterCard(
            title: 'Görevdeki Kuryeler',
            subtitle: 'Aktif teslimat üzerinde görünen kuryeler',
            icon: Icons.delivery_dining_outlined,
            collection: 'couriers',
            statusField: 'availability',
            statusValue: 'gorevde',
          ),
          const SizedBox(height: 26),
          const _SectionTitle(title: 'Son Platform Hareketleri'),
          const SizedBox(height: 12),
          const _RecentReservationsPanel(),
        ],
      ),
    );
  }
}

class _AlarmResult {
  final String message;
  final Color color;

  const _AlarmResult(this.message, this.color);
}

Stream<List<_AlarmResult>> _globalAlarmStream() async* {
  final firestore = FirebaseFirestore.instance;

  while (true) {
    final alarms = <_AlarmResult>[];

    try {
      final orders = await firestore
          .collection('orders')
          .where('orderStatus', isEqualTo: 'pending_vendor_approval')
          .get();

      if (orders.docs.isNotEmpty) {
        final first = orders.docs.first.data();
        final ts = first['updatedAt'] ?? first['createdAt'];

        if (ts is Timestamp) {
          final diff = DateTime.now().difference(ts.toDate());

          if (diff.inMinutes >= 10) {
            alarms.add(
              const _AlarmResult(
                '10 dk işlem yapılmayan sipariş var',
                Colors.redAccent,
              ),
            );
          }
        }
      }

      final reservations = await firestore
          .collection('chef_table_reservations')
          .where('paymentStatus', isEqualTo: 'awaiting_payment')
          .get();

      if (reservations.docs.length >= 10) {
        alarms.add(
          const _AlarmResult(
            'Ödeme bekleyen çok yüksek',
            Colors.redAccent,
          ),
        );
      } else if (reservations.docs.length >= 5) {
        alarms.add(
          const _AlarmResult(
            'Ödeme bekleyen artıyor',
            Colors.orangeAccent,
          ),
        );
      }

      final couriers = await firestore
          .collection('couriers')
          .where('availability', isEqualTo: 'gorevde')
          .get();

      if (couriers.docs.isEmpty) {
        alarms.add(
          const _AlarmResult(
            'Aktif kurye yok',
            Colors.redAccent,
          ),
        );
      } else if (couriers.docs.length < 3) {
        alarms.add(
          const _AlarmResult(
            'Kurye sayısı düşük',
            Colors.orangeAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint('GLOBAL ALARM ERROR: $e');
    }

    yield alarms;

    await Future.delayed(const Duration(seconds: 5));
  }
}

class _AlarmBanner extends StatelessWidget {
  final List<_AlarmResult> alarms;

  const _AlarmBanner({required this.alarms});

  @override
  Widget build(BuildContext context) {
    if (alarms.isEmpty) return const SizedBox.shrink();

    // en kritik rengi seç (kırmızı > turuncu)
    final isCritical = alarms.any((a) => a.color == Colors.redAccent);

    final bg = isCritical
        ? Colors.redAccent.withOpacity(0.15)
        : Colors.orangeAccent.withOpacity(0.15);

    final border = isCritical ? Colors.redAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCritical ? '🚨 Kritik Uyarılar' : '⚠️ Operasyon Uyarıları',
            style: TextStyle(
              color: border,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          ...alarms.map(
            (a) => Text(
              '• ${a.message}',
              style: TextStyle(
                color: a.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

_AlarmResult? _evaluateAlarm({
  required String title,
  required int count,
  required dynamic lastTime,
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs,
}) {
  DateTime? lastDate;
  if (lastTime is Timestamp) {
    lastDate = lastTime.toDate();
  } else if (lastTime is DateTime) {
    lastDate = lastTime;
  }

  final now = DateTime.now();

  // 1) Bekleyen Siparişler → 10 dk işlem yoksa kırmızı
  if (title == 'Bekleyen Siparişler' && lastDate != null) {
    final diff = now.difference(lastDate);
    if (diff.inMinutes >= 10) {
      return const _AlarmResult(
        '⚠️ 10 dk işlem yok (kritik)',
        Colors.redAccent,
      );
    }
  }

  // 2) Görevdeki Kuryeler → atama yok / düşük sayı
  if (title == 'Görevdeki Kuryeler') {
    if (count == 0) {
      return const _AlarmResult(
        '⚠️ Aktif kurye yok',
        Colors.redAccent,
      );
    } else if (count < 3) {
      return const _AlarmResult(
        '🟡 Kurye sayısı düşük',
        Colors.orangeAccent,
      );
    }
  }

  // 3) Ödeme Bekleyen Rezervasyonlar → yoğunluk alarmı
  if (title == 'Ödeme Bekleyen Rezervasyonlar') {
    if (count >= 10) {
      return const _AlarmResult(
        '⚠️ Ödeme bekleyen çok yüksek',
        Colors.redAccent,
      );
    } else if (count >= 5) {
      return const _AlarmResult(
        '🟡 Ödeme bekleyen artıyor',
        Colors.orangeAccent,
      );
    }
  }

  return null;
}

class _LiveCounterCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String collection;
  final String statusField;
  final String statusValue;

  const _LiveCounterCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.collection,
    required this.statusField,
    required this.statusValue,
  });

  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  String _formatTime(dynamic value) {
    try {
      if (value == null) return '-';

      DateTime? date;

      if (value is Timestamp) {
        date = value.toDate();
      } else if (value is DateTime) {
        date = value;
      }

      if (date == null) return '-';

      final diff = DateTime.now().difference(date);

      if (diff.inMinutes < 1) return 'az önce';
      if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
      if (diff.inHours < 24) return '${diff.inHours} saat önce';

      return '${date.day}.${date.month}.${date.year}';
    } catch (_) {
      return '-';
    }
  }

  Color _riskColor(int count) {
    if (count >= 20) return Colors.redAccent;
    if (count >= 10) return Colors.orangeAccent;
    if (count > 0) return _gold;
    return Colors.greenAccent;
  }

  _AlarmResult? _evaluateAlarm({
    required int count,
    required dynamic lastTime,
  }) {
    DateTime? lastDate;

    if (lastTime is Timestamp) {
      lastDate = lastTime.toDate();
    } else if (lastTime is DateTime) {
      lastDate = lastTime;
    }

    final now = DateTime.now();

    if (title == 'Bekleyen Siparişler' && lastDate != null) {
      final diff = now.difference(lastDate);
      if (diff.inMinutes >= 10) {
        return const _AlarmResult(
          '⚠️ 10 dk işlem yok',
          Colors.redAccent,
        );
      }
    }

    if (title == 'Görevdeki Kuryeler') {
      if (count == 0) {
        return const _AlarmResult(
          '⚠️ Aktif kurye yok',
          Colors.redAccent,
        );
      }

      if (count < 3) {
        return const _AlarmResult(
          '🟡 Kurye sayısı düşük',
          Colors.orangeAccent,
        );
      }
    }

    if (title == 'Ödeme Bekleyen Rezervasyonlar') {
      if (count >= 10) {
        return const _AlarmResult(
          '⚠️ Ödeme bekleyen çok yüksek',
          Colors.redAccent,
        );
      }

      if (count >= 5) {
        return const _AlarmResult(
          '🟡 Ödeme bekleyen artıyor',
          Colors.orangeAccent,
        );
      }
    }

    return null;
  }

  void _openDetail(BuildContext context) {
    if (title == 'Bekleyen Başvurular') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProducerApplicationsAdminSayfasi(),
        ),
      );
      return;
    }

    if (title == 'Bekleyen Siparişler') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SiparisYonetimi(),
        ),
      );
      return;
    }

    if (title == 'Ödeme Bekleyen Rezervasyonlar') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChefTableReservationsPage(),
        ),
      );
      return;
    }

    if (title == 'Görevdeki Kuryeler') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const KuryeYonetimi(),
        ),
      );
      return;
    }

    debugPrint('TIKLANDI: $title');
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection(collection)
        .where(statusField, isEqualTo: statusValue);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final count = docs.length;

        dynamic lastTime;
        if (docs.isNotEmpty) {
          final data = docs.first.data();
          lastTime = data['updatedAt'] ??
              data['createdAt'] ??
              data['adminLastActionAt'];
        }

        final alarm = _evaluateAlarm(
          count: count,
          lastTime: lastTime,
        );

        final riskColor = alarm?.color ?? _riskColor(count);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _openDetail(context),
            child: Ink(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: riskColor.withOpacity(0.45)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: riskColor, size: 30),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        if (lastTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Son işlem: ${_formatTime(lastTime)}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        if (alarm != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              alarm.message,
                              style: TextStyle(
                                color: alarm.color,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Detaya Git →',
                          style: TextStyle(
                            color: riskColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: riskColor,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
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

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _RecentReservationsPanel extends StatelessWidget {
  const _RecentReservationsPanel();

  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('chef_table_reservations')
        .orderBy('createdAt', descending: true)
        .limit(8)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(
            'Rezervasyon hareketleri okunamadı.',
            style: TextStyle(color: Colors.redAccent),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(color: _gold),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Color(0x22FFFFFF)),
            ),
            child: const Text(
              'Henüz rezervasyon hareketi yok.',
              style: TextStyle(color: Colors.white60),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          child: Column(
            children: docs.map((doc) {
              final data = doc.data();

              final chefName = _text(data['chefName']);
              final concept = _text(data['concept']);
              final paymentStatus = _text(data['paymentStatus']);
              final flowStatus = _text(data['reservationFlowStatus']);

              return ListTile(
                leading: const Icon(
                  Icons.restaurant_menu_outlined,
                  color: _gold,
                ),
                title: Text(
                  chefName.isEmpty ? 'Şef rezervasyonu' : chefName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  [
                    if (concept.isNotEmpty) concept,
                    if (paymentStatus.isNotEmpty) 'Ödeme: $paymentStatus',
                    if (flowStatus.isNotEmpty) 'Akış: $flowStatus',
                  ].join('  •  '),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  static String _text(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}
