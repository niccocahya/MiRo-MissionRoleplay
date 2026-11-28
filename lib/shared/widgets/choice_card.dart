import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/miro_tokens.dart';
import 'miro_pressable.dart';
import 'motion/miro_motion.dart';

enum ChoiceCardLayout {
  /// Petak vertikal di grid 2 kolom: ikon di atas, label di bawah (24, 26).
  grid,

  /// Baris horizontal: ikon kiri, judul + keterangan (01, 17, 23, 25).
  list,
}

/// Kartu pilihan (DESIGN_SYSTEM §7.3, HANDOFF 01/24/25).
///
/// Terpilih: latar krem, border dan lip coral, ikon wadah berganti solid
/// dengan pop, centang hijau muncul. Ubah [shakeSignal] (mis. +1) untuk
/// menggoyang kartu saat batas pilihan tercapai (M3).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.layout = ChoiceCardLayout.list,
    this.color = MiroColors.coral500,
    this.softColor = MiroColors.coral100,
    this.tileSize,
    this.footer,
    this.multi = false,
    this.shakeSignal = 0,
    this.leading,
  });

  final String title;
  final String? subtitle;

  /// Ikon di dalam wadah bulat. Diabaikan jika [leading] diisi.
  final IconData? icon;

  /// Pengganti wadah ikon (mis. kotak kode bahasa "ID" di layar 23).
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;
  final ChoiceCardLayout layout;

  /// Warna ikon (tidak terpilih) dan latar wadah (terpilih).
  final Color color;

  /// Latar wadah saat tidak terpilih.
  final Color softColor;

  /// Default 56 (grid) atau 48 (list).
  final double? tileSize;

  /// Isi tambahan di bawah garis pemisah (contoh di kartu tipe akun 01).
  final Widget? footer;

  /// Pilihan ganda: semantik checkbox, bukan radio.
  final bool multi;
  final int shakeSignal;

  @override
  Widget build(BuildContext context) {
    final size = tileSize ?? (layout == ChoiceCardLayout.grid ? 56.0 : 48.0);
    final tile = leading ??
        _IconTile(
          icon: icon,
          size: size,
          selected: selected,
          color: color,
          softColor: softColor,
        );

    final text = Column(
      crossAxisAlignment: layout == ChoiceCardLayout.grid
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: layout == ChoiceCardLayout.grid
              ? MiroText.bodyStrong.copyWith(fontWeight: FontWeight.w900)
              : MiroText.title,
          textAlign: layout == ChoiceCardLayout.grid
              ? TextAlign.center
              : TextAlign.start,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: layout == ChoiceCardLayout.grid
                ? MiroText.small.copyWith(color: MiroColors.ink2)
                : MiroText.caption,
            textAlign: layout == ChoiceCardLayout.grid
                ? TextAlign.center
                : TextAlign.start,
          ),
      ],
    );

    final body = layout == ChoiceCardLayout.grid
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [tile, const SizedBox(height: MiroSpace.x2), text],
          )
        : Row(
            children: [
              tile,
              const SizedBox(width: 14),
              Expanded(child: text),
              // Ruang untuk centang di pojok agar teks tidak tertimpa.
              const SizedBox(width: MiroSpace.x5),
            ],
          );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        if (footer != null) ...[
          const SizedBox(height: MiroSpace.x3),
          Container(
            height: 2,
            color: selected ? MiroColors.amber300 : MiroColors.navy100,
          ),
          const SizedBox(height: MiroSpace.x3),
          footer!,
        ],
      ],
    );

    return MiroShake(
      signal: shakeSignal,
      child: MiroPressable(
        onTap: onTap,
        selected: multi ? null : selected,
        semanticsLabel: subtitle == null ? title : '$title. $subtitle',
        excludeChildSemantics: true,
        color: selected ? MiroColors.selected : MiroColors.surface,
        lipColor: selected ? MiroColors.coral500 : MiroColors.line,
        lip: MiroLip.button,
        radius: MiroRadius.xl,
        border: Border.all(
          color: selected ? MiroColors.coral500 : MiroColors.line,
          width: 2,
        ),
        padding: layout == ChoiceCardLayout.grid
            ? const EdgeInsets.fromLTRB(
                MiroSpace.x2,
                MiroSpace.x4,
                MiroSpace.x2,
                14,
              )
            : const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: MiroSpace.x3,
              ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            content,
            Positioned(
              top: layout == ChoiceCardLayout.grid
                  ? -MiroSpace.x2
                  : -MiroSpace.x1,
              right: layout == ChoiceCardLayout.grid ? 0 : -MiroSpace.x1,
              child: _Check(visible: selected),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.size,
    required this.selected,
    required this.color,
    required this.softColor,
  });

  final IconData? icon;
  final double size;
  final bool selected;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.06 : 1,
      duration: MiroMotion.base,
      curve: MiroMotion.easePop,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? color : softColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: size * 0.55,
          color: selected ? MiroColors.white : color,
        ),
      ),
    );
  }
}

/// Centang hijau yang muncul dengan pop (M2).
class _Check extends StatelessWidget {
  const _Check({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1 : 0,
      duration: MiroMotion.base,
      curve: MiroMotion.easePop,
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: MiroColors.green500,
          shape: BoxShape.circle,
        ),
        child: Icon(
          PhosphorIcons.check(PhosphorIconsStyle.bold),
          size: 14,
          color: MiroColors.white,
        ),
      ),
    );
  }
}
