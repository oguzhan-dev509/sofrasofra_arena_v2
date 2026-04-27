import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/kategori_sayfasi.dart';

import '../merchant/uretici_yonetim_merkezi_sayfasi.dart';
import 'package:sofrasofra_arena_v2/onboarding/onayli_panel_yonlendirici.dart';

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

  final Map<String, List<String>> _cityDistricts = const {
    'İstanbul': [
      'Adalar',
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
      'Çekmeköy',
      'Esenyurt',
      'Eyüpsultan',
      'Fatih',
      'Kadıköy',
      'Kartal',
      'Kağıthane',
      'Küçükçekmece',
      'Maltepe',
      'Pendik',
      'Sancaktepe',
      'Sarıyer',
      'Silivri',
      'Şişli',
      'Tuzla',
      'Ümraniye',
      'Üsküdar',
      'Zeytinburnu',
    ],
    'Ankara': [
      'Altındağ',
      'Çankaya',
      'Etimesgut',
      'Keçiören',
      'Mamak',
      'Pursaklar',
      'Sincan',
      'Yenimahalle',
    ],
    'İzmir': [
      'Aliağa',
      'Balçova',
      'Bayraklı',
      'Bornova',
      'Buca',
      'Çeşme',
      'Gaziemir',
      'Karabağlar',
      'Karşıyaka',
      'Konak',
      'Menemen',
      'Narlıdere',
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
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _gold.withValues(alpha: 0.20)),
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
                          'Türkiye’nin seçkin gastronomi ağına hoş geldiniz',
                          style: TextStyle(
                            color: _text,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Ev Lezzetleri, Usta Şefler ve Restoranlar için güçlü bir platform.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: const Color(0xFF2A2114),
                      border: Border.all(color: _gold.withValues(alpha: 0.30)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İlk 100 aboneye 1 yıl ücretsiz',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '30 gün ücretsiz deneyin',
                          style: TextStyle(
                            color: Color(0xFFE6DCCB),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                                child: const Text('Giriş'),
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
                                child: const Text('Giriş'),
                              ),
                            ],
                          ),
                  ),
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
          setState(() {
            _selectedCity = value;
            _selectedDistrict = null;
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
        value: _selectedDistrict,
        isExpanded: true,
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
