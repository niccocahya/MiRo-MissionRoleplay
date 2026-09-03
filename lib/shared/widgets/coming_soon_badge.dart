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
        // Pudarnya pakai lapisan kain semi-transparan di ATAS child yang
        // digambar utuh, BUKAN Opacity() yang ngebungkus seluruh child.
        // Bedanya: Opacity nurunin kontras internal child-nya juga (teks
        // vs background tombol sama-sama ditarik ke warna belakangnya),
        // sedangkan kain cuma nutupin di atas jadi kontras aslinya kejaga.
        //
        // Catatan koreksi: laporan "tombol jadi kotak abu tanpa teks" yang
        // bikin ini diubah TERNYATA bukan gara-gara Opacity -- penyebab
        // aslinya `disabledForegroundColor` yang nggak pernah di-set di
        // tombolnya (lihat _buildSubscriptionSection di profile_page.dart).
        // Cara kain ini tetep dipertahankan karena memang lebih aman, tapi
        // dia bukan yang benerin bug itu.
        IgnorePointer(child: child),
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              // Warna kainnya ngikut background app, BUKAN abu terang
              // hardcoded -- di dark mode kain terang justru bikin tombolnya
              // lebih nyolok dari sekitarnya (kebalik dari maksudnya:
              // "pudar/nyatu ke belakang").
              child: Container(
                color: AppColors.background.withValues(alpha: 0.65),
              ),
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
