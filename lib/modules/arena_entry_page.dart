import 'package:flutter/material.dart';

import 'package:sofrasofra_arena_v2/modules/widgets/campaign_counter_panel.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sofrasofra_pazaryeri_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/auth/satici_admin_giris_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/kurumsal_footer_links.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/kurumsal_site_card.dart';
import 'package:sofrasofra_arena_v2/onboarding/onayli_panel_yonlendirici.dart';

import 'dart:convert';
import 'package:sofrasofra_arena_v2/modules/kurumsal/mahalle_mutfak_kocu_basvuru_sayfasi.dart';
import 'package:flutter/services.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/sofrasofra_ana_modul_gecisleri_section.dart';

import 'package:sofrasofra_arena_v2/modules/restoranlar/restoran_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/ev_lezzetleri_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/sef_vitrini_v2.dart';
import 'package:sofrasofra_arena_v2/modules/kurye_basvuru_formu.dart';

class ArenaEntryPage extends StatefulWidget {
  const ArenaEntryPage({super.key});

  @override
  State<ArenaEntryPage> createState() => _ArenaEntryPageState();
}

class _ArenaEntryPageState extends State<ArenaEntryPage> {
  static const Color _bg = Color(0xFF0D0D0D);
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _text = Colors.white;
  static const Color _muted = Color(0xFFB6ADA0);
  static const Color _panel = Color(0xFF151515);

  Map<String, List<String>> _cityDistricts = const {
    'İstanbul': [
      'Adalar',
      'Arnavutköy',
      'Ataşehir',
      'Avcılar',
      'Bağcılar',
      'Bahçelievler',
      'Bakırköy',
      'Başakşehir',
      'Bayrampaşa',
      'Beşiktaş',
      'Beykoz',
      'Beylikdüzü',
      'Beyoğlu',
      'Büyükçekmece',
      'Çatalca',
      'Çekmeköy',
      'Esenler',
      'Esenyurt',
      'Eyüpsultan',
      'Fatih',
      'Gaziosmanpaşa',
      'Güngören', // 🔥 SENİN İLÇE
      'Kadıköy',
      'Kağıthane',
      'Kartal',
      'Küçükçekmece',
      'Maltepe',
      'Pendik',
      'Sancaktepe',
      'Sarıyer',
      'Silivri',
      'Sultanbeyli',
      'Sultangazi',
      'Şile',
      'Şişli',
      'Tuzla',
      'Ümraniye',
      'Üsküdar',
      'Zeytinburnu',
    ],
    'Ankara': [
      'Akyurt',
      'Altındağ',
      'Ayaş',
      'Bala',
      'Beypazarı',
      'Çamlıdere',
      'Çankaya',
      'Çubuk',
      'Elmadağ',
      'Etimesgut',
      'Evren',
      'Gölbaşı',
      'Güdül',
      'Haymana',
      'Kalecik',
      'Kazan',
      'Keçiören',
      'Kızılcahamam',
      'Mamak',
      'Nallıhan',
      'Polatlı',
      'Pursaklar',
      'Sincan',
      'Şereflikoçhisar',
      'Yenimahalle',
    ],
    'İzmir': [
      'Aliağa',
      'Balçova',
      'Bayındır',
      'Bayraklı',
      'Bergama',
      'Bornova',
      'Buca',
      'Çeşme',
      'Çiğli',
      'Dikili',
      'Foça',
      'Gaziemir',
      'Güzelbahçe',
      'Karabağlar',
      'Karaburun',
      'Karşıyaka',
      'Kemalpaşa',
      'Kınık',
      'Kiraz',
      'Konak',
      'Menderes',
      'Menemen',
      'Narlıdere',
      'Ödemiş',
      'Seferihisar',
      'Selçuk',
      'Tire',
      'Torbalı',
      'Urla',
    ],
    'Bursa': [
      'Gemlik',
      'İnegöl',
      'Mudanya',
      'Nilüfer',
      'Osmangazi',
      'Yıldırım',
    ],
    'Antalya': [
      'Alanya',
      'Aksu',
      'Döşemealtı',
      'Kepez',
      'Konyaaltı',
      'Manavgat',
      'Muratpaşa',
      'Serik',
    ],
    'Adana': ['Çukurova', 'Sarıçam', 'Seyhan', 'Yüreğir'],
    'Mersin': ['Akdeniz', 'Erdemli', 'Mezitli', 'Toroslar', 'Yenişehir'],
    'Gaziantep': ['Nizip', 'Şahinbey', 'Şehitkamil'],
    'Konya': ['Karatay', 'Meram', 'Selçuklu'],
    'Muğla': ['Bodrum', 'Fethiye', 'Marmaris', 'Milas'],
    'Trabzon': ['Akçaabat', 'Ortahisar', 'Yomra'],
    'Kıbrıs': ['Lefkoşa', 'Girne', 'Gazimağusa', 'İskele', 'Güzelyurt'],
  };
  String? _selectedCity;
  String? _selectedDistrict;
  String _selectedModule = 'ev_lezzetleri';
  @override
  void initState() {
    super.initState();
    _loadCityDistricts();
  }

  Future<void> _loadCityDistricts() async {
    try {
      final raw = await rootBundle.loadString('assets/ilceler.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      final parsed = decoded.map(
        (key, value) {
          final cityName = _formatCityName(key.toString());
          final districts = (value as List)
              .map((e) => _formatDistrictName(e.toString()))
              .toList();

          return MapEntry(cityName, districts);
        },
      );

      if (!mounted) return;

      setState(() {
        _cityDistricts = Map<String, List<String>>.from(parsed);

        if (_selectedCity != null &&
            !_cityDistricts.containsKey(_selectedCity)) {
          _selectedCity = null;
          _selectedDistrict = null;
        }
      });
    } catch (e) {
      debugPrint('Ana giriş il/ilçe listesi yüklenemedi: $e');
    }
  }

  String _formatCityName(String raw) {
    final text = raw.trim();

    if (text == 'K.K.T.C.') return 'Kıbrıs';

    return text.toLowerCase().split(' ').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }

  String _formatDistrictName(String raw) {
    final text = raw.trim();

    return text.toLowerCase().split(' ').map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    }).join(' ');
  }

  List<String> get _cities {
    final list = _cityDistricts.keys.toList()..sort();
    if (list.contains('Kıbrıs')) {
      list.remove('Kıbrıs');
      list.add('Kıbrıs');
    }
    return list;
  }

  List<String> get _districts {
    if (_selectedCity == null) return const [];
    return _cityDistricts[_selectedCity] ?? const [];
  }

  void _continueSelection() {
    if (_selectedCity == null || _selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen önce şehir ve ilçe seçin.'),
        ),
      );
      return;
    }

    final city = _selectedCity!;
    final district = _selectedDistrict!;

    Widget targetPage;

    switch (_selectedModule) {
      case 'usta_sefler':
        targetPage = const SefVitriniV2();
        break;
      case 'restoranlar':
        targetPage = const PremiumRestoranVitrini();
        break;
      case 'ev_lezzetleri':
      default:
        targetPage = EvLezzetleriVitrini(
          city: city,
          district: district,
        );
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => targetPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SofrasofraPazaryeriVitrini(),
                  const SizedBox(height: 24),
                  const SofrasofraAnaModulGecisleriSection(),
                  const SizedBox(height: 24),
                  const _CourierFounderBanner(),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _gold,
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _gold.withValues(alpha: 0.08),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.groups_rounded,
                              color: _gold,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'MAHALLE MUTFAK KOÇU OL',
                                style: TextStyle(
                                  color: _gold,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Ev Lezzetleri üreticilerini, Usta Şefleri ve mahalle restoranlarını Sofrasofra’ya kazandır.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.35,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _CoachRewardBadge(
                              icon: Icons.verified_rounded,
                              text: 'Onaylı başvuru: 100 TL',
                            ),
                            _CoachRewardBadge(
                              icon: Icons.shopping_bag_rounded,
                              text: 'İlk satış: +250 TL',
                            ),
                            _CoachRewardBadge(
                              icon: Icons.workspace_premium_rounded,
                              text: 'Aylık bonus ve ilçe liderliği',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MahalleMutfakKocuBasvuruSayfasi(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text(
                              'HEMEN BAŞVUR',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CampaignCounterPanel(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _gold.withValues(alpha: 0.20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hangi Şehirdeyiz?',
                          style: TextStyle(
                            color: _text,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Şehrinizi ve ilçenizi seçin. Size en uygun bölgesel ağı görelim.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 18),
                        isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildCityDropdown(),
                                  const SizedBox(height: 14),
                                  _buildDistrictDropdown(),
                                  const SizedBox(height: 14),
                                  _buildModuleDropdown(),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(child: _buildCityDropdown()),
                                  const SizedBox(width: 14),
                                  Expanded(child: _buildDistrictDropdown()),
                                  const SizedBox(width: 14),
                                  Expanded(child: _buildModuleDropdown()),
                                ],
                              ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: _continueSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Bölgedeki seçenekleri gör',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _gold.withValues(alpha: 0.20)),
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Üretici Girişi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ev Lezzetleri, Şefler ve restoranlar için başvuru ve kurulum alanı',
                                style: TextStyle(color: _muted),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const OnayliPanelYonlendirici(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _gold,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Üretici Girişi'),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SaticiAdminGirisSayfasi(),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _gold,
                                      side: const BorderSide(color: _gold),
                                    ),
                                    child: const Text('Yetkili Giriş'),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Üretici Girişi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Ev Lezzetleri, Şefler ve restoranlar için başvuru ve kurulum alanı',
                                      style: TextStyle(color: _muted),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const OnayliPanelYonlendirici(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _gold,
                                      foregroundColor: Colors.black,
                                    ),
                                    child: const Text('Üretici Girişi'),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SaticiAdminGirisSayfasi(),
                                        ),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _gold,
                                      side: const BorderSide(color: _gold),
                                    ),
                                    child: const Text('Yetkili Giriş'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 28),
                  const KurumsalSiteCard(),
                  const SizedBox(height: 18),
                  const KurumsalFooterLinks(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.16)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCity,
        isExpanded: true,
        menuMaxHeight: 320,
        dropdownColor: const Color(0xFF1C1C1C),
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: 'Şehir seçin',
          labelStyle: TextStyle(color: _muted),
        ),
        style: const TextStyle(
          color: _text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        items: _cities
            .map(
              (city) => DropdownMenuItem<String>(
                value: city,
                child: Text(city),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;

          final districts = _cityDistricts[value] ?? const <String>[];

          setState(() {
            _selectedCity = value;
            _selectedDistrict = districts.isNotEmpty ? districts.first : null;
          });
        },
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    final enabled = _selectedCity != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? _gold.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value:
            _districts.contains(_selectedDistrict) ? _selectedDistrict : null,
        isExpanded: true,
        menuMaxHeight: 320,
        dropdownColor: const Color(0xFF1C1C1C),
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: 'İlçe seçin',
          labelStyle: TextStyle(color: _muted),
        ),
        style: const TextStyle(
          color: _text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        items: _districts
            .map(
              (district) => DropdownMenuItem<String>(
                value: district,
                child: Text(district),
              ),
            )
            .toList(),
        onChanged: enabled
            ? (value) {
                setState(() {
                  _selectedDistrict = value;
                });
              }
            : null,
      ),
    );
  }

  Widget _buildModuleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.16)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedModule,
        isExpanded: true,
        menuMaxHeight: 320,
        dropdownColor: const Color(0xFF1C1C1C),
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: 'Alan seçin',
          labelStyle: TextStyle(color: _muted),
        ),
        style: const TextStyle(
          color: _text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        items: const [
          DropdownMenuItem<String>(
            value: 'ev_lezzetleri',
            child: Text('Ev Lezzetleri'),
          ),
          DropdownMenuItem<String>(
            value: 'usta_sefler',
            child: Text('Usta Şefler'),
          ),
          DropdownMenuItem<String>(
            value: 'restoranlar',
            child: Text('Restoranlar'),
          ),
        ],
        onChanged: (value) {
          if (value == null) return;

          setState(() {
            _selectedModule = value;
          });
        },
      ),
    );
  }
}

// ignore: unused_element
class _HomeBannerImage extends StatelessWidget {
  final String imageUrl;

  const _HomeBannerImage({
    required this.imageUrl,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          imageUrl,
          fit: BoxFit.cover,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Positioned(
          top: 18,
          right: 18,
          child: Text(
            'SOFRASOFRA.COM',
            style: TextStyle(
              color: _gold,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.75),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CoachRewardBadge extends StatelessWidget {
  const _CoachRewardBadge({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  static const Color _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: _gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _gold.withValues(alpha: 0.34),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _gold,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CourierFounderBanner extends StatelessWidget {
  const _CourierFounderBanner();

  static const Color _gold = Color(0xFFFFB300);
  static const Color _text = Colors.white;
  static const Color _muted = Color(0xFFB6ADA0);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold.withValues(alpha: 0.42),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2109),
            Color(0xFF151515),
            Color(0xFF090909),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 720;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delivery_dining_rounded,
                    color: _gold,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'İlk 300 Kurye İçin 3 Ay Komisyonsuz Başlangıç',
                      style: TextStyle(
                        color: _text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.18,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'Mahallende teslimat ağına katıl, Sofrasofra siparişlerinden gelir elde et.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          );

          final button = ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KuryeBasvuruFormu(),
                ),
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Kurye Başvurusu Yap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                const SizedBox(height: 18),
                button,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }
}
