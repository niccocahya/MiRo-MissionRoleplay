import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/miro_tokens.dart';

/// Grup daftar (HANDOFF 37): judul kecil di atas, kartu putih radius 20
/// berlip 3, baris dipisah garis 2px `divider`.
class MiroListGroup extends StatelessWidget {
  const MiroListGroup({super.key, required this.children, this.title});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Container(height: 2, color: MiroColors.divider));
      }
      rows.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: MiroSpace.x1, bottom: 6),
            child: Semantics(
              header: true,
              child: Text(title!, style: MiroText.label),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: MiroColors.surface,
            borderRadius: BorderRadius.circular(MiroRadius.xl),
            border: Border.all(color: MiroColors.line, width: 2),
            boxShadow: const [
              BoxShadow(
                color: MiroColors.line,
                offset: Offset(0, MiroLip.card),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        ),
      ],
    );
  }
}

/// Warna wadah ikon baris.
enum MiroListTone { amber, sky, green, coral, teacher, navy, red }

/// Satu baris di [MiroListGroup]: ikon 36 di kotak radius 11 berwarna
/// lembut, judul 15/800, keterangan 12/700, lalu [trailing] (switch, nilai,
/// atau chevron otomatis jika [onTap] diisi).
class MiroListRow extends StatelessWidget {
  const MiroListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.tone = MiroListTone.sky,
    this.trailing,
    this.value,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final MiroListTone tone;
  final Widget? trailing;

  /// Nilai di kanan ("15 menit") sebelum chevron.
  final String? value;
  final VoidCallback? onTap;

  /// Judul merah (aksi bahaya, mis. "Hapus akun keluarga").
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final (soft, ink) = switch (tone) {
      MiroListTone.amber => (MiroColors.amber75, MiroColors.amber700),
      MiroListTone.sky => (MiroColors.sky50, MiroColors.sky700),
      MiroListTone.green => (MiroColors.green50, MiroColors.green700),
      MiroListTone.coral => (MiroColors.coral100, MiroColors.coral700),
      MiroListTone.teacher => (MiroColors.teacherLine, MiroColors.navy700),
      MiroListTone.navy => (MiroColors.navy100, MiroColors.navy700),
      MiroListTone.red => (MiroColors.red50, MiroColors.red700),
    };

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(MiroRadius.md - 1),
                ),
                child: Icon(icon, size: 20, color: ink),
              ),
              const SizedBox(width: MiroSpace.x3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: MiroText.bodyStrong.copyWith(
                      color: danger ? MiroColors.red700 : MiroColors.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: MiroText.small,
                    ),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: MiroSpace.x2),
              Text(value!, style: MiroText.label),
            ],
            if (trailing != null) ...[
              const SizedBox(width: MiroSpace.x2),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: MiroSpace.x1),
              Icon(
                PhosphorIcons.caretRight(PhosphorIconsStyle.bold),
                size: 18,
                color: MiroColors.ink3,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return row;
    return Semantics(
      button: true,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
