import 'package:flutter/material.dart';

/// Helper responsif. Sebelumnya banyak layar pakai ukuran/padding tetap
/// (angka fix px) yang bisa overflow atau kelihatan kekecilan/kegedean di
/// device lain (HP kecil, tablet, web). Pakai ini sebagai gantinya.
extension ResponsiveContext on BuildContext {
  Size get _screen => MediaQuery.sizeOf(this);

  double get screenWidth => _screen.width;
  double get screenHeight => _screen.height;

  bool get isTablet => screenWidth >= 600;
  bool get isDesktop => screenWidth >= 1024;

  /// Skala sebuah ukuran (font/spacing/icon) relatif terhadap lebar desain
  /// acuan 390 (lebar HP standar), dibatasi 0.85x–1.25x supaya nggak
  /// terlalu ekstrem di HP kecil atau tablet besar.
  double scale(double value) {
    final factor = (screenWidth / 390.0).clamp(0.85, 1.25);
    return value * factor;
  }

  /// Padding horizontal halaman: lebih lega di tablet/desktop, tetap nyaman
  /// di HP kecil.
  double get pageHPadding {
    if (isDesktop) return 48;
    if (isTablet) return 32;
    return 20;
  }
}

/// Bungkus konten dengan lebar maksimum di layar besar (tablet/web) supaya
/// tidak melebar penuh sampai terlihat aneh, sambil tetap full-width di HP.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 560});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
