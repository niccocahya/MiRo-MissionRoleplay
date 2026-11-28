import 'package:flutter/material.dart';

import '../../core/theme/miro_tokens.dart';
import 'miro_pressable.dart';

enum MiroCardVariant {
  /// Putih, border garis (default).
  surface,

  /// Latar `navy100` (kartu nonaktif, kotak info).
  muted,

  /// Kartu terpilih: krem + border coral.
  selected,

  /// Latar `-soft` peran + border/lip warna peran (kartu misi aktif).
  tinted,

  /// Krem dengan lip krem gelap (Profil 06 "jam main bersama").
  cream,

  /// Navy dengan lip navy gelap (kartu streak, kode undangan).
  navy,
}

/// Kartu MiRO (DESIGN_SYSTEM §7.8, DECISIONS C8: lip kartu 3). Jika [onTap]
/// diisi, kartu bisa ditekan dengan efek lip. Kartu info statis tetap
/// punya lip tipis sesuai mockup, tetapi tidak turun saat disentuh.
class MiroCard extends StatelessWidget {
  const MiroCard({
    super.key,
    required this.child,
    this.variant = MiroCardVariant.surface,
    this.role,
    this.onTap,
    this.padding = const EdgeInsets.all(MiroSpace.x4),
    this.radius = MiroRadius.xl,
    this.lip = MiroLip.card,
    this.semanticsLabel,
  }) : assert(
          variant != MiroCardVariant.tinted || role != null,
          'Kartu tinted butuh role',
        );

  final Widget child;
  final MiroCardVariant variant;
  final MiroRole? role;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// 3 untuk kartu biasa, [MiroLip.hero] (6) untuk kartu besar, 0 tanpa lip.
  final double lip;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final (face, edge, border) = switch (variant) {
      MiroCardVariant.surface => (
          MiroColors.surface,
          MiroColors.line,
          MiroColors.line,
        ),
      MiroCardVariant.muted => (
          MiroColors.surfaceMuted,
          MiroColors.line,
          null,
        ),
      MiroCardVariant.selected => (
          MiroColors.selected,
          MiroColors.coral500,
          MiroColors.coral500,
        ),
      MiroCardVariant.tinted => (role!.soft, role!.lip, role!.base),
      MiroCardVariant.cream => (
          MiroColors.cream200,
          MiroColors.cream300,
          null,
        ),
      MiroCardVariant.navy => (
          MiroColors.navy900,
          MiroColors.navy950,
          null,
        ),
    };

    return MiroPressable(
      onTap: onTap,
      color: face,
      lipColor: edge,
      lip: lip,
      radius: radius,
      padding: padding,
      border: border == null ? null : Border.all(color: border, width: 2),
      semanticsLabel: semanticsLabel,
      child: child,
    );
  }
}
