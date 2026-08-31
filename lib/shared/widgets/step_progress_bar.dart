import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Progress bar step-per-step (dipakai di Onboarding & Identify). Sebelumnya
/// ada 2 file (`onboarding_progress_bar.dart` & `identify_progress_bar.dart`)
/// isinya sama persis cuma beda `totalSteps` default — digabung jadi satu.
class StepProgressBar extends StatelessWidget {
  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl + AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isActive = currentStep >= index + 1;
          return Expanded(
            child: Container(
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          );
        }),
      ),
    );
  }
}
