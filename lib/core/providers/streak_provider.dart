import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/date_utils.dart';

/// Streak (hari berturut-turut menyelesaikan misi), dihitung LANGSUNG dari
/// `mission_logs` secara realtime. `children.current_streak` ada di skema
/// tapi nggak pernah ditulis balik dari app manapun — jadi ini streak yang
/// beneran akurat, dulu cuma dipakai di Progress, sekarang juga dipakai di
/// Home buat pengingat.
final streakProvider = StreamProvider.family<int, String>((ref, childId) {
  if (childId.isEmpty) return Stream.value(0);

  final supabase = Supabase.instance.client;
  return supabase
      .from('mission_logs')
      .stream(primaryKey: ['id'])
      .eq('child_id', childId)
      .map((event) {
        final completedLogs = event
            .where((item) => item['status'] == 'completed')
            .toList();
        if (completedLogs.isEmpty) return 0;

        final Set<DateTime> uniqueDates = {};
        for (var log in completedLogs) {
          final date = parseDateSafely(log['completed_at'] ?? '');
          if (date != null) {
            uniqueDates.add(DateTime(date.year, date.month, date.day));
          }
        }

        if (uniqueDates.isEmpty) return 0;

        final sortedDates = uniqueDates.toList()
          ..sort((a, b) => b.compareTo(a));

        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);
        final yesterdayNormalized = todayNormalized.subtract(
          const Duration(days: 1),
        );

        int streak = 0;
        DateTime currentDateToCheck = sortedDates.first;

        if (currentDateToCheck.isBefore(yesterdayNormalized)) {
          return 0;
        }

        DateTime expectedDate = currentDateToCheck;
        for (var date in sortedDates) {
          if (date == expectedDate) {
            streak++;
            expectedDate = expectedDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }

        return streak;
      });
});

/// True kalau streak-nya lagi POSITIF tapi anak BELUM nyelesein misi hari
/// ini -- artinya bakal putus ke 0 kalau kelewat tengah malam tanpa
/// nyelesein 1 misi lagi. Dulu Home cuma nampilin jumlah streak polos,
/// nggak ada yang nandain "buruan, streak-mu bakal ilang" secara jelas.
final streakAtRiskProvider = StreamProvider.family<bool, String>((
  ref,
  childId,
) {
  if (childId.isEmpty) return Stream.value(false);

  final supabase = Supabase.instance.client;
  return supabase
      .from('mission_logs')
      .stream(primaryKey: ['id'])
      .eq('child_id', childId)
      .map((event) {
        final completedLogs = event.where(
          (item) => item['status'] == 'completed',
        );

        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);
        final yesterdayNormalized = todayNormalized.subtract(
          const Duration(days: 1),
        );

        bool doneToday = false;
        DateTime? mostRecent;
        for (final log in completedLogs) {
          final date = parseDateSafely(log['completed_at'] ?? '');
          if (date == null) continue;
          final normalized = DateTime(date.year, date.month, date.day);
          if (normalized == todayNormalized) doneToday = true;
          if (mostRecent == null || normalized.isAfter(mostRecent)) {
            mostRecent = normalized;
          }
        }

        if (doneToday || mostRecent == null) return false;
        // Streak-nya masih "hidup" (terakhir selesai kemarin) tapi belum
        // dilanjutin hari ini -- ini persis kondisi "bakal putus".
        return mostRecent == yesterdayNormalized;
      });
});
