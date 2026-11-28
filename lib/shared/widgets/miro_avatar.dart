import 'package:flutter/material.dart';

import '../../core/theme/miro_tokens.dart';

/// Warna latar avatar anak (6 warna, mockup 16; DECISIONS C13). Avatar
/// pinguin bayi belum ada; sementara memakai `maro-peek` di lingkaran warna
/// (DECISIONS §E, docs/ASSET_TODO.md).
const kAvatarColors = <Color>[
  MiroColors.sky100,
  MiroColors.coral100,
  MiroColors.green50,
  MiroColors.amber100,
  MiroColors.teacherLine,
  MiroColors.navy100,
];

/// Avatar bulat (COMPONENTS §5.1). Tiga bentuk, dipilih otomatis:
/// - [image] diisi: foto (unggahan) dipotong lingkaran;
/// - [initial] diisi: huruf di lingkaran warna (avatar akun);
/// - selain itu: pinguin `maro-peek` di lingkaran [background].
class MiroAvatar extends StatelessWidget {
  const MiroAvatar({
    super.key,
    this.size = 44,
    this.background = MiroColors.sky100,
    this.image,
    this.initial,
    this.initialColor = MiroColors.coral700,
    this.ring,
    this.border = false,
    this.semanticsLabel,
  });

  final double size;
  final Color background;
  final ImageProvider? image;
  final String? initial;
  final Color initialColor;

  /// Cincin luar (mis. 4px coral saat terpilih di Pilih peserta 03).
  final Color? ring;

  /// Border putih 2px (avatar bertumpuk).
  final bool border;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final Widget content;
    if (image != null) {
      content = Image(
        image: image!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _peek(dpr),
      );
    } else if (initial != null && initial!.isNotEmpty) {
      content = Center(
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.2,
          child: Text(
            initial!.characters.first.toUpperCase(),
            style: MiroText.h3.copyWith(
              color: initialColor,
              fontSize: size * 0.42,
              height: 1,
            ),
          ),
        ),
      );
    } else {
      content = _peek(dpr);
    }

    Widget circle = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: border ? Border.all(color: MiroColors.white, width: 2) : null,
      ),
      child: content,
    );

    if (ring != null) {
      circle = Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ring!, width: 3),
        ),
        child: circle,
      );
    }

    return Semantics(
      image: semanticsLabel != null,
      label: semanticsLabel,
      excludeSemantics: true,
      child: circle,
    );
  }

  /// Crop kepala pinguin: rata atas + padding atas 16% (COMPONENTS §5.1).
  Widget _peek(double dpr) => Padding(
        padding: EdgeInsets.only(top: size * 0.16),
        child: Image.asset(
          'assets/mascot/maro-peek.webp',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          cacheWidth: (size * dpr).round(),
        ),
      );
}

/// Avatar bertumpuk (03, 05, 34, 38). Tiap avatar diberi border putih.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.avatars,
    this.size = 28,
    this.overlap = 8,
    this.max = 4,
    this.semanticsLabel,
  });

  /// Avatar yang sudah jadi (biasanya [MiroAvatar] dengan `border: true`).
  final List<Widget> avatars;
  final double size;
  final double overlap;
  final int max;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final shown = avatars.take(max).toList();
    final extra = avatars.length - shown.length;
    final items = <Widget>[
      ...shown.map((a) => SizedBox.square(dimension: size, child: a)),
      if (extra > 0)
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MiroColors.navy100,
            shape: BoxShape.circle,
            border: Border.all(color: MiroColors.white, width: 2),
          ),
          child: Text('+$extra', style: MiroText.small),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    final step = size - overlap;
    return Semantics(
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: SizedBox(
        width: size + step * (items.length - 1),
        height: size,
        child: Stack(
          children: [
            for (var i = 0; i < items.length; i++)
              Positioned(left: step * i, top: 0, child: items[i]),
          ],
        ),
      ),
    );
  }
}
