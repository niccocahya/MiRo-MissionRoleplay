import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline }

/// Tombol standar app. Ganti semua `ElevatedButton`/`GestureDetector` custom
/// yang nulis ulang gradient+radius+shadow di tiap layar.
///
/// ```dart
/// AppButton(label: 'Lanjut', onPressed: _next)
/// AppButton(label: 'Batal', variant: AppButtonVariant.outline, onPressed: pop)
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    Color background;
    Color foreground;
    BoxBorder? border;

    switch (variant) {
      case AppButtonVariant.primary:
        background = AppColors.accent;
        foreground = Colors.white;
        break;
      case AppButtonVariant.secondary:
        background = AppColors.primary;
        foreground = Colors.white;
        break;
      case AppButtonVariant.outline:
        background = Colors.transparent;
        foreground = AppColors.primary;
        border = Border.all(color: AppColors.primary, width: 1.5);
        break;
    }

    final child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: foreground),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTextStyles.button(color: foreground)),
            ],
          );

    return Opacity(
      opacity: disabled && !isLoading ? 0.5 : 1,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          side: border is Border ? border.top : BorderSide.none,
        ),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.lg),
          child: Container(
            width: fullWidth ? double.infinity : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}
