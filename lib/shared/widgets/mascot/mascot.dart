import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/app_info.dart';
import '../../../core/theme/miro_tokens.dart';
import '../../icons/game_icons.dart';
import '../motion/miro_motion.dart';

/// Pose maskot Mink (DECISIONS §F1: nama widget netral `Mascot`, file aset
/// tetap `maro-*.webp`). Pose yang belum ada asetnya memakai pengganti
/// sementara (DECISIONS §E, docs/ASSET_TODO.md).
enum MascotPose {
  main('maro-main'),
  wave('maro-wave'),
  peek('maro-peek'),
  cooking('maro-cooking'),
  doctorWin('maro-doctor-win'),
  chefWin('maro-chef-win'),
  artistWin('maro-artist-win'),
  teacherWin('maro-teacher-win'),
  athleteWin('maro-athlete-win'),

  /// Sedih/bingung (33, 45): sementara `maro-main` dengan saturasi 0.75.
  sad('maro-main'),

  /// Berpikir (empty state): sementara `maro-main`.
  thinking('maro-main');

  const MascotPose(this.file);
  final String file;

  String get asset => 'assets/mascot/$file.webp';

  /// Pose menang per peran (layar 05, kartu misi aktif).
  static MascotPose winFor(MiroRole role) => switch (role) {
        MiroRole.doctor => doctorWin,
        MiroRole.chef => chefWin,
        MiroRole.artist => artistWin,
        MiroRole.teacher => teacherWin,
        MiroRole.athlete => athleteWin,
      };
}

/// Gambar maskot (COMPONENTS §5.3). Ukuran tetap + `BoxFit.contain`, tidak
/// pernah melar (RESPONSIVE §9). Di layar pendek (tinggi < 700) tinggi
/// dibatasi ±22% tinggi layar (RESPONSIVE §3). [float] memakai `MiroFloat`.
class MascotImage extends StatelessWidget {
  const MascotImage({
    super.key,
    required this.pose,
    required this.height,
    this.width,
    this.float = false,
    this.semanticsLabel,
    this.alignment = Alignment.bottomCenter,
  });

  final MascotPose pose;
  final double height;
  final double? width;
  final bool float;

  /// `null` = dekoratif (tidak dibacakan).
  final String? semanticsLabel;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final h = screen.height < 700
        ? height.clamp(0, screen.height * 0.22).toDouble()
        : height;
    final w = width == null ? null : width! * h / height;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    Widget image = Image.asset(
      pose.asset,
      height: h,
      width: w,
      fit: BoxFit.contain,
      alignment: alignment,
      cacheHeight: (h * dpr).round(),
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );

    if (pose == MascotPose.sad) {
      image = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_saturation75),
        child: image,
      );
    }
    if (float) image = MiroFloat(child: image);

    return Semantics(
      image: semanticsLabel != null,
      label: semanticsLabel,
      excludeSemantics: true,
      child: image,
    );
  }

  /// Matriks saturasi 0.75 (DECISIONS §E: pose sedih sementara).
  static const _saturation75 = <double>[
    0.8034, 0.1788, 0.0178, 0, 0, //
    0.0534, 0.9288, 0.0178, 0, 0, //
    0.0534, 0.1788, 0.7678, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

/// Balon bicara maskot (DESIGN_SYSTEM §6.2, HANDOFF 01): putih, border 2,
/// radius 20, ekor segitiga ke arah maskot, teks 17/800. Muncul dengan pop.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text, this.tailBottom = 18});

  final String text;

  /// Jarak ekor dari bawah balon.
  final double tailBottom;

  @override
  Widget build(BuildContext context) {
    return MiroPopIn(
      alignment: Alignment.bottomLeft,
      delay: MiroMotion.fast,
      child: Semantics(
        liveRegion: true,
        label: '$kMascotName: $text',
        excludeSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MiroSpace.x4,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: MiroColors.surface,
                border: Border.all(color: MiroColors.line, width: 2),
                borderRadius: BorderRadius.circular(MiroRadius.xl),
              ),
              child: Text(
                text,
                style: MiroText.title.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            // Ekor: kotak 16 diputar 45°, hanya sisi kiri dan bawah ber-border.
            Positioned(
              left: -9,
              bottom: tailBottom,
              child: Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: MiroColors.surface,
                    border: Border(
                      left: BorderSide(color: MiroColors.line, width: 2),
                      bottom: BorderSide(color: MiroColors.line, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak tips (HANDOFF 04, 07): latar `sky50`, ikon balon bicara + hati di
/// kotak putih 32 ber-border `sky300`, judul + isi. [collapsible] menambah
/// tombol lipat 48px (default terbuka di langkah pertama).
class MascotTip extends StatefulWidget {
  const MascotTip({
    super.key,
    required this.title,
    required this.body,
    this.collapsible = false,
    this.initiallyOpen = true,
  });

  final String title;
  final String body;
  final bool collapsible;
  final bool initiallyOpen;

  @override
  State<MascotTip> createState() => _MascotTipState();
}

class _MascotTipState extends State<MascotTip> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final header = Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: MiroColors.surface,
            borderRadius: BorderRadius.circular(MiroRadius.sm + 2),
            border: Border.all(color: MiroColors.sky300, width: 2),
          ),
          child: const Center(child: TipIcon()),
        ),
        const SizedBox(width: MiroSpace.x3),
        Expanded(child: Text(widget.title, style: MiroText.title)),
        if (widget.collapsible)
          AnimatedRotation(
            turns: _open ? 0.5 : 0,
            duration: MiroMotion.base,
            child: Icon(
              PhosphorIcons.caretDown(PhosphorIconsStyle.bold),
              size: 22,
              color: MiroColors.ink,
            ),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MiroColors.sky50,
        borderRadius: BorderRadius.circular(MiroRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.collapsible)
            Semantics(
              button: true,
              expanded: _open,
              child: InkWell(
                onTap: () => setState(() => _open = !_open),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: MiroSize.touch),
                  child: header,
                ),
              ),
            )
          else
            header,
          // Hanya fade (ANIMATION §3: tinggi tidak dianimasikan).
          AnimatedSwitcher(
            duration: MiroMotion.fast,
            child: _open
                ? Padding(
                    key: const ValueKey('open'),
                    padding: const EdgeInsets.only(
                      left: 44,
                      top: MiroSpace.x2,
                    ),
                    child: Text(widget.body, style: MiroText.body),
                  )
                : const SizedBox(
                    key: ValueKey('closed'),
                    width: double.infinity,
                  ),
          ),
        ],
      ),
    );
  }
}
