import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Baris 5 bintang yang bisa diketuk.
///
/// Sebelumnya ditulis ulang di 3 tempat dan ketiganya BEDA-BEDA:
/// - mission_journal_screen.dart: bintang kosong `star_border_rounded`,
///   warnanya abu (textMuted), ukuran 34
/// - help_center_page.dart: bintang kosong `star_outline_rounded`,
///   warnanya gold juga (jadi kosong/isi susah dibedain), ukuran 30
/// - app_rating_dialog.dart: SEMUA bintang selalu keisi emas, nggak ada
///   bentuk kosong sama sekali -- keliatan kayak udah dinilai 5 padahal
///   belum diapa-apain
///
/// Sekarang satu bentuk: kosong = outline abu, keisi = emas.
class StarRatingRow extends StatelessWidget {
  const StarRatingRow({
    super.key,
    required this.rating,
    required this.onRate,
    this.size = 32,
    this.enabled = true,
  });

  /// 0 = belum dinilai (semua bintang kosong).
  final int rating;

  /// Dipanggil dengan nilai 1..5.
  final ValueChanged<int> onRate;

  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final int starValue = i + 1;
        final bool filled = rating >= starValue;
        return GestureDetector(
          onTap: enabled ? () => onRate(starValue) : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              color: filled ? AppColors.gold : AppColors.textMuted,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
