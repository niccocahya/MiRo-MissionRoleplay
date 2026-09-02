import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Wajib buat baca languageProvider

// JALUR IMPORT
import '../data/mission_model.dart';
import 'mission_journal_screen.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/router/app_page_transition.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

// ==========================================
// 1. DICTIONARY KAMUS BAHASA
// ==========================================
const Map<String, Map<String, String>> _t = {
  'en': {
    'title': "YOU DID IT!",
    'subtitle': "Great job completing this mission",
    'btn_progress': "See progress",
  },
  'id': {
    'title': "KAMU BERHASIL!",
    'subtitle': "Kerja bagus telah menyelesaikan misi ini",
    'btn_progress': "Lihat perkembangan",
  },
};

// Ubah ke ConsumerStatefulWidget agar bisa membaca Riverpod
class MissionWinScreen extends ConsumerStatefulWidget {
  final MissionModel mission;
  final List<String> capturedPhotos;

  const MissionWinScreen({
    super.key,
    required this.mission,
    required this.capturedPhotos,
  });

  @override
  ConsumerState<MissionWinScreen> createState() => _MissionWinScreenState();
}

class _MissionWinScreenState extends ConsumerState<MissionWinScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  // Dulu layar "misi selesai" cuma ada 1 animasi kecil (penguin scale-in)
  // -- momen paling seru buat anak (baru aja nyelesein misi) rasanya
  // hambar. Confetti nembak sekali pas layar ini muncul.
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tarik bahasa aktif secara real-time dari Riverpod
    final lang = ref.watch(languageProvider);
    final texts = _t[lang] ?? _t['en']!;

    return Scaffold(
      body: Container(
        width: double.infinity,
        color: const Color(0xFF92C4E8), // biru khusus layar "misi selesai"
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset('assets/images/snow.png', fit: BoxFit.cover),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: math.pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.04,
                numberOfParticles: 16,
                maxBlastForce: 20,
                minBlastForce: 8,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  Colors.white,
                  Color(0xFFF1A22F),
                  Color(0xFFE57B65),
                  Color(0xFF4CAF50),
                  Color(0xFFA5CBEB),
                ],
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Image.asset(
                              // Mencoba memanggil gambar sesuai ID peran
                              'assets/images/${widget.mission.roleId}_trans.png',
                              width: double.infinity,
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.bottomCenter,
                              // JIKA GAMBAR TIDAK ADA MAKA TAMPILKAN PINGUIN DOCTOR
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/penguin_doctor.png',
                                  width: double.infinity,
                                  fit: BoxFit.fitWidth,
                                  alignment: Alignment.bottomCenter,
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          texts['title']!,
                          style: AppTextStyles.bodyBold(
                            color: AppColors.primary.withValues(alpha: 0.7),
                          ).copyWith(letterSpacing: 2, fontSize: 14),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          texts['subtitle']!,
                          style: AppTextStyles.h1().copyWith(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              appPageRoute(
                                MissionJournalScreen(
                                  mission: widget.mission,
                                  capturedPhotos: widget.capturedPhotos,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                            ),
                          ),
                          child: Text(
                            texts['btn_progress']!,
                            style: AppTextStyles.button().copyWith(fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl + AppSpacing.sm),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
