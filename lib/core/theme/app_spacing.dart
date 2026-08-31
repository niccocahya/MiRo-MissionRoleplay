/// Skala spacing (padding/gap) — kelipatan 4, dipakai di semua layar biar
/// jarak antar elemen konsisten. Contoh: `SizedBox(height: AppSpacing.md)`.
abstract class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

/// Skala border radius — dulu tiap layar pakai angka radius sendiri-sendiri
/// (6, 10, 12, 14, 16, 20, 24, 28, 30, 32, 36...). Sekarang cuma 5 pilihan.
abstract class AppRadius {
  static const sm = 10.0; // input field, chip kecil
  static const md = 16.0; // card kecil, tombol
  static const lg = 24.0; // card besar, sheet
  static const xl = 30.0; // tombol CTA utama, image besar
  static const pill = 999.0; // progress bar, badge bulat penuh
}
