import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Level yang sudah terbuka per role buat 1 anak, dari `child_role_progress`
/// — sebelumnya cuma pernah di-query 1 role sekaligus (di dalam
/// `MissionPathScreen`), jadi nggak ada cara buat tahu status semua misi
/// lintas role sekaligus (dibutuhkan buat layar pencarian misi).
final childRoleProgressProvider =
    FutureProvider.family<Map<String, int>, String>((ref, childId) async {
  if (childId.isEmpty) return {};

  final rows = await Supabase.instance.client
      .from('child_role_progress')
      .select('role_id, unlocked_level')
      .eq('child_id', childId);

  final Map<String, int> result = {};
  for (final row in rows) {
    result[row['role_id'] as String] = (row['unlocked_level'] as int?) ?? 1;
  }
  return result;
});
