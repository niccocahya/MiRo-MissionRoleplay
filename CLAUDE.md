# MiRO: panduan kerja untuk Claude Code (Flutter)

MiRO adalah aplikasi **Flutter** (Android dan iOS) untuk **orang tua dan guru** yang memandu **misi bermain peran tanpa gawai** untuk anak 2 sampai 10 tahun. Backend **Supabase** yang sudah berjalan. HP dipegang orang dewasa; anak bermain di dunia nyata.

Aplikasi ini **sudah ada dan sudah dipakai untuk uji coba** (±22 ribu baris Dart, data nyata di Supabase). Tugasmu adalah **redesign dan perluasan bertahap** mengikuti desain v2 (54 layar), bukan menulis ulang dari nol. Data pengguna yang sudah ada tidak boleh rusak.

## Baca dulu sebelum menulis kode

| Urutan | File | Isi |
|---|---|---|
| 0 | `docs/DECISIONS.md` | Keputusan final, termasuk cara menggabungkan fitur lama dengan desain baru. **Prioritas tertinggi** |
| 1 | `docs/README.md` | Peta dokumen |
| 2 | `docs/PRD.md` | Apa yang dibangun dan kenapa, aturan bisnis |
| 3 | `docs/DESIGN_SYSTEM.md` §0 sampai §12 | Token, komponen, motion, copy (§13 versi web tidak berlaku; diganti `docs/standards/`) |
| 4 | `docs/HANDOFF.md` | Spesifikasi per layar (01 sampai 54) |
| 5 | `docs/standards/*.md` | Arsitektur, widget, animasi, UX, keamanan, performa, kualitas kode, desain |
| 6 | `design/SCREENS.md` | Nomor layar → route go_router → file Dart → widget → fase |
| 7 | `design/screens/NN-Nama.png` | Gambar final tiap layar (390×844 @2x) |
| 8 | `design/source/NN-Nama.html` | Sumber mockup: nilai px, warna, dan copy yang persis (1 px CSS = 1 logical pixel Flutter) |

Urutan kebenaran jika bertentangan: `DECISIONS.md` > gambar layar > `HANDOFF.md` > `DESIGN_SYSTEM.md` > `PRD.md`. Laporkan konflik baru, jangan diam-diam memilih.

## Stack (sudah terpasang, jangan diganti)

- Flutter 3.x, Dart 3, **Riverpod 3** (`flutter_riverpod`, `hooks_riverpod`), **go_router**
- `supabase_flutter` (Auth, Postgres + RLS, Storage, Edge Functions)
- `google_fonts` (Nunito, dibundel sebagai aset), `fl_chart`, `confetti`, `image_picker`, `share_plus`, `gal`, `pdf`, `printing`, `flutter_tts`, `cached_network_image`, `shared_preferences`
- Tambahan yang diizinkan: `phosphor_flutter` (ikon), `flutter_svg` (ikon game kustom), `flutter_image_compress` (kompres + hapus EXIF). Paket lain butuh alasan tertulis.

## Perintah

```bash
flutter pub get
flutter run --dart-define-from-file=env.json      # wajib, lihat env.example.json
flutter analyze
flutter test                                      # unit + widget + golden
flutter test --update-goldens                     # hanya saat desain memang berubah
flutter test integration_test                     # alur ujung ke ujung
dart run flutter_launcher_icons
```

## Aturan yang tidak boleh dilanggar

1. **Tanpa `Color(0xFF…)`, angka radius, atau `Duration` lepas di widget.** Semua dari `lib/core/theme/miro_tokens.dart`. Pengecualian: warna ilustrasi di `lib/shared/icons/**`.
2. **Tanpa emoji** di UI dan copy (termasuk `feeling_emojis.dart` dan `emoji` di `skills.dart`: diganti ikon). Ikon dari `phosphor_flutter` atau `lib/shared/icons/`.
3. **Pakai widget yang sudah ada.** Cek `docs/standards/COMPONENTS.md` sebelum membuat widget baru. Jangan menyalin dekorasi kartu, tombol, atau sheet ke halaman.
4. **Satu tombol utama per layar**, di `MiroStickyFooter`.
5. **Animasi hanya transform dan opacity** (scale, translate, rotate, fade), durasi dari `MiroMotion`, hormati "Kurangi animasi". Lihat `docs/standards/ANIMATION.md`.
6. **Data anak minimal dan privat.** Tidak ada nama murid di akun Guru. Tidak ada data anak di log atau analytics. Lihat `docs/standards/SECURITY_PRIVACY.md`.
7. **Jangan merusak data lama.** Perubahan skema lewat migrasi SQL di `supabase/migrations/` yang aman untuk baris lama. Jangan pernah menghapus kolom atau tabel yang masih dibaca kode.
8. **Tanpa ciri "AI slop"**: tidak ada `·` atau `—` sebagai pemisah, tidak ada eyebrow huruf kapital renggang, tidak ada kartu harga gaya SaaS, tidak ada daftar fitur bercentang, tidak ada gradien acak. Detail di `docs/standards/DESIGN.md` §6.
9. **Logika gamifikasi (XP, level, streak, lencana, rekomendasi) adalah fungsi Dart murni** di `lib/core/game/` dengan unit test.
10. File layar maksimal ±250 baris. File lama yang lebih dari itu dipecah saat disentuh.
11. Semua teks lewat `context.tr('key')` (kamus ID/EN yang sudah ada). Akun Guru mengganti istilah otomatis.

## Cara kerja per tugas

1. Baca layar terkait di `design/screens/` dan `design/source/`, plus bagian `HANDOFF.md`-nya, plus file Dart lama yang sedang diganti.
2. Tulis rencana singkat: widget yang dipakai ulang, widget baru (dan alasannya), provider/data, apakah butuh migrasi.
3. Implementasikan. Widget baru masuk `lib/shared/widgets/` dan ke galeri (`/dev/gallery`, hanya debug).
4. Verifikasi:
   - `flutter analyze` tanpa warning, `flutter test` hijau
   - golden test layar itu di 390×844 dan bandingkan dengan `design/screens/`; selisih yang terlihat diperbaiki atau dilaporkan
   - `grep -rn "Color(0x" lib --include=*.dart | grep -v "lib/shared/icons\|miro_tokens.dart"` kosong
   - uji dengan "Kurangi animasi" aktif dan teks diperbesar 1.3×
5. Ringkas hasilnya: apa yang selesai, apa yang menyimpang dan kenapa, langkah manual (misalnya migrasi Supabase yang harus dijalankan).

## Definition of Done

Ikuti `docs/standards/CODE_QUALITY.md` §Definition of Done.
