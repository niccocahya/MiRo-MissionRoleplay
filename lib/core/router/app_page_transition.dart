import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Transisi halaman standar di seluruh app: fade + naik sedikit dari bawah,
/// 260ms, easeOutCubic. Dulu transisi antar layar nggak konsisten — rute
/// lewat GoRouter pakai transisi default Material, sementara alur misi &
/// sertifikat pakai `MaterialPageRoute` biasa lewat `Navigator.push` di 10
/// tempat berbeda, dan beberapa malah nggak ke-set transisi apa-apa sama
/// sekali pas pindah tab (potongan kasar). Sekarang satu fungsi ini dipakai
/// di mana-mana — baik lewat [GoRoute.pageBuilder] maupun [appPageRoute]
/// buat `Navigator.push` manual — biar berasa jadi satu app yang sama.
const Duration kPageTransitionDuration = Duration(milliseconds: 260);

Widget _transitionBuilder(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// Dipakai sebagai `pageBuilder` untuk `GoRoute`.
CustomTransitionPage<T> appPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: kPageTransitionDuration,
    reverseTransitionDuration: kPageTransitionDuration,
    transitionsBuilder: _transitionBuilder,
  );
}

/// Dipakai sebagai pengganti `MaterialPageRoute` untuk `Navigator.push` /
/// `Navigator.pushReplacement` manual (alur misi, sertifikat, dll — layar
/// fullscreen yang sengaja lompat keluar dari bottom nav bar).
PageRoute<T> appPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: kPageTransitionDuration,
    reverseTransitionDuration: kPageTransitionDuration,
    transitionsBuilder: _transitionBuilder,
  );
}
