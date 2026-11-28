# Progres Redesign MiRO v2

Catatan kerja per fase: apa yang selesai, selisih dari desain yang tersisa, keputusan yang diambil sendiri, dan hal yang perlu dicek Nic di HP.

## Status fase

| Fase | Status | Branch | Catatan |
|---|---|---|---|
| Dokumen | Selesai | `docs/v2-design-kit` (PR #1, merged) | Kit v2.1 Flutter, DECISIONS §F/§H, 5 skill, Mink |
| 0. Fondasi | Selesai | `feat/phase-0-foundation` | Lihat di bawah |
| Sentry (SDK) | Selesai | `chore/sentry-setup` | SDK terpasang; CLI/login menunggu kode handoff baru |
| 1. Widget | Belum | | |
| 2. Data dan logika | Belum | | Butuh baca skema produksi (lihat "Database") |
| 3 sampai 9 | Belum | | |

---

## Fase 0: Fondasi

### Selesai

- Paket baru (semua di daftar izin CLAUDE.md): `phosphor_flutter`, `flutter_svg`, `flutter_image_compress`, dev `integration_test`.
- Token: `design/miro_tokens.dart` → `lib/core/theme/miro_tokens.dart`. Satu perubahan: `MiroText` memakai `TextStyle(fontFamily: 'Nunito')`, bukan `GoogleFonts.nunito()` (lihat keputusan K1).
- Font Nunito 600/700/800/900 dibundel di `assets/google_fonts/`, didaftarkan sebagai keluarga font di pubspec. `GoogleFonts.config.allowRuntimeFetching = false` di `main.dart`. Poppins tidak dipakai lagi.
- `lib/core/theme/miro_theme.dart`: ThemeData dari token (Nunito, warna, input, sheet, `NoSplash`). Dipasang di `MaterialApp`.
- `AppColors`, `AppTextStyles`, `AppSpacing`/`AppRadius`, `AppTheme` lama sekarang alias ke token baru dan ditandai `@Deprecated` (dihapus di Fase 9). Layar lama langsung ikut Nunito dan palet v2.
- `assets/mascot/`, `assets/brand/`, `assets/google_fonts/` didaftarkan di pubspec.
- Ikon aplikasi diganti logo baru (`miro-launcher-1024.png`, adaptive foreground, latar `#FFE8B6`), dan `dart run flutter_launcher_icons` sudah dijalankan.
- `kMascotName = 'Mink'` di `lib/core/app_info.dart`.
- Struktur folder ARCHITECTURE §2 (folder kosong diberi `.gitkeep`).
- `analysis_options.yaml`: aturan CODE_QUALITY §1. Folder `design/` dikecualikan (file referensi, bukan kode app).
- **Kamus `context.tr`** (DECISIONS §H5): `lib/core/l10n/tr.dart` + `strings_id.dart` + `strings_en.dart`. Bahasa diturunkan lewat `MiroLocaleScope` (dipasang di `MaterialApp.router.builder` dari `languageProvider`). `{mascot}` otomatis diganti `kMascotName`. Tes memastikan kunci ID dan EN sama persis dan tidak ada pemisah `·`/`—`.
- **`docs/LINT_BASELINE.md`** + `tool/check_lint_baseline.dart`: baseline 252 temuan (semua `info` di file lama yang belum disentuh). Sebelum aturan baru: 0.
- `settingsProvider` (`lib/core/providers/settings_provider.dart`): `reduceMotion` (null = ikut sistem) dan `haptics`, disimpan di `shared_preferences`. Helper `reduceMotionOf(context, ref)`.
- Route debug `/dev/gallery` (hanya `kDebugMode`), isi judul dulu.
- Helper test `test/helpers/golden.dart`:
  - 390×844, DPR 2, Nunito dimuat dari aset (`test/flutter_test_config.dart`), animasi dimatikan.
  - **Overflow = tes gagal** (`OverflowGuard`, RESPONSIVE §10). Sudah diuji dengan tes yang sengaja overflow: gagal dengan pesan "A RenderFlex overflowed by 540 pixels".
  - `goldenMatrix()`: golden 360×640, 390×844, 430×932, dan 390×844 teks 1.3× (RESPONSIVE §10). Dipakai mulai Fase 1.
  - Golden contoh `test/goldens/00-tokens.png` (tipografi + warna token).
- **CI** `.github/workflows/ci.yml` (QA §1): lint baseline, `flutter test`, build APK debug, di push/PR ke `dev-nicco` dan `master`. Runner Windows supaya golden (dibuat di Windows) tidak berbeda render.
- `test/widget_test.dart` (tes counter template Flutter yang tidak pernah relevan dan selalu gagal) dihapus, diganti tes nyata.
- Dokumen: `docs/standards/RESPONSIVE.md` dan `docs/standards/QA.md`, dirujuk dari CLAUDE.md, CODE_QUALITY §7, dan docs/README.md.

### Verifikasi

- `flutter analyze`: 252 temuan = baseline, 0 warning, 0 error. File baru/yang disentuh bersih.
- `flutter test`: 7 tes hijau.

### Selisih dari desain

Belum ada layar baru di fase ini. Layar lama memakai Nunito dan palet v2 lewat alias, tetapi tata letaknya masih lama (wajar, diganti mulai Fase 3).

### Perlu dicek di HP

- [ ] App terbuka dan **semua layar lama** masih bisa dibuka (Home, Misi, Progres, Profil, Notifikasi, onboarding).
- [ ] Teks sudah Nunito di semua layar; tidak ada teks yang hilang/kotak (bobot 400/500 lama jatuh ke 600).
- [ ] Warna aksen tombol sedikit lebih gelap (coral 600) demi kontras; cek tidak ada teks yang jadi sulit dibaca.
- [ ] Ikon aplikasi baru di launcher (logo MiRO di kotak krem). Ikon lama di HP mungkin perlu uninstall dulu agar terganti.
- [ ] Ganti bahasa ID/EN masih jalan.

### Uji manual (QA §7)

Belum dijalankan; dilakukan Nic di HP. Hasil ditulis di sini.

---

## Sentry (laporan crash)

### Selesai (SDK, `chore/sentry-setup`)

- Paket `sentry_flutter` (diizinkan, CLAUDE.md). Versi yang cocok dengan dependensi sekarang: 8.14.x.
- `lib/core/services/crash_reporting.dart` (QA §2):
  - DSN hanya dari `String.fromEnvironment('SENTRY_DSN')`; **tidak ada DSN di kode**.
  - **DSN kosong atau build debug → Sentry tidak dinyalakan**, app jalan normal. Handler `FlutterError.onError` dan `PlatformDispatcher.instance.onError` tetap dipasang (fallback) supaya error tidak hilang diam-diam dan app tidak tertutup.
  - Di release dengan DSN: Sentry memasang kedua handler itu sendiri. `sendDefaultPii = false`, `tracesSampleRate = 0.1`, tanpa screenshot, tanpa thread, **session replay dan view hierarchy tidak disentuh (default mati)**.
  - `beforeSend` dan `beforeBreadcrumb` men-scrub: email, URL/path foto (Storage dan file lokal), query string URL REST, nama anak yang didaftarkan, dan nilai kunci sensitif (`name`, `nickname`, `note`, `email`, `photo_url`, `path`, `url`, dst.). Data pengguna di event dikosongkan.
  - `CrashReporting.report(error, stack)` untuk error yang sudah ditangani di `catch` (dipakai mulai Fase 1).
- Nama anak didaftarkan untuk scrubbing setiap kali `childrenListProvider` memuat data (`child_provider.dart`).
- `main.dart`: `runApp` dijalankan lewat `CrashReporting.run`.
- `SENTRY_DSN` ditambahkan ke `env.example.json` (kosong) dan `env.json` lokal (kosong, belum ada DSN).
- Tes: `test/core/services/crash_reporting_test.dart` (6 kasus scrubbing).

### File lain yang berubah

Wizard Sentry **tidak** berjalan (kode handoff kedaluwarsa), jadi tidak ada perubahan gradle, `Info.plist`, atau konfigurasi native. Yang berubah hanya file registrasi plugin yang di-generate otomatis oleh `flutter pub add` (`linux/`, `macos/`, `windows/` `generated_plugin*`) dan `pubspec.yaml`/`pubspec.lock`.

### Belum (butuh Nic)

- **Kode handoff Sentry kedaluwarsa** (berlaku 5 menit; installer baru jalan setelah Fase 0 selesai). Login CLI, pembuatan project, dan auth token upload debug symbols belum dilakukan.
- Setelah ada DSN: isi `SENTRY_DSN` di `env.json`, build release, lalu picu satu error uji untuk memastikan event masuk tanpa data anak.
- Auth token Sentry (upload debug symbols) hanya sebagai secret lokal/CI (`SENTRY_AUTH_TOKEN`), tidak di-commit.

### Catatan keamanan

`env.json` lokal masih berisi `GROQ_API_KEY`. Kode app tidak lagi membacanya (chat AI lewat Edge Function `mink-chat`), dan SECURITY_PRIVACY §3 melarang kunci Groq di app. **Saran: hapus baris itu dari `env.json`** supaya tidak ikut terbawa ke build. Nilainya tidak kusentuh.

---

## Keputusan yang kuambil

| # | Fase | Keputusan | Alasan |
|---|---|---|---|
| K1 | 0 | Nunito didaftarkan sebagai keluarga font di pubspec dan dipakai lewat `fontFamily`, bukan `GoogleFonts.nunito()`. File tetap di `assets/google_fonts/`. | Layar lama memakai bobot 400/500. Dengan `allowRuntimeFetching = false`, `google_fonts` gagal memuat bobot yang tidak dibundel; keluarga font pubspec otomatis memakai bobot terdekat. Hasil sama, tanpa risiko gagal muat. |
| K2 | 0 | `AppColors.accent` dipetakan ke `coral600`, bukan `coral500`. | DESIGN_SYSTEM §1.5: teks putih di atas coral harus `coral600` (kontras AA). `accent` dipakai sebagai latar tombol. |
| K3 | 0 | Bobot di `AppTextStyles` lama dinaikkan minimal 600. | DESIGN_SYSTEM §2.3: body tidak pernah di bawah 600. |
| K4 | 0 | `AppRadius` lama dipetakan ke radius v2 terdekat (10→12, 30→28). | Tidak ada token persis; perubahan kecil dan sesuai v2. |
| K5 | 0 | Bahasa default kamus `context.tr` saat tidak ada `MiroLocaleScope` = `id`. | Bahasa utama produk. Di app sungguhan scope selalu terpasang. |
| K6 | 0 | `design/**` dikecualikan dari `flutter analyze`. | `design/miro_tokens.dart` adalah file referensi, bukan kode app; ikut dianalisis membuat baseline tidak akurat. |
| K7 | 0 | CI memakai runner Windows. | Golden dibuat di Windows; render font berbeda antar-OS membuat golden gagal palsu di Linux. |

---

## Database (Supabase)

### Status akses

- Supabase MCP yang sempat tersambung terputus di awal sesi otonom, sehingga skema produksi **belum bisa dibaca** dan branch/project staging **belum bisa dibuat** dari sini.
- Supabase CLI tersedia lewat `npx supabase` (v3.4) tetapi belum login.
- Pekerjaan yang tidak butuh database (widget, layar dengan repository fake) tetap jalan.

### Langkah manual (jika akses otomatis tetap tidak ada di Fase 2)

1. Login CLI di mesin ini: `npx supabase login`, lalu `npx supabase link --project-ref <ref produksi>`.
2. Tarik skema produksi (read-only): `npx supabase db pull --schema public,storage` → menghasilkan file migrasi baseline. Ganti namanya menjadi `supabase/migrations/0000_baseline.sql`.
3. Buat project `miro-staging` di dashboard Supabase (region sama), simpan URL + anon key di `env.staging.json` (sudah di `.gitignore`).
4. Terapkan baseline + migrasi Fase 2 ke staging: `npx supabase db push --db-url <connection string staging>`.

### Pemetaan konsep → nama asli

Diisi di awal Fase 2 setelah skema produksi dibaca (catatan Nic: nama di DECISIONS §D dan contoh SQL hanyalah konsep). Yang sudah diketahui dari kode:

| Konsep di dokumen | Nama asli | Sumber |
|---|---|---|
| Account | `parents` (`parents.id` = `auth.uid()`) | `language_provider.dart`, `onboarding_page.dart` |
| Child | `children` | kode |
| XP anak | `children.total_xp` | §H6, `mission_journal_screen.dart` |
| Poin skill | `child_stats` (kolom per skill) | kode |
| Progres per peran | `child_role_progress.unlocked_level` | kode |
| Log misi | `mission_logs` (`status` `completed`/`replayed`, `earned_xp`, `earned_skills`) | kode |
| Foto jurnal | `journals` + bucket `mission-assets` (publik) | `storage_upload_service.dart` |
| Foto profil | bucket `user_photo` (publik) | `storage_upload_service.dart` |
| Bahasa akun | `parents.language_code` | `language_provider.dart` |
