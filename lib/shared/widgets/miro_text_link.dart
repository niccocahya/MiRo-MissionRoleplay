import 'package:flutter/material.dart';

import '../../core/theme/miro_tokens.dart';

enum MiroTextLinkTone { coral, sky, danger, ink }

/// Tautan aksi berbentuk teks ("Lupa kata sandi?", "Nanti saja").
/// Area sentuh minimal 44 (COMPONENTS §5.1).
class MiroTextLink extends StatelessWidget {
  const MiroTextLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = MiroTextLinkTone.coral,
    this.icon,
    this.textAlign = TextAlign.center,
  });

  final String label;
  final VoidCallback? onPressed;
  final MiroTextLinkTone tone;
  final IconData? icon;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      MiroTextLinkTone.coral => MiroColors.link,
      MiroTextLinkTone.sky => MiroColors.sky700,
      MiroTextLinkTone.danger => MiroColors.red700,
      MiroTextLinkTone.ink => MiroColors.navy700,
    };
    final style = MiroText.bodyStrong.copyWith(
      color: onPressed == null ? MiroColors.inkDisabled : color,
      fontWeight: FontWeight.w900,
    );
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(MiroRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: MiroSize.touch),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: MiroSpace.x1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: style.color),
                  const SizedBox(width: MiroSpace.x2),
                ],
                Flexible(
                  child: Text(label, style: style, textAlign: textAlign),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
