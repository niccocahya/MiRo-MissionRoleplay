import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/date_utils.dart';

/// Satu titik di grafik tren: total kumulatif tiap skill SAMPAI misi ini
/// selesai (bukan skor di hari itu doang).
class SkillTrendPoint {
  const SkillTrendPoint({required this.date, required this.cumulative});

  final DateTime date;
  final Map<String, double> cumulative;
}

/// Tren skor 5 skill dari waktu ke waktu — `child_stats` cuma nyimpen
/// SNAPSHOT skor saat ini, nggak ada riwayatnya. Tapi tiap baris
/// `mission_logs` yang selesai udah nyimpen `earned_skills` (skill yang
/// didapat dari misi itu) + `completed_at`, jadi tren historis bisa
/// dihitung ulang dari situ tanpa perlu tabel/skema baru: jumlahkan
/// `earned_skills` berurutan berdasarkan tanggal selesai.
final skillTrendProvider =
    FutureProvider.family<List<SkillTrendPoint>, String>((ref, childId) async {
  if (childId.isEmpty) return [];

  final rows = await Supabase.instance.client
      .from('mission_logs')
      .select('completed_at, earned_skills')
      .eq('child_id', childId)
      .eq('status', 'completed')
      .order('completed_at', ascending: true);

  final Map<String, double> running = {
    'cognitive': 0,
    'empathy': 0,
    'creativity': 0,
    'literacy': 0,
    'motoric': 0,
  };

  final List<SkillTrendPoint> points = [];
  for (final row in rows) {
    final date = parseDateSafely(row['completed_at']?.toString() ?? '');
    if (date == null) continue;

    final skills = (row['earned_skills'] as Map?) ?? {};
    for (final key in running.keys) {
      final gained = skills[key];
      if (gained is num) running[key] = running[key]! + gained.toDouble();
    }
    points.add(SkillTrendPoint(date: date, cumulative: Map.of(running)));
  }

  return points;
});
