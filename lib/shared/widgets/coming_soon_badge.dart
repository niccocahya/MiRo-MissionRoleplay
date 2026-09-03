import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Bungkus tombol/elemen yang belum jadi fiturnya (mis. login Google,
/// langganan berbayar) supaya keliatan JELAS belum bisa dipencet, bukan
/// tombol aktif yang diem aja pas ditekan — itu yang bikin app kerasa
/// setengah jadi walau sebenarnya emang belum waktunya rilis fitur itu.
///
/// [radius] cuma buat bentuk lapisan pudarnya (`ClipRRect` di bawah) --
/// nggak perlu persis 1:1 sama radius `child`-nya, cuma jangan beda jauh
/// biar sudutnya nggak nongol.
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({
    super.key,
    required this.child,
    this.label = 'Segera Hadir',
    this.radius = AppRadius.xl,
  });

  final Widget child;
  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dulu pudarnya pakai Opacity() ngebungkus seluruh child -- buat
        // tombol berwarna solid + teks kontras tinggi (mis. background
        // navy + teks putih), itu bisa bikin tombolnya kelihatan jadi 1
        // kotak abu-abu rata tanpa teks sama sekali kalau ke-compile ke
        // 1 layer (kejadian pas dicoba di Edge/web) -- teks & background-
        // nya sama-sama numpuk jadi 1 warna abu pas di-render sebagai
        // satu potongan. Sekarang child-nya digambar UTUH di layer-nya
        // sendiri (kontras aslinya kejaga), terus dilapis kain abu-abu
        // semi-transparan di ATASnya buat kesan "pudar" -- teknik yang
        // jauh lebih aman lintas-platform daripada ngerender ulang whole
        // subtree di opacity rendah.
        IgnorePointer(child: child),
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Container(color: Colors.grey.shade200.withValues(alpha: 0.65)),
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
