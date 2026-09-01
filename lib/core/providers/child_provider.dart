import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Anak yang lagi aktif dipilih — buat mendukung multi-anak per akun.
///
/// Sebelumnya ini cuma in-memory (`state = id`), jadi tiap app di-restart
/// selalu balik ke "anak yang paling baru dibuat" (lihat fallback di
/// `childDataProvider`), bukan anak yang terakhir beneran dilihat orang
/// tua. Sekarang dipersist ke SharedPreferences, ngikutin pola yang sama
/// kaya `TextSizeNotifier`/`NotificationPrefsNotifier`.
class SelectedChildNotifier extends Notifier<String?> {
  static const _key = 'selected_child_id';

  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) state = saved;
  }

  Future<void> setId(String id) async {
    state = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, id);
  }

  /// Dipanggil pas logout, atau kalau id yang ke-persist ternyata udah
  /// nggak valid lagi (anak dihapus, atau device dipakai gonta-ganti
  /// akun) — biar nggak nyangkut ke id anak yang salah.
  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ==========================================
// 2. PROVIDER DAFTAR SEMUA ANAK MILIK PARENT INI — REALTIME
// ==========================================
/// Dulu nggak ada cara buat tau "parent ini punya anak berapa" — setiap
/// tempat yang butuh data anak langsung nembak 1 anak lewat
/// `childDataProvider`. Dibutuhkan buat UI ganti-anak (child switcher).
final childrenListProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(authStateProvider.select((s) => s.value?.session?.user.id));
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value([]);

  return Supabase.instance.client
      .from('children')
      .stream(primaryKey: ['id'])
      .eq('parent_id', user.id)
      .order('created_at');
});

// ==========================================
// 3. PROVIDER UTAMA ANAK - REALTIME (Profil, XP, Level, Streak)
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

  // Cari anak paling baru dibuat milik parent ini — dipakai baik buat
  // "belum ada anak yang dipilih" MAUPUN buat "anak yang dipilih ternyata
  // udah nggak ada/nggak valid lagi" (lihat pemakaian di bawah).
  Future<String?> resolveMostRecentChildId() async {
    final childList = await supabase
        .from('children')
        .select('id')
        .eq('parent_id', user.id)
        .order('created_at', ascending: false)
        .limit(1);

    if (childList.isEmpty) return null;
    final resolvedId = childList.first['id'] as String;
    Future.microtask(() {
      ref.read(selectedChildIdProvider.notifier).setId(resolvedId);
    });
    return resolvedId;
  }

  String? childId = ref.watch(selectedChildIdProvider);

  // 1. Kalau belum ada anak yang dipilih (baik karena benar-benar belum
  //    pernah, atau baru dimuat dari SharedPreferences), cari yang
  //    paling baru dibuat.
  if (childId == null) {
    childId = await resolveMostRecentChildId();
    if (childId == null) {
      yield null;
      return;
    }
  }

  // 2. Ambil data awal pakai SELECT biasa biar INSTAN muncul di layar!
  var initialData =
      await supabase.from('children').select().eq('id', childId).maybeSingle();

  // Id yang lagi dipilih (misalnya dari SharedPreferences device lama,
  // atau anaknya udah dihapus) ternyata nggak match baris manapun —
  // jangan macet nampilin layar kosong, cari ulang anak paling baru.
  if (initialData == null) {
    await ref.read(selectedChildIdProvider.notifier).clear();
    childId = await resolveMostRecentChildId();
    if (childId == null) {
      yield null;
      return;
    }
    initialData = await supabase
        .from('children')
        .select()
        .eq('id', childId)
        .maybeSingle();
  }

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
