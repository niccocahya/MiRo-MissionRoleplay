import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../core/theme/miro_tokens.dart';

/// Helper animasi masuk dan loop (ANIMATION §2). Semua hanya memakai
/// transform dan opacity, dan membaca "kurangi animasi" sendiri: saat aktif,
/// langsung menampilkan keadaan akhir (ANIMATION §7).

/// Naik 14px + fade (`rise`, 420 ms). [index] menambah jeda bertahap.
class MiroRise extends ConsumerWidget {
  const MiroRise({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.stagger = MiroMotion.stagger,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Duration stagger;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reduceMotionOf(context, ref)) return child;
    return _Delayed(
      delay: delay + stagger * index,
      duration: MiroMotion.rise,
      curve: MiroMotion.easeOut,
      builder: (t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Muncul dengan skala 0.6 → 1 + fade (`popin`, 460 ms, sedikit lewat).
class MiroPopIn extends ConsumerWidget {
  const MiroPopIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.stagger = MiroMotion.stagger,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final int index;
  final Duration delay;
  final Duration stagger;
  final Alignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reduceMotionOf(context, ref)) return child;
    return _Delayed(
      delay: delay + stagger * index,
      duration: MiroMotion.pop,
      curve: MiroMotion.easePop,
      builder: (t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.4 * t,
          alignment: alignment,
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Animasi satu kali setelah [delay]. Dipakai bersama oleh helper masuk.
class _Delayed extends StatefulWidget {
  const _Delayed({
    required this.delay,
    required this.duration,
    required this.curve,
    required this.builder,
    required this.child,
  });

  final Duration delay;
  final Duration duration;
  final Curve curve;
  final Widget Function(double t, Widget child) builder;
  final Widget child;

  @override
  State<_Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<_Delayed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: widget.curve,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, child) => widget.builder(_t.value, child!),
        child: widget.child,
      ),
    );
  }
}

/// Loop dekoratif yang berhenti sendiri setelah [MiroMotion.maxLoops]
/// putaran (ANIMATION §3.5).
class _Looping extends StatefulWidget {
  const _Looping({
    required this.period,
    required this.delay,
    required this.builder,
    required this.child,
  });

  final Duration period;
  final Duration delay;
  final Widget Function(double wave, Widget child) builder;
  final Widget child;

  @override
  State<_Looping> createState() => _LoopingState();
}

class _LoopingState extends State<_Looping>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.repeat(count: MiroMotion.maxLoops);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          // Gelombang 0 → 1 → 0 dengan ease-in-out.
          final v = _c.value;
          final wave = Curves.easeInOut.transform(v < 0.5 ? v * 2 : 2 - v * 2);
          return widget.builder(wave, child!);
        },
        child: widget.child,
      ),
    );
  }
}

/// Naik-turun 4px, 2,4 s × 3 (`floaty`). Untuk satu elemen "bintang".
class MiroFloat extends ConsumerWidget {
  const MiroFloat({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reduceMotionOf(context, ref)) return child;
    return _Looping(
      period: MiroMotion.floatPeriod,
      delay: MiroMotion.floatDelay,
      builder: (w, child) =>
          Transform.translate(offset: Offset(0, -4 * w), child: child),
      child: child,
    );
  }
}

/// Denyut skala 1 → 1.14, 1,4 s × 3 (`pulse`).
class MiroPulse extends ConsumerWidget {
  const MiroPulse({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reduceMotionOf(context, ref)) return child;
    return _Looping(
      period: MiroMotion.pulsePeriod,
      delay: MiroMotion.pulseDelay,
      builder: (w, child) => Transform.scale(scale: 1 + 0.14 * w, child: child),
      child: child,
    );
  }
}

/// Bar yang tumbuh dari kiri (`grow-x`, `scaleX`), bukan animasi lebar.
class MiroGrowX extends ConsumerWidget {
  const MiroGrowX({super.key, required this.child, this.delay});

  final Widget child;
  final Duration? delay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reduceMotionOf(context, ref)) return child;
    return _Delayed(
      delay: delay ?? MiroMotion.growDelay,
      duration: MiroMotion.grow,
      curve: MiroMotion.easeOut,
      builder: (t, child) => Transform.scale(
        scaleX: t,
        alignment: Alignment.centerLeft,
        child: child,
      ),
      child: child,
    );
  }
}

/// Angka bergulir per digit (M6). Lebar digit tetap (`tabular-nums`).
class Odometer extends ConsumerWidget {
  const Odometer({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabular = style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final text = '$value';
    if (reduceMotionOf(context, ref)) {
      return Text(text, style: tabular);
    }
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < text.length; i++)
            ClipRect(
              child: AnimatedSwitcher(
                duration: MiroMotion.slow,
                switchInCurve: MiroMotion.easeOut,
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
                child: Text(
                  text[i],
                  key: ValueKey('${text.length - i}-${text[i]}'),
                  style: tabular,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Goyang horizontal ±6px, 200 ms, setiap [signal] berubah (M3).
class MiroShake extends ConsumerStatefulWidget {
  const MiroShake({super.key, required this.signal, required this.child});

  final int signal;
  final Widget child;

  @override
  ConsumerState<MiroShake> createState() => _MiroShakeState();
}

class _MiroShakeState extends ConsumerState<MiroShake>
    with SingleTickerProviderStateMixin {
  // Dibuat di initState, bukan lazy: controller lazy yang belum pernah
  // dipakai (mis. saat kurangi animasi) akan dibuat di dispose() dan error.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: MiroMotion.shake);
  }

  @override
  void didUpdateWidget(covariant MiroShake old) {
    super.didUpdateWidget(old);
    if (old.signal != widget.signal) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context, ref)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        // 0 → -6 → +6 → 0 (keyframe shake di tokens.css).
        final dx = t < 0.25
            ? -24 * t
            : t < 0.75
                ? -6 + 24 * (t - 0.25)
                : 6 - 24 * (t - 0.75);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
