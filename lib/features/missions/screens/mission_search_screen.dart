import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mission_provider.dart';
import '../data/mission_model.dart';
import 'mission_path_screen.dart';
import '../../../core/constants/role_visuals.dart';
import '../../../core/providers/child_provider.dart';
import '../../../core/providers/child_role_progress_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/router/app_page_transition.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_state_views.dart';
import '../../../shared/widgets/back_button.dart';

const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "Search Missions",
    'hint': "Search mission name...",
    'all_roles': "All",
    'empty': "No missions match your search.",
    'err': "Failed to load missions: ",
    'status_done': "Completed",
    'status_active': "Active",
    'status_locked': "Locked",
    'view_in_map': "View in map →",
  },
  'id': {
    'title': "Cari Misi",
    'hint': "Cari nama misi...",
    'all_roles': "Semua",
    'empty': "Nggak ada misi yang cocok.",
    'err': "Gagal memuat misi: ",
    'status_done': "Selesai",
    'status_active': "Aktif",
    'status_locked': "Terkunci",
    'view_in_map': "Lihat di peta →",
  },
};

/// Layar pencarian & filter misi lintas role — sebelumnya cara satu-satunya
/// buat lihat misi apa aja yang ada adalah masuk ke tiap role satu-satu di
/// peta petualangan (yang isinya cuma 3-4 misi berurutan & terkunci), jadi
/// orang tua nggak punya cara buat lihat/ cari misi dari semua role
/// sekaligus. Ini juga jadi pintu pencarian global di app (dari Home).
class MissionSearchScreen extends ConsumerStatefulWidget {
  const MissionSearchScreen({super.key});

  @override
  ConsumerState<MissionSearchScreen> createState() =>
      _MissionSearchScreenState();
}

class _MissionSearchScreenState extends ConsumerState<MissionSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedRoleId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;
    final hPad = context.pageHPadding;

    final childDataAsync = ref.watch(childDataProvider);
    final String childId = childDataAsync.value?['id'] ?? '';
    final progressAsync = ref.watch(childRoleProgressProvider(childId));
    final missionsAsync = ref.watch(missionsProvider);

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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: texts['hint'],
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _searchController.clear();
                            _query = '';
                          }),
                        ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: hPad),
                children: [
                  _roleChip(null, texts['all_roles']!, AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  ...kRoleVisuals.map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _roleChip(r.id, r.name(lang), r.resolvedBadgeColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: missionsAsync.when(
                loading: () => const AppLoading(),
                error: (e, s) => AppErrorView(message: "${texts['err']}$e"),
                data: (missions) {
                  final filtered = missions.where((m) {
                    final matchesRole =
                        _selectedRoleId == null || m.roleId == _selectedRoleId;
                    if (!matchesRole) return false;
                    if (_query.isEmpty) return true;
                    final title = (lang == 'id' ? m.titleId : m.titleEn)
                        .toLowerCase();
                    return title.contains(_query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return AppEmptyState(
                      message: texts['empty']!,
                      icon: Icons.search_off_rounded,
                    );
                  }

                  final unlockedByRole = progressAsync.value ?? {};

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm + 2),
                    itemBuilder: (context, index) {
                      final mission = filtered[index];
                      final roleMissions = missions
                          .where((m) => m.roleId == mission.roleId)
                          .toList();
                      final missionIndex = roleMissions.indexWhere(
                        (m) => m.id == mission.id,
                      );
                      final unlockedLevel = unlockedByRole[mission.roleId] ?? 1;

                      return _MissionResultTile(
                        mission: mission,
                        lang: lang,
                        texts: texts,
                        isCompleted: missionIndex < unlockedLevel - 1,
                        isCurrent: missionIndex == unlockedLevel - 1,
                        isLocked: missionIndex > unlockedLevel - 1,
                        onTap: () {
                          final role = roleVisualById(mission.roleId) ??
                              kUnknownRoleVisual;
                          Navigator.of(context, rootNavigator: true).push(
                            appPageRoute(
                              MissionPathScreen(
                                roleId: mission.roleId,
                                roleName: role.name(lang),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String? roleId, String label, Color color) {
    final bool selected = _selectedRoleId == roleId;
    return GestureDetector(
      onTap: () => setState(() => _selectedRoleId = roleId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyBold(
            color: selected ? Colors.white : AppColors.textPrimary,
          ).copyWith(fontSize: 13),
        ),
      ),
    );
  }
}

class _MissionResultTile extends StatelessWidget {
  const _MissionResultTile({
    required this.mission,
    required this.lang,
    required this.texts,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.onTap,
  });

  final MissionModel mission;
  final String lang;
  final Map<String, String> texts;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final role = roleVisualById(mission.roleId) ?? kUnknownRoleVisual;
    final String title = lang == 'id' ? mission.titleId : mission.titleEn;
    final String desc =
        lang == 'id' ? mission.descriptionId : mission.descriptionEn;

    final Color statusColor = isCompleted
        ? AppColors.success
        : isCurrent
        ? AppColors.accent
        : AppColors.textMuted;
    final String statusLabel = isCompleted
        ? texts['status_done']!
        : isCurrent
        ? texts['status_active']!
        : texts['status_locked']!;
    final IconData statusIcon = isCompleted
        ? Icons.check_circle_rounded
        : isCurrent
        ? Icons.play_circle_fill_rounded
        : Icons.lock_rounded;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: role.resolvedTint,
              shape: BoxShape.circle,
              border: Border.all(color: role.resolvedBadgeColor.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                role.skills.isNotEmpty ? role.skills.first.icon : '⭐',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyBold(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTextStyles.caption(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: AppTextStyles.caption(color: statusColor).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      texts['view_in_map']!,
                      style: AppTextStyles.caption(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
