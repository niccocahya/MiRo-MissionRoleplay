import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

// JALUR IMPORT
import '../data/mission_provider.dart';
import '../data/mission_model.dart';
import '../data/role_model.dart';
import 'mission_intro_screen.dart';
import 'mission_journal_screen.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/providers/language_provider.dart'; // Wajib import otak bahasanya!
import '../../../core/router/app_page_transition.dart';
import '../../../core/services/favorite_missions_service.dart';
import '../../../core/theme/app_colors.dart';

// ==========================================
// 1. DICTIONARY (KAMUS LENGKAP HALAMAN PATH)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'err_journal': "Failed to load mission journal: ",
    'err_map': "Failed to load map: ",
    'empty_mission': "No missions available for this category yet.",
    'locked_msg': "Mission locked! Complete the previous mission first.",
  },
  'id': {
    'err_journal': "Gagal memuat jurnal misi ini: ",
    'err_map': "Gagal memuat peta: ",
    'empty_mission': "Belum ada misi untuk kategori ini.",
    'locked_msg':
        "Misi ini masih terkunci! Selesaikan misi sebelumnya dulu ya.",
  },
};

class MissionPathScreen extends ConsumerStatefulWidget {
  final String roleId;
  final String roleName;

  const MissionPathScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  ConsumerState<MissionPathScreen> createState() => _MissionPathScreenState();
}

class _MissionPathScreenState extends ConsumerState<MissionPathScreen> {
  int _unlockedLevel = 1;
  bool _isLoadingProgress = true;
  String _childId = '';

  @override
  void initState() {
    super.initState();
    _fetchChildProgress();
  }

  // FUNGSI UNTUK MENGAMBIL LEVEL YANG TERBUKA DARI DATABASE
  //
  // Sebelumnya ini nge-query `children` sendiri pakai `eq('parent_id',
  // parentId).limit(1)` — ngambil "anak pertama milik parent ini" tanpa
  // peduli anak mana yang lagi aktif dipilih. Kalau parent punya lebih
  // dari 1 anak, peta misi ini bisa nunjukin progres anak yang SALAH.
  // Sekarang pakai `childDataProvider`, sumber kebenaran yang sama yang
  // dipakai Home/Progress/Profile.
  Future<void> _fetchChildProgress() async {
    try {
      final childData = await ref.read(childDataProvider.future);
      final resolvedChildId = childData?['id'] as String?;
      if (resolvedChildId == null) {
        if (mounted) setState(() => _isLoadingProgress = false);
        return;
      }
      _childId = resolvedChildId;

      final progressResponse = await Supabase.instance.client
          .from('child_role_progress')
          .select('unlocked_level')
          .eq('child_id', _childId)
          .eq('role_id', widget.roleId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _unlockedLevel = progressResponse != null
              ? (progressResponse['unlocked_level'] ?? 1)
              : 1;
          _isLoadingProgress = false;
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil progres: $e");
      if (mounted) setState(() => _isLoadingProgress = false);
    }
  }

  // FUNGSI UNTUK MEMBUKA JURNAL MISI LALU YANG SUDAH SELESAI
  Future<void> _openCompletedJournal(
    MissionModel mission,
    Map<String, String> texts,
  ) async {
    // Tampilkan loading screen dengan pelindung root navigator
    showDialog(
      context: context,
      useRootNavigator: true, // Pastikan tampil di atas navbar
      barrierDismissible: false,
      barrierColor: Colors.white.withValues(
        alpha: 0.6,
      ), // Cegah layar terlihat terlalu blank
      builder: (_) => PopScope(
        canPop: false, // Cegah ditutup pakai tombol back HP
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );

    try {
      final supabase = Supabase.instance.client;

      // 1. Cari log misi ini yang sudah selesai
      final logRes = await supabase
          .from('mission_logs')
          .select('id, rating')
          .eq('child_id', _childId)
          .eq('mission_id', mission.id)
          .eq('status', 'completed')
          .order('completed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      List<String> photos = [];

      // 2. Ambil foto dari tabel journals -- dikumpulin dari SEMUA baris
      // mission_logs punya misi ini (baris 'completed' asli + baris
      // 'replayed' kalau anaknya pernah ulang misi ini), bukan cuma dari
      // baris completed yang asli, biar foto dari replay juga keliatan
      // pas jurnal ini dibuka lagi nanti.
      if (logRes != null && logRes['id'] != null) {
        final allLogsForMission = await supabase
            .from('mission_logs')
            .select('id')
            .eq('child_id', _childId)
            .eq('mission_id', mission.id);
        final logIds = allLogsForMission.map((r) => r['id'] as String).toList();

        final journalRes = await supabase
            .from('journals')
            .select('image_url')
            .inFilter('mission_log_id', logIds);

        photos = journalRes.map((e) => e['image_url'].toString()).toList();
      }

      if (mounted) {
        // Menutup dialog dengan aman tanpa menghapus Peta
        Navigator.of(context, rootNavigator: true).pop();

        // Navigasi ke halaman jurnal
        Navigator.of(context, rootNavigator: true).push(
          appPageRoute(
            MissionJournalScreen(
              mission: mission,
              capturedPhotos: photos,
              isViewOnly: true, // Flag agar tidak nambah poin lagi
              existingMissionLogId: logRes?['id'] as String?,
              existingRating: logRes?['rating'] as int?,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Menutup dialog jika gagal
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("${texts['err_journal']}$e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TARIK BAHASA AKTIF
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    final missionsAsync = ref.watch(missionsByRoleProvider(widget.roleId));
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F4F8), Color(0xFFD9E2EC)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, ref, rolesAsync, lang),
              Expanded(
                child: _isLoadingProgress
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : missionsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) =>
                            Center(child: Text("${texts['err_map']}$err")),
                        data: (missions) {
                          if (missions.isEmpty) {
                            return Center(child: Text(texts['empty_mission']!));
                          }
                          return _buildAdventureMap(
                            context,
                            missions,
                            lang,
                            texts,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RoleModel>> rolesAsync,
    String lang,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: rolesAsync.maybeWhen(
          data: (roles) => _buildRolePillDropdown(context, roles, lang),
          orElse: () => Text(
            widget.roleName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolePillDropdown(
    BuildContext context,
    List<RoleModel> roles,
    String lang,
  ) {
    // Fallback ke role pertama kalau roleId nggak ketemu di daftar (mencegah
    // crash firstWhere kalau ada mismatch data antara missions_master & roles_master).
    final currentRole = roles.firstWhere(
      (r) => r.id == widget.roleId,
      orElse: () => roles.first,
    );
    final displayName = lang == 'id' ? currentRole.nameId : currentRole.nameEn;

    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (newRoleId) {
        if (newRoleId != widget.roleId) {
          final selectedRole = roles.firstWhere((r) => r.id == newRoleId);
          Navigator.pushReplacement(
            context,
            appPageRoute(
              MissionPathScreen(
                roleId: selectedRole.id,
                roleName: lang == 'id'
                    ? selectedRole.nameId
                    : selectedRole.nameEn,
              ),
            ),
          );
        }
      },
      itemBuilder: (BuildContext context) {
        return roles.map((role) {
          final roleText = lang == 'id' ? role.nameId : role.nameEn;
          return PopupMenuItem<String>(
            value: role.id,
            child: Text(
              roleText,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          );
        }).toList();
      },
      child: SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdventureMap(
    BuildContext context,
    List<MissionModel> missions,
    String lang,
    Map<String, String> texts,
  ) {
    return Stack(
      children: [
        _buildCloudDecorator(top: 50, left: -10, size: 90),
        _buildCloudDecorator(top: 280, right: -20, size: 110),
        _buildCloudDecorator(bottom: 120, left: 30, size: 70),

        ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 50),
          itemCount: missions.length,
          itemBuilder: (context, index) {
            final mission = missions[index];
            final double alignX = math.sin(index * 1.5) * 0.5;

            // LOGIKA 3 STATUS MISI BERSANDARKAN DATABASE
            final bool isCompleted = index < _unlockedLevel - 1;
            final bool isCurrent = index == _unlockedLevel - 1;
            final bool isLocked = index > _unlockedLevel - 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Align(
                alignment: Alignment(alignX, 0),
                child: _buildLevelNode(
                  context,
                  mission,
                  isCompleted,
                  isCurrent,
                  isLocked,
                  lang,
                  texts,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLevelNode(
    BuildContext context,
    MissionModel mission,
    bool isCompleted,
    bool isCurrent,
    bool isLocked,
    String lang,
    Map<String, String> texts,
  ) {
    return GestureDetector(
      onTap: () {
        if (isCurrent) {
          // Buka Misi Baru
          Navigator.of(context, rootNavigator: true).push(
            appPageRoute(
              MissionIntroScreen(
                mission: mission,
                roleName: widget.roleName,
              ),
            ),
          );
        } else if (isCompleted) {
          // Buka Riwayat (Jurnal)
          _openCompletedJournal(mission, texts);
        } else if (isLocked) {
          // Misi Terkunci
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(texts['locked_msg']!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Bayangan luar
          Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.accentDark.withValues(alpha: 0.5)
                  : isCompleted
                  ? AppColors.success.withValues(alpha: 0.4)
                  : Colors.grey.shade300.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          // Lingkaran utama dengan gradasi radial (efek glossy)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: isCurrent
                  ? RadialGradient(
                      center: const Alignment(-0.3, -0.3),
                      colors: [const Color(0xFFF58B7A), AppColors.accentDark],
                    )
                  : isCompleted
                  ? const RadialGradient(
                      center: Alignment(-0.3, -0.3),
                      colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                    )
                  : RadialGradient(
                      center: Alignment(-0.3, -0.3),
                      colors: [Colors.grey.shade300, Colors.grey.shade400],
                    ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: isCurrent || isCompleted
                  ? [
                      BoxShadow(
                        color: isCurrent
                            ? AppColors.accentDark.withValues(alpha: 0.6)
                            : AppColors.success.withValues(alpha: 0.6),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: isCurrent
                  ? const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 44,
                    )
                  : isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    )
                  : Icon(
                      Icons.lock_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 28,
                    ),
            ),
          ),
          // Label misi
          Positioned(
            bottom: -38,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                lang == 'id' ? mission.titleId : mission.titleEn,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          // Pin bintang HANYA untuk misi yang saat ini aktif (mengundang klik)
          if (isCurrent)
            Positioned(top: -12, right: -12, child: _buildStarPin()),
          // Penanda misi yang difavoritkan dari layar Intro
          if (ref.watch(favoriteMissionsProvider).contains(mission.id))
            Positioned(
              top: -6,
              left: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                child: Icon(Icons.favorite_rounded, color: AppColors.accent, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCloudDecorator({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Icon(
        Icons.cloud,
        color: AppColors.primary.withValues(alpha: 0.06),
        size: size,
      ),
    );
  }

  Widget _buildStarPin() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold, const Color(0xFFE08600)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
    );
  }
}
