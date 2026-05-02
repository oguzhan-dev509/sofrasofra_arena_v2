import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class RadioProgram {
  final String id;
  final String title;
  final String audioUrl;
  final String kategori;
  final int order;

  const RadioProgram({
    required this.id,
    required this.title,
    required this.audioUrl,
    required this.kategori,
    required this.order,
  });

  factory RadioProgram.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return RadioProgram(
      id: doc.id,
      title: (data['title'] ?? '').toString().trim(),
      audioUrl: (data['audioUrl'] ?? '').toString().trim(),
      kategori: (data['kategori'] ?? 'genel').toString().trim(),
      order: data['order'] is int ? data['order'] as int : 999,
    );
  }
}

class SofrasofraRadioService {
  SofrasofraRadioService._();

  static final SofrasofraRadioService instance = SofrasofraRadioService._();

  final AudioPlayer player = AudioPlayer();

  final ValueNotifier<bool> loading = ValueNotifier<bool>(false);
  final ValueNotifier<List<RadioProgram>> programs =
      ValueNotifier<List<RadioProgram>>([]);

  bool _prepared = false;

  Future<void> prepare({bool forceRefresh = false}) async {
    if (!forceRefresh && (_prepared || loading.value)) return;

    try {
      loading.value = true;

      final snapshot = await FirebaseFirestore.instance
          .collection('radyo_yayinlari')
          .where('aktifMi', isEqualTo: true)
          .orderBy('order')
          .get();

      final items = snapshot.docs
          .map(RadioProgram.fromDoc)
          .where((e) => e.audioUrl.trim().isNotEmpty)
          .toList();

      programs.value = items;

      if (items.isEmpty) {
        throw Exception('Aktif radyo yayını bulunamadı.');
      }

      final sources = items.map((program) {
        return AudioSource.uri(
          Uri.parse(program.audioUrl.trim()),
          tag: program.title,
        );
      }).toList();

      if (forceRefresh) {
        await player.stop();
      }

      await player.setAudioSource(
        ConcatenatingAudioSource(children: sources),
      );

      _prepared = true;
    } finally {
      loading.value = false;
    }
  }

  Future<void> refresh() async {
    _prepared = false;
    await prepare(forceRefresh: true);
  }

  Future<void> playProgram(int index) async {
    await prepare();

    if (index < 0 || index >= programs.value.length) return;

    await player.seek(Duration.zero, index: index);
    await player.play();
  }

  Future<void> togglePlay() async {
    await prepare();

    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> next() async {
    await prepare();
    await player.seekToNext();
  }

  Future<void> previous() async {
    await prepare();
    await player.seekToPrevious();
  }
}
