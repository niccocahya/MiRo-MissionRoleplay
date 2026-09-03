import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Wrapper bottom sheet standar (card putih rounded-top + drag handle +
/// judul opsional). Sebelumnya blok kode ini (~15 baris: Container decoration
/// + Center + drag handle abu-abu) ditulis ulang identik di banyak tempat
/// (profile: edit profile, data anak, pengaturan; dan layar lain).
///
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   backgroundColor: Colors.transparent,
///   isScrollControlled: true,
///   builder: (_) => AppBottomSheet(title: 'Edit Profil', child: ...),
/// );
/// ```
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, required this.child, this.title});

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      // Dulu sheet ini ngikut tinggi isinya gitu aja. Isi yang panjang
      // (mis. modal "Data Anak": avatar + nama + 3 kotak statistik +
      // ringkasan kuisioner) nembus batas tinggi sheet dan munculin garis
      // kuning-hitam "BOTTOM OVERFLOWED BY ... PIXELS", karena isinya nggak
      // bisa di-scroll sama sekali. Sekarang tingginya dibatasi dan isinya
      // bisa digulir kalau kepanjangan -- berlaku buat SEMUA bottom sheet
      // sekaligus, bukan ditambal satu-satu.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl + AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (title != null) ...[
              Text(title!, style: AppTextStyles.h2()),
              const SizedBox(height: AppSpacing.lg),
            ],
            // Flexible + scroll: kalau isinya muat, sheet-nya tetap sependek
            // isinya (nggak maksa setinggi layar); kalau kepanjangan, baru
            // digulir.
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
