import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import 'back_button.dart';

/// Header standar layar "halaman dalam" (yang dibuka lewat push, bukan tab):
/// tombol kembali + judul.
///
/// Blok ini sebelumnya ditulis ulang PERSIS SAMA (11 baris, karakter per
/// karakter) di 6 layar: Semua Lencana, Buku Kenangan, Kalender Streak,
/// Minat & Gaya Belajar, Cari Misi, dan Pusat Bantuan — plus 2 variasi
/// mirip di Semua Sertifikat & halaman legal. Sekarang satu tempat.
///
/// ```dart
/// AppScreenHeader(title: texts['title']!)
/// AppScreenHeader(title: 'Judul', trailing: IconButton(...))
/// ```
class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;

  /// Default-nya `Navigator.pop`. Diisi kalau layarnya perlu perlakuan
  /// khusus (mis. `context.pop()` punya go_router di halaman Notifikasi).
  final VoidCallback? onBack;

  /// Aksi opsional di kanan judul (mis. tombol menu "⋮").
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hPad = context.pageHPadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 8),
      child: Row(
        children: [
          CustomBackButton(
            onPressed: onBack ?? () => Navigator.pop(context),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h2(),
              // Judul panjang (mis. "Syarat & Ketentuan") dipotong, bukan
              // wrap ke baris kedua yang bikin tinggi header lompat-lompat
              // beda-beda antar layar.
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
