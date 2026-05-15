import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/kategori_sayfasi.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/campaign_counter_panel.dart';
import 'package:sofrasofra_arena_v2/modules/auth/satici_admin_giris_sayfasi.dart';
import 'package:sofrasofra_arena_v2/modules/widgets/kurumsal_footer_links.dart';
import 'package:sofrasofra_arena_v2/onboarding/onayli_panel_yonlendirici.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const KategoriSayfasi(),
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
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('site_settings')
                        .doc('home_banner')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final data = snapshot.data?.data();
                      final imageUrl = (data?['imageUrl'] ?? '').toString();

                      if (imageUrl.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: isMobile ? 360 : 520,
                            width: double.infinity,
                            child: Image.network(
                              imageUrl,
                              key: ValueKey(imageUrl),
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, 0.34),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _gold,
                        width: 1.4,
                      ),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOFRASOFRA ARENA',
                          style: TextStyle(
                            color: _gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Evde pişen emek, mahallede değer bulur.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Sofrasofra Arena; Ev Lezzetleri, Usta Şefler, Restoranlar, Kurye Ağı ve Mahalle Mutfak Ağı’nı aynı güvenli gastronomi çatısı altında buluşturur.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 16,
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
                        if (isMobile) ...[
                          _buildCityDropdown(),
                          const SizedBox(height: 14),
                          _buildDistrictDropdown(),
                        ] else
                          Row(
                            children: [
                              Expanded(child: _buildCityDropdown()),
                              const SizedBox(width: 14),
                              Expanded(child: _buildDistrictDropdown()),
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
