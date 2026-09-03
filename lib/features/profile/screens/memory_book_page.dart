import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/role_visuals.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/providers/memory_book_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/responsive.dart';
import '../../../shared/widgets/app_state_views.dart';
import '../../../shared/widgets/app_choice_chip.dart';
import '../../../shared/widgets/app_screen_header.dart';
import '../../../shared/widgets/fun_background_decorations.dart';

const Map<String, Map<String, String>> _t = {
  'en': {
    'close_photo': "Close photo",
    'title': "Memory Book",
    'empty':
        "No photos yet -- complete a mission to start collecting memories.",
    'err': "Failed to load photos: ",
    'all_roles': "All",
  },
  'id': {
    'close_photo': "Tutup foto",
    'title': "Buku Kenangan",
    'empty': "Belum ada foto -- selesaikan misi buat mulai ngumpulin kenangan.",
    'err': "Gagal memuat foto: ",
    'all_roles': "Semua",
  },
};

/// Galeri semua foto journal dari SEMUA misi yang udah selesai -- dulu foto
/// cuma bisa diliat lagi 1 misi per 1 misi lewat fitur replay di Progress.
/// App ini photo-heavy (tiap step misi minta foto anak beraktivitas), jadi
/// galeri terpadu kerasa seperti fitur yang harusnya ada dari awal.
class MemoryBookPage extends ConsumerStatefulWidget {
  final String childId;

  const MemoryBookPage({super.key, required this.childId});

  @override
  ConsumerState<MemoryBookPage> createState() => _MemoryBookPageState();
}

class _MemoryBookPageState extends ConsumerState<MemoryBookPage> {
  String? _selectedRoleId;

  void _openViewer(MemoryPhoto photo, String lang, Map<String, String> texts) {
    final role = roleVisualById(photo.roleId) ?? kUnknownRoleVisual;
    final String dateLabel = photo.takenAt != null
        ? DateFormat('dd MMM yyyy').format(photo.takenAt!)
        : '';

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: photo.imageUrl,
                      fit: BoxFit.contain,
                      errorWidget: (c, e, s) => Container(
                        color: AppColors.border,
                        height: 200,
                        child: Icon(Icons.broken_image,
                            color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  if (photo.missionTitle(lang).isNotEmpty)
                    Container(
                      width: double.infinity,
                      color: AppColors.surface,
                      padding: const EdgeInsets.all(AppSpacing.sm + 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            photo.missionTitle(lang),
                            style: AppTextStyles.bodyBold(),
                          ),
                          if (dateLabel.isNotEmpty)
                            Text(
                              "${role.name(lang)} • $dateLabel",
                              style: AppTextStyles.caption(
                                  color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: -16,
              right: -16,
              child: IconButton(
                tooltip: texts['close_photo']!,
                icon: const Icon(Icons.cancel, color: Colors.white, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;
    final hPad = context.pageHPadding;

    final photosAsync = ref.watch(memoryBookProvider(widget.childId));

    return Scaffold(
      backgroundColor: AppColors.background,
      // Sentuhan tipis doang -- ini galeri FOTO, jadi dekorasinya sengaja
      // minimal biar nggak berebut perhatian sama foto anaknya sendiri.
      body: Stack(
        children: [
          const Positioned(
            top: 60,
            right: 20,
            child: Sparkle(size: 18, color: AppColors.gold),
          ),
          const Positioned(
            bottom: 160,
            left: 16,
            child: Sparkle(size: 14, color: AppColors.accent),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppScreenHeader(title: texts['title']!),
                Expanded(
                  child: photosAsync.when(
                    loading: () => const AppLoading(),
                    error: (e, s) => AppErrorView(message: "${texts['err']}$e"),
                    data: (allPhotos) {
                      if (allPhotos.isEmpty) {
                        return AppEmptyState(
                          message: texts['empty']!,
                          icon: Icons.photo_library_outlined,
                        );
                      }

                      // Urutan chip-nya ngikutin kRoleVisuals (Koki/Dokter/
                      // Pelukis/dst), bukan urutan kemunculan role di allPhotos
                      // (yang disortir "terbaru duluan" di provider) -- kalau
                      // pakai itu langsung, urutan chip-nya acak/nggak konsisten
                      // tiap kali data foto berubah.
                      final presentRoleIds =
                          allPhotos.map((p) => p.roleId).toSet();
                      final roleIds = [
                        ...kRoleVisuals
                            .map((r) => r.id)
                            .where(presentRoleIds.contains),
                        ...presentRoleIds.where(
                          (id) => !kRoleVisuals.any((r) => r.id == id),
                        ),
                      ];
                      final photos = _selectedRoleId == null
                          ? allPhotos
                          : allPhotos
                              .where((p) => p.roleId == _selectedRoleId)
                              .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (roleIds.length > 1)
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: hPad),
                                children: [
                                  _roleChip(null, texts['all_roles']!,
                                      AppColors.primary),
                                  const SizedBox(width: AppSpacing.sm),
                                  ...roleIds.map((id) {
                                    final role = roleVisualById(id) ??
                                        kUnknownRoleVisual;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          right: AppSpacing.sm),
                                      child: _roleChip(id, role.name(lang),
                                          role.resolvedBadgeColor),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          const SizedBox(height: AppSpacing.sm),
                          Expanded(
                            child: GridView.builder(
                              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 40),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                              itemCount: photos.length,
                              itemBuilder: (context, index) {
                                final photo = photos[index];
                                return GestureDetector(
                                  onTap: () => _openViewer(photo, lang, texts),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                    child: CachedNetworkImage(
                                      imageUrl: photo.imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (c, u) =>
                                          Container(color: AppColors.border),
                                      errorWidget: (c, e, s) => Container(
                                        color: AppColors.border,
                                        child: Icon(Icons.broken_image,
                                            color: AppColors.textMuted),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String? roleId, String label, Color color) {
    return AppChoiceChip(
      label: label,
      color: color,
      selected: _selectedRoleId == roleId,
      onTap: () => setState(() => _selectedRoleId = roleId),
    );
  }
}
