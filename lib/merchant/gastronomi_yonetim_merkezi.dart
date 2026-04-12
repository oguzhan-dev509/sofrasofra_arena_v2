import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/admin/chef_profile_admin_page.dart';
import 'package:sofrasofra_arena_v2/modules/sef_akademi_dersleri.dart';
import 'package:sofrasofra_arena_v2/modules/sef_itibar_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/chef_table_reservations_page.dart';

class GastronomiYonetimMerkezi extends StatelessWidget {
  final String? chefId;
  final String? chefName;

  const GastronomiYonetimMerkezi({
    super.key,
    this.chefId,
    this.chefName,
  });

  static const Color _bg = Colors.black;
  static const Color _panel = Color(0xFF111111);
  static const Color _panel2 = Color(0xFF171717);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _softText = Color(0xFFBDBDBD);
  static const Color _border = Color(0x22FFFFFF);

  bool _hasChefContext() {
    return (chefId ?? '').trim().isNotEmpty;
  }

  void _showChefRequiredMessage(BuildContext context, String moduleName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$moduleName için önce bir şef seçilerek bu merkeze girilmeli.',
        ),
      ),
    );
  }

  void _openChefProfileAdmin(BuildContext context) {
    final currentChefId = (chefId ?? '').trim();

    if (currentChefId.isEmpty) {
      _showChefRequiredMessage(context, 'Şef Profili');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChefProfileAdminPage(
          chefId: currentChefId,
        ),
      ),
    );
  }

  void _openSefItibarProfili(BuildContext context) {
    final currentChefId = (chefId ?? '').trim();

    if (currentChefId.isEmpty) {
      _showChefRequiredMessage(context, 'Şef İtibar Profili');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SefItibarSayfasi(
          dukkanId: currentChefId,
          isAdmin: true,
        ),
      ),
    );
  }

  void _openSefAkademisi(BuildContext context) {
    final currentChefId = (chefId ?? '').trim();

    if (currentChefId.isEmpty) {
      _showChefRequiredMessage(context, 'Şef Akademisi');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SefAkademiDersleri(
          chefId: currentChefId,
        ),
      ),
    );
  }

  void _openPlaceholder(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PlaceholderPage(
          title: title,
          description: description,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('GASTRONOMI chefId = $chefId | chefName = $chefName');

    final cards = <_DashboardItem>[
      _DashboardItem(
        title: 'Şef İtibar Profili',
        subtitle:
            'Güven, itibar, vitrin, hızlı erişim alanları, kapak ve profil görünümünü yöneten ana merkez.',
        icon: Icons.workspace_premium_rounded,
        onTap: () => _openSefItibarProfili(context),
      ),
      _DashboardItem(
        title: 'Şef Akademisi',
        subtitle:
            'Kurslar, video içerikleri, kategoriler, fiyatlar ve eğitim akışlarını yönetin.',
        icon: Icons.play_lesson_rounded,
        onTap: () => _openSefAkademisi(context),
      ),
      _DashboardItem(
        title: 'Şef Profili',
        subtitle:
            'Premium vitrin, headline, uzmanlık alanları, metrikler ve profil görselleri.',
        icon: Icons.person_rounded,
        onTap: () => _openChefProfileAdmin(context),
      ),
      _DashboardItem(
        title: 'Şef Masası / Rezervasyonlar',
        subtitle:
            'Rezervasyon yönetimi, onay, ödeme bekleniyor ve kesinleşen akışlar.',
        icon: Icons.event_seat_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChefTableReservationsPage(),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'Siparişler / İyzico',
        subtitle:
            'Sipariş akışları, ödeme durumları, timeout ve iyzico süreçleri.',
        icon: Icons.receipt_long_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChefTableReservationsPage(),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'İmza Mutfağı',
        subtitle:
            'İmza tabaklar, vitrin içerikleri ve öne çıkan mutfak koleksiyonu.',
        icon: Icons.restaurant_menu_rounded,
        onTap: () {
          final currentChefId = (chefId ?? '').trim();

          if (currentChefId.isEmpty) {
            _showChefRequiredMessage(context, 'İmza Mutfağı');
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SefItibarSayfasi(
                dukkanId: currentChefId,
                isAdmin: true,
              ),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'Galeri / Medya',
        subtitle:
            'Kapak görselleri, galeri içerikleri, sunum ve etkinlik kareleri.',
        icon: Icons.photo_library_rounded,
        onTap: () {
          final currentChefId = (chefId ?? '').trim();

          if (currentChefId.isEmpty) {
            _showChefRequiredMessage(context, 'Galeri / Medya');
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SefItibarSayfasi(
                dukkanId: currentChefId,
                isAdmin: true,
              ),
            ),
          );
        },
      ),
      _DashboardItem(
        title: 'Kurumsal Davetler / Catering',
        subtitle:
            'Kurumsal çözümler, özel davetler ve catering akışları için hazır modül.',
        icon: Icons.corporate_fare_rounded,
        isComingSoon: true,
        onTap: () => _openPlaceholder(
          context,
          title: 'Kurumsal Davetler / Catering',
          description: 'Bu modül daha sonra aktif edilecek.',
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _gold),
        title: const Text(
          'Gastronomi Yönetim Merkezi',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final int crossAxisCount = width >= 1100
              ? 3
              : width >= 700
                  ? 2
                  : 1;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _HeroIntroCard(
                chefName: chefName,
                chefId: chefId,
              ),
              const SizedBox(height: 16),
              GridView.builder(
                itemCount: cards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: width >= 700 ? 1.35 : 1.18,
                ),
                itemBuilder: (context, index) {
                  final item = cards[index];
                  return _DashboardCard(item: item);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isComingSoon;

  _DashboardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isComingSoon = false,
  });
}

class _HeroIntroCard extends StatelessWidget {
  final String? chefId;
  final String? chefName;

  const _HeroIntroCard({
    this.chefId,
    this.chefName,
  });

  static const Color _panel = Color(0xFF111111);
  static const Color _panel2 = Color(0xFF171717);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _softText = Color(0xFFBDBDBD);
  static const Color _border = Color(0x22FFFFFF);

  @override
  Widget build(BuildContext context) {
    final name = (chefName ?? '').trim();
    final id = (chefId ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        gradient: const LinearGradient(
          colors: [
            _panel2,
            _panel,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GASTRONOMİ YÖNETİM MERKEZİ',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name.isNotEmpty
                ? '$name için Şef İtibar Profili ve gastronomi modülleri tek merkezde.'
                : 'Şef İtibar Profili ve tüm gastronomi modülleri artık tek merkezde.',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Şef itibar profili, akademi, rezervasyonlar, sipariş ve ödeme akışları, imza mutfağı ve medya yönetimini tek ekrandan organize et.',
            style: TextStyle(
              color: _softText,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          if (id.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _border),
              ),
              child: Text(
                'Chef ID: $id',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;

  const _DashboardCard({
    required this.item,
  });

  static const Color _panel = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);
  static const Color _softText = Color(0xFFBDBDBD);
  static const Color _border = Color(0x22FFFFFF);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0x18FFB300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.icon,
                    color: _gold,
                    size: 28,
                  ),
                ),
                const Spacer(),
                if (item.isComingSoon)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _border),
                    ),
                    child: const Text(
                      'Yakında',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white38,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              item.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.subtitle,
              style: const TextStyle(
                color: _softText,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String description;

  const _PlaceholderPage({
    required this.title,
    required this.description,
  });

  static const Color _bg = Colors.black;
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        iconTheme: const IconThemeData(color: _gold),
        title: Text(
          title,
          style: const TextStyle(
            color: _gold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
