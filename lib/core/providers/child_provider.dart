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

  // 🔥 KUNCI UTAMA: Riverpod sekarang akan me-restart provider ini OTOMATIS
  // detik itu juga saat user Login atau Logout!
  ref.watch(authStateProvider);

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
      'total_xp': initialData['total_xp'] ?? initialData['xp'] ?? 0,
      'current_streak': initialData['current_streak'] ?? 0,
      'max_xp': initialData['max_xp'] ?? 100,
      'weekly_progress': [],
      'recent_achievements': [],
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
          'total_xp': childData['total_xp'] ?? childData['xp'] ?? 0,
          'current_streak': childData['current_streak'] ?? 0,
          'max_xp': childData['max_xp'] ?? 100,
          'weekly_progress': [],
          'recent_achievements': [],
        };
      });
});
