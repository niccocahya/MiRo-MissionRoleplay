import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/providers/language_provider.dart';
import '../../core/providers/child_provider.dart';
import '../../core/providers/child_role_progress_provider.dart';
import '../../core/providers/child_stats_provider.dart';
import '../../core/providers/notification_prefs_provider.dart';
import '../../core/providers/parent_provider.dart';
import '../../core/providers/streak_provider.dart';
import '../../core/services/progress_repair_service.dart';
import '../../core/router/app_page_transition.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/level_utils.dart';
import '../profile/screens/all_certificates_page.dart';
import '../../core/constants/role_visuals.dart';
import '../missions/data/mission_provider.dart';
import '../missions/data/mission_model.dart';
import '../missions/screens/mission_intro_screen.dart';
import '../missions/screens/mission_search_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../profile/screens/all_badges_page.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_state_views.dart';
import '../../shared/widgets/penguin_chat_bot.dart';
import '../../shared/widgets/section_header.dart';

// parseDateSafely dipindah ke core/utils/date_utils.dart (dulu duplikat
// persis di sini dan di progress_page.dart).

// ==========================================
// 🔥 PROVIDER BARU: MENGAMBIL NAMA ORANG TUA DARI DATABASE
// ==========================================
// parentNameProvider dipindah ke core/providers/parent_provider.dart --
// layar Profil juga butuh (dulu Profil baca nama dari sumber LAIN, lihat
// catatan di file itu).

// ==========================================
// PROVIDER REAL-TIME 1: MENDENGARKAN TOTAL XP ANAK SECARA LIVE
// ==========================================
final childRealtimeXpProvider = StreamProvider.family<int, String>((
  ref,
  childId,
) {
  if (childId.isEmpty) return Stream.value(0);
  return Supabase.instance.client
      .from('children')
      .stream(primaryKey: ['id'])
      // Disaring di SERVER. Dulu stream ini narik SELURUH baris `children`
      // yang boleh dilihat akun ini, terus nyari anaknya satu-satu di Dart
      // -- tiap perubahan di anak MANA PUN mengirim ulang seluruh daftar
      // dan bikin Home rebuild. 12 stream lain di app ini udah pakai
      // `.eq()`, cuma yang ini sama yang di bawah yang ketinggalan.
      .eq('id', childId)
      .map((event) {
        if (event.isEmpty) return 0;
        return event.first['total_xp'] as int? ?? 0;
      });
});

// ==========================================
// PROVIDER REAL-TIME 2: MENGHITUNG KONSISTENSI MINGGU INI (MINGGU - SABTU)
// ==========================================
final weeklyMissionCountStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, childId) {
      if (childId.isEmpty) return Stream.value([]);

      final supabase = Supabase.instance.client;

      // WAKTU LOKAL, bukan UTC. Dulu batas minggunya dihitung di UTC --
      // buat WIB (UTC+7) itu artinya "minggu" versi grafik ini mulai jam
      // 07:00 pagi Senin, bukan tengah malam. Misi yang dikerjain
      // 00:00-06:59 WIB masuk ke kotak hari SEBELUMNYA, dan misi Minggu
      // malam bisa kehitung minggu berikutnya. parseDateSafely sekarang
      // balikin waktu lokal, jadi batasnya harus lokal juga biar nyambung.
      final now = DateTime.now();

      final int daysSinceSunday = now.weekday == 7 ? 0 : now.weekday;

      final startOfWeek = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysSinceSunday));

      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      return supabase
          .from('mission_logs')
          .stream(primaryKey: ['id'])
          // Sama kayak childRealtimeXpProvider di atas: dulu ini narik
          // SELURUH tabel mission_logs terus disaring di Dart. Makin banyak
          // misi yang diselesaikan, makin berat -- dan tiap perubahan satu
          // baris ngirim ulang semuanya.
          .eq('child_id', childId)
          .map((event) {
        // Satu misi cuma boleh dihitung SEKALI, di penyelesaian
        // pertamanya. Di database masih ada baris 'completed' dobel
        // peninggalan celah lama (sebelum penjaga anti-dobel ada), dan
        // tanpa dedupe ini batang grafiknya kelihatan lebih tinggi dari
        // yang sebenarnya dikerjakan. Level, lencana, sama angka "misi
        // selesai" semuanya udah dihitung per misi unik -- grafik ini
        // yang terakhir belum ikut.
        final Map<String, DateTime> pertamaSelesai = {};
        for (final row in event) {
          if (row['status'] != 'completed') continue;
          final missionId = row['mission_id'] as String?;
          if (missionId == null) continue;
          final date = parseDateSafely(row['completed_at'] ?? '');
          if (date == null) continue;

          final sebelumnya = pertamaSelesai[missionId];
          if (sebelumnya == null || date.isBefore(sebelumnya)) {
            pertamaSelesai[missionId] = date;
          }
        }

        Map<int, int> missionsPerDay = {};

        for (final date in pertamaSelesai.values) {
          if (!date.isBefore(startOfWeek) && date.isBefore(endOfWeek)) {
            missionsPerDay[date.weekday] =
                (missionsPerDay[date.weekday] ?? 0) + 1;
          }
        }

        final List<int> weekdayOrder = [7, 1, 2, 3, 4, 5, 6];

        return weekdayOrder
            .map((wd) => {'weekday': wd, 'count': missionsPerDay[wd] ?? 0})
            .toList();
      });
    });

// ==========================================
// PROVIDER REAL-TIME 3: PENCAPAIAN ANAK LENGKAP DENGAN JOIN
// ==========================================
final childAchievementsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, childId) {
      if (childId.isEmpty) return Stream.value([]);

      final supabase = Supabase.instance.client;

      return supabase
          .from('child_achievements')
          .stream(
            primaryKey: ['child_id', 'achievement_id'],
          ) // Primary Key Komposit
          .eq('child_id', childId)
          .asyncMap((achievements) async {
            if (achievements.isEmpty) return <Map<String, dynamic>>[];

            try {
              final achievementIds = achievements
                  .map((a) => a['achievement_id'])
                  .toSet()
                  .toList();

              final masterRes = await supabase
                  .from('achievements_master')
                  .select('id, title_id, title_en, icon_url, role_id')
                  .inFilter('id', achievementIds);

              final masterMap = {for (var item in masterRes) item['id']: item};

              final List<Map<String, dynamic>> mappedList = achievements.map((
                item,
              ) {
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

              mappedList.sort((a, b) {
                final dateA =
                    parseDateSafely(a['unlocked_at'] ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                final dateB =
                    parseDateSafely(b['unlocked_at'] ?? '') ??
                    DateTime.fromMillisecondsSinceEpoch(0);
                return dateB.compareTo(dateA); // Descending
              });

              return mappedList;
            } catch (e) {
              return [];
            }
          });
    });

// ==========================================
// DICTIONARY (KAMUS BAHASA HOME PAGE)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'greeting': "Hello,",
    'child_fallback': "Champ",
    'subtitle': "Let's start today's adventure!",
    'little_explorer': "Little Explorer",
    'motivation': "You're doing great!",
    'today_rec': "TODAY'S MISSION RECOMMENDATION",
    'btn_start_mission': "Start Mission",
    'qa_certificates': "All Certificates",
    'qa_progress': "Full Progress",
    'choose_role': "Choose role\ntoday",
    'choose_role_desc': "Each role trains different skills",
    'weekly_prog': "Weekly Progress",
    'keep_it_up': "Keep it up this week!",
    'recent_achieve': "Recent Achievements",
    'see_all': "See All",
    'btn_start_role': "Start This Role",
    'empty_progress': "No activity this week. Let's start the first adventure!",
    'empty_achieve': "No achievements yet. Complete a mission to earn one!",
    'err_loading': "Error loading data: ",
    'streak_active_title': "day streak going!",
    'streak_active_desc': "You're all set for today. Nice work!",
    'streak_start_title': "Start a streak today",
    'streak_start_desc': "Complete a mission to begin your streak.",
    'streak_risk_title': "day streak — about to break!",
    'streak_risk_desc': "Finish 1 mission today before it resets to zero.",
  },
  'id': {
    'greeting': "Halo, Bapak/Ibu",
    'child_fallback': "Anak Hebat",
    'subtitle': "Mari mulai petualangan hari ini!",
    'little_explorer': "Penjelajah Kecil",
    'motivation': "Kamu melakukan yang terbaik!",
    'today_rec': "REKOMENDASI MISI HARI INI",
    'btn_start_mission': "Mulai Misi",
    'qa_certificates': "Semua Sertifikat",
    'qa_progress': "Progress Lengkap",
    'choose_role': "Pilih peran\nhari ini",
    'choose_role_desc': "Setiap peran melatih keahlian berbeda",
    'weekly_prog': "Kemajuan Mingguan",
    'keep_it_up': "Pertahankan terus minggu ini!",
    'recent_achieve': "Pencapaian Terbaru",
    'see_all': "Lihat Semua",
    'btn_start_role': "Mulai Peran Ini",
    'empty_progress':
        "Belum ada aktivitas minggu ini. Yuk mulai petualangan pertama!",
    'empty_achieve':
        "Belum ada pencapaian. Selesaikan misi untuk mendapatkannya!",
    'err_loading': "Error memuat data: ",
    'streak_active_title': "hari beruntun!",
    'streak_active_desc': "Udah aman buat hari ini. Mantap!",
    'streak_start_title': "Mulai streak hari ini",
    'streak_start_desc': "Selesaikan misi buat mulai streak-mu.",
    'streak_risk_title': "hari beruntun — hampir putus!",
    'streak_risk_desc': "Selesaikan 1 misi hari ini sebelum balik ke nol.",
  },
};

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Anak-anak yang progresnya udah dicek di sesi ini, biar penambalan
  // nggak jalan berulang tiap Home rebuild.
  final Set<String> _progressRepairChecked = {};

  @override
  void initState() {
    super.initState();
    // 🔥 MUNCULKAN MINK SECARA RESMI DI SINI SAAT HOME KELUAR!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showChatbotGlobalProvider.notifier).show();
    });
  }

  /// Sekali per anak per sesi: hitung ulang XP, level, poin skill, dan
  /// lencana dari log misi, lalu tambal yang kurang. Lihat
  /// ProgressRepairService -- penyimpanan hadiah misi nggak atomik, jadi
  /// koneksi yang putus di tengah bisa bikin sebagian hadiah hilang
  /// permanen kalau nggak ada yang ngecek ulang begini.
  void _repairProgressOnce(String childId) {
    if (childId.isEmpty || _progressRepairChecked.contains(childId)) return;
    _progressRepairChecked.add(childId);
    ProgressRepairService.repairMissing(childId);
  }

  // calculateLevelInfo() dipindah ke core/utils/level_utils.dart — dulu
  // fungsi ini (byte demi byte identik) ditulis ulang terpisah di
  // progress_page.dart dan profile_page.dart.

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    final childDataAsync = ref.watch(childDataProvider);
    final parentNameAsync = ref.watch(parentNameProvider);
    final String parentName = parentNameAsync.value ?? "";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(showChatbotGlobalProvider)) {
        ref.read(showChatbotGlobalProvider.notifier).show();
      }
    });

    return childDataAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const AppLoading(),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: AppColors.background,
        body: AppErrorView(message: "${texts['err_loading']}$error"),
      ),
      data: (data) {
        if (data == null) {
          // Parent ini nggak punya anak sama sekali -- state yang BARU
          // bisa kejadian sejak fitur hapus anak ada (dulu anak cuma bisa
          // nambah, nggak bisa hilang, jadi Home nggak pernah perlu
          // mikirin ini). Tanpa penjaga ini, Home tetap "jalan" dibangun
          // pakai childId kosong -- semua provider di bawah punya
          // fallback nol/kosong buat itu, TAPI kartu "Misi Hari Ini"
          // tetap nawarin misi role rekomendasi default meski nggak ada
          // anak yang beneran bisa ngerjainnya, dan mulai misi dari situ
          // bakal gagal pas nyoba nyimpen progres (butuh anak aktif,
          // lihat mission_journal_screen.dart). Sama kayak
          // login/onboarding: nggak ada anak, arahin ke /identify.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/identify');
          });
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const AppLoading(),
          );
        }

        final String childId = data['id'];
        _repairProgressOnce(childId);
        // Fallback-nya sekarang ikut bahasa, dan ikut jalan buat nama
        // yang KOSONG -- bukan cuma null. `?? "Anak Hebat"` yang dulu
        // nggak nangkep string kosong, dan orang tua yang milih English
        // tetap disapa pakai teks Indonesia.
        final String rawChildName = (data['name'] as String? ?? '').trim();
        final String childName =
            rawChildName.isEmpty ? texts['child_fallback']! : rawChildName;

        final realtimeXpAsync = ref.watch(childRealtimeXpProvider(childId));
        final int totalXp = realtimeXpAsync.value ?? data['total_xp'] ?? 0;

        final levelData = calculateLevelInfo(totalXp);
        final int childLevel = levelData.level;
        final int childCurrentXp = levelData.currentXp;
        final int childMaxXp = levelData.maxXp;

        final progressAsync = ref.watch(
          weeklyMissionCountStreamProvider(childId),
        );
        final achievementsAsync = ref.watch(childAchievementsProvider(childId));
        final streakAsync = ref.watch(streakProvider(childId));
        final streakAtRiskAsync = ref.watch(streakAtRiskProvider(childId));

        // Rekomendasi misi: pilih role berdasarkan skill anak yang PALING
        // RENDAH saat ini (sebelumnya kartu ini statis, selalu nampilin
        // "Memasak Bersama" / role Koki buat semua anak apapun datanya).
        final statsAsync = ref.watch(childStatsProvider(childId));
        final String recommendedRoleId = recommendedRoleFromStats(
          statsAsync.value ?? {},
        );
        final recommendedMissionsAsync = ref.watch(
          missionsByRoleProvider(recommendedRoleId),
        );
        // missionsByRoleProvider balikin SEMUA misi role itu, urutan apa
        // adanya dari database -- dulu kartu "misi hari ini" langsung
        // pakai .first dari situ, jadi kadang nunjukin misi yang udah
        // KESELESAI atau yang masih TERKUNCI, bukan misi yang beneran
        // lagi jadi giliran anak. Dihitung ulang di sini pakai
        // unlocked_level yang sama dipakai peta misi/pencarian misi.
        final roleProgressAsync = ref.watch(
          childRoleProgressProvider(childId),
        );
        final List<MissionModel>? recommendedMissions =
            recommendedMissionsAsync.value;
        final int recommendedUnlockedLevel =
            roleProgressAsync.value?[recommendedRoleId] ?? 1;
        // null kalau list-nya kosong ATAU anak udah nyelesein semua misi
        // role ini (unlockedLevel ngelewatin panjang list) -- di kedua
        // kasus itu kartu fallback ke deskripsi role generik + tombol ke
        // peta role, bukan maksa nunjukin misi yang udah kelar sebagai
        // "misi hari ini".
        final MissionModel? currentMission =
            (recommendedMissions == null ||
                    recommendedMissions.isEmpty ||
                    recommendedUnlockedLevel > recommendedMissions.length)
                ? null
                : recommendedMissions[recommendedUnlockedLevel - 1];

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ResponsiveCenter(
                maxWidth: 640,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, texts, parentName),
                    _buildUserCard(
                      context,
                      texts,
                      childName,
                      childLevel,
                      childCurrentXp,
                      childMaxXp,
                    ),
                    _buildStreakReminder(
                      context,
                      texts,
                      streakAsync.value,
                      streakAtRiskAsync.value ?? false,
                    ),
                    _buildQuickActions(context, texts),
                    _buildTodayMissionCard(
                      context,
                      texts,
                      lang,
                      recommendedRoleId,
                      currentMission,
                    ),
                    _buildChooseRole(context, texts, lang),

                    progressAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: AppLoading(),
                      ),
                      error: (e, s) => Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text("${texts['err_loading']}$e"),
                      ),
                      data: (progressData) =>
                          _buildStackedBoxProgress(context, texts, progressData, lang),
                    ),

                    achievementsAsync.when(
                      loading: () => const SizedBox(),
                      error: (e, s) => const SizedBox(),
                      data: (achievementsData) => _buildRecentAchievements(
                        context,
                        texts,
                        achievementsData,
                        lang,
                        childId,
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Map<String, String> texts,
    String parentName,
  ) {
    final hPad = context.pageHPadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.lg, hPad, AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${texts['greeting']} $parentName".trim(),
                  style: AppTextStyles.h2(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  texts['subtitle']!,
                  style: AppTextStyles.body(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: () => Navigator.of(
              context,
              rootNavigator: true,
            ).push(appPageRoute(MissionSearchScreen())),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Builder(
            builder: (context) {
              // Sebelumnya titik oranye kosong nempel terus tanpa nunjukin
              // ada berapa notif yang belum dibaca.
              final unread = ref.watch(unreadNotificationCountProvider);
              return GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Jalan pintas ke halaman yang sering dicek orang tua — sebelumnya
  /// harus scroll manual atau lewat tab Profil buat sampai ke sini.
  Widget _buildQuickActions(BuildContext context, Map<String, String> texts) {
    final hPad = context.pageHPadding;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: _quickActionChip(
              icon: Icons.emoji_events_rounded,
              label: texts['qa_certificates']!,
              onTap: () => Navigator.of(
                context,
                rootNavigator: true,
              ).push(appPageRoute(AllCertificatesPage())),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: _quickActionChip(
              icon: Icons.bar_chart_rounded,
              label: texts['qa_progress']!,
              onTap: () => context.go('/progress'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(width: AppSpacing.xs + 2),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyBold(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pengingat streak — sebelumnya jumlah hari beruntun cuma kelihatan
  /// di halaman Progress, jadi orang tua nggak diingatkan buat jaga
  /// streak-nya dari layar utama. `streak` null berarti masih loading,
  /// jadi banner disembunyikan dulu biar nggak ada flicker "0 hari".
  Widget _buildStreakReminder(
    BuildContext context,
    Map<String, String> texts,
    int? streak,
    bool atRisk,
  ) {
    if (streak == null) return const SizedBox.shrink();
    final hPad = context.pageHPadding;
    final bool active = streak > 0;

    // 3 kondisi visual: belum punya streak (netral), streak aman (emas),
    // dan streak AKTIF TAPI BELUM lanjut hari ini (danger, mendesak).
    // Sebelumnya cuma 2 kondisi -- streak yang lagi kepotong-hampir-putus
    // ditampilin SAMA PERSIS kayak streak yang udah aman hari ini, jadi
    // orang tua nggak ada tanda sama sekali kalau streak-nya bakal ilang.
    final String emoji = atRisk ? '⚠️' : (active ? '🔥' : '✨');
    final Color bg = atRisk
        ? AppColors.dangerTint
        : (active ? AppColors.goldTint : AppColors.surface);
    final Color borderColor = atRisk
        ? AppColors.danger.withValues(alpha: 0.4)
        : (active ? AppColors.gold.withValues(alpha: 0.4) : AppColors.border);
    final String title = atRisk
        ? '$streak ${texts['streak_risk_title']!}'
        : (active
              ? '$streak ${texts['streak_active_title']!}'
              : texts['streak_start_title']!);
    final String desc = atRisk
        ? texts['streak_risk_desc']!
        : (active ? texts['streak_active_desc']! : texts['streak_start_desc']!);

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyBold(
                      color: atRisk ? AppColors.danger : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    desc,
                    style: AppTextStyles.caption(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    Map<String, String> texts,
    String childName,
    int level,
    int xp,
    int maxXp,
  ) {
    double progressPercent = maxXp > 0 ? xp / maxXp : 0.0;
    progressPercent = progressPercent.clamp(0.0, 1.0);
    final hPad = context.pageHPadding;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          color: AppColors.primary,
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    'assets/images/lamp.png',
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md + 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: const Text("👦🏻", style: TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: AppSpacing.sm + 4),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  childName,
                                  style: AppTextStyles.h3(color: Colors.white),
                                ),
                                Text(
                                  texts['little_explorer']!,
                                  style: AppTextStyles.caption(
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => context.push('/progress'),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "⭐ Level $level",
                          style: AppTextStyles.caption(color: Colors.white).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$xp/$maxXp XP",
                          style: AppTextStyles.caption(color: Colors.white).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressPercent,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6DD5FA), Color(0xFF2980B9)],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      texts['motivation']!,
                      style: AppTextStyles.caption(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayMissionCard(
    BuildContext context,
    Map<String, String> texts,
    String lang,
    String recommendedRoleId,
    MissionModel? mission,
  ) {
    // Rekomendasi asli berdasarkan skill anak yang paling perlu dilatih —
    // dulu kartu ini selalu nampilin "Memasak Bersama" (role Koki) buat
    // SEMUA anak, apapun datanya.
    final role = roleVisualById(recommendedRoleId) ?? kUnknownRoleVisual;

    final String missionTitle = mission == null
        ? role.name(lang)
        : (lang == 'id' ? mission.titleId : mission.titleEn);
    final String missionDesc = mission == null
        ? role.description(lang)
        : (lang == 'id' ? mission.descriptionId : mission.descriptionEn);

    final hPad = context.pageHPadding;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          color: AppColors.primaryLighter,
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.9,
                  child: Image.asset(
                    'assets/images/frost.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: Image.asset('assets/images/snow.png', fit: BoxFit.cover),
                ),
              ),
              Positioned(
                bottom: -20,
                right: -10,
                child: Image.asset(
                  // Pakai versi "_trans" (transparan) biar nyatu sama
                  // background kartu, bukan penguinIcon yang background-nya
                  // solid/nggak transparan.
                  role.bgImage,
                  width: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: SizedBox(
                  width: context.screenWidth * 0.55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texts['today_rec']!,
                        style: AppTextStyles.caption(
                          color: AppColors.primary.withValues(alpha: 0.8),
                        ).copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        missionTitle,
                        style: AppTextStyles.h1(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        missionDesc,
                        style: AppTextStyles.body(color: AppColors.primary.withValues(alpha: 0.7)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        // Dulu selalu bawa ke peta role-nya (`/missions?role=`)
                        // biar sesuai judul "Misi hari ini: [Judul Spesifik]",
                        // walau kartunya nunjukin 1 misi spesifik -- user
                        // harus nyari lagi manual misi yang sama di peta.
                        // Sekarang langsung ke misi itu kalau memang lagi
                        // jadi giliran anak (isCurrent); kalau nggak (mis.
                        // udah selesai semua/masih terkunci -- kasus langka
                        // tapi mungkin), fallback ke peta role seperti dulu.
                        onPressed: () {
                          if (mission != null) {
                            Navigator.of(context, rootNavigator: true).push(
                              appPageRoute(
                                MissionIntroScreen(
                                  mission: mission,
                                  roleName: role.name(lang),
                                ),
                              ),
                            );
                          } else {
                            context.go('/missions?role=$recommendedRoleId');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                        ).copyWith(elevation: WidgetStateProperty.all(5)),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.gold, AppColors.gold.withValues(alpha: 0.85)],
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(minWidth: 100, minHeight: 40),
                            child: Text(
                              texts['btn_start_mission']!,
                              style: AppTextStyles.button(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChooseRole(
    BuildContext context,
    Map<String, String> texts,
    String lang,
  ) {
    final hPad = context.pageHPadding;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                texts['choose_role']!,
                style: AppTextStyles.h2().copyWith(height: 1.2),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  texts['choose_role_desc']!,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            children: kRoleVisuals.map((role) {
              final title = role.name(lang);
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: GestureDetector(
                  onTap: () => _showRoleDetail(context, role, texts, lang),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      width: 140,
                      height: 190,
                      color: role.resolvedTint,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              role.penguinIcon,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: role.resolvedTint,
                                child: const Center(
                                  child: Icon(Icons.stars_rounded, color: Colors.black12, size: 60),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            height: 80,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.9),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: AppSpacing.md,
                            left: AppSpacing.md,
                            right: AppSpacing.md,
                            child: Text(
                              title,
                              style: AppTextStyles.bodyBold(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getDayName(int weekday, String lang) {
    const idNames = {1: 'Sen', 2: 'Sel', 3: 'Rab', 4: 'Kam', 5: 'Jum', 6: 'Sab', 7: 'Min'};
    const enNames = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    return (lang == 'id' ? idNames[weekday] : enNames[weekday]) ?? '-';
  }

  /// Card putih placeholder untuk state "belum ada data" — dipakai di
  /// progress mingguan & pencapaian, sebelumnya 2 blok kode ~30 baris yang
  /// isinya identik cuma beda icon & pesan.
  Widget _emptyCard({required IconData icon, required String message}) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 40),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body(),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedBoxProgress(
    BuildContext context,
    Map<String, String> texts,
    List progressData,
    String lang,
  ) {
    final hPad = context.pageHPadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xl, hPad, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(texts['weekly_prog']!, style: AppTextStyles.h3()),
          const SizedBox(height: AppSpacing.md),
          if (progressData.isEmpty)
            _emptyCard(
              icon: Icons.dashboard_customize_rounded,
              message: texts['empty_progress']!,
            )
          else
            AppCard(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md + 4,
                AppSpacing.xl - 2,
                AppSpacing.md + 4,
                AppSpacing.md + 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: progressData.map((dayData) {
                  final String dayName = _getDayName(dayData['weekday'], lang);
                  final int count = dayData['count'] ?? 0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Tooltip(
                        message: lang == 'id'
                            ? "$count Misi Selesai"
                            : "$count Missions Done",
                        preferBelow: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (count == 0)
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              )
                            else
                              ...List.generate(count, (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutBack,
                                  width: 26,
                                  height: 26,
                                  margin: const EdgeInsets.only(top: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm + 4),
                      Text(
                        dayName,
                        style: AppTextStyles.caption(
                          color: AppColors.primary.withValues(alpha: count > 0 ? 0.9 : 0.4),
                        ).copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievements(
    BuildContext context,
    Map<String, String> texts,
    List achievementsData,
    String lang,
    String childId,
  ) {
    final hPad = context.pageHPadding;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dulu cuma teks statis, nggak ada cara buat liat SEMUA badge
          // (termasuk yang masih terkunci) -- cuma strip beberapa
          // terakhir ini doang.
          SectionHeader(
            title: texts['recent_achieve']!,
            actionLabel: texts['see_all']!,
            onAction: () => Navigator.of(context, rootNavigator: true).push(
              appPageRoute(AllBadgesPage(childId: childId)),
            ),
          ),
          if (achievementsData.isEmpty)
            _emptyCard(
              icon: Icons.emoji_events_outlined,
              message: texts['empty_achieve']!,
            )
          else
            SizedBox(
              // Sebelumnya 80 — kartu ini overflow ~2px karena baris tanggal
              // nggak dibatasi 1 baris (bisa wrap jadi 2 baris kalau format
              // tanggalnya panjang) sementara tingginya udah dipatok pas.
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: achievementsData.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm + 4),
                itemBuilder: (context, index) {
                  final item = achievementsData[index];

                  final unlockedAt = parseDateSafely(item['unlocked_at'] ?? '');
                  final formattedDate = unlockedAt != null
                      ? DateFormat('dd MMM yyyy').format(unlockedAt)
                      : '-';

                  final String badgeTitle = lang == 'id'
                      ? (item['title_id'] ?? 'Prestasi Baru')
                      : (item['title_en'] ?? 'New Achievement');

                  return SizedBox(
                    width: 180,
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.sm + 4),
                      // Dulu kartu ini statis, nggak ada onTap sama sekali.
                      onTap: () => Navigator.of(context, rootNavigator: true)
                          .push(appPageRoute(AllBadgesPage(childId: childId))),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm + 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              item['icon_url'] ?? '🏅',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm + 2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  badgeTitle,
                                  style: AppTextStyles.bodyBold(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  formattedDate,
                                  style: AppTextStyles.caption(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showRoleDetail(
    BuildContext context,
    RoleVisual role,
    Map<String, String> texts,
    String lang,
  ) {
    final title = role.name(lang);
    final description = role.description(lang);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: context.screenHeight * 0.65,
          decoration: BoxDecoration(
            color: AppColors.primaryLighter,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.9,
                  child: Image.asset('assets/images/snow.png', fit: BoxFit.cover),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -80,
                right: -80,
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    role.bgImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.lg,
                right: AppSpacing.lg,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: AppColors.primary, size: 20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.h1(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm + 4),
                    Text(
                      description,
                      style: AppTextStyles.bodyLarge(
                        color: AppColors.primary.withValues(alpha: 0.8),
                      ).copyWith(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm + 4,
                      runSpacing: AppSpacing.sm + 4,
                      alignment: WrapAlignment.center,
                      children: role.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(skill.name(lang), style: AppTextStyles.bodyBold()),
                              const SizedBox(width: AppSpacing.sm),
                              Text(skill.icon, style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/missions?role=${role.id}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        texts['btn_start_role']!,
                        style: AppTextStyles.button().copyWith(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
