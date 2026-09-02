import 'package:flutter/material.dart';

/// Satu-satunya sumber warna di seluruh app. Diambil dari warna yang paling
/// sering dipakai di kode lama (biar identitas visual MiRO tetap sama),
/// cuma sekarang dikasih nama biar konsisten & gampang diganti.
///
/// Jangan tulis `Color(0xFF...)` langsung di widget — pakai token di sini.
///
/// Dulu semua field ini `static const` — nggak mungkin beda-beda per mode
/// (light/dark) selama tetap const. Sekarang jadi getter yang baca
/// `_brightness` (di-set dari `MyApp` tiap kali mode ganti, lihat
/// `main.dart` + `theme_mode_provider.dart`). Konsekuensinya: kode manapun
/// yang makai token ini di dalam `const Widget(...)` bakal error compile
/// ("not a constant expression") — itu justru yang kita mau, karena widget
/// non-const otomatis ikut rebuild pas mode ganti.
abstract class AppColors {
  static Brightness _brightness = Brightness.light;

  static void setBrightness(Brightness b) => _brightness = b;

  /// Publik — dipakai file lain (mis. `role_visuals.dart`) yang juga perlu
  /// nge-branch sendiri berdasarkan mode aktif.
  static bool get isDark => _brightness == Brightness.dark;

  // Brand
  static Color get primary =>
      isDark ? const Color(0xFF3E63A0) : const Color(0xFF0A264F); // navy tua, warna utama MiRO
  static Color get primaryLight =>
      isDark ? const Color(0xFF4E7BC0) : const Color(0xFF153E7E);
  static Color get primaryLighter =>
      isDark ? const Color(0xFF6E93C4) : const Color(0xFFA5CBEB);
  static Color get primaryTint =>
      isDark ? const Color(0xFF17233A) : const Color(0xFFEBF4FA); // background biru muda

  static Color get accent => const Color(0xFFE57B65); // coral, warna aksen/CTA — kuat di dua mode
  static Color get accentDark => const Color(0xFFD46A55);
  static Color get accentTint =>
      isDark ? const Color(0xFF3A2A24) : const Color(0xFFFDF1E8); // background peach

  static Color get gold => const Color(0xFFF1A22F); // XP / bintang / reward
  static Color get goldTint =>
      isDark ? const Color(0xFF3A2D18) : const Color(0xFFFFF4E5);

  // Status
  static Color get success =>
      isDark ? const Color(0xFF6FCB74) : const Color(0xFF4CAF50);
  static Color get successTint =>
      isDark ? const Color(0xFF1E3320) : const Color(0xFFE8F2E6);
  static Color get warning => const Color(0xFFFFB74D);
  static Color get danger =>
      isDark ? const Color(0xFFFF6B60) : const Color(0xFFE53935);
  static Color get dangerTint =>
      isDark ? const Color(0xFF3A2020) : const Color(0xFFFDE8E7);
  static Color get info => const Color(0xFF4DB6AC);

  // Neutral
  static Color get background =>
      isDark ? const Color(0xFF0B121C) : const Color(0xFFF5F8FB); // background dasar app
  static Color get surface => isDark ? const Color(0xFF161F2E) : Colors.white;
  static Color get border =>
      isDark ? const Color(0xFF2A3648) : const Color(0xFFE2E8F0);
  static Color get textPrimary =>
      isDark ? const Color(0xFFECF1F7) : const Color(0xFF0A264F);
  static Color get textSecondary =>
      isDark ? const Color(0xFFA9B7C8) : const Color(0xFF64748B);
  static Color get textMuted =>
      isDark ? const Color(0xFF7C8AA0) : const Color(0xFF90A4AE);
}
