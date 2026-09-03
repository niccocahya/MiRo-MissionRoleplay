import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Dua gaya chip yang kepakai di app ini.
enum AppChipStyle {
  /// Kepilih = kotaknya keisi penuh warna, teksnya putih.
  /// Dipakai buat filter (peran di Cari Misi / Buku Kenangan, skill di Progres).
  solid,

  /// Kepilih = background tipis + border + teks warnanya sama.
  /// Dipakai buat pilihan isian (kuisioner minat, jenis masukan di Bantuan).
  soft,
}

/// Chip "bisa dipilih" berbentuk pil.
///
/// Sebelumnya pola ini ditulis ulang di 5 tempat dengan bentuk yang
/// hampir sama tapi nggak persis: `_roleChip` di mission_search_screen.dart
/// DAN memory_book_page.dart (identik baris per baris), `_favoritesChip`,
/// chip skill di progress_page.dart, dan `_chipWrap` di
/// edit_questionnaire_page.dart -- beda-beda tipis di radius, padding,
/// warna teks pas nggak kepilih, dan ada yang pakai `Colors.white` mentah
/// alih-alih `AppColors.surface`. Sekarang satu bentuk.
///
/// ```dart
/// AppChoiceChip(label: 'Koki', selected: true, color: role.badgeColor, onTap: ...)
/// AppChoiceChip(label: 'Favorit', icon: Icons.favorite, selected: on, onTap: ...)
/// AppChoiceChip(label: 'Visual', selected: on, style: AppChipStyle.soft, onTap: ...)
/// ```
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
    this.style = AppChipStyle.solid,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Ikon kecil di kiri label (opsional).
  final IconData? icon;

  /// Warna "aktif" chip ini. Default: aksen app.
  final Color? color;

  final AppChipStyle style;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = color ?? AppColors.accent;
    final bool isSoft = style == AppChipStyle.soft;

    final Color background = selected
        ? (isSoft ? activeColor.withValues(alpha: 0.15) : activeColor)
        : (isSoft ? AppColors.background : AppColors.surface);
    final Color borderColor = selected ? activeColor : AppColors.border;
    final Color contentColor = selected
        ? (isSoft ? activeColor : Colors.white)
        : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: contentColor),
              const SizedBox(width: AppSpacing.xs + 2),
            ],
            Text(
              label,
              style: AppTextStyles.bodyBold(color: contentColor)
                  .copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
