import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/skills.dart';
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
///
/// Dulu `FutureProvider` -- sekali ambil per `childId`, nggak pernah
/// kehitung ulang lagi buat sisa sesi app (sama kayak bug yang sempat ada
/// di `childRoleProgressProvider`). Efeknya: misi baru yang diselesaikan
/// nggak nongol di grafik tren Progress sampai app ditutup total & dibuka
/// ulang, walau angka XP/level di layar lain udah keupdate realtime.
/// Sekarang `StreamProvider` yang dengerin `mission_logs`, sama kayak
/// `streakProvider`/`weeklyMissionCountStreamProvider` yang baca tabel
/// yang sama.
final skillTrendProvider =
    StreamProvider.family<List<SkillTrendPoint>, String>((ref, childId) {
  if (childId.isEmpty) return Stream.value([]);

  return Supabase.instance.client
      .from('mission_logs')
      .stream(primaryKey: ['id'])
      .eq('child_id', childId)
      .map((event) {
        final completedRows = event.where((r) => r['status'] == 'completed').toList()
          ..sort((a, b) {
            final da = parseDateSafely(a['completed_at']?.toString() ?? '');
            final db = parseDateSafely(b['completed_at']?.toString() ?? '');
            if (da == null || db == null) return 0;
            return da.compareTo(db);
          });

        // Daftar skill-nya dari core/constants/skills.dart (dulu ditulis
        // ulang di sini) -- biar skill baru otomatis kebawa ke grafik
        // tren juga.
        final Map<String, double> running = {for (final s in kSkills) s.key: 0};

        final List<SkillTrendPoint> points = [];
        for (final row in completedRows) {
          final date = parseDateSafely(row['completed_at']?.toString() ?? '');
          if (date == null) continue;

          // Loop atas KEY YANG BENERAN ADA di earned_skills, bukan cuma 5
          // nama yang di-hardcode di atas -- sebelumnya kalau satu baris
          // punya key yang nggak persis cocok sama daftar itu (typo,
          // skill baru yang belum ditambahin ke daftar, dsb.) poinnya
          // ke-skip diem-diem tanpa ketauan, bikin tren keliatan lebih
          // rendah dari yang seharusnya.
          final skills = (row['earned_skills'] as Map?) ?? {};
          for (final entry in skills.entries) {
            final gained = entry.value;
            if (gained is num) {
              final key = entry.key.toString();
              running[key] = (running[key] ?? 0) + gained.toDouble();
            }
          }
          points.add(SkillTrendPoint(date: date, cumulative: Map.of(running)));
        }

        return points;
      });
});
