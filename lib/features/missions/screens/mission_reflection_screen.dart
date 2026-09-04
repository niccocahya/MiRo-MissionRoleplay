import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Wajib untuk ConsumerStatefulWidget
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// JALUR IMPORT
import '../data/mission_model.dart';
import '../../../core/providers/language_provider.dart'; // Wajib narik provider bahasa
import '../../../core/constants/feeling_emojis.dart';
import '../../../core/constants/role_visuals.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

// ==========================================
// 1. DICTIONARY (KAMUS BAHASA)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'err_select': "Please select parent and child feelings first",
    'err_save': "Failed to save reflection: ",
    'err_unlinked':
        "This mission's progress hasn't been saved yet, so the reflection can't be attached to it. Go back and tap Try Again first.",
    'title': "How was the mission?",
    'parent_feeling': "PARENT FEELING",
    'child_feeling': "CHILD FEELING",
    'hint_notes': "Write your short reflection",
    'btn_save': "Save and finish",
    'skill_label': "SKILL DEVELOPED",
  },
  'id': {
    'err_select': "Pilih perasaan ayah bunda dan anak dulu ya",
    'err_save': "Gagal menyimpan refleksi: ",
    'err_unlinked':
        "Progres misinya belum kesimpen, jadi refleksinya nggak bisa ditempelin ke misi ini. Balik dulu terus pencet Coba Lagi ya.",
    'title': "Bagaimana misinya?",
    'parent_feeling': "PERASAAN ORANG TUA",
    'child_feeling': "PERASAAN ANAK",
    'hint_notes': "Tulis refleksi singkatmu",
    'btn_save': "Simpan dan selesai",
    'skill_label': "SKILL TERLATIH",
  },
};

// Ubah ke ConsumerStatefulWidget agar bisa membaca Riverpod
class MissionReflectionScreen extends ConsumerStatefulWidget {
  final MissionModel mission;
  final String? missionLogId;

  const MissionReflectionScreen({
    super.key,
    required this.mission,
    this.missionLogId,
  });

  @override
  ConsumerState<MissionReflectionScreen> createState() =>
      _MissionReflectionScreenState();
}

class _MissionReflectionScreenState
    extends ConsumerState<MissionReflectionScreen> {
  int? parentFeeling;
  int? childFeeling;
  final TextEditingController _notesController = TextEditingController();
  // Daftar emoji-nya dipindah ke core/constants/feeling_emojis.dart --
  // indeks di daftar ini yang kesimpen ke database, dan layar jurnal misi
  // baca balik pakai daftar yang sama.
  final List<String> emojis = kFeelingEmojis;

  bool _isSaving = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveReflection() async {
    final lang = ref.read(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    if (parentFeeling == null || childFeeling == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts['err_select']!)));
      return;
    }

    setState(() => _isSaving = true);

    // Lapis kedua (yang pertama: tombol masuk ke layar ini dikunci sampai
    // id-nya siap, lihat mission_journal_screen.dart). Tanpa mission_log_id,
    // baris refleksinya nggak nyambung ke misi mana pun -- kesimpen tapi
    // nggak akan pernah bisa ditampilin lagi. Lebih baik jujur gagal
    // daripada diem-diem bikin data yatim.
    if (widget.missionLogId == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(texts['err_unlinked']!)));
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // MENGIRIM DATA KE TABEL 'reflections' SESUAI SKEMA SQL-MU
      await supabase.from('reflections').insert({
        // Tembak ID Log Misi agar berelasi dengan riwayat misi
        'mission_log_id': widget.missionLogId,
        'parent_feeling': parentFeeling,
        'child_feeling': childFeeling,
        'notes': _notesController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      // Jika berhasil, kembali ke root dan pindah ke tab progress
      Navigator.of(context).popUntil((route) => route.isFirst);
      context.go('/progress');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${texts['err_save']!}$e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tarik bahasa aktif secara real-time dari Riverpod
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    // Ambil satu skill utama untuk ditampilkan di kartu
    final String primarySkill = widget.mission.skillsReward.keys.isNotEmpty
        ? widget.mission.skillsReward.keys.first.toUpperCase()
        : texts['skill_label']!;

    final roleVisual =
        roleVisualById(widget.mission.roleId) ?? kUnknownRoleVisual;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Gradasi tipis bertema role, SEBAGAI SATU lapis pembungkus doang --
      // ini layar "gimana perasaan kalian", momen yang hangat, jadi cocok
      // dikasih warna dikit ketimbang abu polos, tanpa perlu ngerombak
      // struktur form emoji di bawahnya.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(roleVisual.resolvedBadgeColor, Colors.white, 0.85)!,
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texts['title']!,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // KARTU RINGKASAN MISI (Glassmorphism Style)
                _buildMissionSummaryCard(primarySkill, lang),

                const SizedBox(height: AppSpacing.xl),

                // INPUT PERASAAN
                _buildFeelingSelector(
                  texts['parent_feeling']!,
                  parentFeeling,
                  (val) => setState(() => parentFeeling = val),
                ),
                const SizedBox(height: AppSpacing.lg),

                _buildFeelingSelector(
                  texts['child_feeling']!,
                  childFeeling,
                  (val) => setState(() => childFeeling = val),
                ),
                const SizedBox(height: AppSpacing.xl),

                // INPUT CATATAN REFLEKSI
                Expanded(
                  child: TextField(
                    controller: _notesController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: texts['hint_notes']!,
                      hintStyle: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.all(20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // TOMBOL SIMPAN (Dengan Loading State)
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveReflection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    disabledBackgroundColor:
                        AppColors.accent.withValues(alpha: 0.7),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          texts['btn_save']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET KARTU YANG KEPOTONG DI KODINGAN SEBELUMNYA
  Widget _buildMissionSummaryCard(String skill, String lang) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star_rounded,
              color: AppColors.gold,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lang == 'id'
                      ? widget.mission.titleId
                      : widget.mission.titleEn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET SELECTOR PERASAAN
  Widget _buildFeelingSelector(
    String label,
    int? currentValue,
    Function(int) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(emojis.length, (index) {
              final isSelected = currentValue == index;
              return GestureDetector(
                onTap: () => onSelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  transformAlignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..scaleByDouble(
                      isSelected ? 1.3 : 1.0,
                      isSelected ? 1.3 : 1.0,
                      1.0,
                      1.0,
                    ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Opacity(
                    opacity: isSelected ? 1.0 : 0.3,
                    child: Text(
                      emojis[index],
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
