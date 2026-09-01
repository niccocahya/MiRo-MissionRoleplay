import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import widget custom navbar kita
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../theme/app_colors.dart';
import 'app_page_transition.dart';

// Import semua halaman
import '../../features/onboarding/onboarding_page.dart';
import '../../features/identify/identify_page.dart';
import '../../features/home/home_page.dart';
import '../../features/missions/missions_page.dart';
import '../../features/progress/progress_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/notifications/notifications_page.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Konten Halaman (Home, Missions, dll)
          Positioned.fill(child: child),

          // 2. Floating Bottom Nav Bar (Melayang di atas)
          Positioned(
            bottom: 24, // Jarak dari bawah layar
            left: 0,
            right: 0,
            child: const Center(child: CustomBottomNavBar()),
          ),
        ],
      ),
    );
  }
}

// ==================== ROUTER UTAMA ====================
// Semua rute pakai transisi yang sama (lihat app_page_transition.dart) biar
// pindah tab & pindah halaman berasa konsisten, bukan potongan kasar di
// beberapa tempat dan slide di tempat lain.
final GoRouter router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) =>
          appPage(key: state.pageKey, child: const OnboardingPage()),
    ),
    GoRoute(
      path: '/identify',
      pageBuilder: (context, state) => appPage(
        key: state.pageKey,
        child: IdentifyPage(
          isAddingChild: state.uri.queryParameters['mode'] == 'add',
        ),
      ),
    ),

    // Rute Notifikasi diletakkan di luar ShellRoute agar menutupi Bottom Nav Bar saat dibuka
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) =>
          appPage(key: state.pageKey, child: const NotificationsPage()),
    ),

    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              appPage(key: state.pageKey, child: const HomePage()),
        ),
        GoRoute(
          path: '/missions',
          pageBuilder: (context, state) => appPage(
            key: state.pageKey,
            child: MissionsPage(roleId: state.uri.queryParameters['role']),
          ),
        ),
        GoRoute(
          path: '/progress',
          pageBuilder: (context, state) =>
              appPage(key: state.pageKey, child: const ProgressPage()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              appPage(key: state.pageKey, child: const ProfilePage()),
        ),
      ],
    ),
  ],
);
