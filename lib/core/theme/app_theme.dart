import 'package:flutter/material.dart';

import 'miro_theme.dart';

/// Alias sementara ke `MiroTheme` (DECISIONS B17). Dihapus di Fase 9.
@Deprecated('Pakai MiroTheme.light. Dihapus di Fase 9.')
abstract class AppTheme {
  static ThemeData get light => MiroTheme.light;
}
