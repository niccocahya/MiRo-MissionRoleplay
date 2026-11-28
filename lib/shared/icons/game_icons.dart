import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Ikon game kustom (COMPONENTS §5.4, DESIGN_SYSTEM §5.1 lapis C).
//
// Path SVG disalin persis dari mockup (design/source/*.html). Warna
// ilustrasi boleh hex di folder ini (CLAUDE.md aturan 1, pengecualian).
// Semua ikon `aria-hidden`: beri label lewat widget pembungkus bila ikon
// berdiri sendiri tanpa teks.

/// Keadaan kristal streak (DESIGN_SYSTEM §7.12, HANDOFF 45).
enum CrystalState {
  /// Hari tercapai: kristal biru penuh dengan faset.
  done,

  /// Kristal besar di kartu streak, dengan kilau putih.
  hero,

  /// Belum: kristal `navy700` redup (di atas kartu navy).
  future,

  /// Hari terlewat tanpa pembeku (layar 45).
  missed,

  /// Kristal retak (layar 45).
  broken,
}

/// Kristal es streak (bukan api).
class StreakCrystal extends StatelessWidget {
  const StreakCrystal({
    super.key,
    this.size = 24,
    this.state = CrystalState.done,
  });

  final double size;
  final CrystalState state;

  static const _done =
      '<svg viewBox="0 0 24 24"><path d="M12 2 20 8 17 21H7L4 8Z" fill="#6FA6D6"/><path d="M12 2 20 8 12 11 4 8Z" fill="#A5CBEB"/><path d="M12 11 17 21H7Z" fill="#3D7FB8"/></svg>';
  static const _hero =
      '<svg viewBox="0 0 24 24"><path d="M12 2 20 8 17 21H7L4 8Z" fill="#8BBCE6"/><path d="M12 2 20 8 12 11 4 8Z" fill="#D3E3F2"/><path d="M12 11 17 21H7Z" fill="#6FA6D6"/><path d="M8 7.5 10.5 5.5" stroke="#fff" stroke-width="1.8" stroke-linecap="round"/></svg>';
  static const _future =
      '<svg viewBox="0 0 24 24"><path d="M12 2 20 8 17 21H7L4 8Z" fill="#1E467A"/></svg>';
  static const _missed =
      '<svg viewBox="0 0 24 24"><path d="M12 2 20 8 17 21H7L4 8Z" fill="#3B4E6B"/></svg>';
  static const _broken =
      '<svg viewBox="0 0 24 24"><path d="M12 2 20 8 17 21H7L4 8Z" fill="#3B4E6B"/><path d="M12 2 10 9l3 3-2 9" stroke="#0A264F" stroke-width="1.6" fill="none"/></svg>';

  @override
  Widget build(BuildContext context) {
    final svg = switch (state) {
      CrystalState.done => _done,
      CrystalState.hero => _hero,
      CrystalState.future => _future,
      CrystalState.missed => _missed,
      CrystalState.broken => _broken,
    };
    return SvgPicture.string(svg, width: size, height: size);
  }
}

/// Ikan oranye, mata uang dalam aplikasi (HANDOFF 02).
class FishIcon extends StatelessWidget {
  const FishIcon({super.key, this.size = 24});

  final double size;

  static const _svg =
      '<svg viewBox="0 0 26 24"><path d="M3 12c3-6 11-7 16-3l5-4v14l-5-4c-5 4-13 3-16-3Z" fill="#F1A22F"/><circle cx="8" cy="10.5" r="1.6" fill="#0A264F"/><path d="M6 8c1.5-1.6 3.5-2.4 5.5-2.4" stroke="#fff" stroke-width="1.6" stroke-linecap="round" fill="none"/></svg>';

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_svg, width: size * 26 / 24, height: size);
}

/// Peti hadiah harian (HANDOFF 10), tertutup atau terbuka.
class ChestIcon extends StatelessWidget {
  const ChestIcon({super.key, this.width = 84, this.open = false});

  final double width;
  final bool open;

  static const _closed =
      '<svg viewBox="0 0 84 72"><rect x="8" y="30" width="68" height="36" rx="8" fill="#C67B0D"/><rect x="8" y="30" width="68" height="10" fill="#A86A0A"/><path d="M8 34a34 22 0 0 1 68 0Z" fill="#F1A22F"/><path d="M16 26a26 14 0 0 1 20-10" stroke="#FFE8B6" stroke-width="4" stroke-linecap="round" fill="none"/><rect x="35" y="28" width="14" height="18" rx="4" fill="#FFE8B6"/><circle cx="42" cy="37" r="3" fill="#8A5608"/></svg>';
  static const _open =
      '<svg viewBox="0 0 84 72"><path d="M10 26 18 4h48l8 22Z" fill="#F1A22F"/><rect x="8" y="30" width="68" height="36" rx="8" fill="#C67B0D"/><rect x="14" y="24" width="56" height="12" rx="4" fill="#8A5608"/><path d="M26 30c4-10 28-10 32 0" fill="#FFE8B6"/><circle cx="32" cy="22" r="3" fill="#FFFFFF"/><circle cx="52" cy="18" r="2.4" fill="#FFFFFF"/><circle cx="44" cy="12" r="2" fill="#FFFFFF"/></svg>';

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        open ? _open : _closed,
        width: width,
        height: width * 72 / 84,
      );
}

/// Mahkota level (HANDOFF 21).
class CrownIcon extends StatelessWidget {
  const CrownIcon({super.key, this.width = 88});

  final double width;

  static const _svg =
      '<svg viewBox="0 0 88 60"><path d="M6 50 2 14l22 16L44 4l20 26 22-16-4 36Z" fill="#F1A22F"/><path d="M6 50h76v8H6z" fill="#C67B0D"/><circle cx="44" cy="4" r="4" fill="#FFE8B6"/><circle cx="2" cy="14" r="3" fill="#FFE8B6"/><circle cx="86" cy="14" r="3" fill="#FFE8B6"/><path d="M14 40h60" stroke="#FFE8B6" stroke-width="3" stroke-linecap="round" opacity=".7"/></svg>';

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_svg, width: width, height: width * 60 / 88);
}

/// Ikon "Tips untuk Ayah/Bunda": balon bicara + hati (DESIGN_SYSTEM §5.4),
/// bukan bola lampu. Biasanya di kotak putih 32 ber-border `sky300`.
class TipIcon extends StatelessWidget {
  const TipIcon({super.key, this.size = 20});

  final double size;

  static const _svg =
      '<svg viewBox="0 0 24 24"><path d="M5 4.5h14a2.5 2.5 0 0 1 2.5 2.5v8a2.5 2.5 0 0 1-2.5 2.5h-6.5L8 21v-3.5H5A2.5 2.5 0 0 1 2.5 15V7A2.5 2.5 0 0 1 5 4.5Z" fill="none" stroke="#3D7FB8" stroke-width="2.2" stroke-linejoin="round"/><path d="M12 14.3 9.6 12a1.5 1.5 0 0 1 2.1-2.1l.3.3.3-.3a1.5 1.5 0 0 1 2.1 2.1Z" fill="#E57B65"/></svg>';

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(_svg, width: size, height: size);
}

/// Kepingan salju: Pembeku Streak (HANDOFF 10, 11).
class SnowflakeIcon extends StatelessWidget {
  const SnowflakeIcon({super.key, this.size = 16, this.color});

  final double size;

  /// Default `sky700`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final hex = _hex(color ?? const Color(0xFF3D7FB8));
    return SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="2.6" stroke-linecap="round"><path d="M12 2v20M4 7l16 10M20 7 4 17"/></svg>',
      width: size,
      height: size,
    );
  }
}

/// Panci: kegiatan "Memasak" di layar 24 (bukan di keahlian 26).
class PotIcon extends StatelessWidget {
  const PotIcon({super.key, this.size = 30, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = _hex(color);
    return SvgPicture.string(
      '<svg viewBox="0 0 24 24" fill="none" stroke="$hex" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M4 10h16v6a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4Z"/><path d="M2 10h20M9 6.5c0-1 .5-2 1.5-2M14 6.5c0-1 .5-2 1.5-2"/></svg>',
      width: size,
      height: size,
    );
  }
}

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
