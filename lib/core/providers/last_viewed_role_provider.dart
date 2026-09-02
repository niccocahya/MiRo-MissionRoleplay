import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Role terakhir yang dibuka di tab Misi -- dulu nggak ada, jadi tiap kali
/// tap tab "Misi" di bottom nav (yang manggil context.go('/missions') TANPA
/// query param role), MissionsPage selalu fallback ke role PERTAMA di
/// database (bukan yang terakhir kamu liat), walau ada dropdown switcher
/// di dalam mission_path_screen.dart buat ganti role. Milih role lewat
/// switcher itu, atau lewat kartu role di Home/hasil pencarian, sekarang
/// nyimpen pilihannya ke sini biar "nempel" pas balik ke tab lewat bottom
/// nav.
class LastViewedRoleNotifier extends Notifier<String?> {
  static const _key = 'last_viewed_role_id';

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> setRole(String roleId) async {
    if (state == roleId) return;
    state = roleId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, roleId);
  }
}

final lastViewedRoleProvider =
    NotifierProvider<LastViewedRoleNotifier, String?>(
  () => LastViewedRoleNotifier(),
);
