/// Elemen dekoratif "seru" yang dipakai berulang di banyak layar --
/// awan berlapis, gelembung warna, kelap-kelip bintang. Awalnya ditulis
/// khusus buat latar peta misi (mission_path_screen.dart) buat ngegantiin
/// 1 icon awan pipih 6% opacity yang nyaris nggak keliatan. Sekarang
/// diekstrak jadi komponen bersama biar layar lain (Home, Onboarding,
/// Progress, dst) bisa pakai bahasa visual yang SAMA tanpa nulis ulang
/// 3 widget yang persis sama tiap kali.
///
/// Semua widget di sini murni dekoratif -- nggak ada gesture handler,
/// jadi aman ditumpuk DI BAWAH konten interaktif manapun di dalam Stack
/// (taruh sebagai children PALING AWAL, sebelum konten sungguhan).
library;

import 'package:flutter/material.dart';

/// Awan "dilapis tangan" dari 3 lingkaran putih semi-transparan yang
/// saling tumpang tindih -- bentuknya kebaca sebagai awan beneran
/// (gumpalan nggak rata), bukan lingkaran/icon tunggal yang digital
/// banget.
class PuffyCloud extends StatelessWidget {
  const PuffyCloud({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.scale = 1.0,
    this.opacity = 0.55,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double scale;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    Widget puff(double size) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: SizedBox(
        width: 100 * scale,
        height: 60 * scale,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
                left: 10 * scale, top: 10 * scale, child: puff(50 * scale)),
            Positioned(left: 0, top: 20 * scale, child: puff(38 * scale)),
            Positioned(
                left: 42 * scale, top: 16 * scale, child: puff(42 * scale)),
          ],
        ),
      ),
    );
  }
}

/// Gelembung warna lembut -- ngasih "tekstur" ke background tanpa perlu
/// gambar/asset tambahan. Warnanya dikasih dari luar (biasanya warna
/// identitas role atau `AppColors.gold`) biar tiap layar bisa nyesuain
/// tema warnanya sendiri.
class ColorBlob extends StatelessWidget {
  const ColorBlob({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    this.opacity = 0.18,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Kelap-kelip kecil -- nuansa "petualangan seru" ala game.
class Sparkle extends StatelessWidget {
  const Sparkle({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    this.color = Colors.white,
    this.opacity = 0.75,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Icon(
        Icons.auto_awesome_rounded,
        color: color.withValues(alpha: opacity),
        size: size,
      ),
    );
  }
}
