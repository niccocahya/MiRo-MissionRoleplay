# Standar QA dan Keandalan

Aplikasi ini sudah dipakai dengan data nyata. Standar ini menjaga agar setiap perubahan tidak menambah crash, data dobel, atau data hilang.

Berlaku mulai Fase 1. Layar dari fase sebelumnya diperbaiki di Fase 9.

## 1. CI

- GitHub Actions berjalan di setiap push dan PR ke `dev-nicco` dan `master`.
- Langkahnya:
  - `flutter analyze` (tidak boleh naik dari `docs/LINT_BASELINE.md`, lewat `dart run tool/check_lint_baseline.dart`)
  - `flutter test` termasuk golden
  - build APK debug
- **Merge hanya jika hijau.**

## 2. Laporan crash (Sentry)

- Paket `sentry_flutter` (diizinkan).
- `sendDefaultPii: false`.
- Scrubbing wajib untuk nama anak, email, catatan refleksi, dan path foto, baik di event maupun breadcrumb.
- DSN dibaca lewat `--dart-define` (`SENTRY_DSN`), tidak pernah ditulis di kode. DSN kosong = app tetap jalan tanpa Sentry.
- Pasang `FlutterError.onError` dan `PlatformDispatcher.instance.onError`.
- Tanpa session replay dan tanpa screenshot otomatis (bisa merekam wajah dan nama anak).

## 3. Parsing data tahan banting

- Semua model `fromJson` tahan terhadap nilai `null` dan tipe yang berbeda dari data lama (`int`/`String`/`double`), dengan fallback yang masuk akal.
- Tidak ada `as String` atau `!` langsung pada data dari database.
- Setiap model punya unit test parsing dengan contoh baris berbentuk data lama.

## 4. Error handling

- Setiap aksi async memakai `try`/`catch` dengan pesan ramah ke pengguna.
- **Dilarang `catch` kosong.**
- Error dicatat ke Sentry tanpa data anak.

## 5. Cegah aksi ganda

- Tombol yang memicu tulisan ke server menjadi `loading` dan nonaktif sampai selesai.
- RPC `complete_mission_run` **idempoten** berdasarkan `run_id` dari klien, sehingga ketuk dua kali tidak menyimpan data dobel.

## 6. State lifecycle

- Aplikasi di-kill di tengah misi lalu dibuka lagi tidak boleh kehilangan langkah atau foto (draft tersimpan).
- Uji juga pergantian hari saat aplikasi sedang terbuka.

## 7. Checklist uji manual per fase

Dilakukan di HP sungguhan. Hasilnya ditulis di `docs/PROGRESS.md`.

- [ ] Android kelas bawah
- [ ] Android biasa
- [ ] iPhone (jika ada)
- [ ] Mode offline
- [ ] Kill app di tengah misi
- [ ] Teks sistem paling besar
- [ ] Bahasa EN
- [ ] Akun lama yang punya riwayat
- [ ] Akun baru
- [ ] Dua anak sekaligus

## 8. Rilis

Lewat **internal testing track** Play Console dulu, baru rilis bertahap.

## 9. Definition of Done tambahan

- Nol overflow.
- Nol exception tak tertangani di log selama checklist manual.
