# Standar Kualitas Kode (Flutter)

## 1. Konvensi

| Hal | Aturan |
|---|---|
| Lint | `flutter_lints` + aturan tambahan di `analysis_options.yaml`: `prefer_const_constructors`, `prefer_final_locals`, `avoid_print`, `require_trailing_commas`, `use_build_context_synchronously`, `always_declare_return_types` |
| Format | `dart format .` sebelum commit |
| Nama | Kelas `PascalCase`, file `snake_case.dart`, variabel/fungsi `camelCase`, konstanta `kCamelCase` |
| Identitas kode | Bahasa Inggris. Teks UI lewat kamus ID/EN |
| Ukuran | Layar ≤ ±250 baris, widget ≤ ±150 baris, fungsi ≤ ±40 baris |
| Komentar | Jelaskan *kenapa*, rujuk nomor layar atau dokumen: `// HANDOFF 33: fokus awal di tombol aman`. Komentar panjang ala log perubahan di kode lama diringkas saat file disentuh |
| `print` | Dilarang. Pakai `debugPrint` di `kDebugMode` saja, tanpa data anak |
| `BuildContext` | Tidak dipakai setelah `await` tanpa cek `context.mounted` |

## 2. Logika murni dan unit test

`lib/core/game/` berisi fungsi tanpa efek samping, masing-masing dengan tes di `test/core/game/`.

| Fungsi | Kasus wajib |
|---|---|
| `xpForLevel(n)` | `40 + 20 × (n − 1)`; level 1, 2, 7, 50 |
| `levelFromXp(total)` | tepat di batas, satu di bawah, 0 |
| `applyMissionRun(...)` | XP ke **setiap** peserta, tidak dibagi; misi sempurna; Misi Puncak 60 |
| `nextStreak(days, goal, today)` | hari pertama, lanjut, terlewat dengan pembeku, tanpa pembeku, pergantian hari Asia/Jakarta, tengah malam |
| `canRestoreStreak(...)` | ≤ 24 jam, ikan cukup/kurang |
| `awardBadges(...)` | naik tier, tidak memberi dua kali |
| `recommendRole(...)` | skill fokus terendah, mode "Semua anak" memakai irisan usia |
| `classStatsVisible(sessions)` | < 3 → tersembunyi |

Cakupan `lib/core/game/` ≥ 90% (`flutter test --coverage`).

## 3. Widget dan golden test

- Setiap widget di `lib/shared/widgets/` punya widget test perilaku (ketuk, disabled, semantik) dan **golden test** di 390 lebar.
- Setiap layar yang selesai punya golden test 390×844 dengan data palsu (repository fake), disimpan di `test/goldens/NN-nama.png`, lalu **dibandingkan manual sekali** dengan `design/screens/NN-*.png` sebelum golden pertama dikunci.
- Golden dijalankan dengan font Nunito yang dimuat di test (`loadFonts` dari aset), `disableAnimations: true`, dan `devicePixelRatio: 2`.
- Ubah golden (`--update-goldens`) hanya jika desain memang berubah, dan sebutkan di commit.

## 4. Integration test (`integration_test/`)

Alur wajib (pakai repository fake atau project Supabase staging, bukan produksi):
1. Onboarding orang tua sampai Beranda (14 → 23 → 01 → 15 → 16 → 24 → 25 → 26 → 27 → 17 → 28 → 02)
2. Misi lengkap dua anak (02 → 18 → 03 → 04 → 07 → 05 → 08 → 21/31 → 02)
3. Keluar misi di tengah (04 → 33 → 02)
4. Onboarding guru dan misi kelas (01 → 15 → 29 → 17 → 28 → 12 → 13 → 04 → 51 → 05)
5. Hapus anak (36 → 39 → 40)
6. Offline: selesaikan misi tanpa jaringan, lalu sinkron

## 5. Git

- Branch per fase: `feat/phase-1-widgets`, perbaikan `fix/streak-midnight`.
- Commit kecil dengan format conventional: `feat(adventure): kartu Misi Puncak`.
- Satu PR = satu tujuan, sertakan screenshot sebelum/sesudah untuk UI.
- Migrasi Supabase di commit terpisah, dengan catatan cara menjalankannya.
- `master` selalu bisa di-build dan dijalankan.

## 6. Checklist review

- [ ] Memakai widget katalog, tidak ada dekorasi duplikat (COMPONENTS §6)
- [ ] Tanpa `Color(0x…)`, radius, `Duration` lepas di luar token/ikon
- [ ] Tanpa emoji
- [ ] Semua state ada: loading, error, kosong, disabled, pressed
- [ ] Semantik: label tombol ikon, urutan fokus
- [ ] Tidak ada data anak di log
- [ ] Migrasi aman untuk data lama (kolom baru nullable atau punya default)
- [ ] Unit test untuk logika baru, golden untuk widget/layar baru

## 7. Definition of Done

Sebuah layar dianggap selesai jika:

- [ ] Sama dengan `design/screens/NN-*.png` di 390×844 (jarak, warna, ukuran font, copy)
- [ ] Rapi di semua ukuran `RESPONSIVE.md` §1; golden di 360×640, 390×844, 430×932, dan 390×844 dengan teks 1.3× (`RESPONSIVE.md` §10)
- [ ] Nol overflow dan nol exception tak tertangani (`QA.md` §9)
- [ ] Aksi tulis ke server: loading + nonaktif sampai selesai, `try`/`catch` dengan pesan ramah, tidak ada `catch` kosong (`QA.md` §4, §5)
- [ ] Model baru: `fromJson` tahan data lama + unit test parsing (`QA.md` §3)
- [ ] Memakai widget katalog; widget baru terdaftar dan ada di galeri
- [ ] Semua state di HANDOFF diimplementasikan
- [ ] Animasi sesuai ANIMATION §6, "Kurangi animasi" diuji
- [ ] Target sentuh ≥ 44, semantik lengkap, kontras lolos
- [ ] `flutter analyze` bersih, `flutter test` hijau, golden terkunci
- [ ] Grep hex dan emoji kosong
- [ ] Data lama tetap tampil benar (uji dengan akun uji coba yang sudah punya riwayat)
