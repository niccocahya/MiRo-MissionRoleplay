import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/miro_tokens.dart';
import 'miro_pressable.dart';
import 'motion/miro_motion.dart';

/// Saklar 48×28 (HANDOFF 37): aktif `green600`, knob putih 22.
/// Seluruh baris yang memakai [MiroSwitch] sebaiknya bisa diketuk; switch ini
/// sendiri punya area sentuh 48×44.
class MiroSwitch extends StatelessWidget {
  const MiroSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.activeColor = MiroColors.green600,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Label untuk pembaca layar jika switch berdiri sendiri.
  final String? label;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: 48,
          height: MiroSize.touch,
          child: Center(
            child: AnimatedContainer(
              duration: MiroMotion.base,
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: !enabled
                    ? MiroColors.navy100
                    : value
                        ? activeColor
                        : MiroColors.line,
                borderRadius: BorderRadius.circular(MiroRadius.pill),
              ),
              child: AnimatedAlign(
                duration: MiroMotion.base,
                curve: MiroMotion.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: MiroColors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kontrol segmen (HANDOFF 15): wadah `navy100` radius 14, tab aktif putih
/// radius 10 dengan lip 2, tinggi tab 40.
class MiroSegmented<T> extends StatelessWidget {
  const MiroSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  /// Pasangan nilai dan label, berurutan.
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MiroSpace.x1),
      decoration: BoxDecoration(
        color: MiroColors.navy100,
        borderRadius: BorderRadius.circular(MiroRadius.segmented),
      ),
      child: Row(
        children: [
          for (final (v, label) in options)
            Expanded(
              child: Semantics(
                selected: v == value,
                button: true,
                label: label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: MiroMotion.fast,
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: MiroSpace.x2,
                      vertical: MiroSpace.x1,
                    ),
                    decoration: BoxDecoration(
                      color: v == value ? MiroColors.white : null,
                      borderRadius:
                          BorderRadius.circular(MiroRadius.segmentedTab),
                      boxShadow: v == value
                          ? const [
                              BoxShadow(
                                color: MiroColors.line,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: MiroText.bodyStrong.copyWith(
                        fontWeight: FontWeight.w900,
                        color: v == value ? MiroColors.ink : MiroColors.ink3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stepper angka (HANDOFF 13): tombol −/+ bulat ber-lip, angka besar di
/// tengah yang muncul dengan pop setiap berubah, diumumkan ke pembaca layar.
/// [compact] = tombol 40 dan angka 17 (baris jumlah kelompok, usia di 39).
class MiroStepper extends ConsumerWidget {
  const MiroStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    this.caption,
    this.compact = false,
    this.decrementLabel = '−',
    this.incrementLabel = '+',
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  /// Teks kecil di bawah angka ("dari 24 siswa").
  final String? caption;
  final bool compact;

  /// Label pembaca layar ("Kurangi siswa", "Tambah siswa").
  final String decrementLabel;
  final String incrementLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final button = compact ? 40.0 : 52.0;
    final number = compact
        ? MiroText.title
        : MiroText.h1.copyWith(fontSize: 44, height: 48 / 44);

    Widget step(IconData icon, String label, int next, bool enabled) =>
        MiroPressable(
          onTap: enabled ? () => onChanged(next) : null,
          enabled: enabled,
          circle: true,
          lip: compact ? MiroLip.iconButton : MiroLip.card,
          color: MiroColors.surface,
          lipColor: MiroColors.line,
          border: Border.all(color: MiroColors.line, width: 2),
          semanticsLabel: label,
          excludeChildSemantics: true,
          child: SizedBox.square(
            dimension: button - 4,
            child: Icon(
              icon,
              size: compact ? 20 : 24,
              color: enabled ? MiroColors.ink : MiroColors.inkDisabled,
            ),
          ),
        );

    final display = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Angka besar boleh dibatasi skala teksnya (RESPONSIVE §4).
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.5,
          child: MiroPopIn(
            key: ValueKey(value),
            child: Text(
              '$value',
              style: number.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        if (caption != null)
          Text(
            caption!,
            style: MiroText.label.copyWith(color: MiroColors.ink2),
          ),
      ],
    );

    return Semantics(
      liveRegion: true,
      value: '$value',
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          step(
            PhosphorIcons.minus(PhosphorIconsStyle.bold),
            decrementLabel,
            value - 1,
            value > min,
          ),
          if (compact)
            SizedBox(width: MiroSpace.x10, child: Center(child: display))
          else
            Expanded(child: Center(child: display)),
          step(
            PhosphorIcons.plus(PhosphorIconsStyle.bold),
            incrementLabel,
            value + 1,
            value < max,
          ),
        ],
      ),
    );
  }
}
