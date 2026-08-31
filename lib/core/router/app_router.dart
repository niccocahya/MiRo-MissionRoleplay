import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import widget custom navbar kita
import '../../shared/widgets/custom_bottom_nav_bar.dart';

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
      backgroundColor: const Color(
        0xFFF5F8FB,
      ), // Warna latar belakang dasar aplikasi
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
final GoRouter router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/identify',
      builder: (context, state) => const IdentifyPage(),
    ),

    // Rute Notifikasi diletakkan di luar ShellRoute agar menutupi Bottom Nav Bar saat dibuka
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),

    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/missions',
          builder: (context, state) =>
              MissionsPage(roleId: state.uri.queryParameters['role']),
        ),
        GoRoute(
          path: '/progress',
          builder: (context, state) => const ProgressPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
  ],
);
