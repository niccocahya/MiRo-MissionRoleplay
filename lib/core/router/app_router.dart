import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import widget custom navbar kita
import '../../shared/widgets/custom_bottom_nav_bar.dart';
import '../providers/language_provider.dart';
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
            // BUKAN const — widget const dikanonikalisasi jadi 1 objek yang
            // sama persis tiap kali, jadi Flutter skip rebuild-nya walau
            // parent (ScaffoldWithNavBar) rebuild. Itu bikin warnanya
            // "nyangkut" ke mode lama pas dark mode di-toggle sementara
            // masih di halaman yang sama. Sama alasannya buat semua
            // `const XxxPage()` di bawah.
            child: Center(child: CustomBottomNavBar()),
          ),
        ],
      ),
    );
  }
}

// Dulu nggak ada errorBuilder sama sekali -- rute yang nggak cocok (link
// notifikasi yang salah ketik, deep link lama/rusak, dst.) jatuh ke
// halaman error bawaan GoRouter, yang gayanya generic Material dan nggak
// nyambung sama tampilan MiRO sama sekali.
class _RouteNotFoundPage extends ConsumerWidget {
  const _RouteNotFoundPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final isId = lang == 'id';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.explore_off_rounded,
                  size: 64,
                  color: AppColors.primaryLighter,
                ),
                const SizedBox(height: 16),
                Text(
                  isId ? "Halaman nggak ketemu" : "Page not found",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isId
                      ? "Sepertinya kamu nyasar. Yuk balik ke beranda."
                      : "Looks like you took a wrong turn. Let's head back home.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                  child: Text(
                    isId ? "Ke Beranda" : "Go Home",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
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
  errorBuilder: (context, state) => const _RouteNotFoundPage(),
  routes: [
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) =>
          appPage(key: state.pageKey, child: OnboardingPage()),
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
          appPage(key: state.pageKey, child: NotificationsPage()),
    ),

    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              appPage(key: state.pageKey, child: HomePage()),
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
              appPage(key: state.pageKey, child: ProgressPage()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              appPage(key: state.pageKey, child: ProfilePage()),
        ),
      ],
    ),
  ],
);
