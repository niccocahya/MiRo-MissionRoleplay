/// Level anak dihitung dari `total_xp` — TIDAK dari kolom `children
/// .current_level`. Kolom itu ada di skema tapi nggak pernah ditulis balik
/// dari manapun di app ini (sama kasusnya kaya `current_streak`, lihat
/// `core/providers/streak_provider.dart`), jadi kalau dibaca langsung
/// selalu berhenti di angka default dan nggak pernah naik — sementara
/// Home/Progress yang udah ngitung dari XP kelihatan benar. Baca level
/// SELALU lewat sini, jangan pernah `data['current_level']`.
///
/// Sebelumnya breakpoint 100/250/500 XP ini ditulis ulang identik di
/// `home_page.dart`, `progress_page.dart`, dan `profile_page.dart` — kalau
/// salah satu diubah tanpa yang lain ikut, 3 layar itu bisa nunjukin level
/// yang beda-beda buat anak yang sama.
class LevelInfo {
  const LevelInfo({
    required this.level,
    required this.currentXp,
    required this.maxXp,
  });

  final int level;
  final int currentXp;
  final int maxXp;
}

LevelInfo calculateLevelInfo(int totalXp) {
  if (totalXp < 100) {
    return LevelInfo(level: 1, currentXp: totalXp, maxXp: 100);
  }
  if (totalXp < 250) {
    return LevelInfo(level: 2, currentXp: totalXp - 100, maxXp: 150);
  }
  if (totalXp < 500) {
    return LevelInfo(level: 3, currentXp: totalXp - 250, maxXp: 250);
  }
  return LevelInfo(level: 4, currentXp: totalXp - 500, maxXp: 500);
}

/// Versi ringkas kalau cuma butuh angka level-nya doang.
int calculateLevel(int totalXp) => calculateLevelInfo(totalXp).level;
