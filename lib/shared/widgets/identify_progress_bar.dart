import 'package:flutter/material.dart';

class IdentifyProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const IdentifyProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 5, // Default 5 langkah untuk Identify
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = currentStep >= index + 1;
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF0A264F)
                    : const Color(0xFF0A264F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}
