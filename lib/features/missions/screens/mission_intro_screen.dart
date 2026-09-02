import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// JALUR IMPORT
import '../../../shared/widgets/back_button.dart';
import '../data/mission_model.dart';
import 'mission_play_screen.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/router/app_page_transition.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/responsive.dart';
import '../../../core/services/favorite_missions_service.dart';

// ==========================================
// 1. DICTIONARY (KAMUS LENGKAP)
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'btn_start': "Start mission",
    'prep_tools': "PREPARATION TOOLS",
    'mins': "mins",
  },
  'id': {
    'btn_start': "Mulai misi",
    'prep_tools': "YANG PERLU DISIAPKAN",
    'mins': "mnt",
  },
};

class MissionIntroScreen extends ConsumerWidget {
  final MissionModel mission;
  final String? roleName;

  const MissionIntroScreen({super.key, required this.mission, this.roleName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color bgColor = AppColors.background;

    // TARIK BAHASA AKTIF DARI PROVIDER
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;
    final isFavorite = ref.watch(favoriteMissionsProvider).contains(mission.id);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. BACKGROUND & GAMBAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomIllustration(context, mission.roleId, bgColor),
          ),

          // 2. KONTEN UTAMA
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TOMBOL KEMBALI + FAVORIT
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomBackButton(
                        onPressed: () => Navigator.pop(context),
                      ),
                      GestureDetector(
                        onTap: () => ref
                            .read(favoriteMissionsProvider.notifier)
                            .toggle(mission.id),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: AppColors.accent,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LABEL PERAN MODERN
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm + 10),
                          ),
                          child: Text(
                            (roleName ?? mission.roleId).toUpperCase(),
                            style: TextStyle(
                              color: AppColors.accentDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // JUDUL MISI DINAMIS (ID/EN)
                        Text(
                          lang == 'id' ? mission.titleId : mission.titleEn,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // DESKRIPSI MISI DINAMIS (ID/EN)
                        Text(
                          lang == 'id'
                              ? mission.descriptionId
                              : mission.descriptionEn,
                          style: TextStyle(
                            color: AppColors.primary.withValues(alpha: 0.75),
                            fontSize: 16,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // BADGES WAKTU & SKILL
                        _buildBadgeSection(mission, lang, texts),

                        const SizedBox(height: 36),

                        // ALAT YANG PERLU DISIAPKAN
                        _buildMaterialsSection(mission, lang, texts),

                        // Ruang ekstra bawah agar konten terakhir tidak mentok tombol
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // 3. TOMBOL MULAI BARU (GLOSSY DENGAN PANAH)
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentDark.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // KUNCI HILANGKAN NAVBAR DI HALAMAN SELANJUTNYA
                        Navigator.of(context, rootNavigator: true).push(
                          appPageRoute(MissionPlayScreen(mission: mission)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFF58B7A), AppColors.accentDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Container(
                          constraints: const BoxConstraints(
                            minHeight: 64,
                            minWidth: double.infinity,
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                texts['btn_start']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildBottomIllustration(
    BuildContext context,
    String roleId,
    Color bgColor,
  ) {
    String assetPath = 'assets/images/penguin_$roleId.png';

    return SizedBox(
      height: context.screenHeight * 0.45,
      child: Stack(
        children: [
          Positioned(
            bottom: -80,
            left: -40,
            right: -40,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const SizedBox(),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bgColor,
                    bgColor.withValues(alpha: 0.8),
                    bgColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeSection(
    MissionModel mission,
    String lang,
    Map<String, String> texts,
  ) {
    // FIX ERROR: Ekstrak angka saja dari mission.duration (karena tipenya String)
    String minutes = "15"; // Fallback default
    if (mission.duration != null) {
      final numbersOnly = mission.duration!.replaceAll(RegExp(r'[^0-9]'), '');
      if (numbersOnly.isNotEmpty) {
        minutes = numbersOnly;
      }
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildBadge("$minutes ${texts['mins']}", Icons.timer_outlined),
        ...mission.skillsReward.entries.map((skill) {
          return _buildBadge(
            "${skill.key.toUpperCase()} +${skill.value}",
            null,
            emoji: _getSkillEmoji(skill.key),
          );
        }),
      ],
    );
  }

  Widget _buildMaterialsSection(
    MissionModel mission,
    String lang,
    Map<String, String> texts,
  ) {
    final List tools = lang == 'id' ? mission.toolsId : mission.toolsEn;
    if (tools.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texts['prep_tools']!,
          style: TextStyle(
            color: AppColors.primary.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tools.map((material) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primaryLighter.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                material.toString(),
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String text, IconData? icon, {String? emoji}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(width: 6),
          ],
          if (emoji != null) ...[
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getSkillEmoji(String skillKey) {
    switch (skillKey.toLowerCase()) {
      case 'motoric':
        return '🧩';
      case 'cognitive':
        return '🧠';
      case 'creativity':
        return '🎨';
      case 'literacy':
        return '📚';
      case 'empathy':
        return '💗';
      default:
        return '🌟';
    }
  }
}
