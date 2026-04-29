import 'package:flutter/material.dart';

import 'package:sofrasofra_arena_v2/modules/vitrinler/ev_lezzetleri_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/restoranlar_vitrini.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/sef_vitrini_v2.dart';
import 'package:sofrasofra_arena_v2/modules/vitrinler/ev_lezzetleri_vitrini_clean.dart';
import 'package:sofrasofra_arena_v2/modules/radyo/radyo_merkezi_sayfasi.dart';
import 'package:sofrasofra_arena_v2/onboarding/uretici_basvuru_secim_sayfasi.dart';

class KategoriSayfasi extends StatefulWidget {
  const KategoriSayfasi({super.key});

  @override
  State<KategoriSayfasi> createState() => _KategoriSayfasiState();
}

class _KategoriSayfasiState extends State<KategoriSayfasi> {
  static const Color _bg = Color(0xFF0F0F10);
  static const Color _gold = Color(0xFFFFD54F);

  final List<String> _cities = const [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Aksaray',
    'Amasya',
    'Ankara',
    'Antalya',
    'Ardahan',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bartın',
    'Batman',
    'Bayburt',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Düzce',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkâri',
    'Hatay',
    'Iğdır',
    'Isparta',
    'İstanbul',
    'İzmir',
    'Kahramanmaraş',
    'Karabük',
    'Karaman',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırıkkale',
    'Kırklareli',
    'Kırşehir',
    'Kilis',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Mardin',
    'Mersin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Osmaniye',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Şanlıurfa',
    'Şırnak',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Uşak',
    'Van',
    'Yalova',
    'Yozgat',
    'Zonguldak',
    'Kıbrıs',
  ];

  final Map<String, List<String>> _districtMap = const {
    'İstanbul': [
      'Tümü',
      'Kadıköy',
      'Beşiktaş',
      'Şişli',
      'Üsküdar',
      'Bakırköy',
      'Fatih',
      'Ataşehir',
      'Maltepe',
      'Sarıyer',
      'Pendik',
      'Beylikdüzü',
    ],
    'Ankara': [
      'Tümü',
      'Çankaya',
      'Keçiören',
      'Yenimahalle',
      'Mamak',
      'Etimesgut',
      'Sincan',
      'Gölbaşı',
    ],
    'İzmir': [
      'Tümü',
      'Konak',
      'Karşıyaka',
      'Bornova',
      'Buca',
      'Bayraklı',
      'Çeşme',
      'Urla',
    ],
    'Antalya': [
      'Tümü',
      'Muratpaşa',
      'Konyaaltı',
      'Kepez',
      'Alanya',
      'Manavgat',
      'Kaş',
    ],
    'Bursa': [
      'Tümü',
      'Nilüfer',
      'Osmangazi',
      'Yıldırım',
      'Mudanya',
      'Gemlik',
    ],
    'Kıbrıs': [
      'Tümü',
      'Lefkoşa',
      'Girne',
      'Gazimağusa',
      'İskele',
      'Güzelyurt',
    ],
  };

  late String _selectedCity;
  late String _selectedDistrict;

  @override
  void initState() {
    super.initState();
    _selectedCity = 'İstanbul';
    _selectedDistrict = _districtsFor(_selectedCity).first;
  }

  List<String> _districtsFor(String city) {
    return _districtMap[city] ?? const ['Tümü'];
  }

  void _onCityChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedCity = value;
      _selectedDistrict = _districtsFor(value).first;
    });
  }

  void _onDistrictChanged(String? value) {
    if (value == null) return;
    setState(() {
      _selectedDistrict = value;
    });
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 760;
    final horizontal = isMobile ? 16.0 : 28.0;
    final maxContentWidth = isMobile ? size.width : 1240.0;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(horizontal, 18, horizontal, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _TopHeader(
                          city: _selectedCity,
                          district: _selectedDistrict,
                        ),
                        const SizedBox(height: 18),
                        _HeroBanner(
                          isMobile: isMobile,
                          onPrimaryTap: () {
                            _openPage(
                              EvLezzetleriVitrini(
                                city: _selectedCity,
                                district: _selectedDistrict,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        _LocationPanel(
                          cities: _cities,
                          districts: _districtsFor(_selectedCity),
                          selectedCity: _selectedCity,
                          selectedDistrict: _selectedDistrict,
                          onCityChanged: _onCityChanged,
                          onDistrictChanged: _onDistrictChanged,
                        ),
                        const SizedBox(height: 24),
                        const _SectionTitle(
                          title: 'Sofrasofra’nın üç ana ayağı',
                          subtitle:
                              'Platformun ana omurgası: Ev Lezzetleri, Usta Şefler ve Restoranlar.',
                        ),
                        const SizedBox(height: 16),
                        _CategoryGrid(
                          isMobile: isMobile,
                          children: [
                            _MainCategoryCard(
                              title: 'Ev Lezzetleri',
                              badge: 'Ev Mutfağından Gelir',
                              icon: Icons.home_rounded,
                              description:
                                  'Ev kadınları ve üreticiler için sıcak, güvenilir ve gelir odaklı vitrin.',
                              features: const [
                                'Mahalle bazlı görünürlük',
                                'Siparişe hazır vitrin',
                                'Yerel güven ve sıcaklık',
                              ],
                              onTap: () {
                                _openPage(
                                  EvLezzetleriVitrini(
                                    city: _selectedCity,
                                    district: _selectedDistrict,
                                  ),
                                );
                              },
                            ),
                            _MainCategoryCard(
                              title: 'Usta Şefler',
                              badge: 'Premium Deneyim',
                              icon: Icons.workspace_premium_rounded,
                              description:
                                  'Şef profilleri, akademi, davet, catering ve Gastronomi Merkezi geçişi.',
                              features: const [
                                'Şef vitrinleri',
                                'Akademi ve eğitim',
                                'Gastronomi Merkezi erişimi',
                              ],
                              onTap: () {
                                _openPage(const SefVitriniV2());
                              },
                            ),
                            _MainCategoryCard(
                              title: 'Restoranlar',
                              badge: 'Kurumsal Lezzet Ağı',
                              icon: Icons.restaurant_menu_rounded,
                              description:
                                  'Restoranların menü, mutfak, servis ve görünürlük gücünü büyüten alan.',
                              features: const [
                                'Marka vitrini',
                                'Bölgesel keşif',
                                'Premium restoran görünümü',
                              ],
                              onTap: () {
                                _openPage(const RestoranlarVitrini());
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x44FFB300)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kendi Mutfağınızın Patronu Olun',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Ürün sizin, emek sizin.\n'
                                'Kazanç da sizin olacak.\n\n'
                                'Sofrasofra’da satış yaptığınız anda, '
                                'ödemeler gecikmeden hesabınıza aktarılır.\n\n'
                                'Aracı yok, karmaşa yok.\n'
                                'Sadece üretin, kazanın.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Asıl farkı ilk satışınızda göreceksiniz.',
                                style: TextStyle(
                                  color: Color(0xFFFFB300),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _RadioComingSoonCard(isMobile: isMobile),
                        const SizedBox(height: 20),
                        _TrustStoryBlock(isMobile: isMobile),
                        const SizedBox(height: 28),
                        _InfoFooter(
                          city: _selectedCity,
                          district: _selectedDistrict,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String city;
  final String district;

  const _TopHeader({
    required this.city,
    required this.district,
  });

  static const Color _gold = Color(0xFFFFD54F);
  static const Color _soft = Color(0xFFB8BDC7);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_awesome_rounded, color: _gold, size: 22),
            SizedBox(width: 10),
            Text(
              'Sofrasofra',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF17181C),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x22FFD54F)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_on_rounded, color: _gold, size: 18),
              const SizedBox(width: 8),
              Text(
                '$city • $district',
                style: const TextStyle(
                  color: _soft,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final bool isMobile;
  final VoidCallback onPrimaryTap;

  const _HeroBanner({
    required this.isMobile,
    required this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B1D22),
            Color(0xFF111214),
            Color(0xFF191409),
          ],
        ),
        border: Border.all(color: const Color(0x30FFD54F)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroTextBlock(),
                const SizedBox(height: 22),
                _HeroActionBlock(onPrimaryTap: onPrimaryTap),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  flex: 7,
                  child: _HeroTextBlock(),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: _HeroActionBlock(onPrimaryTap: onPrimaryTap),
                ),
              ],
            ),
    );
  }
}

class _HeroTextBlock extends StatelessWidget {
  const _HeroTextBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SizedBox(height: 16),
        Text(
          'Ev Lezzetlerinden\nUsta Şeflere uzanan\npremium gastronomi platformu',
          style: TextStyle(
            color: Colors.white,
            height: 1.08,
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Sofrasofra; ev üreticilerini, usta şefleri ve restoranları aynı çatı altında görünür, güvenilir ve kazanç odaklı biçimde bir araya getirir.',
          style: TextStyle(
            color: Color(0xFFB8BDC7),
            fontSize: 15.5,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _HeroActionBlock extends StatelessWidget {
  final VoidCallback onPrimaryTap;

  const _HeroActionBlock({
    required this.onPrimaryTap,
  });

  static const Color _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x24FFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hemen başlayın',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Şehrinizi seçin, bölgenizi netleştirin ve ana kategorilerden giriş yapın.',
            style: TextStyle(
              color: Color(0xFFB8BDC7),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPrimaryTap,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Ev Lezzetleri ile Başla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '30 gün ücretsiz deneyim • premium görünüm • bölgesel keşif',
            style: TextStyle(
              color: Color(0xFF8E949E),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPanel extends StatelessWidget {
  final List<String> cities;
  final List<String> districts;
  final String selectedCity;
  final String selectedDistrict;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onDistrictChanged;

  const _LocationPanel({
    required this.cities,
    required this.districts,
    required this.selectedCity,
    required this.selectedDistrict,
    required this.onCityChanged,
    required this.onDistrictChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 760;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF17181C),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0x20FFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konum seçimi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ev Lezzetleri, Usta Şefler ve Restoranlar görünümünü seçtiğiniz konuma göre yönlendirin.',
            style: TextStyle(
              color: Color(0xFFB8BDC7),
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          isMobile
              ? Column(
                  children: [
                    _DropdownField(
                      label: 'Şehir',
                      value: selectedCity,
                      items: cities,
                      onChanged: onCityChanged,
                    ),
                    const SizedBox(height: 12),
                    _DropdownField(
                      label: 'İlçe / Bölge',
                      value: selectedDistrict,
                      items: districts,
                      onChanged: onDistrictChanged,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _DropdownField(
                        label: 'Şehir',
                        value: selectedCity,
                        items: cities,
                        onChanged: onCityChanged,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _DropdownField(
                        label: 'İlçe / Bölge',
                        value: selectedDistrict,
                        items: districts,
                        onChanged: onDistrictChanged,
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniInfoChip(
                icon: Icons.place_rounded,
                text: 'Mahalle ve bölge uyumu',
              ),
              _MiniInfoChip(
                icon: Icons.storefront_rounded,
                text: 'Yerel keşif önceliği',
              ),
              _MiniInfoChip(
                icon: Icons.workspace_premium_rounded,
                text: 'Premium vitrin akışı',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  static const Color _gold = Color(0xFFFFD54F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x22FFD54F)),
      ),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFFB8BDC7),
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
        ),
        dropdownColor: const Color(0xFF1D1F24),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _gold),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFFB8BDC7),
            fontSize: 14.5,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final bool isMobile;
  final List<Widget> children;

  const _CategoryGrid({
    required this.isMobile,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }
}

class _MainCategoryCard extends StatefulWidget {
  final String title;
  final String badge;
  final IconData icon;
  final String description;
  final List<String> features;
  final VoidCallback onTap;

  const _MainCategoryCard({
    required this.title,
    required this.badge,
    required this.icon,
    required this.description,
    required this.features,
    required this.onTap,
  });

  @override
  State<_MainCategoryCard> createState() => _MainCategoryCardState();
}

class _MainCategoryCardState extends State<_MainCategoryCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()..translate(0.0, _hover ? -4.0 : 0.0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF17181C),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _hover ? const Color(0x44FFD54F) : const Color(0x22FFD54F),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hover ? 0.30 : 0.18),
              blurRadius: _hover ? 28 : 18,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GoldChip(label: widget.badge),
            const SizedBox(height: 16),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0x14FFD54F),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x33FFD54F)),
              ),
              child: Icon(
                widget.icon,
                color: const Color(0xFFFFD54F),
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              style: const TextStyle(
                color: Color(0xFFB8BDC7),
                fontSize: 14.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.features.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFFFFD54F),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Color(0xFFE6E8EC),
                          fontSize: 13.8,
                          height: 1.45,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: widget.onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD54F),
                  side: const BorderSide(color: Color(0x55FFD54F)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Bu alana gir',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoStrip extends StatelessWidget {
  final bool isMobile;

  const _PromoStrip({
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final cards = const [
      _PromoItem(
        icon: Icons.card_giftcard_rounded,
        title: '30 gün ücretsiz deneyim',
        text: 'Başlangıç bariyerini kaldıran güçlü bir giriş alanı.',
      ),
      _PromoItem(
        icon: Icons.groups_rounded,
        title: 'İlk 100 aboneye 1 yıl ücretsiz',
        text: 'Erken topluluk etkisini büyüten, net ve güçlü teklif.',
      ),
      _PromoItem(
        icon: Icons.auto_graph_rounded,
        title: 'Kazanç odaklı yapı',
        text: 'Sadece güzel görünen değil, gelir getiren ürün mimarisi.',
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 18),
      decoration: BoxDecoration(
        color: const Color(0xFF17181C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x20FFD54F)),
      ),
      child: isMobile
          ? Column(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  cards[i],
                  if (i != cards.length - 1) const SizedBox(height: 12),
                ],
              ],
            )
          : Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i != cards.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
    );
  }
}

class _PromoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _PromoItem({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x18FFD54F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0x14FFD54F),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFFFD54F), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFB8BDC7),
                    fontSize: 13.2,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioComingSoonCard extends StatelessWidget {
  final bool isMobile;

  const _RadioComingSoonCard({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x33FFB300)),
      ),
      child: isMobile
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RadioTextBlock(),
                SizedBox(height: 18),
                _RadioVisual(),
              ],
            )
          : const Row(
              children: [
                Expanded(flex: 7, child: _RadioTextBlock()),
                SizedBox(width: 20),
                Expanded(flex: 3, child: _RadioVisual()),
              ],
            ),
    );
  }
}

class _RadioTextBlock extends StatelessWidget {
  const _RadioTextBlock();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const RadyoMerkeziSayfasi(),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0x22FFB300),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x55FFB300)),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Color(0xFFFFB300),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.graphic_eq_rounded,
                color: Color(0xFFFFB300),
                size: 22,
              ),
              const SizedBox(width: 10),
              const _GoldChip(label: 'Sofrasofra Radyo'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'CANLI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Dinleyerek öğrenen kullanıcılar için sesli rehber akışı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Platforma nasıl abone olunur, nasıl kullanılır, nasıl satış yapılır gibi kritik alanlar sesli anlatımla desteklenecek.',
            style: TextStyle(
              color: Color(0xFFB8BDC7),
              fontSize: 14.2,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Şu an yayında ▶',
            style: TextStyle(
              color: Color(0xFFFFB300),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioVisual extends StatelessWidget {
  const _RadioVisual();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F24),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x22FFD54F)),
      ),
      child: const Center(
        child: Icon(
          Icons.radio_rounded,
          color: Color(0xFFFFD54F),
          size: 44,
        ),
      ),
    );
  }
}

class _TrustStoryBlock extends StatelessWidget {
  final bool isMobile;

  const _TrustStoryBlock({
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 18 : 22),
      decoration: BoxDecoration(
        color: const Color(0xFF17181C),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x20FFD54F)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _StoryTextBlock(),
                SizedBox(height: 16),
                _StoryStats(),
              ],
            )
          : Row(
              children: const [
                Expanded(flex: 7, child: _StoryTextBlock()),
                SizedBox(width: 18),
                Expanded(flex: 4, child: _StoryStats()),
              ],
            ),
    );
  }
}

class _StoryTextBlock extends StatelessWidget {
  const _StoryTextBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _GoldChip(label: 'Güven ve hikâye'),
        SizedBox(height: 14),
        Text(
          'Basit görünen ama derinliği yüksek bir ana sayfa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Bu yapı; yalnızca navigasyon değil, güven veren bir giriş deneyimi kurar. Kullanıcı ilk bakışta neye tıklayacağını, neden burada olduğunu ve nasıl kazanacağını anlar.',
          style: TextStyle(
            color: Color(0xFFB8BDC7),
            fontSize: 14.2,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _StoryStats extends StatelessWidget {
  const _StoryStats();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _StatTile(
          title: '3 Ana Ayak',
          subtitle: 'Ev Lezzetleri • Usta Şefler • Restoranlar',
        ),
        SizedBox(height: 12),
        _StatTile(
          title: 'Premium Hissiyat',
          subtitle: 'Altın vurgu • ferah bloklar • derin vitrin',
        ),
        SizedBox(height: 12),
        _StatTile(
          title: 'Kazanç Mantığı',
          subtitle: 'Abonelik, görünürlük ve dönüşüm odaklı',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _StatTile({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x18FFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFFD54F),
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFFB8BDC7),
              fontSize: 13.2,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoFooter extends StatelessWidget {
  final String city;
  final String district;

  const _InfoFooter({
    required this.city,
    required this.district,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Color(0x18FFFFFF), height: 1),
        const SizedBox(height: 18),
        Text(
          'Aktif konum: $city / $district',
          style: const TextStyle(
            color: Color(0xFFB8BDC7),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sofrasofra • Ev Lezzetleri • Usta Şefler • Restoranlar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7F8690),
            fontSize: 12.8,
          ),
        ),
      ],
    );
  }
}

class _GoldChip extends StatelessWidget {
  final String label;

  const _GoldChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x14FFD54F),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x40FFD54F)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFFD54F),
          fontSize: 12.6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x16FFD54F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFFD54F)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFE6E8EC),
              fontSize: 12.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
