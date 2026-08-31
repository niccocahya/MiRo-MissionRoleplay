import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // 🔥 Positioned DIHAPUS!
    // Karena margin/posisi (top/left) sudah diatur oleh halaman yang memanggilnya (via Padding/Align).
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF0A264F),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Padding(
          // Tambahan dikit biar panah back-nya kerasa lebih pas di tengah lingkaran
          padding: EdgeInsets.only(right: 2.0),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
