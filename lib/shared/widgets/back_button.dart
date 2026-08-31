import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tombol back bulat standar. Posisi/margin diatur oleh halaman pemanggil
/// (lewat Padding/Align), widget ini cuma urus tampilannya.
class CustomBackButton extends StatelessWidget {
  const CustomBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Padding(
          // Geser dikit biar panah kerasa center di lingkaran.
          padding: EdgeInsets.only(right: 2.0),
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
