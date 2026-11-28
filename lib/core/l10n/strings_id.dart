/// Kamus Bahasa Indonesia. Kunci dikelompokkan per area dengan awalan
/// (`common.`, `nav.`, `onboarding.`, …). Teks persis dari mockup
/// (`design/source/*.html`). Setiap kunci di sini wajib ada juga di
/// `strings_en.dart` (dicek oleh `test/core/l10n/strings_test.dart`).
const Map<String, String> kStringsId = {
  // Umum
  'common.next': 'LANJUT',
  'common.save': 'SIMPAN',
  'common.back': 'Kembali',
  'common.close': 'Tutup',
  'common.later': 'Nanti saja',
  'common.skip': 'Lewati',
  'common.retry': 'Coba lagi',
  'common.loading': 'Memuat',
  'common.errorTitle': 'Ada yang tidak beres',
  'common.errorBody': 'Coba lagi sebentar lagi. Datamu aman.',

  // Navigasi bawah (DECISIONS B2)
  'nav.adventure': 'Petualangan',
  'nav.challenges': 'Tantangan',
  'nav.memories': 'Memori',
  'nav.profile': 'Profil',

  // Field
  'field.showPassword': 'Tampilkan kata sandi',
  'field.hidePassword': 'Sembunyikan kata sandi',

  // Onboarding
  'onboarding.stepOf': 'Langkah {n} dari {total}',

  // Top bar
  'topbar.switchProfile': 'Ganti anak: {name}',
  'topbar.fish': '{n} ikan',
  'topbar.search': 'Cari misi',
  'topbar.notifications': 'Notifikasi',

  // Galeri debug
  'dev.galleryTitle': 'Galeri widget',
  'dev.reduceMotion': 'Kurangi animasi',
};
