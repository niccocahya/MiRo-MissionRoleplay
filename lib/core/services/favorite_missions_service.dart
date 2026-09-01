import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Misi favorit/bookmark anak — disimpan lokal di HP (belum ada tabel
/// khusus di Supabase buat ini, dan datanya emang lebih cocok per-device
/// daripada disinkron server, mirip preferensi bahasa).
class FavoriteMissionsNotifier extends Notifier<Set<String>> {
  static const _prefsKey = 'favorite_mission_ids';

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_prefsKey) ?? []).toSet();
  }

  Future<void> toggle(String missionId) async {
    final next = Set<String>.from(state);
    if (next.contains(missionId)) {
      next.remove(missionId);
    } else {
      next.add(missionId);
    }
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, next.toList());
  }

  bool isFavorite(String missionId) => state.contains(missionId);
}

final favoriteMissionsProvider =
    NotifierProvider<FavoriteMissionsNotifier, Set<String>>(
  () => FavoriteMissionsNotifier(),
);
