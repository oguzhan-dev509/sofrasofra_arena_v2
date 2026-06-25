import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:sofrasofra_arena_v2/services/platform_admin_service.dart';

class AppInstallAnalyticsPage extends StatefulWidget {
  const AppInstallAnalyticsPage({super.key});

  @override
  State<AppInstallAnalyticsPage> createState() =>
      _AppInstallAnalyticsPageState();
}

class _AppInstallAnalyticsPageState extends State<AppInstallAnalyticsPage> {
  static const Color _bg = Color(0xFF090909);
  static const Color _panel = Color(0xFF171717);
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _muted = Color(0xFFB9B2A6);

  late final Future<bool> _adminFuture;

  @override
  void initState() {
    super.initState();
    _adminFuture = PlatformAdminService.isCurrentUserPlatformAdmin();
  }

  DateTime? _asDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  String _safeText(
    dynamic value, {
    String fallback = '-',
  }) {
    final text = (value ?? '').toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _dateText(dynamic value) {
    final date = _asDate(value);

    if (date == null) {
      return '-';
    }

    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _gold.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: _gold,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    int mobile = 0;
    int desktop = 0;
    int tablet = 0;
    int installDetected = 0;
    int standalone = 0;
    int totalLaunches = 0;
    int active7Days = 0;
    int active30Days = 0;
    int anonymous = 0;

    for (final doc in docs) {
      final data = doc.data();

      final deviceType =
          _safeText(data['deviceType'], fallback: '').toLowerCase();

      if (deviceType == 'mobile') {
        mobile++;
      } else if (deviceType == 'tablet') {
        tablet++;
      } else {
        desktop++;
      }

      if (data['installDetected'] == true) {
        installDetected++;
      }

      if (data['isStandalone'] == true) {
        standalone++;
      }

      if (data['isAnonymous'] == true) {
        anonymous++;
      }

      totalLaunches += _asInt(data['launchCount']);

      final lastSeenAt = _asDate(data['lastSeenAt']);

      if (lastSeenAt != null) {
        if (!lastSeenAt.isBefore(sevenDaysAgo)) {
          active7Days++;
        }

        if (!lastSeenAt.isBefore(thirtyDaysAgo)) {
          active30Days++;
        }
      }
    }

    final metrics = <Widget>[
      _metricCard(
        icon: Icons.devices_rounded,
        title: 'Toplam Benzersiz Cihaz',
        value: docs.length.toString(),
        subtitle: 'Tarayıcı ve cihaz bazında oluşturulan benzersiz kayıtlar.',
      ),
      _metricCard(
        icon: Icons.phone_android_rounded,
        title: 'Telefon',
        value: mobile.toString(),
        subtitle: 'Mobil cihaz olarak tespit edilen kayıtlar.',
      ),
      _metricCard(
        icon: Icons.desktop_windows_rounded,
        title: 'Bilgisayar',
        value: desktop.toString(),
        subtitle: 'Windows, macOS ve masaüstü tarayıcı kayıtları.',
      ),
      _metricCard(
        icon: Icons.tablet_mac_rounded,
        title: 'Tablet',
        value: tablet.toString(),
        subtitle: 'Tablet cihaz olarak tespit edilen kayıtlar.',
      ),
      _metricCard(
        icon: Icons.install_mobile_rounded,
        title: 'Kurulum Tespit Edilen',
        value: installDetected.toString(),
        subtitle:
            'PWA kurulumu veya kurulu uygulama modu tespit edilen cihazlar.',
      ),
      _metricCard(
        icon: Icons.open_in_new_rounded,
        title: 'Kurulu Moddan Açılış',
        value: standalone.toString(),
        subtitle:
            'Tarayıcı sekmesi yerine bağımsız uygulama modunda açılanlar.',
      ),
      _metricCard(
        icon: Icons.restart_alt_rounded,
        title: 'Toplam Açılış',
        value: totalLaunches.toString(),
        subtitle: 'Bütün cihazlardaki toplam uygulama açılış sayısı.',
      ),
      _metricCard(
        icon: Icons.calendar_view_week_rounded,
        title: 'Son 7 Gün Aktif',
        value: active7Days.toString(),
        subtitle: 'Son yedi gün içinde yeniden görülen benzersiz cihazlar.',
      ),
      _metricCard(
        icon: Icons.calendar_month_rounded,
        title: 'Son 30 Gün Aktif',
        value: active30Days.toString(),
        subtitle: 'Son otuz gün içinde yeniden görülen benzersiz cihazlar.',
      ),
      _metricCard(
        icon: Icons.person_outline_rounded,
        title: 'Anonim Kullanım',
        value: anonymous.toString(),
        subtitle: 'Henüz normal kullanıcı hesabına geçmemiş cihaz kayıtları.',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final crossAxisCount = width >= 1200
            ? 4
            : width >= 760
                ? 2
                : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: width >= 1200 ? 1.45 : 1.75,
          children: metrics,
        );
      },
    );
  }

  Widget _buildDeviceList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final sortedDocs = [...docs];

    sortedDocs.sort((a, b) {
      final aDate = _asDate(a.data()['lastSeenAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final bDate = _asDate(b.data()['lastSeenAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Text(
              'SON CİHAZ KAYITLARI',
              style: TextStyle(
                color: _gold,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const Divider(
            height: 1,
            color: Colors.white12,
          ),
          if (sortedDocs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Henüz cihaz kaydı bulunmuyor.',
                style: TextStyle(
                  color: _muted,
                ),
              ),
            )
          else
            ...sortedDocs.take(50).map(
              (doc) {
                final data = doc.data();

                final deviceType =
                    _safeText(data['deviceType'], fallback: 'desktop');

                final platform = _safeText(data['platform']);

                final browser = _safeText(data['browser']);

                final installed = data['installDetected'] == true;

                final standalone = data['isStandalone'] == true;

                final launchCount = _asInt(data['launchCount']);

                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _gold.withValues(alpha: 0.12),
                        child: Icon(
                          deviceType == 'mobile'
                              ? Icons.phone_android_rounded
                              : deviceType == 'tablet'
                                  ? Icons.tablet_mac_rounded
                                  : Icons.desktop_windows_rounded,
                          color: _gold,
                        ),
                      ),
                      title: Text(
                        '$platform • $browser',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          'Son görülme: ${_dateText(data['lastSeenAt'])}\n'
                          'Açılış: $launchCount • '
                          'Kurulum: ${installed ? 'Evet' : 'Hayır'} • '
                          'Bağımsız mod: ${standalone ? 'Evet' : 'Hayır'}',
                          style: const TextStyle(
                            color: _muted,
                            height: 1.35,
                          ),
                        ),
                      ),
                      trailing: Text(
                        deviceType.toUpperCase(),
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: Colors.white10,
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminFuture,
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: _bg,
            body: Center(
              child: CircularProgressIndicator(
                color: _gold,
              ),
            ),
          );
        }

        if (adminSnapshot.data != true) {
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: _gold,
              title: const Text(
                'Uygulama Kullanım Analizi',
              ),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Bu sayfayı yalnız platform yöneticileri görüntüleyebilir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: _gold,
            elevation: 0,
            title: const Text(
              'Uygulama Kullanım Analizi',
              style: TextStyle(
                color: _gold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('appInstallations')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Kullanım kayıtları yüklenemedi:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: _gold,
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return RefreshIndicator(
                color: _gold,
                onRefresh: () async {
                  await FirebaseFirestore.instance
                      .collection('appInstallations')
                      .limit(1)
                      .get();
                },
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Benzersiz cihaz, PWA kurulumu ve tekrar açılış hareketleri',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bu değerler fiziksel kişi sayısı değil; cihaz ve tarayıcı bazlı ölçümlerdir.',
                      style: TextStyle(
                        color: _muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _buildSummary(docs),
                    const SizedBox(height: 22),
                    _buildDeviceList(docs),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
