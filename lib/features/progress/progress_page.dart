import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../core/providers/language_provider.dart';
import '../../core/providers/child_provider.dart';
import '../../core/providers/child_stats_provider.dart';
import '../../core/providers/streak_provider.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/level_utils.dart';
import '../../core/services/report_pdf_service.dart';
import '../../core/providers/skill_trend_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/role_visuals.dart';
import '../../core/constants/skills.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../core/router/app_page_transition.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_choice_chip.dart';
import '../../shared/widgets/app_state_views.dart';
// IMPORT BARU UNTUK MEMBUKA JURNAL
import '../missions/data/mission_model.dart';
import '../missions/screens/mission_journal_screen.dart';
import 'screens/streak_calendar_page.dart';

// parseDateSafely & streakProvider dipindah ke core/utils/date_utils.dart
// dan core/providers/streak_provider.dart (dulu duplikat persis di sini
// dan di home_page.dart).

// childStatsProvider sekarang di core/providers/child_stats_provider.dart
// (dipakai bareng home_page.dart buat rekomendasi misi).

// ==========================================
// PROVIDER 2: KALENDER BULAN INI (Hanya menyimpan tanggal yang selesai)
// ==========================================
final monthlyConsistencyProvider = StreamProvider.family<Set<int>, String>((
  ref,
  childId,
) {
  if (childId.isEmpty) return Stream.value(<int>{});

  final supabase = Supabase.instance.client;
  final now = DateTime.now();

  return supabase
      .from('mission_logs')
      .stream(primaryKey: ['id'])
      .eq('child_id', childId)
      .map((response) {
        Set<int> activeDays = {};

        for (var row in response) {
          if (row['status'] != 'completed') continue;
          if (row['completed_at'] == null) continue;

          final completedAt = parseDateSafely(row['completed_at']);
          if (completedAt == null) continue;

          // Hanya catat jika bulannya sama dengan bulan saat ini
          if (completedAt.month == now.month && completedAt.year == now.year) {
            activeDays.add(completedAt.day);
          }
        }
        return activeDays;
      });
});

// ==========================================
// PROVIDER 3: MENGAMBIL RIWAYAT MISI DENGAN FILTER - REALTIME
// ==========================================
final missionHistoryProvider = StreamProvider.family<List<dynamic>, String>((
  ref,
  params,
) {
  final parts = params.split('|');
  if (parts.length != 3) return Stream.value([]);

  final childId = parts[0];
  final timeFilter = parts[1];
  final roleFilter = parts[2];

  if (childId.isEmpty) return Stream.value([]);

  final supabase = Supabase.instance.client;
  final now = DateTime.now();
  DateTime startDate;
  if (timeFilter == 'hari') {
    startDate = DateTime(now.year, now.month, now.day);
  } else if (timeFilter == 'minggu') {
    startDate = now.subtract(const Duration(days: 7));
  } else {
    startDate = now.subtract(const Duration(days: 30));
  }

  return supabase
      .from('mission_logs')
      .stream(primaryKey: ['id'])
      .eq('child_id', childId)
      .map((event) {
        var list = List<dynamic>.from(event);
        list = list.where((item) {
          if (item['status'] != 'completed') return false;
          final completedAt = parseDateSafely(item['completed_at'] ?? '');
          if (completedAt == null || completedAt.isBefore(startDate)) {
            return false;
          }
          if (roleFilter != 'semua' && item['role_id'] != roleFilter) {
            return false;
          }
          return true;
        }).toList();

        list.sort((a, b) {
          final dateA =
              parseDateSafely(a['completed_at'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final dateB =
              parseDateSafely(b['completed_at'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return dateB.compareTo(dateA);
        });

        return list;
      });
});

// ==========================================
// PROVIDER 4: PENCAPAIAN ANAK (CHILD ACHIEVEMENTS) - REALTIME DENGAN JOIN
// ==========================================
final childAchievementsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, childId) {
      if (childId.isEmpty) return Stream.value([]);

      final supabase = Supabase.instance.client;

      return supabase
          .from('child_achievements')
          .stream(primaryKey: ['id'])
          .eq('child_id', childId)
          .asyncMap((achievements) async {
            if (achievements.isEmpty) return <Map<String, dynamic>>[];
            try {
              final masterRes = await supabase
                  .from('achievements_master')
                  .select();
              final masterMap = {for (var item in masterRes) item['id']: item};

              return achievements.map((item) {
                final master = masterMap[item['achievement_id']] ?? {};
                return {
                  'achievement_id': item['achievement_id'],
                  'unlocked_at': item['unlocked_at'],
                  'title_id': master['title_id'] ?? 'Pencapaian',
                  'title_en': master['title_en'] ?? 'Achievement',
                  'icon_url': master['icon_url'] ?? '🏅',
                  'role_id': master['role_id'] ?? '',
                };
              }).toList();
            } catch (e) {
              debugPrint("Gagal memuat master achievements: $e");
              return [];
            }
          });
    });

// ==========================================
// DICTIONARY (KAMUS BAHASA LENGKAP)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "Development of",
    'subtitle': "Their progress, transparently summarized",
    'cognitive': "Cognitive",
    'empathy': "Empathy",
    'creativity': "Creativity",
    'literacy': "Literacy",
    'motoric': "Motoric",
    'consistency': "This Month's Activity",
    'streak_label': "Day Streak!",
    'mission_history': "Mission History",
    'filter_today': "Today",
    'filter_week': "This Week",
    'filter_month': "This Month",
    'filter_all': "All Roles",
    'empty_history': "No missions found for this filter.",
    'achievements': "Achievements Earned",
    'xp_progress': "XP Progress",
    'level': "Level",
    'empty_achievements':
        "No achievements yet. Complete missions to earn them!",
    'err_journal': "Failed to load mission journal: ",
    'err_load': "Error loading data: ",
    'missions_count': "Missions",
    'default_child_name': "Child",
    'export_pdf': "Export as PDF",
    'skill_trend_title': "Growth Trend",
    'skill_trend_empty': "Complete at least 2 missions to see this skill's trend.",
    'skill_trend_unit': "pts",
    // Role Names
    'role_chef': "Chef",
    'role_doctor': "Doctor",
    'role_artist': "Artist",
    'role_athlete': "Athlete",
    'role_teacher': "Teacher",
  },
  'id': {
    'title': "Perkembangan",
    'subtitle': "Rangkuman data secara transparan",
    'cognitive': "Kognitif",
    'empathy': "Empati",
    'creativity': "Kreativitas",
    'literacy': "Literasi",
    'motoric': "Motorik",
    'consistency': "Aktivitas Bulan Ini",
    'streak_label': "Hari Beruntun!",
    'mission_history': "Riwayat Misi",
    'filter_today': "Hari Ini",
    'filter_week': "Seminggu",
    'filter_month': "Sebulan",
    'filter_all': "Semua Peran",
    'empty_history': "Belum ada riwayat misi di filter ini.",
    'achievements': "Pencapaian Diraih",
    'xp_progress': "Progres XP",
    'level': "Level",
    'empty_achievements':
        "Belum ada pencapaian. Selesaikan misi untuk mendapatkannya!",
    'err_journal': "Gagal memuat jurnal misi: ",
    'err_load': "Error memuat data: ",
    'missions_count': "Misi",
    'default_child_name': "Anak",
    'export_pdf': "Ekspor PDF",
    'skill_trend_title': "Tren Perkembangan",
    'skill_trend_empty': "Selesaikan minimal 2 misi buat lihat tren skill ini.",
    'skill_trend_unit': "poin",
    // Role Names
    'role_chef': "Koki",
    'role_doctor': "Dokter",
    'role_artist': "Pelukis",
    'role_athlete': "Atlet",
    'role_teacher': "Guru",
  },
};

// ==========================================
// HELPER BULAN UNTUK KALENDER
// ==========================================
const List<String> _monthsId = [
  "",
  "Januari",
  "Februari",
  "Maret",
  "April",
  "Mei",
  "Juni",
  "Juli",
  "Agustus",
  "September",
  "Oktober",
  "November",
  "Desember",
];
const List<String> _monthsEn = [
  "",
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends ConsumerState<ProgressPage> {
  String _selectedTimeFilter = 'minggu';
  String _selectedRoleFilter = 'semua';
  bool _isExportingPdf = false;
  String? _selectedTrendSkill;

  // calculateLevelInfo() dipindah ke core/utils/level_utils.dart — dulu
  // fungsi ini (byte demi byte identik) ditulis ulang terpisah di
  // home_page.dart dan profile_page.dart.

  /// Ekspor laporan PDF — sebelumnya nggak ada cara buat orang tua nyimpen/
  /// nge-print/ngirim rangkuman progres anaknya ke luar app (misal buat
  /// ditunjukin ke guru/psikolog anak). Datanya persis riwayat & filter
  /// yang lagi aktif di layar (default filter "Minggu Ini" jadi otomatis
  /// ini bisa dipakai sebagai ringkasan mingguan tanpa fitur terpisah).
  Future<void> _exportReport(
    Map<String, String> texts,
    String lang,
    AsyncValue<List<dynamic>> historyAsync, {
    required String childName,
    required int level,
    required int totalXp,
    required int currentStreak,
    required Map<String, double> skillScores,
    required AsyncValue<List<Map<String, dynamic>>> achievementsAsync,
  }) async {
    setState(() => _isExportingPdf = true);
    try {
      final historyList = historyAsync.value ?? [];
      final missionHistory = historyList.map((item) {
        final skills = (item['earned_skills'] as Map?) ?? {};
        return {
          'roleId': item['role_id'],
          'completedAt': parseDateSafely(item['completed_at'] ?? ''),
          'xp': item['earned_xp'] ?? 0,
          'skills': skills.keys
              .map((k) => texts[k.toString().toLowerCase()] ?? k.toString())
              .toList(),
        };
      }).toList();

      final achievementsList = achievementsAsync.value ?? [];
      final achievements = achievementsList.map((a) {
        return {
          'title': lang == 'id'
              ? (a['title_id'] ?? 'Pencapaian')
              : (a['title_en'] ?? 'Achievement'),
          'unlockedAt': parseDateSafely(a['unlocked_at'] ?? ''),
        };
      }).toList();

      final timeFilterLabel = switch (_selectedTimeFilter) {
        'hari' => texts['filter_today']!,
        'bulan' => texts['filter_month']!,
        _ => texts['filter_week']!,
      };
      final roleFilterLabel = _selectedRoleFilter == 'semua'
          ? texts['filter_all']!
          : (roleVisualById(_selectedRoleFilter)?.name(lang) ?? _selectedRoleFilter);

      await exportProgressReportPdf(
        lang: lang,
        data: ProgressReportData(
          childName: childName,
          level: level,
          totalXp: totalXp,
          currentStreak: currentStreak,
          skillScores: skillScores,
          achievements: achievements,
          missionHistory: missionHistory,
          periodLabel: '$timeFilterLabel • $roleFilterLabel',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${texts['err_load']}$e")));
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  Future<void> _openJournalFromHistory(
    Map<String, dynamic> logItem,
    Map<String, String> texts,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const AppLoading(),
    );

    try {
      final supabase = Supabase.instance.client;
      final missionRes = await supabase
          .from('missions_master')
          .select()
          .eq('id', logItem['mission_id'])
          .single();
      final mission = MissionModel.fromJson(missionRes);

      final journalRes = await supabase
          .from('journals')
          .select('image_url')
          .eq('mission_log_id', logItem['id']);
      List<String> photos = (journalRes as List)
          .map((e) => e['image_url'].toString())
          .toList();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context, rootNavigator: true).push(
          appPageRoute(
            MissionJournalScreen(
              mission: mission,
              capturedPhotos: photos,
              isViewOnly: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${texts['err_journal']}$e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    final childDataAsync = ref.watch(childDataProvider);
    final String childId = childDataAsync.value?['id'] ?? '';

    final realtimeStreakAsync = ref.watch(streakProvider(childId));
    final statsAsync = ref.watch(childStatsProvider(childId));
    final monthlyDaysAsync = ref.watch(monthlyConsistencyProvider(childId));
    final trendAsync = ref.watch(skillTrendProvider(childId));

    final historyParams = "$childId|$_selectedTimeFilter|$_selectedRoleFilter";
    final historyAsync = ref.watch(missionHistoryProvider(historyParams));

    final achievementsAsync = ref.watch(childAchievementsProvider(childId));

    return childDataAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const AppLoading(),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: AppColors.background,
        body: AppErrorView(message: "${texts['err_load']}$error"),
      ),
      data: (data) {
        final String childName = data?['name'] ?? texts['default_child_name']!;
        final int currentStreak =
            realtimeStreakAsync.value ?? data?['current_streak'] ?? 0;
        final int totalXp = data?['total_xp'] ?? 0;

        final stats = statsAsync.value ?? {};
        final double cog = (stats['cognitive_score'] ?? 0).toDouble();
        final double emp = (stats['empathy_score'] ?? 0).toDouble();
        final double cre = (stats['creativity_score'] ?? 0).toDouble();
        final double lit = (stats['literacy_score'] ?? 0).toDouble();
        final double mot = (stats['motoric_score'] ?? 0).toDouble();

        final List<double> rawScores = [cog, emp, cre, lit, mot];

        double maxScore = 1.0;
        int maxIndex = 0;
        for (int i = 0; i < rawScores.length; i++) {
          if (rawScores[i] > rawScores[maxIndex]) maxIndex = i;
          if (rawScores[i] > maxScore) maxScore = rawScores[i];
        }

        final List<double> radarData = rawScores.map((score) {
          double normalized = score / maxScore;
          return normalized < 0.05 ? 0.05 : normalized;
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(texts, childName),
                  _buildStreakAndLevelSection(currentStreak, totalXp, texts, childId),
                  _buildRadarChart(texts, radarData, rawScores, maxIndex),
                  _buildSkillTrendSection(texts, trendAsync, maxIndex),

                  monthlyDaysAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: AppLoading(),
                    ),
                    error: (e, s) => const SizedBox(),
                    data: (activeDays) =>
                        _buildMonthlyCalendar(texts, activeDays, lang),
                  ),

                  _buildMissionHistorySection(
                    context,
                    texts,
                    lang,
                    historyAsync,
                    childName: childName,
                    level: calculateLevel(totalXp),
                    totalXp: totalXp,
                    currentStreak: currentStreak,
                    skillScores: {
                      'cognitive': cog,
                      'empathy': emp,
                      'creativity': cre,
                      'literacy': lit,
                      'motoric': mot,
                    },
                    achievementsAsync: achievementsAsync,
                  ),

                  _buildAchievementsSection(texts, achievementsAsync, lang),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, String> texts, String childName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${texts['title']} $childName",
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            texts['subtitle']!,
            style: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakAndLevelSection(
    int streak,
    int totalXp,
    Map<String, String> texts,
    String childId,
  ) {
    final levelData = calculateLevelInfo(totalXp);
    final int level = levelData.level;
    final int currentXp = levelData.currentXp;
    final int maxXp = levelData.maxXp;

    final double progress = (currentXp / maxXp).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              // Dulu kartu ini statis (angka streak polos, nggak bisa
              // di-tap). Sekarang buka kalender streak -- pola hari
              // aktif/kelewat, bukan cuma 1 angka.
              child: GestureDetector(
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  appPageRoute(StreakCalendarPage(childId: childId)),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF4E5), Color(0xFFFFE8CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("🔥", style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 8),
                      Text(
                        "$streak",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        texts['streak_label']!,
                        style: TextStyle(
                          color: AppColors.primary.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryTint, const Color(0xFFD9EAFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryLighter.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("⭐", style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      "${texts['level']} $level",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(
                          0xFF0A264F,
                        ).withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.gold,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$currentXp / $maxXp XP",
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarChart(
    Map<String, String> texts,
    List<double> dataValues,
    List<double> rawScores,
    int topIndex,
  ) {
    return Container(
      height: 360,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: RadarChartPainter(dataValues: dataValues),
            ),
          ),
          Positioned(
            top: 0,
            child: _ChartLabel(
              texts['cognitive']!,
              rawScores[0].toInt(),
              isActive: topIndex == 0,
            ),
          ),
          Positioned(
            right: 16,
            top: 80,
            child: _ChartLabel(
              texts['empathy']!,
              rawScores[1].toInt(),
              isActive: topIndex == 1,
            ),
          ),
          Positioned(
            right: 24,
            bottom: 20,
            child: _ChartLabel(
              texts['creativity']!,
              rawScores[2].toInt(),
              isActive: topIndex == 2,
            ),
          ),
          Positioned(
            left: 24,
            bottom: 20,
            child: _ChartLabel(
              texts['literacy']!,
              rawScores[3].toInt(),
              isActive: topIndex == 3,
            ),
          ),
          Positioned(
            left: 16,
            top: 80,
            child: _ChartLabel(
              texts['motoric']!,
              rawScores[4].toInt(),
              isActive: topIndex == 4,
            ),
          ),
        ],
      ),
    );
  }

  // Daftar key-nya dari core/constants/skills.dart (dulu ditulis ulang
  // di sini). Dipertahankan sebagai field biar sisa kodenya nggak berubah.
  static final List<String> _trendSkillKeys = kSkillKeys;

  /// Tren skor skill dari waktu ke waktu — `child_stats` cuma nyimpen
  /// snapshot skor SAAT INI, jadi sebelumnya nggak ada cara buat orang tua
  /// lihat perkembangan itu naik dari mana ke mana. Dihitung dari
  /// `skillTrendProvider` (kumulatif `earned_skills` tiap misi selesai,
  /// diurutkan berdasarkan tanggal — nggak perlu skema baru).
  Widget _buildSkillTrendSection(
    Map<String, String> texts,
    AsyncValue<List<SkillTrendPoint>> trendAsync,
    int defaultSkillIndex,
  ) {
    // Default skill yang ditampilkan = skill paling menonjol di radar chart,
    // tapi cuma di-set sekali (kalau parent belum pernah ganti pilihan)
    // biar nggak reset ke default tiap kali data lain berubah.
    _selectedTrendSkill ??= _trendSkillKeys[defaultSkillIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts['skill_trend_title']!,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            // 34 -> 40: AppChoiceChip tingginya ditentukan padding-nya
            // sendiri (biar seragam sama chip di layar lain), sedikit
            // lebih tinggi dari kotak lama yang dipatok pas-pasan.
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _trendSkillKeys
                  .map(
                    (key) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChoiceChip(
                        label: texts[key]!,
                        selected: _selectedTrendSkill == key,
                        onTap: () => setState(() => _selectedTrendSkill = key),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          trendAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AppLoading(),
            ),
            error: (e, s) => const SizedBox(),
            data: (points) {
              if (points.length < 2) {
                return AppEmptyState(
                  message: texts['skill_trend_empty']!,
                  icon: Icons.show_chart_rounded,
                );
              }

              final skill = _selectedTrendSkill!;
              final spots = points
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.cumulative[skill] ?? 0))
                  .toList();
              final double maxY = spots
                  .map((s) => s.y)
                  .reduce((a, b) => a > b ? a : b);
              final double interval = (points.length / 4).clamp(1, 999).roundToDouble();

              return AppCard(
                child: SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY <= 0 ? 10 : maxY * 1.2,
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              final idx = value.round();
                              if (idx < 0 || idx >= points.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('d/M').format(points[idx].date),
                                  style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                            return LineTooltipItem(
                              '${s.y.toInt()} ${texts['skill_trend_unit']}',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                            );
                          }).toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppColors.accent,
                          barWidth: 3,
                          dotData: FlDotData(show: points.length <= 12),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.accent.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== WIDGET KALENDER BULANAN ====================
  Widget _buildMonthlyCalendar(
    Map<String, String> texts,
    Set<int> activeDays,
    String lang,
  ) {
    final now = DateTime.now();
    final int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);

    // Tentukan hari pertama di bulan ini (Senin=1, Minggu=7)
    final int firstDayWeekday = DateTime(now.year, now.month, 1).weekday;
    // Mengubah index supaya hari Senin = 0, Selasa = 1, dll.
    final int startOffset = firstDayWeekday - 1;

    final List<String> weekdays = lang == 'id'
        ? ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final String monthName = lang == 'id'
        ? "${_monthsId[now.month]} ${now.year}"
        : "${_monthsEn[now.month]} ${now.year}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                texts['consistency']!,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  monthName,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Hari
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: weekdays
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                color: const Color(
                                  0xFF0A264F,
                                ).withValues(alpha: 0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),

                // Grid Kalender
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: startOffset + daysInMonth,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, // 7 hari dalam seminggu
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0, // Bentuk kotak/lingkaran presisi
                  ),
                  itemBuilder: (context, index) {
                    // Kotak kosong di awal bulan
                    if (index < startOffset) {
                      return const SizedBox();
                    }

                    // Tanggal aktual
                    final int day = index - startOffset + 1;
                    final bool isActive = activeDays.contains(day);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.accent
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFE57B65,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: isActive
                          ? const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 18,
                            )
                          : Text(
                              "$day",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionHistorySection(
    BuildContext context,
    Map<String, String> texts,
    String lang,
    AsyncValue<List<dynamic>> historyAsync, {
    required String childName,
    required int level,
    required int totalXp,
    required int currentStreak,
    required Map<String, double> skillScores,
    required AsyncValue<List<Map<String, dynamic>>> achievementsAsync,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  texts['mission_history']!,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Ekspor PDF — sebelumnya nggak ada cara buat orang tua
              // nyimpen/ngirim rangkuman progres ke luar app. Ngikutin
              // filter yang lagi aktif di layar (default "Minggu Ini"),
              // jadi otomatis jadi ringkasan mingguan kalau filternya
              // dibiarkan default.
              IconButton(
                tooltip: texts['export_pdf'],
                onPressed: _isExportingPdf
                    ? null
                    : () => _exportReport(
                        texts,
                        lang,
                        historyAsync,
                        childName: childName,
                        level: level,
                        totalXp: totalXp,
                        currentStreak: currentStreak,
                        skillScores: skillScores,
                        achievementsAsync: achievementsAsync,
                      ),
                icon: _isExportingPdf
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.picture_as_pdf_rounded, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Row(
            children: [
              Expanded(
                child: _buildStyledDropdown(
                  value: _selectedTimeFilter,
                  items: {
                    'hari': texts['filter_today']!,
                    'minggu': texts['filter_week']!,
                    'bulan': texts['filter_month']!,
                  },
                  onChanged: (v) => setState(() => _selectedTimeFilter = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStyledDropdown(
                  value: _selectedRoleFilter,
                  items: {
                    'semua': texts['filter_all']!,
                    'chef': texts['role_chef']!,
                    'doctor': texts['role_doctor']!,
                    'artist': texts['role_artist']!,
                    'athlete': texts['role_athlete']!,
                    'teacher': texts['role_teacher']!,
                  },
                  onChanged: (v) => setState(() => _selectedRoleFilter = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          historyAsync.when(
            loading: () => const AppLoading(),
            error: (e, s) => AppErrorView(message: "${texts['err_load']}$e"),
            data: (historyData) {
              if (historyData.isEmpty) {
                return AppEmptyState(
                  message: texts['empty_history']!,
                  icon: Icons.history_toggle_off_rounded,
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historyData.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = historyData[index];
                  return GestureDetector(
                    onTap: () => _openJournalFromHistory(item, texts),
                    child: _buildHistoryCard(item, texts, lang),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(
    Map<String, String> texts,
    AsyncValue<List<Map<String, dynamic>>> achievementsAsync,
    String lang, // Tambahkan parameter bahasa
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts['achievements']!,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          achievementsAsync.when(
            loading: () => const AppLoading(),
            error: (e, s) => const SizedBox(),
            data: (achievements) {
              if (achievements.isEmpty) {
                return AppEmptyState(
                  message: texts['empty_achievements']!,
                  icon: Icons.emoji_events_outlined,
                );
              }
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: achievements
                    .map((a) => _buildAchievementBadge(a, lang))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(Map<String, dynamic> achievement, String lang) {
    final String icon = achievement['icon_url']?.toString() ?? '🏅';
    // Gunakan translasi dinamis
    final String title = lang == 'id'
        ? (achievement['title_id'] ?? 'Pencapaian')
        : (achievement['title_en'] ?? 'Achievement');

    final role = roleVisualById(achievement['role_id']?.toString()) ?? kUnknownRoleVisual;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md - 2),
      radius: AppRadius.md,
      child: SizedBox(
        width: (context.screenWidth - 72) / 2 - (AppSpacing.md - 2) * 2,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(color: role.resolvedTint, shape: BoxShape.circle),
              child: Text(icon, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyBold(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String value,
    required Map<String, String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary,
          ),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          items: items.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    Map<String, dynamic> item,
    Map<String, String> texts,
    String lang,
  ) {
    final int xp = item['earned_xp'] ?? 0;
    final Map<String, dynamic> skills = item['earned_skills'] ?? {};

    final String dateStr = item['completed_at'] ?? '';
    final dateTime = parseDateSafely(dateStr);
    final String formattedDate = dateTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(dateTime)
        : dateStr;

    final role = roleVisualById(item['role_id']?.toString()) ?? kUnknownRoleVisual;
    final String roleName = role.name(lang);

    String skillsGained = skills.keys
        .map((k) {
          return texts[k.toLowerCase()] ?? k;
        })
        .join(', ');

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: role.resolvedTint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Image.asset(
              role.penguinIcon,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roleName, style: AppTextStyles.bodyBold().copyWith(fontSize: 16)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formattedDate,
                  style: AppTextStyles.caption(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (skillsGained.isNotEmpty)
                  Text(
                    "+ $skillsGained",
                    style: AppTextStyles.caption(color: AppColors.success).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              "+$xp XP",
              style: AppTextStyles.caption(color: AppColors.gold).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// WIDGET BANTUAN & CUSTOM PAINTER
// ==========================================
class _ChartLabel extends StatelessWidget {
  final String text;
  final int score;
  final bool isActive;
  const _ChartLabel(this.text, this.score, {required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? null
            : Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : AppColors.primary.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "$score Pts",
            style: TextStyle(
              color: isActive
                  ? AppColors.accent
                  : AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final List<double> dataValues;
  RadarChartPainter({required this.dataValues});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;

    final paintWebLine = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final paintAxisLine = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const int sides = 5;
    final double angle = (2 * math.pi) / sides;
    const double rotationOffset = -math.pi / 2;

    for (int step = 1; step <= 4; step++) {
      final double currentRadius = radius * (step / 4);
      final Path path = Path();
      for (int i = 0; i < sides; i++) {
        double x =
            center.dx + currentRadius * math.cos(angle * i + rotationOffset);
        double y =
            center.dy + currentRadius * math.sin(angle * i + rotationOffset);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paintWebLine);
    }

    for (int i = 0; i < sides; i++) {
      double x = center.dx + radius * math.cos(angle * i + rotationOffset);
      double y = center.dy + radius * math.sin(angle * i + rotationOffset);
      canvas.drawLine(center, Offset(x, y), paintAxisLine);
    }

    final safeValues = dataValues.length == 5
        ? dataValues
        : [0.05, 0.05, 0.05, 0.05, 0.05];

    final Path dataPath = Path();
    final List<Offset> dataPoints = [];

    for (int i = 0; i < sides; i++) {
      double dataRadius = radius * safeValues[i];
      double x = center.dx + dataRadius * math.cos(angle * i + rotationOffset);
      double y = center.dy + dataRadius * math.sin(angle * i + rotationOffset);
      dataPoints.add(Offset(x, y));
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    final paintDataFill = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.5),
          AppColors.accent.withValues(alpha: 0.2),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, paintDataFill);

    final paintDataStroke = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(dataPath, paintDataStroke);

    final paintDot = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    for (var point in dataPoints) {
      canvas.drawCircle(
        point,
        6,
        Paint()..color = AppColors.accent.withValues(alpha: 0.3),
      );
      canvas.drawCircle(point, 4, paintDot);
    }
  }

  @override
  bool shouldRepaint(covariant RadarChartPainter oldDelegate) {
    return true;
  }
}
