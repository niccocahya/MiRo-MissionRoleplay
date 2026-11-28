import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/settings_provider.dart';
import '../../core/theme/miro_tokens.dart';

/// Bar progres (DESIGN_SYSTEM §7.7). Isi tumbuh dengan `scaleX` dari nilai
/// lama ke baru (bukan animasi lebar, ANIMATION §3.2), dengan garis
/// highlight putih di sepertiga atas untuk ukuran ≥ 12.
class MiroProgressBar extends ConsumerWidget {
  const MiroProgressBar({
    super.key,
    required this.value,
    this.color = MiroColors.amber500,
    this.track = MiroColors.navy100,
    this.height = 12,
    this.semanticsLabel,
  });

  /// 0 sampai 1.
  final double value;
  final Color color;
  final Color track;

  /// 8, 10, 12, atau 16 (lesson bar).
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = value.clamp(0.0, 1.0);
    final reduce = reduceMotionOf(context, ref);
    return Semantics(
      label: semanticsLabel,
      value: '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MiroRadius.pill),
        child: Container(
          height: height,
          color: track,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: v),
            duration: reduce ? Duration.zero : MiroMotion.grow,
            curve: MiroMotion.easeOut,
            builder: (context, t, child) => Transform.scale(
              scaleX: t,
              alignment: Alignment.centerLeft,
              child: child,
            ),
            child: _Fill(color: color, height: height),
          ),
        ),
      ),
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(MiroRadius.pill),
      ),
      child: height >= 12
          ? Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  MiroSpace.x2,
                  height * 0.19,
                  MiroSpace.x2,
                  0,
                ),
                height: height * 0.25,
                decoration: BoxDecoration(
                  color: MiroColors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(MiroRadius.pill),
                ),
              ),
            )
          : null,
    );
  }
}

/// Lesson bar (HANDOFF 01, 04): tinggi 16, isi hijau, menunjukkan langkah
/// [current] dari [steps]. [onMood] = track putih 60% di atas latar biru.
class SegmentBar extends StatelessWidget {
  const SegmentBar({
    super.key,
    required this.current,
    required this.steps,
    this.onMood = false,
    this.semanticsLabel,
  });

  final int current;
  final int steps;
  final bool onMood;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return MiroProgressBar(
      value: steps == 0 ? 0 : current / steps,
      color: MiroColors.green500,
      track:
          onMood ? MiroColors.white.withValues(alpha: 0.6) : MiroColors.navy100,
      height: 16,
      semanticsLabel: semanticsLabel,
    );
  }
}
