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

    return ValueListenableBuilder(
      valueListenable: radio.programs,
      builder: (context, programs, _) {
        if (programs.isEmpty) return const SizedBox.shrink();

        return StreamBuilder<int?>(
          stream: radio.player.currentIndexStream,
          builder: (context, indexSnap) {
            final index = indexSnap.data ?? 0;

            if (index >= programs.length) {
              return const SizedBox.shrink();
            }

            final program = programs[index];

            return StreamBuilder<PlayerState>(
              stream: radio.player.playerStateStream,
              builder: (context, stateSnap) {
                final playing = radio.player.playing;

                return Align(
                  alignment: Alignment.bottomLeft,
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
                                    : Icons.play_arrow_rounded,
                                color: playing ? Colors.black : _gold,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                program.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => radio.togglePlay(),
                              icon: Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                              ),
                              color: _gold,
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
