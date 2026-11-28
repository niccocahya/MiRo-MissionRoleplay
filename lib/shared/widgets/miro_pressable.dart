import 'package:flutter/material.dart';

import '../../core/theme/miro_tokens.dart';

/// Dasar semua elemen yang bisa ditekan (COMPONENTS §3.1, DESIGN_SYSTEM §4).
///
/// Menggambar "lip": lapisan padat berwarna [lipColor] setinggi [lip] di
/// bawah permukaan. Saat ditekan, permukaan turun setinggi lip dan lip
/// tertutup (80 ms). Tinggi total = tinggi konten + [lip], sehingga layout
/// tidak melompat saat ditekan. Tanpa efek riak dan tanpa bayangan blur.
///
/// Juga menangani kontrak interaktif: semantik tombol, fokus keyboard dengan
/// ring 3px `sky500`, aktivasi Enter/Spasi, dan state nonaktif.
class MiroPressable extends StatefulWidget {
  const MiroPressable({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    required this.lipColor,
    this.lip = MiroLip.button,
    this.radius = MiroRadius.lg,
    this.border,
    this.padding = EdgeInsets.zero,
    this.semanticsLabel,
    this.selected,
    this.enabled = true,
    this.excludeChildSemantics = false,
    this.circle = false,
  });

  final Widget child;

  /// `null` = tidak bisa diketuk (tetap tampil dengan lip).
  final VoidCallback? onTap;
  final Color color;
  final Color lipColor;
  final double lip;
  final double radius;
  final BoxBorder? border;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabel;

  /// Untuk pilihan (radio/checkbox): diumumkan ke pembaca layar.
  final bool? selected;
  final bool enabled;
  final bool excludeChildSemantics;

  /// Bentuk lingkaran (tombol ikon, tombol stepper).
  final bool circle;

  @override
  State<MiroPressable> createState() => _MiroPressableState();
}

class _MiroPressableState extends State<MiroPressable> {
  bool _pressed = false;
  bool _focused = false;

  bool get _active => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (!_active || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _activate() {
    if (!_active) return;
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final shape = widget.circle ? null : BorderRadius.circular(widget.radius);
    final boxShape = widget.circle ? BoxShape.circle : BoxShape.rectangle;
    final offset = _pressed ? widget.lip : 0.0;

    final face = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: shape,
        shape: boxShape,
        border: widget.border,
      ),
      child: widget.child,
    );

    final body = Padding(
      padding: EdgeInsets.only(bottom: widget.lip),
      child: Stack(
        // Permukaan menerima batasan induk apa adanya (lebar penuh di footer,
        // tinggi sel di grid), sama seperti lapisan lip di bawahnya.
        fit: StackFit.passthrough,
        clipBehavior: Clip.none,
        children: [
          // Lip: bentuk yang sama, digeser ke bawah setinggi lip.
          Positioned(
            left: 0,
            right: 0,
            top: widget.lip,
            bottom: -widget.lip,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.lipColor,
                borderRadius: shape,
                shape: boxShape,
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(end: offset),
            duration: MiroMotion.instant,
            curve: Curves.easeOut,
            builder: (context, dy, child) =>
                Transform.translate(offset: Offset(0, dy), child: child),
            child: face,
          ),
        ],
      ),
    );

    // Ring fokus 3px sky500, offset 2px (COMPONENTS §3).
    final ringed = _focused
        ? Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: boxShape,
              borderRadius: widget.circle
                  ? null
                  : BorderRadius.circular(widget.radius + 4),
              border: Border.all(color: MiroColors.sky500, width: 3),
            ),
            child: body,
          )
        : body;

    return Semantics(
      // Tombol nonaktif tetap diumumkan sebagai tombol (nonaktif); kartu
      // statis (tanpa onTap, tidak dinonaktifkan) bukan tombol.
      button:
          widget.selected == null && (widget.onTap != null || !widget.enabled),
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.selected != null ? true : null,
      enabled: _active,
      label: widget.semanticsLabel,
      excludeSemantics: widget.excludeChildSemantics,
      onTap: _active ? _activate : null,
      child: FocusableActionDetector(
        enabled: _active,
        mouseCursor:
            _active ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _active ? _activate : null,
          child: ringed,
        ),
      ),
    );
  }
}
