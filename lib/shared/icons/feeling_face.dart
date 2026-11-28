import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lima wajah pinguin untuk skala perasaan (DESIGN_SYSTEM §5.5, HANDOFF 08),
/// pengganti emoji. Bentuk disalin persis dari `design/source/08-Refleksi.html`
/// (DECISIONS §E). Nilai 1 = kurang seru sampai 5 = luar biasa.
class FeelingFace extends StatelessWidget {
  const FeelingFace({super.key, required this.level, this.size = 48})
      : assert(level >= 1 && level <= 5);

  final int level;
  final double size;

  static const _head =
      '<circle cx="22" cy="22" r="21" fill="#9DB2DD"/><ellipse cx="22" cy="25" rx="15.5" ry="14" fill="#FFF6E8"/>';

  static const _faces = [
    // 1 Kurang seru: mata sayu, alis turun, paruh terbalik.
    '<path d="M14 21q2-2 4 0M26 21q2-2 4 0" stroke="#0A264F" stroke-width="2" fill="none" stroke-linecap="round"/><path d="M13 17.5l5 1.5M31 17.5l-5 1.5" stroke="#0A264F" stroke-width="1.6" stroke-linecap="round"/><path d="M19.5 27h5l-2.5 2.6Z" fill="#F1A22F" transform="rotate(180 22 28)"/>',
    // 2 Biasa.
    '<circle cx="16" cy="21" r="2" fill="#0A264F"/><circle cx="28" cy="21" r="2" fill="#0A264F"/><path d="M19.5 26h5l-2.5 3Z" fill="#F1A22F"/>',
    // 3 Seru: senyum kecil.
    '<circle cx="16" cy="21" r="2.2" fill="#0A264F"/><circle cx="28" cy="21" r="2.2" fill="#0A264F"/><path d="M18.5 31q3.5 2 7 0" stroke="#0A264F" stroke-width="1.6" fill="none" stroke-linecap="round"/><path d="M19.5 26h5l-2.5 3Z" fill="#F1A22F"/>',
    // 4 Seru banget: mata melengkung + pipi.
    '<path d="M13.5 22q2.5-3 5 0M25.5 22q2.5-3 5 0" stroke="#0A264F" stroke-width="2.2" fill="none" stroke-linecap="round"/><ellipse cx="12" cy="27" rx="2.4" ry="1.4" fill="#F4C6BC"/><ellipse cx="32" cy="27" rx="2.4" ry="1.4" fill="#F4C6BC"/><path d="M18.5 26h7q-1 4-3.5 4t-3.5-4Z" fill="#F1A22F"/><path d="M20 28q2 1.4 4 0" stroke="#D9654E" stroke-width="1.2" fill="none"/>',
    // 5 Luar biasa: mata besar berbinar + pipi.
    '<circle cx="16" cy="21" r="3.6" fill="#0A264F"/><circle cx="28" cy="21" r="3.6" fill="#0A264F"/><circle cx="17.2" cy="19.8" r="1.3" fill="#FFFFFF"/><circle cx="29.2" cy="19.8" r="1.3" fill="#FFFFFF"/><ellipse cx="11.5" cy="27.5" rx="2.6" ry="1.5" fill="#F4C6BC"/><ellipse cx="32.5" cy="27.5" rx="2.6" ry="1.5" fill="#F4C6BC"/><path d="M18 25.5h8q-1 5-4 5t-4-5Z" fill="#F1A22F"/><path d="M19.6 28.2q2.4 1.6 4.8 0" stroke="#D9654E" stroke-width="1.3" fill="none"/>',
  ];

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg viewBox="0 0 44 44">$_head${_faces[level - 1]}</svg>',
      width: size,
      height: size,
    );
  }
}
