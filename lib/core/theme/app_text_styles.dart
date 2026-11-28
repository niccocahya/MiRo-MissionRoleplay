import 'package:flutter/material.dart';

import 'miro_tokens.dart';

/// Alias sementara (DECISIONS B16/B17): ukuran lama dipertahankan agar tata
/// letak layar lama tidak bergeser, tetapi font sudah Nunito dan bobot
/// minimal 600 (DESIGN_SYSTEM §2.3). Dihapus di Fase 9; layar baru memakai
/// `MiroText`.
@Deprecated('Pakai MiroText dari miro_tokens.dart. Dihapus di Fase 9.')
abstract class AppTextStyles {
  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color? color,
    double? height,
  }) =>
      TextStyle(
        fontFamily: MiroText.family,
        fontSize: size,
        fontWeight: weight,
        color: color ?? MiroColors.ink,
        height: height,
      );

  static TextStyle h1({Color? color}) =>
      _base(size: 28, weight: FontWeight.w900, color: color, height: 1.2);

  static TextStyle h2({Color? color}) =>
      _base(size: 22, weight: FontWeight.w900, color: color, height: 1.25);

  static TextStyle h3({Color? color}) =>
      _base(size: 18, weight: FontWeight.w800, color: color, height: 1.3);

  static TextStyle bodyLarge({Color? color}) =>
      _base(size: 16, weight: FontWeight.w600, color: color, height: 1.4);

  static TextStyle body({Color? color}) => _base(
        size: 14,
        weight: FontWeight.w600,
        color: color ?? MiroColors.ink2,
        height: 1.4,
      );

  static TextStyle bodyBold({Color? color}) =>
      _base(size: 14, weight: FontWeight.w800, color: color, height: 1.4);

  static TextStyle caption({Color? color}) => _base(
        size: 12,
        weight: FontWeight.w700,
        color: color ?? MiroColors.ink3,
      );

  static TextStyle button({Color color = MiroColors.white}) =>
      _base(size: 15, weight: FontWeight.w800, color: color);
}
