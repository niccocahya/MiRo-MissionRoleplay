import 'package:flutter/material.dart';

import '../../core/theme/miro_tokens.dart';
import 'miro_pressable.dart';

/// Chip yang bisa dipilih (DESIGN_SYSTEM §7.4): usia, filter memori, rentang
/// usia kelas. Tinggi 36 (atau 32), radius penuh, lip 2. Terpilih: navy
/// dengan teks putih. Selalu dipakai di dalam `Wrap` agar tidak terpotong.
class MiroChip extends StatelessWidget {
  const MiroChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.small = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Avatar/ikon kecil di kiri (mis. avatar anak di filter Memori 09).
  final Widget? leading;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final height = small ? 32.0 : 36.0;
    return MiroPressable(
      onTap: onTap,
      selected: selected,
      semanticsLabel: label,
      excludeChildSemantics: true,
      color: selected ? MiroColors.navy900 : MiroColors.surface,
      lipColor: selected ? MiroColors.navy950 : MiroColors.line,
      lip: MiroLip.iconButton,
      radius: MiroRadius.pill,
      border: selected ? null : Border.all(color: MiroColors.line, width: 2),
      padding: EdgeInsets.fromLTRB(
        leading != null ? MiroSpace.x1 : 14,
        0,
        14,
        0,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height - 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: MiroSpace.x2),
            ],
            Flexible(
              child: Text(
                label,
                style: MiroText.bodyStrong.copyWith(
                  fontWeight: FontWeight.w900,
                  color: selected ? MiroColors.white : MiroColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Warna label kecil non-interaktif.
enum MiroPillTone { amber, sky, green, coral, navy, white, teacher }

/// Label kecil non-interaktif tanpa lip ("Misi pertama", "Rekor 21",
/// tingkat lencana, chip durasi). Bukan tombol (DESIGN_SYSTEM §0 D1).
class MiroPill extends StatelessWidget {
  const MiroPill({
    super.key,
    required this.label,
    this.tone = MiroPillTone.white,
    this.icon,
    this.role,
  });

  final String label;
  final MiroPillTone tone;
  final IconData? icon;

  /// Jika diisi, teks memakai warna lip peran di latar putih ("Koki").
  final MiroRole? role;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = role != null
        ? (MiroColors.white, role!.lip)
        : switch (tone) {
            MiroPillTone.amber => (MiroColors.amber100, MiroColors.amber800),
            MiroPillTone.sky => (MiroColors.sky50, MiroColors.sky700),
            MiroPillTone.green => (MiroColors.green100, MiroColors.green700),
            MiroPillTone.coral => (MiroColors.coral100, MiroColors.coral700),
            MiroPillTone.navy => (MiroColors.navy800, MiroColors.sky300),
            MiroPillTone.white => (MiroColors.white, MiroColors.ink),
            MiroPillTone.teacher => (
                MiroColors.teacherLine,
                MiroColors.navy900,
              ),
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MiroRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: MiroSpace.x1),
          ],
          Flexible(
            child: Text(
              label,
              style: MiroText.small.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
