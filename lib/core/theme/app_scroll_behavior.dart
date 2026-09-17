import 'package:flutter/material.dart';

/// Sebelumnya nggak ada scrollbar yang keliatan sama sekali di halaman
/// panjang (ListView/SingleChildScrollView) -- Flutter di Android emang
/// nyembunyiin scrollbar-nya sampai lagi discroll doang, jadi orang tua
/// nggak punya petunjuk visual "halaman ini masih ada lanjutannya di
/// bawah" sebelum mulai gesek. Dipasang SEKALI di sini lewat
/// `scrollBehavior` MaterialApp (bukan nempelin widget `Scrollbar` manual
/// ke tiap ListView satu-satu di puluhan file) -- otomatis kepakai di
/// SELURUH scrollable app, termasuk yang nanti ditambah di masa depan.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Cuma arah VERTIKAL -- beberapa layar (mis. carousel sub-langkah
    // misi) pakai PageView horizontal, yang scrollbar-nya bakal keliatan
    // aneh/nggak perlu (geser antar-halaman penuh, bukan "ada konten
    // lanjutan" kayak scroll vertikal biasa).
    if (axisDirectionToAxis(details.direction) != Axis.vertical) {
      return child;
    }
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      radius: const Radius.circular(8),
      thickness: 5,
      child: child,
    );
  }
}
