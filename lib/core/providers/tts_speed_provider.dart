import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kecepatan suara pas misi ngebacain instruksi (TTS).
///
/// Sebelumnya cuma ada toggle 2 pilihan (tombol kura-kura di
/// mission_play_screen.dart) yang nggak kesimpen -- balik ke "normal"
/// tiap kali layar misi dibuka ulang -- dan "normal"-nya sendiri masih
/// dirasa kecepetan sama tester walau udah pernah diturunin sekali.
/// Sekarang 3 tingkat, beneran tersimpan (sekali pilih, kepakai terus di
/// semua misi berikutnya), dan defaultnya diturunin lagi dari sebelumnya.
enum TtsSpeed { slow, normal, fast }

extension TtsSpeedX on TtsSpeed {
  // Skala setSpeechRate flutter_tts di Android itu 0.0 (paling lambat) -
  // 1.0 (paling cepat), BUKAN skala 0.5-2.0 punya Android asli -- lihat
  // catatan di _setupTts()/mission_play_screen.dart. Dibacain buat ANAK
  // yang lagi ngikutin instruksi sambil kerja, bukan buat didengar santai
  // kayak podcast, jadi lebih lambat dari "normal" ngomong manusia.
  double get rate => switch (this) {
    TtsSpeed.slow => 0.22,
    TtsSpeed.normal => 0.34,
    TtsSpeed.fast => 0.48,
  };

  String label(String lang) => switch (this) {
    TtsSpeed.slow => lang == 'id' ? 'Pelan' : 'Slow',
    TtsSpeed.normal => lang == 'id' ? 'Normal' : 'Normal',
    TtsSpeed.fast => lang == 'id' ? 'Cepat' : 'Fast',
  };
}

class TtsSpeedNotifier extends Notifier<TtsSpeed> {
  static const _key = 'tts_speed';

  @override
  TtsSpeed build() {
    _load();
    return TtsSpeed.normal;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == null) return;
    state = TtsSpeed.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => TtsSpeed.normal,
    );
  }

  Future<void> setSpeed(TtsSpeed speed) async {
    state = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, speed.name);
  }
}

final ttsSpeedProvider = NotifierProvider<TtsSpeedNotifier, TtsSpeed>(
  () => TtsSpeedNotifier(),
);
