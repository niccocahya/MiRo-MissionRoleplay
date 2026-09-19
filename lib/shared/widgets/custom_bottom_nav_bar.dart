import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/language_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/responsive.dart';

const List<IconData> _kNavIcons = [
  Icons.home_filled,
  Icons.flag,
  Icons.bar_chart_rounded,
  Icons.person_rounded,
];

// Nama tab buat tooltip (tekan lama) -- dulu navbar cuma 4 ikon polos
// tanpa label sama sekali, jadi nggak jelas artinya apa buat orang yang
// belum hafal (masukan tester: "clueless kalo cuma logo").
const Map<String, List<String>> _kNavLabels = {
  'id': ['Beranda', 'Misi', 'Progress', 'Profil'],
  'en': ['Home', 'Missions', 'Progress', 'Profile'],
};

bool _isActiveFor(String path, String location) {
  if (path == '/missions') return location.startsWith('/missions');
  if (path == '/home') return location == '/home' || location == '/';
  return location == path;
}

class CustomBottomNavBar extends ConsumerWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).uri.toString();
    final String lang = ref.watch(languageProvider);
    final labels = _kNavLabels[lang] ?? _kNavLabels['en']!;

    final int activeIndex = kTabRoutePaths.indexWhere(
      (path) => _isActiveFor(path, location),
    );
    // Kalau lagi di rute di luar 4 tab ini (nggak seharusnya kejadian,
    // tapi tetap dijaga), jangan biarin index -1 kepakai buat animasi --
    // itu bakal bikin lingkarannya nge-lerp ke posisi negatif yang aneh.
    final int safeIndex = activeIndex < 0 ? 0 : activeIndex;

    return Container(
      width: context.screenWidth * 0.9,
      constraints: const BoxConstraints(maxWidth: 300),
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      // Dulu tiap ikon punya AnimatedContainer SENDIRI yang cuma nge-fade
      // warna lingkarannya sendiri -- kelihatan kayak 4 lingkaran independen
      // nyala-mati gantian, bukan SATU lingkaran yang beneran BERGESER dari
      // ikon lama ke ikon baru. LayoutBuilder di sini buat tau lebar asli
      // yang tersedia (lebar Container - padding kiri-kanan), dibagi rata
      // jadi 4 "slot" -- lingkarannya cuma satu widget, posisi `left`-nya
      // dianimasikan (AnimatedPositioned) tiap kali tab aktif ganti.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double slotWidth = constraints.maxWidth / kTabRoutePaths.length;
          const double circleSize = 48;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                // Dulu Curves.easeOutBack -- lingkarannya sengaja LEWAT
                // dulu dari posisi targetnya baru mantul balik. Efeknya
                // kalau tab diketuk cepat berturut-turut (animasi baru
                // nimpa animasi lama yang belum selesai mantul), gerakannya
                // jadi kebalik-balik dan kelihatan kayak glitch, bukan
                // playful. easeOut polos -- geser lalu berhenti bersih,
                // nggak pernah lewat dari targetnya, jadi nggak ada apa
                // pun buat "dikoreksi balik" walau diketuk berkali-kali.
                curve: Curves.easeOut,
                left: safeIndex * slotWidth + (slotWidth - circleSize) / 2,
                top: (constraints.maxHeight - circleSize) / 2,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(kTabRoutePaths.length, (i) {
                  return SizedBox(
                    width: slotWidth,
                    child: _NavItem(
                      icon: _kNavIcons[i],
                      label: labels[i],
                      isActive: i == safeIndex,
                      onTap: () => context.go(kTabRoutePaths[i]),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Latar lingkarannya sekarang ditangani SATU widget di atas (yang
    // bergeser), jadi di sini cukup ikonnya doang -- warnanya masih
    // beda pas aktif/nggak, tapi nggak perlu dianimasikan sendiri lagi
    // karena lingkaran yang bergeser itu udah jadi penanda utamanya.
    //
    // Tooltip: Flutter otomatis munculinnya pas ikonnya DITEKAN LAMA
    // (long-press) -- tap biasa tetap langsung pindah tab kayak biasa,
    // nggak keganggu/tertunda oleh tooltip-nya.
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Icon(
            icon,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
            size: 24,
          ),
        ),
      ),
    );
  }
}
