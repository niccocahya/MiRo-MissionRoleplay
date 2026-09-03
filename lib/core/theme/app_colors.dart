import 'package:flutter/material.dart';

/// Satu-satunya sumber warna di seluruh app. Diambil dari warna yang paling
/// sering dipakai di kode lama (biar identitas visual MiRO tetap sama),
/// cuma sekarang dikasih nama biar konsisten & gampang diganti.
///
/// Jangan tulis `Color(0xFF...)` langsung di widget — pakai token di sini.
///
/// App ini SENGAJA cuma punya satu mode (terang) -- dark mode sempat
/// dibangun penuh (getter reaktif + palet gelap + toggle di Settings) lalu
/// diminta dicabut total karena nggak cocok sama identitas visual MiRO
/// yang colorful/playful. Field-field ini balik jadi `static const` biasa,
/// bukan getter -- lebih simpel dan lebih cepat (const-foldable di seluruh
/// widget tree), dan nutup jalan buat dark mode nyelinap balik nggak
/// sengaja lewat provider lain.
abstract class AppColors {
  // Brand
  static const Color primary = Color(0xFF0A264F); // navy tua, warna utama MiRO
  static const Color primaryLight = Color(0xFF153E7E);
  static const Color primaryLighter = Color(0xFFA5CBEB);
  static const Color primaryTint = Color(0xFFEBF4FA); // background biru muda

  static const Color accent = Color(0xFFE57B65); // coral, warna aksen/CTA
  static const Color accentDark = Color(0xFFD46A55);
  static const Color accentTint = Color(0xFFFDF1E8); // background peach

  static const Color gold = Color(0xFFF1A22F); // XP / bintang / reward
  static const Color goldTint = Color(0xFFFFF4E5);

  // Status
  static const Color success = Color(0xFF4CAF50);
  static const Color successTint = Color(0xFFE8F2E6);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerTint = Color(0xFFFDE8E7);
  static const Color info = Color(0xFF4DB6AC);

  // Neutral
  static const Color background = Color(0xFFF5F8FB); // background dasar app
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0A264F);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF90A4AE);
}
