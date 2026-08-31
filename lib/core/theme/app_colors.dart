import 'package:flutter/material.dart';

/// Satu-satunya sumber warna di seluruh app. Diambil dari warna yang paling
/// sering dipakai di kode lama (biar identitas visual MiRO tetap sama),
/// cuma sekarang dikasih nama biar konsisten & gampang diganti.
///
/// Jangan tulis `Color(0xFF...)` langsung di widget — pakai token di sini.
abstract class AppColors {
  // Brand
  static const primary = Color(0xFF0A264F); // navy tua, warna utama MiRO
  static const primaryLight = Color(0xFF153E7E);
  static const primaryLighter = Color(0xFFA5CBEB);
  static const primaryTint = Color(0xFFEBF4FA); // background biru muda

  static const accent = Color(0xFFE57B65); // coral, warna aksen/CTA
  static const accentDark = Color(0xFFD46A55);
  static const accentTint = Color(0xFFFDF1E8); // background peach

  static const gold = Color(0xFFF1A22F); // XP / bintang / reward
  static const goldTint = Color(0xFFFFF4E5);

  // Status
  static const success = Color(0xFF4CAF50);
  static const successTint = Color(0xFFE8F2E6);
  static const warning = Color(0xFFFFB74D);
  static const danger = Color(0xFFE53935);
  static const dangerTint = Color(0xFFFDE8E7);
  static const info = Color(0xFF4DB6AC);

  // Neutral
  static const background = Color(0xFFF5F8FB); // background dasar app
  static const surface = Colors.white;
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0A264F);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF90A4AE);
}
