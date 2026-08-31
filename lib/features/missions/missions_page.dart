import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/mission_provider.dart';
import 'screens/mission_path_screen.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/app_state_views.dart';

/// Halaman peta misi per-role. [roleId] datang dari query param `?role=`
/// (dipasang dari kartu role di Home) — sebelumnya diabaikan sepenuhnya,
/// jadi tap kartu role manapun di Home selalu nyasar ke role pertama yang
/// kebetulan urutan pertama di database, bukan role yang benar-benar dipilih.
class MissionsPage extends ConsumerWidget {
  const MissionsPage({super.key, this.roleId});

  final String? roleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final missionsAsync = ref.watch(missionsProvider);
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: missionsAsync.when(
        loading: () => const AppLoading(),
        error: (err, stack) => AppErrorView(
          message: lang == 'id' ? "Masalah koneksi: $err" : "Connection error: $err",
        ),
        data: (missions) {
          if (missions.isEmpty) {
            return AppEmptyState(
              message: lang == 'id'
                  ? "Data misi tidak ditemukan"
                  : "Mission data not found",
            );
          }

          // Pakai role dari query param kalau ada & valid; kalau nggak,
          // fallback ke role pertama yang punya misi (perilaku lama).
          final availableRoleIds = missions.map((m) => m.roleId).toSet();
          final resolvedRoleId =
              (roleId != null && availableRoleIds.contains(roleId))
              ? roleId!
              : missions.first.roleId;

          final roleName = rolesAsync.maybeWhen(
            data: (roles) {
              final match = roles.where((r) => r.id == resolvedRoleId);
              if (match.isEmpty) return null;
              final role = match.first;
              return lang == 'id' ? role.nameId : role.nameEn;
            },
            orElse: () => null,
          );

          return MissionPathScreen(
            roleId: resolvedRoleId,
            roleName: roleName ?? (lang == 'id' ? 'Penjelajah' : 'Explorer'),
          );
        },
      ),
    );
  }
}
