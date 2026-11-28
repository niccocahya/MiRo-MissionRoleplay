import 'miro_tokens.dart';

/// Alias sementara ke `MiroSpace` (DECISIONS B17). Dihapus di Fase 9.
@Deprecated('Pakai MiroSpace dari miro_tokens.dart. Dihapus di Fase 9.')
abstract class AppSpacing {
  static const xs = MiroSpace.x1;
  static const sm = MiroSpace.x2;
  static const md = MiroSpace.x4;
  static const lg = MiroSpace.x6;
  static const xl = MiroSpace.x8;
  static const xxl =
      MiroSpace.x10 + MiroSpace.x2; // 48, tidak ada token tunggal
}

/// Alias sementara ke `MiroRadius`. Nilai lama dipetakan ke radius v2
/// terdekat (10 → 12, 16 → 16, 24 → 24, 30 → 28). Dihapus di Fase 9.
@Deprecated('Pakai MiroRadius dari miro_tokens.dart. Dihapus di Fase 9.')
abstract class AppRadius {
  static const sm = MiroRadius.md;
  static const md = MiroRadius.lg;
  static const lg = MiroRadius.xxl;
  static const xl = MiroRadius.sheet;
  static const pill = MiroRadius.pill;
}
