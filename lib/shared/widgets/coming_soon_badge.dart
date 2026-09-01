import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Bungkus tombol/elemen yang belum jadi fiturnya (mis. login Google,
/// langganan berbayar) supaya keliatan JELAS belum bisa dipencet, bukan
/// tombol aktif yang diem aja pas ditekan — itu yang bikin app kerasa
/// setengah jadi walau sebenarnya emang belum waktunya rilis fitur itu.
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({super.key, required this.child, this.label = 'Segera Hadir'});

  final Widget child;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(opacity: 0.55, child: IgnorePointer(child: child)),
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
