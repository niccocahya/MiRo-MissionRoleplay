import 'package:flutter/material.dart';

import 'miro_tokens.dart';

/// Alias sementara ke token v2 (DECISIONS B17). Layar lama tetap memakai
/// nama ini sampai di-redesign; nilainya sudah diarahkan ke `MiroColors`
/// supaya warnanya langsung ikut palet baru. Dihapus di Fase 9.
@Deprecated('Pakai MiroColors dari miro_tokens.dart. Dihapus di Fase 9.')
abstract class AppColors {
  // Brand
  static const Color primary = MiroColors.navy900;
  static const Color primaryLight = MiroColors.navy700;
  static const Color primaryLighter = MiroColors.sky300;
  static const Color primaryTint = MiroColors.sky50;

  // Coral 600 (bukan 500) karena teks putih di atasnya butuh kontras AA.
  static const Color accent = MiroColors.coral600;
  static const Color accentDark = MiroColors.coral700;
  static const Color accentTint = MiroColors.coral100;

  static const Color gold = MiroColors.amber500;
  static const Color goldTint = MiroColors.amber75;

  // Status
  static const Color success = MiroColors.green600;
  static const Color successTint = MiroColors.green50;
  static const Color warning = MiroColors.amber300;
  static const Color danger = MiroColors.red600;
  static const Color dangerTint = MiroColors.red50;
  static const Color info = MiroColors.sky500;

  // Neutral
  static const Color background = MiroColors.app;
  static const Color surface = MiroColors.surface;
  static const Color border = MiroColors.line;
  static const Color textPrimary = MiroColors.ink;
  static const Color textSecondary = MiroColors.ink2;
  static const Color textMuted = MiroColors.ink3;
}
