import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sofrasofra_arena_v2/services/sofrasofra_radio_service.dart';

class SofrasofraRadyoBolumu extends StatefulWidget {
  const SofrasofraRadyoBolumu({
    super.key,
    this.padding = const EdgeInsets.all(18),
    this.maxPrograms,
    this.showRefreshButton = true,
  });

  final EdgeInsets padding;
  final int? maxPrograms;
  final bool showRefreshButton;

  @override
  State<SofrasofraRadyoBolumu> createState() => _SofrasofraRadyoBolumuState();
}

class _SofrasofraRadyoBolumuState extends State<SofrasofraRadyoBolumu> {
  final SofrasofraRadioService _radio = SofrasofraRadioService.instance;

  String _selectedCategory = 'tum';

  static const Color _gold = Color(0xFFFFB300);

  static const List<_RadioCategory> _categories = [
    _RadioCategory(label: 'Tümü', value: 'tum'),
    _RadioCategory(label: 'Ev Lezzetleri', value: 'ev_lezzetleri'),
    _RadioCategory(label: 'Usta Şefler', value: 'usta_sefler'),
    _RadioCategory(label: 'Restoranlar', value: 'restoranlar'),
    _RadioCategory(label: 'Kurye', value: 'kurye'),
  ];

  @override
  void initState() {
    super.initState();
    _radio.prepare().catchError((e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Radyo hazırlanamadı: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    });
  }

  String _normalizeCategory(String raw) {
    final value = raw
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');

    if (value == 'ev' || value == 'ev_lezzeti' || value == 'ev_lezzetleri') {
      return 'ev_lezzetleri';
    }

    if (value == 'usta_sef' ||
        value == 'usta_sefler' ||
        value == 'usta_sefleri' ||
        value == 'sef' ||
        value == 'sefler' ||
        value == 'sefleri') {
      return 'usta_sefler';
    }

    if (value == 'restoran' ||
        value == 'restoranlar' ||
        value == 'restaurant' ||
        value == 'restaurants') {
      return 'restoranlar';
    }

    if (value == 'kurye' || value == 'kuryeler' || value == 'kurye_agi') {
      return 'kurye';
    }

    return value.isEmpty ? 'genel' : value;
  }

  List<RadioProgram> _filteredPrograms(List<RadioProgram> all) {
    if (_selectedCategory == 'tum') return all;

    return all
        .where((e) => _normalizeCategory(e.kategori) == _selectedCategory)
        .toList();
  }

  int _globalIndexOf(RadioProgram program) {
    return _radio.programs.value.indexWhere((e) => e.id == program.id);
  }

  Future<void> _togglePlay() async {
    try {
      await _radio.togglePlay();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Radyo başlatılamadı: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _playProgram(RadioProgram program) async {
    final index = _globalIndexOf(program);
    if (index < 0) return;

    try {
      await _radio.playProgram(index);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yayın açılamadı: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _refreshPrograms() async {
    try {
      await _radio.refresh();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yayın listesi yenilenemedi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _radio.loading,
      builder: (context, loading, _) {
        return ValueListenableBuilder<List<RadioProgram>>(
          valueListenable: _radio.programs,
          builder: (context, programs, _) {
            final filtered = _filteredPrograms(programs);
            final visiblePrograms = widget.maxPrograms == null
                ? filtered
                : filtered.take(widget.maxPrograms!).toList();

            return Padding(
              padding: widget.padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroRadioCard(
                    loading: loading,
                    radio: _radio,
                    onTogglePlay: _togglePlay,
                  ),
                  const SizedBox(height: 18),
                  _CategoryTabs(
                    selectedCategory: _selectedCategory,
                    categories: _categories,
                    onChanged: (value) {
                      setState(() => _selectedCategory = value);
                    },
                  ),
                  if (widget.showRefreshButton) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: loading ? null : _refreshPrograms,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Yayınları Yenile'),
                        style: TextButton.styleFrom(
                          foregroundColor: _gold,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _NowPlayingCard(radio: _radio),
                  const SizedBox(height: 18),
                  _ProgramList(
                    programs: visiblePrograms,
                    radio: _radio,
                    onPlayProgram: _playProgram,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HeroRadioCard extends StatelessWidget {
  final bool loading;
  final SofrasofraRadioService radio;
  final VoidCallback onTogglePlay;

  const _HeroRadioCard({
    required this.loading,
    required this.radio,
    required this.onTogglePlay,
  });

  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x44FFB300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sofrasofra Radyo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ev Lezzetleri, Usta Şefler, Restoranlar ve Kurye ağı için gastronomi yayınları.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          StreamBuilder<PlayerState>(
            stream: radio.player.playerStateStream,
            builder: (context, snapshot) {
              final playing = radio.player.playing;

              return SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : onTogglePlay,
                  icon: Icon(
                    loading
                        ? Icons.hourglass_top_rounded
                        : playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    loading
                        ? 'Radyo hazırlanıyor...'
                        : playing
                            ? 'Yayını Durdur'
                            : 'Yayını Başlat',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final String selectedCategory;
  final List<_RadioCategory> categories;
  final ValueChanged<String> onChanged;

  const _CategoryTabs({
    required this.selectedCategory,
    required this.categories,
    required this.onChanged,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = categories[index];
          final selected = item.value == selectedCategory;

          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(item.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _gold : const Color(0xFF151515),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? _gold : const Color(0x22FFFFFF),
                ),
              ),
              child: Text(
                item.label,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final SofrasofraRadioService radio;

  const _NowPlayingCard({required this.radio});

  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Şu an yayında',
            style: TextStyle(
              color: _gold,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<int?>(
            stream: radio.player.currentIndexStream,
            builder: (context, snapshot) {
              final index = snapshot.data ?? 0;
              final programs = radio.programs.value;

              if (programs.isEmpty || index >= programs.length) {
                return const Text(
                  'Yayın bulunamadı',
                  style: TextStyle(color: Colors.white60),
                );
              }

              return Text(
                programs[index].title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Bu yayın, yeni kullanıcıların platformu hızlı anlaması için hazırlanmıştır.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramList extends StatelessWidget {
  final List<RadioProgram> programs;
  final SofrasofraRadioService radio;
  final ValueChanged<RadioProgram> onPlayProgram;

  const _ProgramList({
    required this.programs,
    required this.radio,
    required this.onPlayProgram,
  });

  static const Color _card = Color(0xFF151515);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x22FFFFFF)),
        ),
        child: const Text(
          'Bu kategoride henüz yayın yok.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yayın Listesi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<int?>(
          stream: radio.player.currentIndexStream,
          builder: (context, snapshot) {
            final currentIndex = snapshot.data ?? -1;
            final allPrograms = radio.programs.value;

            return Column(
              children: programs.map((program) {
                final globalIndex =
                    allPrograms.indexWhere((e) => e.id == program.id);
                final selected = globalIndex == currentIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () => onPlayProgram(program),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected
                              ? const Color(0x88FFB300)
                              : const Color(0x22FFFFFF),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: selected ? _gold : const Color(0xFF202020),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              selected
                                  ? Icons.graphic_eq_rounded
                                  : Icons.play_arrow_rounded,
                              color: selected ? Colors.black : _gold,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  program.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_categoryLabel(program.kategori)} • Sıra ${program.order}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? _gold : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _gold),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  selected
                                      ? Icons.volume_up_rounded
                                      : Icons.play_arrow_rounded,
                                  color: selected ? Colors.black : _gold,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  selected ? 'Çalıyor' : 'Dinle',
                                  style: TextStyle(
                                    color: selected ? Colors.black : _gold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  static String _categoryLabel(String value) {
    switch (value) {
      case 'ev_lezzetleri':
        return 'Ev Lezzetleri';
      case 'usta_sefler':
        return 'Usta Şefler';
      case 'restoranlar':
        return 'Restoranlar';
      case 'kurye':
        return 'Kurye';
      default:
        return 'Genel';
    }
  }
}

class _RadioCategory {
  final String label;
  final String value;

  const _RadioCategory({
    required this.label,
    required this.value,
  });
}
