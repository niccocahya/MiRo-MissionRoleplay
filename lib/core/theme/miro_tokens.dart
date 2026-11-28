// MiRO v2 design tokens untuk Flutter.
// Disalin dari design/miro_tokens.dart (Fase 0).
// Sumber: docs/DESIGN_SYSTEM.md §1 sampai §4 dan §8, docs/DECISIONS.md, docs/standards/ANIMATION.md.
//
// Aturan: widget TIDAK BOLEH menulis Color(0xFF...), angka radius, atau Duration
// sendiri. Semua lewat token di file ini. Pengecualian: warna ilustrasi di
// lib/shared/icons/** (wajah perasaan, peti, kristal, logo Google).

import 'package:flutter/material.dart';

// ============================================================
// Warna
// ============================================================
abstract final class MiroColors {
  // Navy
  static const navy50 = Color(0xFFF5F8FB);
  static const navy100 = Color(0xFFE8EEF5);
  static const navy200 = Color(0xFFD5DEEA);
  static const navy300 = Color(0xFFA3B1C4);
  static const navy400 = Color(0xFF7A8BA3);
  static const navy500 = Color(0xFF5B6F8A);
  static const navy600 = Color(0xFF3D5677);
  static const navy700 = Color(0xFF1E467A);
  static const navy800 = Color(0xFF123462);
  static const navy900 = Color(0xFF0A264F);
  static const navy950 = Color(0xFF04152E);

  // Coral (aksi)
  static const coral100 = Color(0xFFFBEBE8);
  static const coral200 = Color(0xFFF4C6BC);
  static const coral300 = Color(0xFFECA091);
  static const coral500 = Color(0xFFE57B65);
  static const coral600 = Color(0xFFD9654E);
  static const coral700 = Color(0xFFB24A34);
  static const coral800 = Color(0xFF8F3A28);

  // Sky
  static const sky50 = Color(0xFFEBF4FA);
  static const sky100 = Color(0xFFD3E3F2);
  static const sky200 = Color(0xFFC9DFF1);
  static const sky300 = Color(0xFFA5CBEB);
  static const sky400 = Color(0xFF8BBCE6);
  static const sky500 = Color(0xFF6FA6D6);
  static const sky700 = Color(0xFF3D7FB8);

  // Amber (hadiah)
  static const amber50 = Color(0xFFFEF7EE);
  static const amber75 = Color(0xFFFFF4DF);
  static const amber100 = Color(0xFFFFE8B6);
  static const amber200 = Color(0xFFF5D39A);
  static const amber300 = Color(0xFFF5B555);
  static const amber500 = Color(0xFFF1A22F);
  static const amber600 = Color(0xFFC67B0D);
  static const amber700 = Color(0xFFA86A0A);
  static const amber800 = Color(0xFF8A5608);
  static const amber900 = Color(0xFF6B4307);

  // Cream
  static const cream50 = Color(0xFFFFFBF2); // notifikasi belum dibaca
  static const cream100 =
      Color(0xFFFFF8E9); // kertas sertifikat, kartu Misi Puncak
  static const cream200 =
      Color(0xFFFFE8B6); // latar logo, kartu krem (= amber100)
  static const cream300 = Color(0xFFF1C97A); // lip kartu krem

  // Sand
  static const sand100 = Color(0xFFF9F6F1);
  static const sand300 = Color(0xFFE9DFCE);

  // Green (berhasil)
  static const green50 = Color(0xFFE8F2E6);
  static const green100 = Color(0xFFDCFCE7);
  static const green200 = Color(0xFFBFDDBF);
  static const green500 = Color(0xFF22C55E); // hanya ikon centang & isi progres
  static const green600 = Color(0xFF17843F);
  static const green700 = Color(0xFF15803D);
  static const green800 = Color(0xFF0F582A);
  static const green900 = Color(0xFF2B5E3A);

  // Red (bahaya)
  static const red50 = Color(0xFFFDECEA);
  static const red100 = Color(0xFFFDE7E7);
  static const red200 = Color(0xFFF4B4AE);
  static const red500 = Color(0xFFE5484D); // border error
  static const red600 = Color(0xFFC93A3F); // tombol bahaya
  static const red700 = Color(0xFFB42318); // teks error
  static const red800 = Color(0xFF9A2A2F);
  static const red900 = Color(0xFF8F2219);

  // Lain-lain
  static const white = Color(0xFFFFFFFF);
  static const divider = Color(0xFFEEF2F7);
  static const teacherLine = Color(0xFFD9CCF0);
  static const streakMissed = Color(0xFF3B4E6B);
  static const scrim = Color(0x8C04152E); // rgba(4,21,46,.55)

  // Tingkat lencana (emas = amber500 / amber600)
  static const tierBronze = Color(0xFFC8865A);
  static const tierBronzeLip = Color(0xFFA86A3E);
  static const tierBronzeSoft = Color(0xFFE0B08E);
  static const tierBronzeInk = Color(0xFF8E5530);
  static const tierSilver = Color(0xFFAFC0D3);
  static const tierSilverLip = Color(0xFF8A9DB3);

  // ---------- Semantik (yang dipakai widget) ----------
  static const app = navy50;
  static const surface = white;
  static const surfaceMuted = navy100;
  static const selected = cream200;
  static const ink = navy900; // teks utama
  static const ink2 = navy600; // teks pendukung
  static const ink3 = navy500; // caption, placeholder
  static const inkDisabled = navy300;
  static const line = navy200; // border kartu & input
  static const link = coral700;

  static const actionPrimary = coral600;
  static const actionPrimaryLip = coral700;
  static const actionDark = navy900;
  static const actionDarkLip = navy950;
  static const actionReward = amber500;
  static const actionRewardLip = amber600;
  static const actionSuccess = green600;
  static const actionSuccessLip = green800;
  static const actionDanger = red600;
  static const actionDangerLip = red800;

  static const xp = amber500;
  static const streak = sky500;

  /// Latar suasana (onboarding, perayaan).
  static const moodGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sky300, sky100, sand300],
  );
}

/// Warna per peran. `id` sama dengan `roles_master.id` di Supabase.
enum MiroRole {
  doctor(Color(0xFF5FA873), Color(0xFF3F8253), Color(0xFFE8F2E6)),
  chef(Color(0xFF5C9FD6), Color(0xFF3D7FB8), Color(0xFFEBF4FA)),
  artist(Color(0xFFF08A4B), Color(0xFFC86A30), Color(0xFFFDF1E8)),
  teacher(Color(0xFF9B7FD4), Color(0xFF7A5FB3), Color(0xFFF6F0FA)),
  athlete(Color(0xFFE56B7E), Color(0xFFBF4C5F), Color(0xFFFAF0F0));

  const MiroRole(this.base, this.lip, this.soft);
  final Color base; // tab, node, rail
  final Color lip;
  final Color soft; // latar ilustrasi & kartu aktif

  static MiroRole? fromId(String? id) =>
      MiroRole.values.where((r) => r.name == id).firstOrNull;
}

// ============================================================
// Jarak, radius, lip
// ============================================================
abstract final class MiroSpace {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0; // margin samping layar
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;

  static const screen = EdgeInsets.symmetric(horizontal: x5);
  static const footer = EdgeInsets.fromLTRB(x5, x4, x5, x6);
}

abstract final class MiroRadius {
  static const sm = 8.0;
  static const md = 12.0; // input, tile ikon
  static const lg = 16.0; // tombol
  static const xl = 20.0; // kartu
  static const xxl = 24.0; // kartu besar, foto
  static const sheet = 28.0;
  static const pill = 999.0;
}

/// Tinggi "lip" (bayangan padat di bawah elemen yang bisa ditekan).
abstract final class MiroLip {
  static const button = 4.0;
  static const card = 3.0;
  static const iconButton = 2.0;
  static const hero = 6.0; // kartu streak navy, kartu besar
}

abstract final class MiroSize {
  static const designWidth = 390.0;
  static const designHeight = 844.0;
  static const touch = 44.0; // target sentuh minimal
  static const buttonL = 56.0;
  static const buttonM = 48.0;
  static const buttonS = 40.0;
  static const input = 52.0;
  static const topBar = 64.0;
  static const bottomNav = 80.0;
}

// ============================================================
// Tipografi (Nunito, dibundel sebagai aset; lihat DECISIONS.md)
// ============================================================
abstract final class MiroText {
  /// Nama keluarga font yang didaftarkan di pubspec (assets/google_fonts/).
  /// Dipakai lewat `fontFamily` biasa, bukan `GoogleFonts.nunito()`, supaya
  /// bobot yang tidak dibundel (400/500 di layar lama) jatuh ke bobot
  /// terdekat tanpa mencoba mengunduh dari internet.
  static const family = 'Nunito';

  static TextStyle _n(
    double size,
    double lineHeight,
    FontWeight w, {
    Color color = MiroColors.ink,
    double letterSpacing = 0,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: w,
        color: color,
        letterSpacing: letterSpacing,
      );

  static final display = _n(40, 44, FontWeight.w900);
  static final h1 = _n(32, 38, FontWeight.w900);
  static final h2 = _n(24, 30, FontWeight.w900);
  static final h3 = _n(20, 26, FontWeight.w900);
  static final title = _n(17, 24, FontWeight.w900);
  static final bodyLg = _n(17, 26, FontWeight.w600);
  static final body = _n(15, 22, FontWeight.w600, color: MiroColors.ink2);
  static final bodyStrong = _n(15, 22, FontWeight.w800);
  static final caption = _n(13, 18, FontWeight.w700, color: MiroColors.ink2);
  // Pengganti eyebrow: huruf kalimat, bukan kapital renggang.
  static final label = _n(
    13,
    18,
    FontWeight.w800,
    color: MiroColors.ink3,
  );
  static final small = _n(12, 16, FontWeight.w800, color: MiroColors.ink3);

  /// Label tombol: 15 sampai 17px, 800, UPPERCASE, tracking 0.04em.
  static TextStyle button({double size = 17, Color color = MiroColors.white}) =>
      _n(
        size,
        size + 4,
        FontWeight.w800,
        color: color,
        letterSpacing: size * 0.04,
      );
}

// ============================================================
// Motion (ANIMATION.md)
// ============================================================
abstract final class MiroMotion {
  static const instant = Duration(milliseconds: 80); // tekan
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const rise = Duration(milliseconds: 420);
  static const pop = Duration(milliseconds: 460);
  static const slow = Duration(milliseconds: 400);
  static const grow = Duration(milliseconds: 900);
  static const celebrate = Duration(milliseconds: 1000);

  static const stagger = Duration(milliseconds: 60);
  static const staggerTight = Duration(milliseconds: 40);
  static const staggerLoose = Duration(milliseconds: 120);

  static const easeOut = Cubic(0.22, 1, 0.36, 1);
  static const easeIn = Cubic(0.64, 0, 0.78, 0);
  static const easePop = Cubic(0.34, 1.56, 0.64, 1);

  /// Loop dekoratif (floaty, pulse) maksimal 3 putaran.
  static const maxLoops = 3;

  /// True jika sistem atau pengaturan app meminta kurangi animasi.
  /// Pakai bersama provider pengaturan: `reduce = MiroMotion.reduced(context) || settings.reduceMotion`.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
