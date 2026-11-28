import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/miro_tokens.dart';
import 'miro_pressable.dart';

/// Kartu pilih-satu dari daftar (anak 19, paket 38, kelas 52, target 17).
///
/// Slot [leading] (avatar/ikon) di kiri, judul + keterangan di tengah, dan
/// lingkaran radio di kanan (atau [trailing] kustom). Radius 20 (mockup 18; token terdekat), lip 3
/// sesuai mockup 19-GantiAnak.
class RadioCard extends StatelessWidget {
  const RadioCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  /// Pengganti lingkaran radio (mis. chip "Disarankan").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return MiroPressable(
      onTap: onTap,
      selected: selected,
      semanticsLabel: subtitle == null ? title : '$title. $subtitle',
      excludeChildSemantics: true,
      color: selected ? MiroColors.selected : MiroColors.surface,
      lipColor: selected ? MiroColors.coral500 : MiroColors.line,
      lip: MiroLip.card,
      radius: MiroRadius.xl,
      border: Border.all(
        color: selected ? MiroColors.coral500 : MiroColors.line,
        width: 2,
      ),
      padding: const EdgeInsets.fromLTRB(
        MiroSpace.x3 - 2,
        MiroSpace.x3 - 2,
        14,
        MiroSpace.x3 - 2,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MiroSize.touch),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: MiroSpace.x3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: MiroText.title),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: MiroText.caption,
                    ),
                ],
              ),
            ),
            const SizedBox(width: MiroSpace.x2),
            trailing ?? RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// Lingkaran radio 26px: kosong ber-border, atau hijau dengan centang.
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MiroMotion.fast,
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: selected ? MiroColors.green500 : MiroColors.surface,
        shape: BoxShape.circle,
        border: selected ? null : Border.all(color: MiroColors.line, width: 2),
      ),
      child: selected
          ? Icon(
              PhosphorIcons.check(PhosphorIconsStyle.bold),
              size: 16,
              color: MiroColors.white,
            )
          : null,
    );
  }
}
