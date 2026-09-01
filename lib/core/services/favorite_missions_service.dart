import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/child_provider.dart';

/// Misi favorit/bookmark anak — disimpan lokal di HP (belum ada tabel
/// khusus di Supabase buat ini, dan datanya emang lebih cocok per-device
/// daripada disinkron server, mirip preferensi bahasa).
///
/// Dulu key SharedPreferences-nya global 1 buat seluruh akun
/// (`favorite_mission_ids`) — begitu 1 akun bisa punya lebih dari 1 anak,
/// misi favorit anak A bakal kelihatan seolah-olah favorit anak B juga.
/// Sekarang di-key per anak, dan otomatis reload kalau anak yang aktif
/// dipilih ganti (`selectedChildIdProvider`) — provider & semua caller-nya
/// (`ref.watch(favoriteMissionsProvider)`, `.toggle(id)`) nggak perlu
/// berubah sama sekali.
class FavoriteMissionsNotifier extends Notifier<Set<String>> {
  String? _childId;

  @override
  Set<String> build() {
    ref.listen(selectedChildIdProvider, (prev, next) {
      if (next != prev) {
        _childId = next;
        _load(next);
      }
    });
    _childId = ref.read(selectedChildIdProvider);
    _load(_childId);
    return {};
  }

  String _keyFor(String? childId) =>
      'favorite_mission_ids_${childId ?? Supabase.instance.client.auth.currentUser?.id ?? "default"}';

  Future<void> _load(String? childId) async {
    // Kosongin dulu biar nggak sekilas nampilin favorit anak sebelumnya
    // pas lagi ganti anak.
    state = {};
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_keyFor(childId)) ?? []).toSet();
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
    await prefs.setStringList(_keyFor(_childId), next.toList());
  }

  bool isFavorite(String missionId) => state.contains(missionId);
}

final favoriteMissionsProvider =
    NotifierProvider<FavoriteMissionsNotifier, Set<String>>(
  () => FavoriteMissionsNotifier(),
);
