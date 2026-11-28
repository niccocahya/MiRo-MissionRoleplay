import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/tr.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/miro_tokens.dart';
import 'miro_pressable.dart';

/// Varian tombol (DESIGN_SYSTEM §7.1, COMPONENTS §5.1).
enum MiroButtonVariant {
  /// Satu aksi utama per layar (coral 600).
  primary,

  /// Aksi alternatif (putih, border garis).
  secondary,

  /// Aksi utama di atas latar biru `moodGradient` (navy).
  dark,

  /// Klaim hadiah, buka peti (amber, teks navy).
  reward,

  /// "Sudah!" di langkah misi (hijau 600).
  success,

  /// Hapus, keluar akun (merah 600).
  danger,

  /// Aksi bahaya yang tidak boleh menonjol (putih, teks merah, garis coral
  /// muda). Contoh: "Keluar dari akun" di Pengaturan (37).
  dangerOutline,
}

/// Ukuran tombol: tinggi 56 / 48 / 40.
enum MiroButtonSize { l, m, s }

/// Tombol MiRO dengan sistem lip (HANDOFF 01, 33). Label otomatis kapital
/// dengan tracking 0.04em. [loading] mengganti label dengan titik memuat
/// tanpa mengubah ukuran, dan menonaktifkan tombol (QA §5: cegah aksi ganda).
class MiroButton extends StatelessWidget {
  const MiroButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MiroButtonVariant.primary,
    this.size = MiroButtonSize.l,
    this.icon,
    this.expand = true,
    this.loading = false,
    this.semanticsLabel,
  });

  final String label;

  /// `null` = nonaktif.
  final VoidCallback? onPressed;
  final MiroButtonVariant variant;
  final MiroButtonSize size;
  final IconData? icon;

  /// Lebar penuh (default di footer). `false` = selebar isi.
  final bool expand;
  final bool loading;
  final String? semanticsLabel;

  bool get _enabled => onPressed != null && !loading;

  @override
  Widget build(BuildContext context) {
    final colors = _enabled || loading
        ? _colorsFor(variant)
        : const _ButtonColors(
            face: MiroColors.navy100,
            lip: MiroColors.navy200,
            text: MiroColors.navy400,
          );

    final (height, padX, fontSize, iconSize) = switch (size) {
      MiroButtonSize.l => (MiroSize.buttonL, MiroSpace.x6, 17.0, 20.0),
      MiroButtonSize.m => (MiroSize.buttonM, MiroSpace.x5, 15.0, 20.0),
      MiroButtonSize.s => (MiroSize.buttonS, MiroSpace.x4, 13.0, 16.0),
    };
    final textStyle = MiroText.button(size: fontSize, color: colors.text);

    final content = loading
        ? _LoadingDots(color: colors.text, label: context.tr('common.loading'))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: colors.text),
                const SizedBox(width: MiroSpace.x2),
              ],
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  style: textStyle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final button = MiroPressable(
      onTap: _enabled ? onPressed : null,
      enabled: _enabled,
      color: colors.face,
      lipColor: colors.lip,
      lip: MiroLip.button,
      radius: MiroRadius.lg,
      border: colors.border == null
          ? null
          : Border.all(color: colors.border!, width: 2),
      semanticsLabel: semanticsLabel ?? label,
      excludeChildSemantics: true,
      child: ConstrainedBox(
        // Tinggi minimal, bukan tetap: teks yang diperbesar 2× boleh
        // membuat tombol lebih tinggi daripada terpotong (RESPONSIVE §4).
        constraints: BoxConstraints(minHeight: height),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: padX,
            vertical: MiroSpace.x2,
          ),
          child: Center(widthFactor: 1, child: content),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  static _ButtonColors _colorsFor(MiroButtonVariant v) => switch (v) {
        MiroButtonVariant.primary => const _ButtonColors(
            face: MiroColors.actionPrimary,
            lip: MiroColors.actionPrimaryLip,
            text: MiroColors.white,
          ),
        MiroButtonVariant.secondary => const _ButtonColors(
            face: MiroColors.surface,
            lip: MiroColors.line,
            text: MiroColors.ink,
            border: MiroColors.line,
          ),
        MiroButtonVariant.dark => const _ButtonColors(
            face: MiroColors.actionDark,
            lip: MiroColors.actionDarkLip,
            text: MiroColors.white,
          ),
        MiroButtonVariant.reward => const _ButtonColors(
            face: MiroColors.actionReward,
            lip: MiroColors.actionRewardLip,
            text: MiroColors.ink,
          ),
        MiroButtonVariant.success => const _ButtonColors(
            face: MiroColors.actionSuccess,
            lip: MiroColors.actionSuccessLip,
            text: MiroColors.white,
          ),
        MiroButtonVariant.danger => const _ButtonColors(
            face: MiroColors.actionDanger,
            lip: MiroColors.actionDangerLip,
            text: MiroColors.white,
          ),
        MiroButtonVariant.dangerOutline => const _ButtonColors(
            face: MiroColors.surface,
            lip: MiroColors.coral200,
            text: MiroColors.red700,
            border: MiroColors.coral200,
          ),
      };
}

class _ButtonColors {
  const _ButtonColors({
    required this.face,
    required this.lip,
    required this.text,
    this.border,
  });

  final Color face;
  final Color lip;
  final Color text;
  final Color? border;
}

/// Tiga titik memantul bergantian (DESIGN_SYSTEM §7.1). Indikator memuat
/// boleh berulang (ANIMATION §3.5); saat "kurangi animasi" titiknya diam.
class _LoadingDots extends ConsumerStatefulWidget {
  const _LoadingDots({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  ConsumerState<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends ConsumerState<_LoadingDots>
    with SingleTickerProviderStateMixin {
  // Dibuat di initState, bukan lazy: controller lazy yang belum pernah
  // dipakai (mis. saat kurangi animasi) akan dibuat di dispose() dan error.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: MiroMotion.celebrate);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context, ref)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.translate(
                  offset: Offset(0, -4 * _bounce(_c.value, i)),
                  child: Container(
                    width: MiroSpace.x2,
                    height: MiroSpace.x2,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Fase pantulan titik ke-[i], bergeser sepertiga siklus.
  static double _bounce(double t, int i) {
    final p = (t - i / 3) % 1.0;
    return p < 0.5 ? Curves.easeOut.transform(p * 2) : 0;
  }
}
