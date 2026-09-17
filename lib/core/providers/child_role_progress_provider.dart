import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Level yang sudah terbuka per role buat 1 anak, dari `child_role_progress`
/// — sebelumnya cuma pernah di-query 1 role sekaligus (di dalam
/// `MissionPathScreen`), jadi nggak ada cara buat tahu status semua misi
/// lintas role sekaligus (dibutuhkan buat layar pencarian misi & kartu
/// rekomendasi "Misi Hari Ini" di Home).
///
/// Dulu ini `FutureProvider` -- sekali ambil, DIEM SELAMANYA buat sisa sesi
/// app (nggak ada `.autoDispose` atau refresh otomatis). Efeknya: begitu
/// misi baru selesai (unlocked_level-nya beneran naik di database), kartu
/// "Misi Hari Ini" di Home & status kunci di layar Cari Misi tetap
/// nunjukin data LAMA -- kartu Home bisa terus ngerekomendasiin misi yang
/// udah kelar, atau layar Cari Misi nunjukin misi berikutnya masih
/// "terkunci" padahal udah kebuka -- sampai app di-tutup total & dibuka
/// ulang. Sekarang realtime `StreamProvider`, sama kayak provider lain di
/// app ini yang baca data yang bisa berubah pas dipakai
/// (`streakProvider`, `childRealtimeXpProvider`, dst).
final childRoleProgressProvider =
    StreamProvider.family<Map<String, int>, String>((ref, childId) {
  if (childId.isEmpty) return Stream.value({});

  return Supabase.instance.client
      .from('child_role_progress')
      .stream(primaryKey: ['child_id', 'role_id'])
      .eq('child_id', childId)
      .map((rows) {
        final Map<String, int> result = {};
        for (final row in rows) {
          result[row['role_id'] as String] = (row['unlocked_level'] as int?) ?? 1;
        }
        return result;
      });
});
