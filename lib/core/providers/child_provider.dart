import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 🔥 PROVIDER BARU: PENGINTAI STATUS LOGIN (Biar Riverpod melek!)
// ==========================================
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// ==========================================
// 1. PROVIDER ID ANAK (MODERN RIVERPOD)
// ==========================================

final selectedChildIdProvider =
    NotifierProvider<SelectedChildNotifier, String?>(() {
  return SelectedChildNotifier();
});

class SelectedChildNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setId(String id) {
    state = id;
  }
}

// ==========================================
// 2. PROVIDER UTAMA ANAK - REALTIME (Profil, XP, Level, Streak)
// ==========================================
final childDataProvider = StreamProvider<Map<String, dynamic>?>((ref) async* {
  final supabase = Supabase.instance.client;

  // 🔥 Restart provider ini HANYA kalau user yang login beneran ganti
  // (login/logout/ganti akun) — bukan tiap event auth apapun.
  //
  // Sebelumnya `ref.watch(authStateProvider)` nonton SELURUH stream auth,
  // termasuk event TOKEN_REFRESHED yang otomatis ditembak Supabase tiap
  // token mau kedaluwarsa (biasanya ~1 jam sekali) walau user-nya sama
  // persis. Tiap event itu bikin provider ini restart total dari nol: ambil
  // ulang childId, query ulang, baru nyalain stream lagi — jadi data yang
  // udah kebaca di layar sempat kosong/reload sendiri di tengah pemakaian.
  // `.select()` bikin Riverpod cuma restart kalau nilai yang dipilih
  // (id user) beneran berubah.
  ref.watch(authStateProvider.select((s) => s.value?.session?.user.id));

  final user = supabase.auth.currentUser;

  // Jika tidak ada user yang login, langsung hentikan
  if (user == null) {
    yield null;
    return;
  }

  String? childId = ref.watch(selectedChildIdProvider);

  // 1. Jika childId belum dipilih, ambil anak pertama/terbaru dari database
  if (childId == null) {
    final childList = await supabase
        .from('children')
        .select('id')
        .eq('parent_id', user.id)
        .order('created_at', ascending: false)
        .limit(1);

    if (childList.isNotEmpty) {
      childId = childList.first['id'] as String;

      // Kasih tau seluruh aplikasi ID yang baru ketemu
      Future.microtask(() {
        ref.read(selectedChildIdProvider.notifier).setId(childId!);
      });
    } else {
      yield null;
      return;
    }
  }

  // 2. Ambil data awal pakai SELECT biasa biar INSTAN muncul di layar!
  final initialData =
      await supabase.from('children').select().eq('id', childId).maybeSingle();

  if (initialData != null) {
    yield {
      ...initialData,
      'current_level': initialData['current_level'] ?? 1,
      'total_xp': initialData['total_xp'] ?? 0,
      'current_streak': initialData['current_streak'] ?? 0,
    };
  }

  // 3. Setelah data instan muncul di layar, nyalakan STREAM untuk memantau perubahan Realtime
  yield* supabase
      .from('children')
      .stream(primaryKey: ['id'])
      .eq('id', childId)
      .map((
        events,
      ) {
        if (events.isEmpty) return null;

        final childData = events.first;

        return {
          ...childData,
          'current_level': childData['current_level'] ?? 1,
          'total_xp': childData['total_xp'] ?? 0,
          'current_streak': childData['current_streak'] ?? 0,
        };
      });
});
