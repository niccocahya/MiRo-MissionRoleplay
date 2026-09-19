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

// Indeks tab TERAKHIR yang di-build lewat appTabPage() -- dibandingin
// tiap kali tab baru dibuka buat nentuin arah geser (kanan kalau
// indeksnya lebih besar dari sebelumnya, kiri kalau lebih kecil).
// Aman ditaruh di level module (bukan Riverpod/State) karena `router`
// itu singleton stabil (lihat app_router.dart) -- pageBuilder cuma
// beneran dipanggil ulang pas ganti rute sungguhan, bukan tiap kali
// MyApp rebuild (ganti bahasa/ukuran teks, dst).
int _lastTabIndex = 0;

/// Dipakai sebagai `pageBuilder` KHUSUS 4 tab navbar bawah (Home/Misi/
/// Progress/Profil) -- dulu transisinya sama persis kayak semua layar
/// lain (fade + naik dikit dari bawah), jadi pindah antar-tab kerasa
/// kayak buka halaman baru, bukan geser di antara "halaman-halaman"
/// yang posisinya sejajar. Sekarang halaman tujuan geser masuk dari
/// KANAN kalau tabnya lebih ke kanan di navbar (mis. Home -> Profil),
/// atau dari KIRI kalau sebaliknya -- konsisten arahnya kayak swipe
/// antar-halaman, bukan cuma satu arah fix.
CustomTransitionPage<T> appTabPage<T>({
  required LocalKey key,
  required Widget child,
  required int tabIndex,
}) {
  final bool changed = tabIndex != _lastTabIndex;
  final int direction = !changed ? 0 : (tabIndex > _lastTabIndex ? 1 : -1);
  _lastTabIndex = tabIndex;

  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: kPageTransitionDuration,
    reverseTransitionDuration: kPageTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // direction == 0 -- tab yang sama dibangun ulang (mis. deep link
      // langsung ke tab ini pas app pertama dibuka) -- pakai transisi
      // fade+naik yang netral, bukan geser ke arah yang nggak jelas.
      if (direction == 0) {
        return _transitionBuilder(context, animation, secondaryAnimation, child);
      }
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final curvedSecondary = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOutCubic);
      return SlideTransition(
        // Halaman BARU masuk dari kanan (direction 1) atau kiri (-1).
        position: Tween<Offset>(
          begin: Offset(direction.toDouble(), 0),
          end: Offset.zero,
        ).animate(curved),
        child: SlideTransition(
          // Halaman LAMA ikut kegeser ke arah berlawanan (bukan diam di
          // tempat) -- biar kerasa satu gerakan geser, bukan halaman
          // baru numpuk di atas halaman lama yang diam.
          position: Tween<Offset>(
            begin: Offset.zero,
            end: Offset(-direction.toDouble(), 0),
          ).animate(curvedSecondary),
          child: child,
        ),
      );
    },
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
