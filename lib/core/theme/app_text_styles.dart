import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Semua text style app lewat sini, pakai GoogleFonts.poppins().
///
/// Sebelumnya `ThemeData(fontFamily: 'Poppins')` di main.dart nunjuk ke font
/// yang nggak pernah didaftarkan di pubspec.yaml (section `fonts:` di-comment
/// semua), jadi diam-diam selalu fallback ke font default OS. Sekarang pakai
/// google_fonts (sudah ada di pubspec) supaya Poppins-nya beneran kepakai.
abstract class AppTextStyles {
  static TextStyle _base({
    required double size,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? height,
  }) => GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );

  static TextStyle h1({Color color = AppColors.textPrimary}) =>
      _base(size: 28, weight: FontWeight.w700, color: color, height: 1.2);

  static TextStyle h2({Color color = AppColors.textPrimary}) =>
      _base(size: 22, weight: FontWeight.w700, color: color, height: 1.25);

  static TextStyle h3({Color color = AppColors.textPrimary}) =>
      _base(size: 18, weight: FontWeight.w600, color: color, height: 1.3);

  static TextStyle bodyLarge({Color color = AppColors.textPrimary}) =>
      _base(size: 16, weight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle body({Color color = AppColors.textSecondary}) =>
      _base(size: 14, weight: FontWeight.w400, color: color, height: 1.4);

  static TextStyle bodyBold({Color color = AppColors.textPrimary}) =>
      _base(size: 14, weight: FontWeight.w600, color: color, height: 1.4);

  static TextStyle caption({Color color = AppColors.textMuted}) =>
      _base(size: 12, weight: FontWeight.w400, color: color);

  static TextStyle button({Color color = Colors.white}) =>
      _base(size: 15, weight: FontWeight.w600, color: color);
}
