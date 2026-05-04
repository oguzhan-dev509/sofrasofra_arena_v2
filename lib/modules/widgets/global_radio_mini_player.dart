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

                return Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 280,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final navigator = Navigator.maybeOf(context);
                        if (navigator == null) return;

                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => const RadyoMerkeziSayfasi(),
                          ),
                        );
                      },
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(
                          color: _bg,
                          border: Border(
                            top: BorderSide(color: Color(0x22FFFFFF)),
                            right: BorderSide(color: Color(0x22FFFFFF)),
                          ),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(18),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color:
                                    playing ? _gold : const Color(0xFF222222),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                playing
                                    ? Icons.graphic_eq_rounded
                                    : Icons.radio_rounded,
                                color: playing ? Colors.black : _gold,
                                size: 19,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasPrograms
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.72),
                                  fontSize: hasPrograms ? 15 : 13,
                                  fontWeight: hasPrograms
                                      ? FontWeight.w800
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  hasPrograms ? () => radio.togglePlay() : null,
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              color: hasPrograms
                                  ? _gold
                                  : Colors.white.withValues(alpha: 0.30),
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 34,
                                minHeight: 34,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
