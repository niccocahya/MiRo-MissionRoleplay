import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/l10n/tr.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/miro_tokens.dart';
import 'mascot/mascot.dart';
import 'miro_button.dart';

enum MiroBannerTone { info, success, warning, danger, cream }

/// Banner informasi (COMPONENTS §5.1; 42, 43, 50, 51). `info` = navy
/// (mis. offline 50), `danger` diumumkan sebagai alert.
class MiroBanner extends StatelessWidget {
  const MiroBanner({
    super.key,
    required this.message,
    this.tone = MiroBannerTone.info,
    this.title,
    this.icon,
    this.action,
  });

  final String message;
  final String? title;
  final MiroBannerTone tone;
  final IconData? icon;

  /// Tombol/tautan di bawah pesan (mis. "Coba lagi").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, iconColor, defaultIcon) = switch (tone) {
      MiroBannerTone.info => (
          MiroColors.navy900,
          MiroColors.white,
          MiroColors.sky300,
          PhosphorIcons.info(PhosphorIconsStyle.bold),
        ),
      MiroBannerTone.success => (
          MiroColors.green50,
          MiroColors.green900,
          MiroColors.green600,
          PhosphorIcons.checkCircle(PhosphorIconsStyle.bold),
        ),
      MiroBannerTone.warning => (
          MiroColors.amber75,
          MiroColors.amber900,
          MiroColors.amber700,
          PhosphorIcons.warning(PhosphorIconsStyle.bold),
        ),
      MiroBannerTone.danger => (
          MiroColors.red50,
          MiroColors.red900,
          MiroColors.red700,
          PhosphorIcons.warningCircle(PhosphorIconsStyle.bold),
        ),
      MiroBannerTone.cream => (
          MiroColors.cream100,
          MiroColors.amber900,
          MiroColors.amber700,
          PhosphorIcons.info(PhosphorIconsStyle.bold),
        ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: MiroSpace.x3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(MiroRadius.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? defaultIcon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: MiroText.bodyStrong.copyWith(color: fg),
                    ),
                  Text(
                    message,
                    style: MiroText.label.copyWith(color: fg),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: MiroSpace.x2),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Toast konfirmasi kecil (DESIGN_SYSTEM §7.16): navy, teks putih, ikon 20.
/// Maksimal satu tampil (toast lama diganti), hilang setelah 4 detik.
void showMiroToast(
  BuildContext context,
  String message, {
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: MiroMotion.toast,
        backgroundColor: MiroColors.navy900,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          MiroSpace.x5,
          0,
          MiroSpace.x5,
          MiroSpace.x4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MiroRadius.lg),
        ),
        content: Row(
          children: [
            Icon(
              icon ?? PhosphorIcons.checkCircle(PhosphorIconsStyle.bold),
              size: 20,
              color: MiroColors.sky300,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: MiroText.bodyStrong.copyWith(color: MiroColors.white),
              ),
            ),
          ],
        ),
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: MiroColors.amber300,
                onPressed: onAction ?? () {},
              ),
      ),
    );
}

/// State kosong (DESIGN_SYSTEM §7.16; 48, 49, 53): maskot, judul, satu
/// kalimat, langkah bernomor opsional, satu tombol utama.
class MiroEmptyState extends StatelessWidget {
  const MiroEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.illustration,
    this.steps = const [],
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;

  /// Default: maskot pose berpikir 120.
  final Widget? illustration;
  final List<String> steps;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        illustration ??
            const MascotImage(pose: MascotPose.thinking, height: 120),
        const SizedBox(height: MiroSpace.x3),
        Text(title, style: MiroText.h3, textAlign: TextAlign.center),
        const SizedBox(height: MiroSpace.x1),
        Text(body, style: MiroText.body, textAlign: TextAlign.center),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: MiroSpace.x4),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: MiroSpace.x2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: MiroColors.sky50,
                      borderRadius: BorderRadius.circular(MiroRadius.sm),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: MiroText.label.copyWith(color: MiroColors.sky700),
                    ),
                  ),
                  const SizedBox(width: MiroSpace.x3),
                  Expanded(child: Text(steps[i], style: MiroText.body)),
                ],
              ),
            ),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: MiroSpace.x4),
          MiroButton(label: actionLabel!, onPressed: onAction),
        ],
      ],
    );
  }
}

/// Tampilan error layar data (ARCHITECTURE §7): maskot, pesan ramah,
/// tombol coba lagi. Tidak pernah menampilkan pesan mentah dari server.
class MiroErrorView extends StatelessWidget {
  const MiroErrorView({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: MiroSpace.screen,
        child: MiroEmptyState(
          illustration: const MascotImage(pose: MascotPose.sad, height: 120),
          title: context.tr('common.errorTitle'),
          body: message ?? context.tr('common.errorBody'),
          actionLabel: context.tr('common.retry'),
          onAction: onRetry,
        ),
      ),
    );
  }
}

/// Blok skeleton (DESIGN_SYSTEM §7.17) dengan kilau melintas. Berulang
/// selama memuat (pengecualian loop, ANIMATION §3.5); diam saat "kurangi
/// animasi".
class MiroSkeleton extends ConsumerStatefulWidget {
  const MiroSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = MiroRadius.md,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  ConsumerState<MiroSkeleton> createState() => _MiroSkeletonState();
}

class _MiroSkeletonState extends ConsumerState<MiroSkeleton>
    with SingleTickerProviderStateMixin {
  // Dibuat di initState, bukan lazy: controller lazy yang belum pernah
  // dipakai (mis. saat kurangi animasi) akan dibuat di dispose() dan error.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: MiroMotion.skeleton);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context, ref);
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
    final box = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: MiroColors.navy100,
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius:
            widget.circle ? null : BorderRadius.circular(widget.radius),
      ),
    );
    if (reduce) return ExcludeSemantics(child: box);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          widget.circle ? MiroRadius.pill : widget.radius,
        ),
        child: Stack(
          children: [
            box,
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => FractionalTranslation(
                  translation: Offset(-1 + 2 * _c.value, 0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          MiroColors.white.withValues(alpha: 0),
                          MiroColors.white.withValues(alpha: 0.35),
                          MiroColors.white.withValues(alpha: 0),
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
    );
  }
}

/// Kode 6 karakter dalam kotak 40×52 (HANDOFF 41), di atas kartu navy.
/// Bisa diketuk untuk menyalin.
class CodeBoxes extends StatelessWidget {
  const CodeBoxes({super.key, required this.code, this.onCopied});

  final String code;
  final VoidCallback? onCopied;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: code.split('').join(' '),
      button: onCopied != null,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onCopied == null
            ? null
            : () {
                Clipboard.setData(ClipboardData(text: code));
                onCopied!();
              },
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final ch in code.split(''))
              Container(
                width: 40,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MiroColors.navy700,
                  borderRadius: BorderRadius.circular(MiroRadius.md),
                ),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.2,
                  child: Text(
                    ch,
                    style: MiroText.h1.copyWith(
                      fontSize: 28,
                      color: MiroColors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
