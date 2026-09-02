import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/role_visuals.dart';
import '../../../core/providers/all_badges_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/responsive.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_state_views.dart';
import '../../../shared/widgets/back_button.dart';

const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "All Badges",
    'empty': "No badges available yet.",
    'err': "Failed to load badges: ",
    'locked': "Not unlocked yet",
  },
  'id': {
    'title': "Semua Lencana",
    'empty': "Belum ada data lencana.",
    'err': "Gagal memuat lencana: ",
    'locked': "Belum terbuka",
  },
};

/// Semua badge (terbuka & masih terkunci) 1 anak, dikelompokin per role --
/// dulu nggak ada tempat buat liat ini, badge cuma keliatan sepotong di
/// strip "Pencapaian Terbaru" Home atau nempel di kartu sertifikat.
class AllBadgesPage extends ConsumerWidget {
  final String childId;

  const AllBadgesPage({super.key, required this.childId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;
    final hPad = context.pageHPadding;

    final badgesAsync = ref.watch(allBadgesProvider(childId));

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
              child: badgesAsync.when(
                loading: () => const AppLoading(),
                error: (e, s) => AppErrorView(message: "${texts['err']}$e"),
                data: (badges) {
                  if (badges.isEmpty) {
                    return AppEmptyState(message: texts['empty']!);
                  }

                  // Dikelompokin per role biar konsisten sama Peta Misi /
                  // Semua Sertifikat, bukan 1 grid rata tanpa konteks.
                  final Map<String, List<BadgeEntry>> byRole = {};
                  for (final b in badges) {
                    byRole.putIfAbsent(b.roleId, () => []).add(b);
                  }

                  // Urutan SECTION-nya sendiri (Koki/Dokter/Pelukis/dst)
                  // ngikutin kRoleVisuals -- bukan urutan insersi Map, yang
                  // kebentuk dari urutan badges (badges disortir "kebuka
                  // duluan" di provider), jadi tanpa ini urutan section-nya
                  // acak/nggak konsisten tiap kali data berubah, beda dari
                  // urutan role yang stabil di layar lain (mission search,
                  // dst).
                  final orderedRoleIds = [
                    ...kRoleVisuals.map((r) => r.id).where(byRole.containsKey),
                    ...byRole.keys.where(
                      (id) => !kRoleVisuals.any((r) => r.id == id),
                    ),
                  ];

                  return ListView(
                    padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 40),
                    children: orderedRoleIds.map((roleId) {
                      final role = roleVisualById(roleId) ?? kUnknownRoleVisual;
                      final entryValue = byRole[roleId]!;
                      final unlockedCount =
                          entryValue.where((b) => b.isUnlocked).length;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(role.name(lang), style: AppTextStyles.h3()),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  "$unlockedCount/${entryValue.length}",
                                  style: AppTextStyles.caption(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...entryValue.map(
                              (b) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: _BadgeTile(badge: b, role: role, lang: lang, texts: texts),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({
    required this.badge,
    required this.role,
    required this.lang,
    required this.texts,
  });

  final BadgeEntry badge;
  final RoleVisual role;
  final String lang;
  final Map<String, String> texts;

  @override
  Widget build(BuildContext context) {
    final bool unlocked = badge.isUnlocked;
    final String subtitle = unlocked
        ? DateFormat('dd MMM yyyy').format(badge.unlockedAt!)
        : texts['locked']!;

    return Opacity(
      opacity: unlocked ? 1 : 0.5,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: unlocked ? role.resolvedTint : AppColors.border,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  unlocked ? badge.icon : '🔒',
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
                    badge.title(lang),
                    style: AppTextStyles.bodyBold(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption(
                      color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
