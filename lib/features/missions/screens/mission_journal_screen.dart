import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';

// JALUR IMPORT
import '../data/mission_model.dart';
import 'mission_intro_screen.dart';
import 'mission_reflection_screen.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/mission_reflection_provider.dart';
import '../../../core/constants/feeling_emojis.dart';
import '../../../core/constants/role_visuals.dart';
import '../../../core/constants/skills.dart';
import '../../../core/router/app_page_transition.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/star_rating_row.dart';

// ==========================================
// 1. DICTIONARY (KAMUS LENGKAP)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'journal_view': "Mission Journal",
    'journal_new': "Your child is doing great!",
    'no_photo':
        "No photos were saved for this mission, but here is the progress summary",
    'download': "Download",
    'share': "Share",
    'skill_prog': "Skill Progress",
    'no_points': "No specific points for this mission.",
    'new_badge': "New Badge!",
    'back': "Back",
    'continue': "Continue to Reflection",
    // Role Names
    'role_chef': "Chef",
    'role_doctor': "Doctor",
    'role_artist': "Artist",
    'role_athlete': "Athlete",
    'role_teacher': "Teacher",
    // Notif
    'saving': "Saving photo...",
    'save_success': "Saved to Gallery! 🎉",
    'save_fail': "Failed to save photo.",
    'preparing': "Preparing photo...",
    'share_text': "Look at my child's exciting mission on MiRO! 🐧✨",
    'sync_failed': "Failed to save this mission's progress. Your XP/skills weren't recorded yet.",
    'btn_retry': "Try Again",
    'rate_mission': "How fun was this mission?",
    'btn_replay': "Play This Mission Again",
    'replay_note': "Replaying won't earn extra XP or badges -- it's just for fun!",
    'reflection_title': "How you both felt",
    'reflection_parent': "Parent",
    'reflection_child': "Child",
  },
  'id': {
    'journal_view': "Jurnal Misi",
    'journal_new': "Anakmu berkembang dengan baik!",
    'no_photo':
        "Bunda tidak menyimpan foto di misi ini, tapi ini dia ringkasan perkembangannya",
    'download': "Unduh",
    'share': "Bagikan",
    'skill_prog': "Peningkatan Skill",
    'no_points': "Misi ini tidak memiliki poin spesifik.",
    'new_badge': "Lencana Baru!",
    'back': "Kembali",
    'continue': "Lanjut ke Refleksi",
    // Role Names
    'role_chef': "Koki",
    'role_doctor': "Dokter",
    'role_artist': "Pelukis",
    'role_athlete': "Atlet",
    'role_teacher': "Guru",
    // Notif
    'saving': "Menyimpan foto...",
    'save_success': "Berhasil disimpan ke Galeri! 🎉",
    'save_fail': "Gagal menyimpan foto.",
    'preparing': "Menyiapkan foto...",
    'share_text': "Yuk lihat keseruan misi anakku di MiRO! 🐧✨",
    'sync_failed': "Gagal nyimpen progres misi ini. XP/skill-nya belum kecatat.",
    'btn_retry': "Coba Lagi",
    'rate_mission': "Seberapa seru misi ini?",
    'btn_replay': "Ulangi Misi Ini",
    'replay_note': "Ulangi misi nggak nambah XP/lencana lagi -- ini cuma buat seru-seruan!",
    'reflection_title': "Gimana perasaan kalian",
    'reflection_parent': "Orang Tua",
    'reflection_child': "Anak",
  },
};

class MissionJournalScreen extends ConsumerStatefulWidget {
  final MissionModel mission;
  final List<String> capturedPhotos;
  final bool isViewOnly;
  // Cuma keisi kalau isViewOnly (dikasih dari mission_path_screen.dart,
  // yang udah nyari baris mission_logs-nya) -- perlu ID-nya biar rating
  // bintang bisa di-update pas ngeliat jurnal misi yang udah lewat.
  final String? existingMissionLogId;
  final int? existingRating;

  const MissionJournalScreen({
    super.key,
    required this.mission,
    required this.capturedPhotos,
    this.isViewOnly = false,
    this.existingMissionLogId,
    this.existingRating,
  });

  @override
  ConsumerState<MissionJournalScreen> createState() =>
      _MissionJournalScreenState();
}

class _MissionJournalScreenState extends ConsumerState<MissionJournalScreen> {
  bool _isLoading = true;
  String? _generatedMissionLogId;
  Map<String, Map<String, dynamic>> _updatedSkillsData = {};
  Map<String, dynamic>? _earnedAchievement;

  // Dulu kalau _syncToDatabase gagal (network putus dkk), errornya cuma
  // di-print ke console — orang tua/anak tetap lihat tampilan "berhasil"
  // padahal XP/progres-nya nggak beneran kesimpen, tanpa cara buat tau
  // atau nyoba lagi. Sekarang statusnya dilacak biar ada banner + tombol
  // "Coba Lagi" di layar.
  bool _syncFailed = false;
  String? _pendingAchievementId;

  // Rating bintang (1-5) buat misi ini -- null berarti belum dikasih
  // rating. Dulu nggak ada cara buat anak/orang tua ngasih tau seberapa
  // seru satu misi dibanding misi lain.
  int? _rating;

  // 🔥 KEY UNTUK MENG-CAPTURE KOLASE JADI GAMBAR
  final GlobalKey _collageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _rating = widget.existingRating;
    if (widget.isViewOnly) {
      _generatedMissionLogId = widget.existingMissionLogId;
    }
    _initJournalData();
  }

  // Baris 5 bintang tappable -- dulu nggak ada cara buat anak/orang tua
  // ngasih tau seberapa seru satu misi dibanding misi lain di app ini.
  Widget _buildRatingRow(Map<String, String> texts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texts['rate_mission']!,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        StarRatingRow(
          rating: _rating ?? 0,
          size: 34,
          onRate: _saveRating,
        ),
      ],
    );
  }

  // Refleksi (perasaan Bunda/Ayah & anak + catatan) yang diisi pas misi ini
  // pertama kali diselesaikan -- dulu cuma pernah DITULIS, nggak pernah
  // ditampilin lagi di mana pun. Sekarang muncul lagi pas jurnal ini
  // dibuka ulang (replay dari Progress/Buku Kenangan), jadi ngisinya nggak
  // sia-sia.
  Widget _buildReflectionCard(Map<String, String> texts) {
    if (_generatedMissionLogId == null) return const SizedBox.shrink();

    final reflectionAsync = ref.watch(
      missionReflectionProvider(_generatedMissionLogId!),
    );

    return reflectionAsync.maybeWhen(
      data: (reflection) {
        if (reflection == null) return const SizedBox.shrink();

        final int? parentFeeling = reflection['parent_feeling'] as int?;
        final int? childFeeling = reflection['child_feeling'] as int?;
        final String notes = (reflection['notes'] as String? ?? '').trim();

        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texts['reflection_title']!,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _feelingChip(
                      texts['reflection_parent']!,
                      parentFeeling,
                    ),
                    const SizedBox(width: 16),
                    _feelingChip(
                      texts['reflection_child']!,
                      childFeeling,
                    ),
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    notes,
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _feelingChip(String label, int? feelingIndex) {
    final String emoji = feelingEmoji(feelingIndex);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _saveRating(int stars) async {
    setState(() => _rating = stars);
    if (_generatedMissionLogId == null) return;
    try {
      await Supabase.instance.client
          .from('mission_logs')
          .update({'rating': stars})
          .eq('id', _generatedMissionLogId!);
    } catch (e) {
      debugPrint("Gagal simpan rating: $e");
    }
  }

  Future<void> _initJournalData() async {
    // 1. Siapkan data skill
    Map<String, Map<String, dynamic>> localData = {};
    if (widget.mission.skillsReward.isNotEmpty) {
      for (var entry in widget.mission.skillsReward.entries) {
        int reward = entry.value as int;
        localData[entry.key] = {
          'level': 1,
          'progress': (reward / 100.0).clamp(0.0, 1.0),
          'reward': reward,
          'needed': 100 - reward,
        };
      }
    }

    setState(() {
      _updatedSkillsData = localData;
    });

    // 2. Cari tahu apakah misi ini punya hadiah lencana
    String? achIdToSync;
    Map<String, dynamic>? fetchedAchievement;
    try {
      final supabase = Supabase.instance.client;
      final missionRes = await supabase
          .from('missions_master')
          .select('achievement_reward_id')
          .eq('id', widget.mission.id)
          .maybeSingle();

      if (missionRes != null &&
          missionRes['achievement_reward_id'] != null &&
          missionRes['achievement_reward_id'].toString().trim().isNotEmpty) {
        achIdToSync = missionRes['achievement_reward_id'].toString().trim();

        fetchedAchievement = await supabase
            .from('achievements_master')
            .select()
            .eq('id', achIdToSync)
            .maybeSingle();
      }
    } catch (e) {
      debugPrint("❌ Gagal memuat data achievement master: $e");
    }

    _pendingAchievementId = achIdToSync;
    if (!widget.isViewOnly) {
      // Dulu banner "Lencana Baru!" ditampilin cuma berdasarkan "misi ini
      // PUNYA hadiah lencana", TANPA peduli lencananya beneran baru
      // dikreditkan atau nggak -- efeknya, ngeliat jurnal misi yang udah
      // selesai lagi (isViewOnly) ATAU ngulang misi lewat "Ulangi Misi"
      // (replay, yang sengaja nggak ngasih lencana lagi) tetap nunjukin
      // "Lencana Baru!" seolah baru dapet, padahal nggak ada yang
      // dikreditkan. Sekarang banner cuma muncul kalau _syncToDatabase
      // bilang ini beneran completion yang FRESH (bukan replay).
      final bool wasFreshCompletion = await _syncToDatabase(achIdToSync);
      if (wasFreshCompletion && fetchedAchievement != null && mounted) {
        setState(() => _earnedAchievement = fetchedAchievement);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveJournalPhotos(
    SupabaseClient supabase,
    String missionLogId,
  ) async {
    if (widget.capturedPhotos.isEmpty) return;
    try {
      final rows = [
        for (int i = 0; i < widget.capturedPhotos.length; i++)
          {
            'mission_log_id': missionLogId,
            'step_index': i,
            'image_url': widget.capturedPhotos[i],
          },
      ];
      await supabase.from('journals').insert(rows);
    } catch (e) {
      debugPrint("Gagal simpan foto jurnal: $e");
    }
  }

  // Balikin `true` cuma kalau ini beneran completion FRESH (bukan replay,
  // bukan retry dari baris yang udah ada) -- dipakai _initJournalData buat
  // mutusin boleh nggaknya nampilin banner "Lencana Baru!".
  Future<bool> _syncToDatabase(String? earnedAchievementId) async {
    try {
      final supabase = Supabase.instance.client;

      // Sebelumnya di sini nge-query `children` sendiri pakai
      // `eq('parent_id', parentId).maybeSingle()` buat nentuin siapa yang
      // dapat XP/progres dari misi ini — kalau parent-nya punya lebih dari
      // 1 anak, `.maybeSingle()` bakal ERROR (baris cocok > 1), dan kalaupun
      // nggak error, ini beresiko ngasih XP ke anak yang SALAH. Sekarang
      // pakai `childDataProvider`, sumber kebenaran anak yang lagi aktif
      // dipilih (sama yang dipakai Home/Progress/Profile).
      final childDb = await ref.read(childDataProvider.future);
      if (childDb == null) return false;

      final String childId = childDb['id'];
      final int currentTotalXp = childDb['total_xp'] ?? 0;
      final String nowLocal = DateTime.now().toIso8601String();

      // Cegah XP/skill/level kecatat dobel kalau misi ini kebetulan udah
      // pernah diselesaikan sebelumnya buat anak ini — bisa kejadian kalau
      // orang tua/anak pencet tombol back dari layar Win/Journal terus
      // mulai ulang misi yang sama (Intro screen nggak pernah kecopot
      // dari stack navigasi begitu Play/Win/Journal ke-push, jadi masih
      // bisa "Mulai misi" lagi dari sana).
      final alreadyCompleted = await supabase
          .from('mission_logs')
          .select('id')
          .eq('child_id', childId)
          .eq('mission_id', widget.mission.id)
          .eq('status', 'completed')
          .limit(1);

      if (alreadyCompleted.isNotEmpty) {
        // Ini "Ulangi Misi" (replay) atau alur-balik-lalu-mulai-lagi yang
        // udah dijelasin di atas -- baik pun caranya, misi ini emang lagi
        // dikerjain ulang. Dulu di sini langsung return tanpa nyimpen apa
        // pun; sekarang tetap dicatat sebagai baris BARU berstatus
        // 'replayed' (bukan 'completed') + foto barunya kesimpen ke jurnal,
        // TAPI nggak ngasih XP/skill/lencana lagi. Semua provider yang
        // ngitung progres (streak, misi minggu ini, tren skill, total
        // misi) explicitly filter status == 'completed', jadi baris
        // 'replayed' otomatis nggak kehitung di mana pun -- nggak ada
        // celah buat farming XP dari replay.
        debugPrint("⚠️ Misi ini udah pernah selesai — catat sbg replay, nggak dobel XP.");
        try {
          final replayLog = await supabase
              .from('mission_logs')
              .insert({
                'child_id': childId,
                'role_id': widget.mission.roleId,
                'mission_id': widget.mission.id,
                'status': 'replayed',
                'earned_xp': 0,
                'earned_skills': {},
                'completed_at': nowLocal,
              })
              .select('id')
              .single();
          _generatedMissionLogId = replayLog['id'];
          await _saveJournalPhotos(supabase, _generatedMissionLogId!);
        } catch (e) {
          debugPrint("Gagal simpan log replay: $e");
          _generatedMissionLogId = alreadyCompleted.first['id'];
        }
        if (mounted) setState(() => _syncFailed = false);
        return false;
      }

      // 1. Simpan Log Misi
      final logResponse = await supabase
          .from('mission_logs')
          .insert({
            'child_id': childId,
            'role_id': widget.mission.roleId,
            'mission_id': widget.mission.id,
            'status': 'completed',
            'earned_xp': widget.mission.xpReward,
            'earned_skills': widget.mission.skillsReward,
            'completed_at': nowLocal,
          })
          .select('id')
          .single();

      _generatedMissionLogId = logResponse['id'];
      // Dulu foto yang diambil pas misi berlangsung cuma ada di memori
      // layar ini (buat kolase win screen) -- nggak PERNAH ditulis ke
      // tabel `journals`. Efeknya, buka lagi jurnal misi yang udah
      // selesai (dari peta misi) SELALU nunjukin nol foto, walau anaknya
      // beneran ambil beberapa pas ngerjain. step_index di sini pakai
      // urutan pengambilan (bukan step misi asli -- itu nggak pernah
      // diteruskan sampai ke sini), cukup buat urutan tampil & nggak ada
      // yang baca kolom itu di tempat lain.
      await _saveJournalPhotos(supabase, _generatedMissionLogId!);

      // 2. Update Total XP Anak
      await supabase
          .from('children')
          .update({'total_xp': currentTotalXp + widget.mission.xpReward})
          .eq('id', childId);

      // 3. Update Progress Level
      final progressRes = await supabase
          .from('child_role_progress')
          .select('unlocked_level')
          .eq('child_id', childId)
          .eq('role_id', widget.mission.roleId)
          .maybeSingle();

      if (progressRes == null) {
        await supabase.from('child_role_progress').insert({
          'child_id': childId,
          'role_id': widget.mission.roleId,
          'unlocked_level': 2,
        });
      } else {
        int currentUnlocked = progressRes['unlocked_level'] ?? 1;
        await supabase
            .from('child_role_progress')
            .update({'unlocked_level': currentUnlocked + 1})
            .eq('child_id', childId)
            .eq('role_id', widget.mission.roleId);
      }

      // 4. Update Child Stats
      if (widget.mission.skillsReward.isNotEmpty) {
        final statsRes = await supabase
            .from('child_stats')
            .select()
            .eq('child_id', childId)
            .maybeSingle();

        if (statsRes != null) {
          Map<String, dynamic> updates = {};
          widget.mission.skillsReward.forEach((key, value) {
            // Pemetaan key -> kolom child_stats (termasuk varian ejaan
            // Indonesia) dipindah ke core/constants/skills.dart.
            String dbCol = skillStatColumn(key);
            updates[dbCol] = (statsRes[dbCol] as int? ?? 0) + (value as int);
          });
          if (updates.isNotEmpty) {
            await supabase
                .from('child_stats')
                .update(updates)
                .eq('child_id', childId);
          }
        } else {
          Map<String, dynamic> inserts = {'child_id': childId};
          widget.mission.skillsReward.forEach((key, value) {
            String dbCol = skillStatColumn(key);
            inserts[dbCol] = value;
          });
          await supabase.from('child_stats').insert(inserts);
        }
      }

      // 5. Eksekusi Achievement
      if (earnedAchievementId != null && earnedAchievementId.isNotEmpty) {
        try {
          await supabase.from('child_achievements').insert({
            'child_id': childId,
            'achievement_id': earnedAchievementId,
            'unlocked_at': nowLocal, 
          });
          debugPrint("✅ LENCANA BERHASIL TERCATAT!");
        } on PostgrestException catch (e) {
          if (e.code != '23505') {
            debugPrint("❌ Gagal Simpan Lencana: ${e.message}");
          }
        }
      }
      if (mounted) setState(() => _syncFailed = false);
      return true;
    } catch (e) {
      debugPrint("❌ FATAL DB SYNC ERROR: $e");
      // Dulu di sini berhenti, dan tampilan tetap keliatan "berhasil"
      // walau XP/progres-nya nggak beneran kesimpen. Sekarang ditandain
      // biar ada banner + tombol coba lagi di layar.
      if (mounted) setState(() => _syncFailed = true);
      return false;
    }
  }

  // =========================================================================
  // 🔥 FUNGSI CAPTURE, DOWNLOAD & SHARE
  // =========================================================================
  Future<Uint8List?> _captureCollage() async {
    try {
      RenderRepaintBoundary boundary =
          _collageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Gagal mengambil gambar kolase: $e");
      return null;
    }
  }

Future<void> _downloadCollage() async {
      final lang = ref.read(languageProvider);
      final texts = _t[lang] ?? _t['en']!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts['saving']!), duration: const Duration(seconds: 1)),
      );

      final bytes = await _captureCollage();
      if (bytes != null) {
        try {
          // 1. Simpan bytes ke file sementara (Temporary File)
          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/MiRO_Mission_${DateTime.now().millisecondsSinceEpoch}.png');
          await tempFile.writeAsBytes(bytes);

          // 2. Minta izin ke HP pengguna (Sangat penting di Android/iOS modern!)
          final hasAccess = await Gal.hasAccess();
          if (!hasAccess) {
             await Gal.requestAccess();
          }

          // 3. Simpan file sementara tadi ke Galeri pakai package 'gal'
          await Gal.putImage(tempFile.path);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(texts['save_success']!),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          debugPrint("Gagal menyimpan ke galeri: $e");
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(texts['save_fail']!),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
  Future<void> _shareCollage() async {
    final lang = ref.read(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texts['preparing']!), duration: const Duration(seconds: 1)),
    );

    final bytes = await _captureCollage();
    if (bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/miro_mission.png').create();
      await file.writeAsBytes(bytes);
      
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: texts['share_text']!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;
    final bool hasPhotos = widget.capturedPhotos.isNotEmpty;

    final String role = widget.mission.roleId;
    final Color badgeColor = (roleVisualById(role) ?? kUnknownRoleVisual).resolvedBadgeColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          Text(
                            widget.isViewOnly
                                ? texts['journal_view']!
                                : texts['journal_new']!,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (_syncFailed && !widget.isViewOnly) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.dangerTint,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          texts['sync_failed']!,
                                          style: TextStyle(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () => _syncToDatabase(_pendingAchievementId),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: BorderSide(color: AppColors.danger),
                                      ),
                                      child: Text(texts['btn_retry']!),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          if (!hasPhotos) ...[
                            Text(
                              texts['no_photo']!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ] else ...[
                            // ==========================================
                            // MEMANGGIL KOLASE ESTETIK DI SINI
                            // ==========================================
                            _buildCollageCard(lang, texts, badgeColor, role),
                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _downloadCollage,
                                    icon: Icon(
                                      Icons.download_rounded,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    label: Text(
                                      texts['download']!,
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      side: BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _shareCollage,
                                    icon: const Icon(
                                      Icons.share_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    label: Text(
                                      texts['share']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],

                          _buildRatingRow(texts),
                          if (widget.isViewOnly) _buildReflectionCard(texts),
                          const SizedBox(height: 32),

                          Text(
                            texts['skill_prog']!,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (_updatedSkillsData.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 10,
                                bottom: 20,
                              ),
                              child: Text(
                                texts['no_points']!,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            ..._updatedSkillsData.entries.map((skillEntry) {
                              return _buildSkillProgressRow(
                                skillEntry.key,
                                skillEntry.value,
                                lang,
                              );
                            }),

                          if (_earnedAchievement != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFF4E5),
                                    Color(0xFFFFE8CC),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.sm + 10),
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: badgeColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: badgeColor.withValues(
                                          alpha: 0.8,
                                        ),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: badgeColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _earnedAchievement!['icon_url'] ?? '🏅',
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          texts['new_badge']!,
                                          style: TextStyle(
                                            color: AppColors.accent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          lang == 'id'
                                              ? _earnedAchievement!['title_id'] ??
                                                  ''
                                              : _earnedAchievement!['title_en'] ??
                                                  '',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
              ),
              if (widget.isViewOnly) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    texts['replay_note']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context, rootNavigator: true).push(
                          appPageRoute(
                            MissionIntroScreen(mission: widget.mission),
                          ),
                        );
                      },
                      icon: Icon(Icons.replay_rounded, color: AppColors.primary, size: 18),
                      label: Text(
                        texts['btn_replay']!,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: () {
                    if (widget.isViewOnly) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(
                        context,
                        appPageRoute(
                          MissionReflectionScreen(
                            mission: widget.mission,
                            missionLogId: _generatedMissionLogId,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    widget.isViewOnly ? texts['back']! : texts['continue']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // KOLASE FOTO ESTETIK ALA POLAROID DENGAN PENGUIN PEEK & WATERMARK
  // =========================================================================
  Widget _buildCollageCard(
    String lang,
    Map<String, String> texts,
    Color badgeColor,
    String role,
  ) {
    final displayPhotos = widget.capturedPhotos.take(4).toList();

    // 🔥 FIX PENGUIN: Menggunakan format _trans.png seperti permintaan Bos!
    String penguinAsset = 'assets/images/${role}_trans.png';

    final String missionTitle = lang == 'id'
        ? widget.mission.titleId
        : widget.mission.titleEn;

    final String roleLabel = texts['role_$role'] ?? role.toUpperCase();

    // 🔥 DIBUNGKUS OLEH RepaintBoundary AGAR BISA DI-CAPTURE
    return RepaintBoundary(
      key: _collageKey,
      child: Container(
        height: 380,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // BINGKAI FOTO DI DALAM
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    _buildPhotoGrid(displayPhotos),

                    // GRADASI HITAM DI BAWAH AGAR TEKS TERBACA JELAS
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 140,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                          ),
                        ),
                      ),
                    ),

                    // WATERMARK MIRO
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Text(
                        "MIRO",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          shadows: const [
                            Shadow(color: Colors.black45, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),

                    // TEKS DETAIL MISI DI KIRI BAWAH
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 100, 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4),
                              ],
                            ),
                            child: Text(
                              roleLabel.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            missionTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              shadows: [
                                Shadow(color: Colors.black45, blurRadius: 4),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // PENGUIN PEEK! 
            Positioned(
              bottom: -15,
              right: -15,
              child: Image.asset(
                penguinAsset,
                width: 130,
                height: 130,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LOGIKA PENYUSUNAN GRID FOTO (1 sampai 4 foto)
  Widget _buildPhotoGrid(List<String> images) {
    if (images.length == 1) {
      return _buildImageItem(images[0]);
    } else if (images.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildImageItem(images[0])),
          const SizedBox(width: 4),
          Expanded(child: _buildImageItem(images[1])),
        ],
      );
    } else if (images.length == 3) {
      return Column(
        children: [
          Expanded(flex: 3, child: _buildImageItem(images[0])),
          const SizedBox(height: 4),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(child: _buildImageItem(images[1])),
                const SizedBox(width: 4),
                Expanded(child: _buildImageItem(images[2])),
              ],
            ),
          ),
        ],
      );
    } else {
      // 4 Foto Grid (2x2)
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageItem(images[0])),
                const SizedBox(width: 4),
                Expanded(child: _buildImageItem(images[1])),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildImageItem(images[2])),
                const SizedBox(width: 4),
                Expanded(child: _buildImageItem(images[3])),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildImageItem(String url) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: url.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (c, e, s) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          : Image.asset(
              url,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
    );
  }

  Widget _buildSkillProgressRow(
    String skillName,
    Map<String, dynamic> skillData,
    String lang,
  ) {
    int level = skillData['level'];
    double progressPercent = skillData['progress'];
    int reward = skillData['reward'];
    int needed = skillData['needed'];

    final textNeed = lang == 'id'
        ? "Butuh $needed poin lagi untuk naik level"
        : "Need $needed more points to level up";

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    skillName.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "↑ +$reward",
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                "Level $level",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressPercent.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.gold, const Color(0xFFF5B555)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            textNeed,
            style: TextStyle(
              color: AppColors.primary.withValues(alpha: 0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}