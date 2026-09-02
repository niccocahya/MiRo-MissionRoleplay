import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kapan nunjukin prompt "kasih rating MiRO" -- dulu nggak ada cara sama
/// sekali buat orang tua ngasih tau seneng/nggaknya pakai app ini kecuali
/// nemu sendiri menu Bantuan. Munculnya SEKALI aja per ambang jumlah misi
/// selesai (default 3), dan kalau di-"Nanti Aja" digeser 5 misi lagi ke
/// depan -- begitu udah beneran ngasih rating (jenis apa pun), nggak
/// pernah muncul lagi.
class AppRatingPromptNotifier extends Notifier<bool> {
  static const _kAnsweredKey = 'app_rating_answered';
  static const _kNextThresholdKey = 'app_rating_next_threshold';
  static const int _firstThreshold = 3;
  static const int _snoozeStep = 5;

  @override
  bool build() => false;

  Future<void> maybeShow(int totalMissionsCompleted) async {
    if (state) return; // Lagi ketampil, jangan dobel.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kAnsweredKey) ?? false) return;

    final int threshold =
        prefs.getInt(_kNextThresholdKey) ?? _firstThreshold;
    if (totalMissionsCompleted >= threshold) {
      state = true;
    }
  }

  Future<void> dismissTemporarily(int totalMissionsCompleted) async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _kNextThresholdKey,
      totalMissionsCompleted + _snoozeStep,
    );
  }

  Future<void> markAnswered() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAnsweredKey, true);
  }
}

final appRatingPromptProvider =
    NotifierProvider<AppRatingPromptNotifier, bool>(
  () => AppRatingPromptNotifier(),
);
