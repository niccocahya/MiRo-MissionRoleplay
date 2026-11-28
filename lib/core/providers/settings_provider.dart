import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/miro_tokens.dart';

/// Pengaturan tampilan dan umpan balik (ARCHITECTURE §4, layar 37).
///
/// Bahasa, ukuran teks, dan kecepatan TTS masih di provider masing-masing
/// yang sudah ada (`languageProvider`, `textSizeProvider`,
/// `ttsSpeedProvider`) supaya layar lama tidak terganggu.
@immutable
class MiroSettings {
  const MiroSettings({this.reduceMotion, this.haptics = true});

  /// `null` = ikut pengaturan sistem (default). `true`/`false` = dipilih
  /// sendiri oleh pengguna di Pengaturan.
  final bool? reduceMotion;
  final bool haptics;

  MiroSettings copyWith({bool? Function()? reduceMotion, bool? haptics}) =>
      MiroSettings(
        reduceMotion: reduceMotion != null ? reduceMotion() : this.reduceMotion,
        haptics: haptics ?? this.haptics,
      );
}

class SettingsNotifier extends Notifier<MiroSettings> {
  static const _kReduceMotion = 'settings.reduce_motion';
  static const _kHaptics = 'settings.haptics';

  @override
  MiroSettings build() {
    _load();
    return const MiroSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = MiroSettings(
      reduceMotion: prefs.getBool(_kReduceMotion),
      haptics: prefs.getBool(_kHaptics) ?? true,
    );
  }

  /// `null` mengembalikan ke "ikut sistem".
  Future<void> setReduceMotion(bool? value) async {
    state = state.copyWith(reduceMotion: () => value);
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_kReduceMotion);
    } else {
      await prefs.setBool(_kReduceMotion, value);
    }
  }

  Future<void> setHaptics(bool value) async {
    state = state.copyWith(haptics: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHaptics, value);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, MiroSettings>(
  SettingsNotifier.new,
);

/// Satu-satunya cara widget menanyakan "kurangi animasi?" (ANIMATION §7):
/// pilihan pengguna di app menang; kalau belum dipilih, ikut sistem.
bool reduceMotionOf(BuildContext context, WidgetRef ref) {
  final chosen = ref.watch(settingsProvider.select((s) => s.reduceMotion));
  return chosen ?? MiroMotion.reduced(context);
}
