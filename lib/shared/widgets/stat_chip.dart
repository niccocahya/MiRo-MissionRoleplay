import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Pil kecil buat nampilin angka/statistik (XP, level, streak, jumlah misi).
/// Dulu ada versi berbeda-beda di home/progress/profile untuk hal yang sama.
class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.background,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: background ?? resolvedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: resolvedColor),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppTextStyles.bodyBold(color: resolvedColor)),
        ],
      ),
    );
  }
}
