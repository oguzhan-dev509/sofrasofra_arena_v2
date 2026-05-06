import 'package:flutter/material.dart';

class SefMembershipCard extends StatelessWidget {
  final String membershipType;
  final bool isLoading;
  final int galleryLimit;
  final int videoLimit;
  final VoidCallback onTapUpgrade;

  const SefMembershipCard({
    super.key,
    required this.membershipType,
    required this.isLoading,
    required this.galleryLimit,
    required this.videoLimit,
    required this.onTapUpgrade,
  });

  static const Color gold = Color(0xFFFFB300);

  String _planTitle() {
    switch (membershipType.toLowerCase()) {
      case 'premium':
        return 'Premium';
      case 'pro':
        return 'Pro';
      default:
        return 'Ücretsiz';
    }
  }

  String _upgradeTitle() {
    switch (membershipType.toLowerCase()) {
      case 'pro':
        return "Premium'a yükselt";
      case 'premium':
        return 'Premium aktif';
      default:
        return "PRO'ya yükselt";
    }
  }

  String _upgradeSubtitle() {
    switch (membershipType.toLowerCase()) {
      case 'pro':
        return '32 galeri fotoğrafı + 3 tanıtım video linki + eğitim videoları ücretsiz + vitrin önceliği';
      case 'premium':
        return 'En yüksek görünürlük paketi aktif';
      default:
        return '12 galeri fotoğrafı + 1 tanıtım video linki + eğitim videoları ücretsiz + daha güçlü görünürlük';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ŞEF PAKETİ',
            style: TextStyle(
              color: gold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isLoading ? 'Yükleniyor...' : 'Paket: ${_planTitle()}',
            style: const TextStyle(
              color: gold,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Galeri hakkı: $galleryLimit',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tanıtım video hakkı: $videoLimit',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Akademi videoları link tabanlıdır ve daha esnek yönetilir.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _buildCta(context),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    if (membershipType.toLowerCase() == 'premium') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: const [
            Icon(Icons.workspace_premium_rounded, color: gold, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Premium aktif · En yüksek görünürlük paketi',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => showChefPlanSheet(context, membershipType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: gold, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _upgradeTitle(),
                    style: const TextStyle(
                      color: gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _upgradeSubtitle(),
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: gold),
          ],
        ),
      ),
    );
  }
}

/// BOTTOM SHEET
void showChefPlanSheet(BuildContext context, String membershipType) {
  const gold = Color(0xFFFFB300);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111111),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        builder: (context, controller) {
          return SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: SizedBox(
                    width: 40,
                    child: Divider(thickness: 3, color: Colors.white24),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Şef Paketleri',
                  style: TextStyle(
                    color: gold,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _plan(
                  'Ücretsiz',
                  [
                    'Aylık: 0 TL',
                    'Komisyon: %12',
                    '6 galeri fotoğrafı',
                    '0 tanıtım videosu',
                    'Eğitim videoları ücretsiz',
                    'Temel görünürlük',
                  ],
                  membershipType == 'free',
                ),
                _plan(
                  'Pro',
                  [
                    'Aylık: 249 TL',
                    'Komisyon: %6',
                    '12 galeri fotoğrafı',
                    '1 tanıtım video linki',
                    'Eğitim videoları ücretsiz',
                    'Daha güçlü görünürlük',
                  ],
                  membershipType == 'pro',
                ),
                _plan(
                  'Premium',
                  [
                    'Aylık: 499 TL',
                    'Komisyon: %3',
                    '32 galeri fotoğrafı',
                    '3 tanıtım video linki',
                    'Eğitim videoları ücretsiz',
                    'Vitrin önceliği',
                  ],
                  membershipType == 'premium',
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Pro & Premium açıldığında sana haber vereceğiz'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Erken erişim listesine katıl'),
                )
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _plan(String title, List<String> items, bool active) {
  return Container(
    width: double.infinity,
    constraints: const BoxConstraints(
      minHeight: 178,
    ),
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFF181818),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: active ? const Color(0xFFFFB300) : Colors.white12,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
              color: active ? const Color(0xFFFFB300) : Colors.white,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 6),
        for (var e in items)
          Text('• $e',
              style: const TextStyle(color: Colors.white70, fontSize: 12))
      ],
    ),
  );
}
