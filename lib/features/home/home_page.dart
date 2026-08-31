import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/providers/language_provider.dart';
import '../../core/providers/child_provider.dart';

// 🔥 IMPORT INI UNTUK MENGAKSES PROVIDER VISIBILITAS MINK
import '../../shared/widgets/penguin_chat_bot.dart';

// ==========================================
// FUNGSI PARSING TANGGAL SUPER ROBUST
// Menangani semua format dari Supabase & memaksa UTC → WIB
// ==========================================
DateTime? parseDateSafely(String dateStr) {
  if (dateStr.isEmpty) return null;

  String s = dateStr.trim();

  // Normalize ke ISO8601
  if (!s.contains('T') && s.contains(' ')) {
    s = s.replaceFirst(' ', 'T');
  }

  try {
    return DateTime.parse(s); // ✅ NO toLocal()
  } catch (_) {
    return null;
  }
}

// ==========================================
// 🔥 PROVIDER BARU: MENGAMBIL NAMA ORANG TUA DARI DATABASE
// ==========================================
final parentNameProvider = FutureProvider<String>((ref) async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "";
    final res = await Supabase.instance.client
        .from('parents')
        .select('full_name')
        .eq('id', user.id)
        .maybeSingle();
    return res?['full_name'] ?? "";
  } catch (e) {
    return "";
  }
});

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
      .map((event) {
        try {
          final childRow = event.firstWhere((row) => row['id'] == childId);
          return childRow['total_xp'] as int? ?? childRow['xp'] as int? ?? 0;
        } catch (e) {
          return 0;
        }
      });
});

// ==========================================
// PROVIDER REAL-TIME 2: MENGHITUNG KONSISTENSI MINGGU INI (MINGGU - SABTU)
// ==========================================
final weeklyMissionCountStreamProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, childId) {
      if (childId.isEmpty) return Stream.value([]);

      final supabase = Supabase.instance.client;

      // 🔥 PAKAI UTC AGAR SAMA DENGAN DATABASE
      final now = DateTime.now().toUtc();

      final int daysSinceSunday = now.weekday == 7 ? 0 : now.weekday;

      final startOfWeek = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysSinceSunday));

      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      return supabase.from('mission_logs').stream(primaryKey: ['id']).map((
        event,
      ) {
        final filteredMissions = event.where(
          (row) => row['child_id'] == childId && row['status'] == 'completed',
        );

        Map<int, int> missionsPerDay = {};

        for (var row in filteredMissions) {
          final completedAt = row['completed_at'];

          if (completedAt != null) {
            final date = parseDateSafely(completedAt);

            if (date != null &&
                !date.isBefore(startOfWeek) &&
                date.isBefore(endOfWeek)) {
              missionsPerDay[date.weekday] =
                  (missionsPerDay[date.weekday] ?? 0) + 1;
            }
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
    'subtitle': "Let's start today's adventure!",
    'little_explorer': "Little Explorer",
    'motivation': "You're doing great!",
    'today_rec': "TODAY'S MISSION RECOMMENDATION",
    'mission_title': "Cooking\nTogether",
    'mission_desc': "A fun way to play and learn together",
    'btn_start_mission': "Start Mission",
    'choose_role': "Choose role\ntoday",
    'choose_role_desc': "Each role trains different skills",
    'weekly_prog': "Weekly Progress",
    'keep_it_up': "Keep it up this week!",
    'recent_achieve': "Recent Achievements",
    'btn_start_role': "Start This Role",
    'empty_progress': "No activity this week. Let's start the first adventure!",
    'empty_achieve': "No achievements yet. Complete a mission to earn one!",
    'err_loading': "Error loading data: ",
  },
  'id': {
    'greeting': "Halo, Bapak/Ibu",
    'subtitle': "Mari mulai petualangan hari ini!",
    'little_explorer': "Penjelajah Kecil",
    'motivation': "Kamu melakukan yang terbaik!",
    'today_rec': "REKOMENDASI MISI HARI INI",
    'mission_title': "Memasak\nBersama",
    'mission_desc': "Cara yang menyenangkan untuk bermain dan belajar bersama",
    'btn_start_mission': "Mulai Misi",
    'choose_role': "Pilih peran\nhari ini",
    'choose_role_desc': "Setiap peran melatih keahlian berbeda",
    'weekly_prog': "Kemajuan Mingguan",
    'keep_it_up': "Pertahankan terus minggu ini!",
    'recent_achieve': "Pencapaian Terbaru",
    'btn_start_role': "Mulai Peran Ini",
    'empty_progress':
        "Belum ada aktivitas minggu ini. Yuk mulai petualangan pertama!",
    'empty_achieve':
        "Belum ada pencapaian. Selesaikan misi untuk mendapatkannya!",
    'err_loading': "Error memuat data: ",
  },
};

// ==========================================
// DATA ROLE
// ==========================================
final List<Map<String, dynamic>> roleData = [
  {
    "id": "artist",
    "title": "Pelukis",
    "title_en": "Artist",
    "description": "Ekspresikan dirimu lewat warna, bentuk, dan kreativitas.",
    "description_en":
        "Express yourself through colors, shapes, and creativity.",
    "skills": [
      {"name": "Kreativitas", "name_en": "Creativity", "icon": "🎨"},
      {"name": "Motorik", "name_en": "Motor Skills", "icon": "🧩"},
    ],
    "bgImage": "assets/images/artist_trans.png",
    "cardImage": "assets/images/penguin_artist.png",
    "cardBg": const Color(0xFFFDF1E8),
  },
  {
    "id": "chef",
    "title": "Koki",
    "title_en": "Chef",
    "description": "Belajar membuat makanan sambil mengenal tekstur dan rasa.",
    "description_en":
        "Learn to make food while getting to know textures and flavors.",
    "skills": [
      {"name": "Kognitif", "name_en": "Cognitive", "icon": "🧠"},
      {"name": "Motorik", "name_en": "Motor Skills", "icon": "🧩"},
    ],
    "bgImage": "assets/images/chef_trans.png",
    "cardImage": "assets/images/penguin_chef.png",
    "cardBg": const Color(0xFFEBF4FA),
  },
  {
    "id": "doctor",
    "title": "Dokter",
    "title_en": "Doctor",
    "description":
        "Jelajahi tubuh manusia dan belajar merawat orang lain tanpa gawai.",
    "description_en":
        "Explore the human body and learn how to care for others screen free.",
    "skills": [
      {"name": "Kognitif", "name_en": "Cognitive", "icon": "🧠"},
      {"name": "Empati", "name_en": "Empathy", "icon": "💗"},
    ],
    "bgImage": "assets/images/doctor_trans.png",
    "cardImage": "assets/images/penguin_doctor.png",
    "cardBg": const Color(0xFFE8F2E6),
  },
  {
    "id": "athlete",
    "title": "Atlet",
    "title_en": "Athlete",
    "description": "Latih ketangkasan fisik dan sportivitasmu sejak dini.",
    "description_en": "Train your physical agility and sportsmanship early on.",
    "skills": [
      {"name": "Motorik", "name_en": "Motoric", "icon": "🏃"},
      {"name": "Kognitif", "name_en": "Cognitive", "icon": "🧠"},
    ],
    "bgImage": "assets/images/frost.png",
    "cardImage": "assets/images/penguin_athlete.png",
    "cardBg": const Color(0xFFFFF0E6),
  },
  {
    "id": "teacher",
    "title": "Guru",
    "title_en": "Teacher",
    "description": "Berbagi ilmu dan latih komunikasimu dengan gembira.",
    "description_en": "Share knowledge and train your communication happily.",
    "skills": [
      {"name": "Literasi", "name_en": "Literacy", "icon": "📚"},
      {"name": "Empati", "name_en": "Empathy", "icon": "💗"},
    ],
    "bgImage": "assets/images/frost.png",
    "cardImage": "assets/images/penguin_teacher.png",
    "cardBg": const Color(0xFFE6FAF0),
  },
];

// 🔥 DIUBAH JADI STATEFUL WIDGET AGAR BISA INITSTATE
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // 🔥 MUNCULKAN MINK SECARA RESMI DI SINI SAAT HOME KELUAR!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showChatbotGlobalProvider.notifier).show();
    });
  }

  Map<String, int> _calculateLevelData(int totalXp) {
    int level = 1;
    int currentLevelXp = 0;
    int nextLevelRequiredXp = 100;

    if (totalXp < 100) {
      level = 1;
      currentLevelXp = totalXp;
      nextLevelRequiredXp = 100;
    } else if (totalXp < 250) {
      level = 2;
      currentLevelXp = totalXp - 100;
      nextLevelRequiredXp = 150;
    } else if (totalXp < 500) {
      level = 3;
      currentLevelXp = totalXp - 250;
      nextLevelRequiredXp = 250;
    } else {
      level = 4;
      currentLevelXp = totalXp - 500;
      nextLevelRequiredXp = 500;
    }

    return {
      'level': level,
      'currentXp': currentLevelXp,
      'maxXp': nextLevelRequiredXp,
    };
  }

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
      loading: () => const Scaffold(
        backgroundColor: Color(0xFFF5F8FB),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0A264F)),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        backgroundColor: const Color(0xFFF5F8FB),
        body: Center(child: Text("${texts['err_loading']}$error")),
      ),
      data: (data) {
        final String childId = data?['id'] ?? '';
        final String childName = data?['name'] ?? "Anak Hebat";

        final realtimeXpAsync = ref.watch(childRealtimeXpProvider(childId));
        final int totalXp =
            realtimeXpAsync.value ?? data?['total_xp'] ?? data?['xp'] ?? 0;

        final levelData = _calculateLevelData(totalXp);
        final int childLevel = levelData['level']!;
        final int childCurrentXp = levelData['currentXp']!;
        final int childMaxXp = levelData['maxXp']!;

        final progressAsync = ref.watch(
          weeklyMissionCountStreamProvider(childId),
        );
        final achievementsAsync = ref.watch(childAchievementsProvider(childId));

        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FB),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
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
                  _buildTodayMissionCard(context, texts),
                  _buildChooseRole(context, texts, lang),

                  progressAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE57B65),
                        ),
                      ),
                    ),
                    error: (e, s) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text("${texts['err_loading']}$e"),
                    ),
                    data: (progressData) =>
                        _buildStackedBoxProgress(texts, progressData, lang),
                  ),

                  achievementsAsync.when(
                    loading: () => const SizedBox(),
                    error: (e, s) => const SizedBox(),
                    data: (achievementsData) =>
                        _buildRecentAchievements(texts, achievementsData, lang),
                  ),
                  const SizedBox(height: 120),
                ],
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${texts['greeting']} $parentName".trim(),
                  style: const TextStyle(
                    color: Color(0xFF0A264F),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  texts['subtitle']!,
                  style: TextStyle(
                    color: const Color(0xFF0A264F).withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF0A264F),
                    size: 24,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE57B65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          color: const Color(0xFF0A264F),
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
                padding: const EdgeInsets.all(20),
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
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "👦🏻",
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  childName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  texts['little_explorer']!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
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
                            decoration: const BoxDecoration(
                              color: Color(0xFFE57B65),
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
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "⭐ Level $level",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$xp/$maxXp XP",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      texts['motivation']!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
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
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          color: const Color(0xFFA5CBEB),
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
                  child: Image.asset(
                    'assets/images/snow.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                right: -10,
                child: Image.asset(
                  'assets/images/penguin_cooking1.png',
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        texts['today_rec']!,
                        style: TextStyle(
                          color: const Color(0xFF0A264F).withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        texts['mission_title']!,
                        style: const TextStyle(
                          color: Color(0xFF0A264F),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        texts['mission_desc']!,
                        style: TextStyle(
                          color: const Color(0xFF0A264F).withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.go('/missions?role=chef'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ).copyWith(elevation: WidgetStateProperty.all(5)),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF1A22F), Color(0xFFF5B555)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            constraints: const BoxConstraints(
                              minWidth: 100,
                              minHeight: 40,
                            ),
                            child: Text(
                              texts['btn_start_mission']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                texts['choose_role']!,
                style: const TextStyle(
                  color: Color(0xFF0A264F),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  texts['choose_role_desc']!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: const Color(0xFF0A264F).withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: roleData.map((role) {
              final title = lang == 'id' ? role["title"] : role["title_en"];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () => _showRoleDetail(context, role, texts, lang),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 140,
                      height: 190,
                      color: role["cardBg"] as Color,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              role["cardImage"] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: role["cardBg"] as Color,
                                child: const Center(
                                  child: Icon(
                                    Icons.stars_rounded,
                                    color: Colors.black12,
                                    size: 60,
                                  ),
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
                                    const Color(
                                      0xFF0A264F,
                                    ).withValues(alpha: 0.9),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Text(
                              title as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
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
    if (lang == 'id') {
      switch (weekday) {
        case 1:
          return 'Sen';
        case 2:
          return 'Sel';
        case 3:
          return 'Rab';
        case 4:
          return 'Kam';
        case 5:
          return 'Jum';
        case 6:
          return 'Sab';
        case 7:
          return 'Min';
        default:
          return '-';
      }
    } else {
      switch (weekday) {
        case 1:
          return 'Mon';
        case 2:
          return 'Tue';
        case 3:
          return 'Wed';
        case 4:
          return 'Thu';
        case 5:
          return 'Fri';
        case 6:
          return 'Sat';
        case 7:
          return 'Sun';
        default:
          return '-';
      }
    }
  }

  Widget _buildStackedBoxProgress(
    Map<String, String> texts,
    List progressData,
    String lang,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts['weekly_prog']!,
            style: const TextStyle(
              color: Color(0xFF0A264F),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (progressData.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0A264F).withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Color(0xFFE57B65),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    texts['empty_progress']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF0A264F).withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                                  color: Colors.grey.shade200,
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
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE57B65),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFE57B65,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        dayName,
                        style: TextStyle(
                          color: const Color(
                            0xFF0A264F,
                          ).withValues(alpha: count > 0 ? 0.9 : 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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
    Map<String, String> texts,
    List achievementsData,
    String lang,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            texts['recent_achieve']!,
            style: const TextStyle(
              color: Color(0xFF0A264F),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (achievementsData.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF0A264F).withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    color: Color(0xFFE57B65),
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    texts['empty_achieve']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF0A264F).withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: achievementsData.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = achievementsData[index];

                  final unlockedAt = parseDateSafely(item['unlocked_at'] ?? '');
                  final formattedDate = unlockedAt != null
                      ? DateFormat('dd MMM yyyy, HH:mm').format(unlockedAt)
                      : '-';

                  final String badgeTitle = lang == 'id'
                      ? (item['title_id'] ?? 'Prestasi Baru')
                      : (item['title_en'] ?? 'New Achievement');

                  return Container(
                    width: 180,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF1A22F,
                            ).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            item['icon_url'] ?? '🏅',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                badgeTitle,
                                style: const TextStyle(
                                  color: Color(0xFF0A264F),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
    Map<String, dynamic> role,
    Map<String, String> texts,
    String lang,
  ) {
    final title = lang == 'id' ? role["title"] : role["title_en"];
    final description = lang == 'id'
        ? role["description"]
        : role["description_en"];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(
            color: Color(0xFFA5CBEB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: 0.9,
                  child: Image.asset(
                    'assets/images/snow.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -80,
                right: -80,
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    role["bgImage"] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                right: 24,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF0A264F),
                      size: 20,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title as String,
                      style: const TextStyle(
                        color: Color(0xFF0A264F),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description as String,
                      style: TextStyle(
                        color: const Color(0xFF0A264F).withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: (role["skills"] as List<dynamic>).map((skill) {
                        final skillName = lang == 'id'
                            ? skill["name"]
                            : skill["name_en"];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                skillName as String,
                                style: const TextStyle(
                                  color: Color(0xFF0A264F),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                skill["icon"] as String,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/missions?role=${role["id"]}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57B65),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        texts['btn_start_role']!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
