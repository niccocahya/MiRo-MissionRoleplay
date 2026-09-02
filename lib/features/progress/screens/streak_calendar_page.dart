import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/language_provider.dart';
import '../../../core/providers/streak_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/responsive.dart';
import '../../../shared/widgets/app_state_views.dart';
import '../../../shared/widgets/back_button.dart';

const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "Streak Calendar",
    'subtitle': "Every day a mission was completed, in the last ~12 weeks.",
    'legend_active': "Active",
    'legend_inactive': "No mission",
    'err': "Failed to load streak history: ",
  },
  'id': {
    'title': "Kalender Streak",
    'subtitle': "Hari-hari misi diselesaikan, ~12 minggu terakhir.",
    'legend_active': "Aktif",
    'legend_inactive': "Nggak ada misi",
    'err': "Gagal memuat riwayat streak: ",
  },
};

const List<String> _kDayLabelsId = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
const List<String> _kDayLabelsEn = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

/// Kalender ala "contribution graph" GitHub buat streak -- dulu streak
/// cuma ditampilin sebagai 1 angka polos ("7 hari beruntun"), nggak ada
/// cara liat POLA aktivitasnya (hari apa biasanya aktif, kapan kelewat).
class StreakCalendarPage extends ConsumerWidget {
  final String childId;

  const StreakCalendarPage({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;
    final hPad = context.pageHPadding;

    final activeDatesAsync = ref.watch(streakActiveDatesProvider(childId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
              child: Row(
                children: [
                  CustomBackButton(onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(texts['title']!, style: AppTextStyles.h2()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: activeDatesAsync.when(
                loading: () => const AppLoading(),
                error: (e, s) => AppErrorView(message: "${texts['err']}$e"),
                data: (activeDates) => SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texts['subtitle']!,
                        style: AppTextStyles.body(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _CalendarGrid(activeDates: activeDates, lang: lang),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          _legendDot(AppColors.accent),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            texts['legend_active']!,
                            style: AppTextStyles.caption(color: AppColors.textSecondary),
                          ),
                          const SizedBox(width: AppSpacing.lg),
                          _legendDot(AppColors.border),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            texts['legend_inactive']!,
                            style: AppTextStyles.caption(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({required this.activeDates, required this.lang});

  final Set<DateTime> activeDates;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final dayLabels = lang == 'id' ? _kDayLabelsId : _kDayLabelsEn;
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    // Mundur ke hari Senin minggu ini, terus mundur lagi 11 minggu penuh --
    // total 12 minggu (84 hari), disusun kolom = minggu, baris = hari.
    final int weekdayOffset = todayNormalized.weekday - 1; // Senin = 0
    final startOfThisWeek = todayNormalized.subtract(Duration(days: weekdayOffset));
    final gridStart = startOfThisWeek.subtract(const Duration(days: 7 * 11));

    final List<List<DateTime>> weeks = List.generate(12, (weekIndex) {
      final weekStart = gridStart.add(Duration(days: 7 * weekIndex));
      return List.generate(7, (dayIndex) => weekStart.add(Duration(days: dayIndex)));
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // Mulai scroll dari minggu paling baru (kanan).
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: dayLabels
                .map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: SizedBox(
                        height: 16,
                        child: Text(
                          d,
                          style: AppTextStyles.caption(color: AppColors.textMuted)
                              .copyWith(fontSize: 10),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...weeks.map((week) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Column(
                children: week.map((date) {
                  final bool isFuture = date.isAfter(todayNormalized);
                  final bool isActive = activeDates.contains(date);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Tooltip(
                      message: DateFormat('dd MMM yyyy').format(date),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isFuture
                              ? Colors.transparent
                              : (isActive ? AppColors.accent : AppColors.border),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
