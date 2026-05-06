import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sofrasofra_arena_v2/modules/radyo/radyo_merkezi_sayfasi.dart';
import 'package:sofrasofra_arena_v2/services/sofrasofra_radio_service.dart';

class GlobalRadioMiniPlayer extends StatelessWidget {
  const GlobalRadioMiniPlayer({super.key});

  static const Color _bg = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    final radio = SofrasofraRadioService.instance;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return ValueListenableBuilder<List<RadioProgram>>(
      valueListenable: radio.programs,
      builder: (context, programs, _) {
        return StreamBuilder<int?>(
          stream: radio.player.currentIndexStream,
          builder: (context, indexSnap) {
            final rawIndex = indexSnap.data ?? 0;
            final hasPrograms = programs.isNotEmpty;
            final safeIndex =
                hasPrograms ? rawIndex.clamp(0, programs.length - 1) : 0;

            final title = hasPrograms
                ? programs[safeIndex].title
                : 'Sofrasofra Radyo hazırlanıyor...';

            return StreamBuilder<PlayerState>(
              stream: radio.player.playerStateStream,
              builder: (context, stateSnap) {
                final playing = radio.player.playing;

                if (isMobile) {
                  return _MobileRadioButton(
                    playing: playing,
                    hasPrograms: hasPrograms,
                    onTap: hasPrograms ? () => radio.togglePlay() : null,
                  );
                }

                return _DesktopRadioBand(
                  title: title,
                  playing: playing,
                  hasPrograms: hasPrograms,
                  onTogglePlay: hasPrograms ? () => radio.togglePlay() : null,
                  onOpenRadioPage: () {
                    final navigator = Navigator.maybeOf(context);
                    if (navigator == null) return;

                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => const RadyoMerkeziSayfasi(),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MobileRadioButton extends StatelessWidget {
  final bool playing;
  final bool hasPrograms;
  final VoidCallback? onTap;

  const _MobileRadioButton({
    required this.playing,
    required this.hasPrograms,
    required this.onTap,
  });

  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(
          left: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              shape: BoxShape.circle,
              border: Border.all(
                color: playing
                    ? _gold.withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.36),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  playing ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                  color: hasPrograms ? _gold : Colors.white38,
                  size: 25,
                ),
                if (playing)
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: _gold,
                        shape: BoxShape.circle,
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

class _DesktopRadioBand extends StatelessWidget {
  final String title;
  final bool playing;
  final bool hasPrograms;
  final VoidCallback? onTogglePlay;
  final VoidCallback onOpenRadioPage;

  const _DesktopRadioBand({
    required this.title,
    required this.playing,
    required this.hasPrograms,
    required this.onTogglePlay,
    required this.onOpenRadioPage,
  });

  static const Color _bg = Color(0xFF111111);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 280,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: _bg,
            border: Border.all(
              color: const Color(0x22FFFFFF),
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onTogglePlay,
                child: Container(
                  width: 31,
                  height: 31,
                  decoration: BoxDecoration(
                    color: playing ? _gold : const Color(0xFF222222),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    playing ? Icons.graphic_eq_rounded : Icons.radio_rounded,
                    color: playing ? Colors.black : _gold,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpenRadioPage,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasPrograms
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.72),
                      fontSize: hasPrograms ? 13.5 : 12.5,
                      fontWeight:
                          hasPrograms ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onTogglePlay,
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                color:
                    hasPrograms ? _gold : Colors.white.withValues(alpha: 0.30),
                iconSize: 21,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 31,
                  minHeight: 31,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
