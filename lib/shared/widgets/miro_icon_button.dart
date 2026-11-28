import 'package:flutter/material.dart';

import '../../core/theme/miro_tokens.dart';
import 'miro_pressable.dart';

enum MiroIconButtonVariant {
  /// Lingkaran putih, border garis, lip 2 (top bar semua layar).
  surface,

  /// Di atas latar biru onboarding: putih 75%.
  onMood,

  /// Tanpa lingkaran (tombol X di layar misi).
  ghost,
}

/// Tombol ikon bulat (DESIGN_SYSTEM §7.2). [label] wajib untuk pembaca
/// layar karena tombol ini tidak punya teks.
class MiroIconButton extends StatelessWidget {
  const MiroIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = MiroIconButtonVariant.surface,
    this.size = MiroSize.touch,
    this.iconColor = MiroColors.ink,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final MiroIconButtonVariant variant;

  /// 44 (default) atau 40 (tombol notifikasi Beranda).
  final double size;
  final Color iconColor;

  /// Titik coral 8px di pojok (ada notifikasi belum dibaca).
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 24, color: iconColor);

    if (variant == MiroIconButtonVariant.ghost) {
      return Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onPressed,
          radius: size / 2,
          child: SizedBox.square(
            dimension: MiroSize.touch,
            child: Center(child: iconWidget),
          ),
        ),
      );
    }

    final button = MiroPressable(
      onTap: onPressed,
      circle: true,
      lip: MiroLip.iconButton,
      color: variant == MiroIconButtonVariant.onMood
          ? MiroColors.white.withValues(alpha: 0.75)
          : MiroColors.surface,
      lipColor: MiroColors.line,
      border: Border.all(color: MiroColors.line, width: 2),
      semanticsLabel: label,
      excludeChildSemantics: true,
      child: SizedBox.square(
        dimension: size - 4, // dikurangi border 2 di kedua sisi
        child: Center(child: iconWidget),
      ),
    );

    if (!badge) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: MiroColors.coral500,
              shape: BoxShape.circle,
              border: Border.all(color: MiroColors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
