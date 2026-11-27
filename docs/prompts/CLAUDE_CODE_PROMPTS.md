# Prompt untuk Claude Code (Flutter)

Cara pakai:
1. Pasang kit sesuai `PANDUAN_PASANG.md`, commit, push.
2. Buka terminal di folder repo Flutter (`MiRo-MissionRoleplay`), jalankan `claude`.
3. Kirim **Prompt 0** dulu. Lalu satu fase per sesi (`/clear` di antara fase).
4. Setelah tiap fase: `flutter run --dart-define-from-file=env.json` di HP, cek, commit. Jangan lanjut kalau fase ini belum hijau.

Aplikasi ini sudah dipakai uji coba. Setiap prompt mengingatkan Claude Code untuk tidak merusak data dan fitur yang sudah jalan.

---

## Prompt 0: Orientasi (wajib pertama)

```
Kamu akan me-redesign aplikasi Flutter MiRO mengikuti desain v2 yang sudah final. Aplikasi ini SUDAH berjalan dengan data nyata di Supabase, jadi ini redesign bertahap, bukan tulis ulang.

Sebelum menulis kode:
1. Baca CLAUDE.md, docs/DECISIONS.md, docs/README.md, docs/PRD.md, semua file di docs/standards/, dan design/SCREENS.md.
2. Lihat gambar di design/screens/ (minimal 01, 02, 04, 05, 09, 12, 38).
3. Baca kode di lib/ secukupnya untuk memetakan: layar lama → layar baru (cek kolom "Menggantikan" di design/SCREENS.md), provider yang ada, tabel Supabase yang dipakai, widget di lib/shared/widgets/.
4. Cek pubspec.yaml dan analysis_options.yaml.

Lalu tulis di chat (jangan ubah file):
- Ringkasan produk 5 kalimat.
- Peta: fitur lama yang tetap jalan, yang berubah, yang baru (sesuai DECISIONS §B).
- Risiko terbesar terhadap data/fitur yang sudah ada, dan cara mencegahnya.
- Konflik dokumen yang belum tercakup DECISIONS.md.
- Pertanyaan untukku, maksimal 5.
```

---

## Prompt Fase 0: Fondasi

```
Kerjakan Fase 0 di branch feat/phase-0-foundation (dari dev-nicco).

Tujuan: fondasi visual siap, aplikasi lama tetap bisa jalan.

1. Tambah paket: phosphor_flutter, flutter_svg, flutter_image_compress. Dev: golden test bawaan flutter_test sudah cukup; tambah integration_test (sdk).
2. Salin design/miro_tokens.dart ke lib/core/theme/miro_tokens.dart. Perbaiki bila ada error kompilasi dan jelaskan.
3. Font: unduh Nunito (600, 700, 800, 900) ke assets/google_fonts/, daftarkan di pubspec, set GoogleFonts.config.allowRuntimeFetching = false di main.dart. Poppins tidak dipakai lagi.
4. Buat lib/core/theme/miro_theme.dart (ThemeData dari token: scaffoldBackgroundColor, textTheme Nunito, inputDecorationTheme, bottomSheetTheme, splashFactory NoSplash karena kita pakai lip). Pasang di MaterialApp.
5. Arahkan AppColors/AppTextStyles/AppSpacing lama ke token baru (alias) supaya layar lama langsung ikut Nunito dan warna baru tanpa rusak. Tandai @Deprecated.
6. Daftarkan assets/mascot/ dan assets/brand/ di pubspec.
7. Ikon aplikasi: perbarui konfigurasi flutter_launcher_icons ke assets/brand/miro-launcher-1024.png, adaptive foreground assets/brand/miro-adaptive-foreground-1024.png, background #FFE8B6. Jalankan dart run flutter_launcher_icons.
8. lib/core/app_info.dart: tambah kMascotName = 'Maro' (DECISIONS F1).
9. Buat struktur folder kosong sesuai docs/standards/ARCHITECTURE.md §2.
10. analysis_options.yaml: aturan dari CODE_QUALITY §1.
11. Siapkan golden test: helper test/helpers/golden.dart (ukuran 390x844, DPR 2, load font Nunito dari aset, disableAnimations) + satu golden contoh.
12. Route debug /dev/gallery (hanya kDebugMode), isinya judul saja dulu.
13. Settings: tambahkan reduceMotion ke provider pengaturan (default ikut sistem) bila belum ada.

Verifikasi: flutter analyze bersih (warning lama boleh dicatat), flutter test hijau, app jalan di HP dan semua layar lama masih bisa dibuka.
Laporkan file yang diubah, keputusan, dan hal yang perlu aku cek di HP.
```

---

## Prompt Fase 1: Widget

```
Kerjakan Fase 1 di branch feat/phase-1-widgets.

Tujuan: semua widget di docs/standards/COMPONENTS.md §5.1, §5.2, §5.4, helper animasi (ANIMATION §2: MiroRise, MiroPopIn, MiroFloat, MiroPulse, Odometer), dan MaroImage/SpeechBubble/MaroTip selesai dengan semua varian dan state, tampil di /dev/gallery.

Aturan:
- Mulai dari MiroPressable (COMPONENTS §3.1), lalu MiroButton, MiroCard, ChoiceCard, dst.
- Ukuran/warna/radius/lip diambil dari design/source/*.html (1 px = 1 logical px). Rujukan: MiroButton → 01-TipeAkun dan 33-KonfirmasiKeluar; ChoiceCard → 24-Kesukaan; MiroSheet → 19-GantiAnak; MiroListGroup/MiroSwitch → 37-Pengaturan; MiroTextField error → 15-Masuk; MiroStepper → 13-GuruPeserta; SegmentBar → 04-Misi; CodeBoxes → 41-UndangPendamping.
- Widget baru menggantikan widget lama di lib/shared/widgets/ (app_button, app_card, app_choice_chip, app_bottom_sheet, step_progress_bar, child_avatar, custom_bottom_nav_bar, back_button, app_screen_header). Jangan hapus file lama dulu; tandai @Deprecated dan arahkan ke yang baru bila bisa.
- Semua helper animasi membaca "kurangi animasi" sendiri.
- Tidak ada Color(0x...) di luar token dan lib/shared/icons/.

Verifikasi:
- Widget test + golden untuk setiap widget (CODE_QUALITY §3).
- Bandingkan golden tombol, ChoiceCard, sheet, list dengan design/screens dan perbaiki selisihnya.
- Uji TalkBack di galeri: semua tombol terbaca.
Laporkan widget yang selesai dan yang menyimpang dari katalog.
```

---

## Prompt Fase 2: Data dan logika

```
Kerjakan Fase 2 di branch feat/phase-2-data.

1. Tarik skema Supabase sekarang ke supabase/migrations/0000_baseline.sql (supabase db pull, atau beri aku langkah ekspor manual jika CLI belum terhubung). JANGAN mengubah apa pun di database produksi pada langkah ini.
2. Tulis migrasi tambahan sesuai DECISIONS §D.3 sebagai file terpisah bernomor. Semua kolom baru nullable atau punya default, aman untuk baris lama. RLS + policy untuk setiap tabel baru (SECURITY_PRIVACY §3). Jangan jalankan ke produksi; beri aku instruksi menjalankannya di project staging dulu.
3. lib/core/game/: xp.dart, level.dart (rumus baru DECISIONS B4), streak.dart (per akun, DECISIONS B5), badges.dart, quests.dart, recommend.dart, class_stats.dart. Fungsi murni + tes, minimal kasus di CODE_QUALITY §2, cakupan ≥ 90%.
4. RPC complete_mission_run (SQL) dengan aturan yang sama persis, plus tes Dart yang memanggil RPC di project staging dan membandingkan hasilnya dengan lib/core/game untuk kasus yang sama.
5. Pecah supabase_repository.dart menjadi repository per domain (ARCHITECTURE §5) dengan model, tanpa mengubah perilaku layar lama. Buat versi Fake untuk tes.
6. accountProvider, activeProfileProvider, settingsProvider sesuai ARCHITECTURE §4.
7. Ganti emoji di skills.dart dan feeling_emojis.dart dengan nama ikon (render di Fase 1/3).

Verifikasi: flutter test hijau, app lama tetap jalan dengan data yang sama (level boleh berubah sesuai rumus baru). Laporkan migrasi yang perlu aku jalankan dan urutannya.
```

---

## Prompt Fase 3: Onboarding dan akun

```
Kerjakan Fase 3 di branch feat/phase-3-onboarding.

Layar: 14 Splash, 23 Bahasa, 01 Tipe akun, 15 Daftar/Masuk (+ akun terakhir, DECISIONS B14), 43 Lupa sandi, 16 Setup anak, 24, 25, 26, 27, 17 Target harian, 28 Izin notifikasi.

Untuk setiap layar: baca design/screens/NN-*.png, design/source/NN-*.html, bagian HANDOFF-nya, dan file lama di kolom "Menggantikan" (design/SCREENS.md). Susun dari widget katalog.

- Route baru sesuai ARCHITECTURE §3 + redirect §3.1. Route lama (/onboarding, /identify) diarahkan ke yang baru.
- Data setup anak disimpan ke tabel yang sama seperti sekarang (questionnaires dkk) lewat repository, dengan pemetaan DECISIONS B15.
- Pilihan tipe akun Guru membuka 29 (Fase 7); di fase ini cukup simpan account_type dan tampilkan 29 sebagai placeholder sederhana.
- Semua state: tombol LANJUT nonaktif sampai input wajib terisi, error inline, batas pilihan maks 3 dengan shake.

Verifikasi: golden tiap layar dibandingkan dengan design/screens; integration test alur 1 (CODE_QUALITY §4) dengan repository fake; uji di HP dengan akun baru dan akun lama (akun lama harus langsung masuk ke Beranda, tidak disuruh onboarding ulang).
```

---

## Prompt Fase 4: Loop inti misi

```
Kerjakan Fase 4 di branch feat/phase-4-core-loop.

Layar: navigasi 4 tab baru (DECISIONS B2), 02 Beranda (+48 pengguna baru, + ikon cari → layar cari misi lama di-restyle), 11 Kalender streak, 19 Ganti anak, 18 Detail misi + 47 Misi Puncak (+ favorit), 03 Pilih peserta, 04 Mainkan (+ TTS, DECISIONS B8), 33 Konfirmasi keluar, 07 Abadikan, 05 Perayaan, 08 Refleksi, 21 Level naik, 31 Lencana baru, 45 Streak terhenti.

Penting:
- Urutan setelah misi: 07 → 05 → 08 → 21 (jika ada) → 31 (jika ada) → 02, data dari hasil completeMissionRun.
- XP dan poin skill ke setiap anak peserta; mission_logs tetap ditulis per anak.
- Foto: maks 3, kompres + hapus EXIF (lib/core/services/image_service.dart), Storage privat.
- Perayaan bisa dilewati dengan ketuk, CTA muncul terakhir, satu konfeti.
- 45 tampil sekali saat app dibuka jika kemarin terlewat tanpa pembeku.
- Layar lama yang tergantikan (home_page, missions_page, mission_path_screen, mission_intro_screen, mission_play_screen, mission_journal_screen, mission_win_screen, mission_reflection_screen, streak_calendar_page) baru dihapus setelah semua tes hijau, di commit terpisah.

Verifikasi: golden tiap layar; integration test alur 2 dan 3; DevTools profile di HP: tidak ada jank saat ganti tab peran dan di layar perayaan; uji "Kurangi animasi".
```

---

## Prompt Fase 5: Memori, tantangan, lencana

```
Kerjakan Fase 5 di branch feat/phase-5-memories.

Layar: 09 Memori (+49 kosong; foto jurnal lama tetap tampil, DECISIONS B6), 34 Detail momen, 35 Kolase bulanan (ekspor PNG lewat RepaintBoundary, bagikan dengan share_plus, simpan dengan gal), 10 Tantangan + peti, 22 Koleksi lencana, 32 Sertifikat (gantikan certificate_detail_page dan all_certificates_page), 20 Perkembangan anak (SkillRadar 5 sumbu fl_chart bergaya token, tombol laporan PDF dari report_pdf_service yang sudah ada, di-restyle).

Verifikasi: golden; scroll Memori dengan 100 foto mulus di HP (PERFORMANCE §10).
```

---

## Prompt Fase 6: Profil, akun, paket

```
Kerjakan Fase 6 di branch feat/phase-6-profile.

Layar: 06 Profil, 44 Ubah profil, 36 Kelola anak, 39 Ubah data anak (gantikan edit_questionnaire_page), 40 Hapus anak (pakai child_deletion_service yang ada, tambahkan unduh foto + ketik nama), 41 Undang pendamping, 37 Pengaturan (+ ukuran teks, kecepatan TTS, bantuan), 42 Privasi (pakai data_export_service dan account_deletion_service yang ada; hapus baris suara), 38 Paket Keluarga (tampilan + status paket dari database; pembayaran asli di Fase 8), 46 Peran terkunci, 54 Notifikasi (restyle notifications_page). Pusat bantuan dan legal di-restyle.

profile_page.dart (2.600 baris) dipecah habis. Verifikasi: golden; integration test alur 5.
```

---

## Prompt Fase 7: Versi Guru

```
Kerjakan Fase 7 di branch feat/phase-7-teacher.

Layar: 29 Setup kelas, 12 Beranda Guru, 52 Pilih kelas (tanpa kode kelas), 13 Mulai misi di kelas, 51 Abadikan versi Guru, 30 Statistik kelas, 53 Statistik belum cukup data.

Aturan keras:
- Tidak ada input atau penyimpanan nama siswa di mana pun.
- Statistik hanya agregat, tersembunyi sampai 3 sesi.
- Buram wajah otomatis aktif default di 51: pilih pendekatan deteksi wajah di perangkat (mis. google_mlkit_face_detection, minta persetujuanku dulu karena menambah ukuran app), proses sebelum unggah, sediakan buram manual sebagai cadangan.
- Copy berganti otomatis lewat lib/core/utils/copy.dart.

Verifikasi: integration test alur 4.
```

---

## Prompt Fase 8: Offline dan pembayaran

```
Kerjakan Fase 8 di branch feat/phase-8-offline-billing.

1. Antrean offline (PERFORMANCE §7) dan banner offline (layar 50): misi selesai tanpa jaringan tetap tercatat dan tersinkron nanti.
2. Langganan Paket Keluarga lewat Google Play Billing / App Store (in_app_purchase), verifikasi di Edge Function, status paket di database hanya diubah oleh server. Uji coba 7 hari + pengingat H-2.
3. Jalankan checklist SECURITY_PRIVACY §11 dan laporkan.

Laporkan langkah manual (Play Console, App Store Connect, Supabase secrets).
```

---

## Prompt Fase 9: Poles dan audit

```
Kerjakan Fase 9 di branch feat/phase-9-polish.

1. Golden semua 54 layar/state, bandingkan satu per satu dengan design/screens, buat tabel selisih, perbaiki.
2. docs/standards/DESIGN.md §6 (AI slop): cari pemisah · dan —, eyebrow kapital renggang, kartu template, emoji. Grep Color(0x dan emoji di luar token/ikon harus kosong.
3. Jalankan checklist UX_COMFORT §11, ANIMATION §9, PERFORMANCE §10, SECURITY_PRIVACY §11; laporkan per butir.
4. Hapus AppColors/AppTextStyles/AppSpacing lama, widget lama yang @Deprecated, PNG lama di assets/images/ yang tidak dipakai, dan route lama. Pastikan tidak ada import yang rusak.
5. Build rilis: flutter build appbundle --obfuscate --split-debug-info=build/symbols --dart-define-from-file=env.json, cek ukuran.

Laporkan dalam tabel: butir, status, bukti, tindakan.
```

---

## Prompt cadangan

### Satu layar saja

```
Kerjakan layar [NN Nama] (design/SCREENS.md). Baca design/screens/[NN-Nama].png, design/source/[NN-Nama].html, bagian HANDOFF, dan file lama yang digantikan. Tulis rencana singkat (widget dipakai ulang, widget baru + alasan, data, animasi), lalu implementasikan. Verifikasi dengan golden 390x844 dibandingkan gambar desain.
```

### Perbaiki bug

```
Bug: [apa yang terjadi, langkah memunculkan, yang seharusnya].
Cari penyebabnya dan jelaskan dulu sebelum mengubah kode. Tambahkan tes yang gagal sebelum perbaikan dan lulus sesudahnya. Jangan ubah hal lain.
```

### Review sebelum merge

```
Review branch ini terhadap dev-nicco dengan checklist docs/standards/CODE_QUALITY.md §6 dan §7 plus DESIGN.md §6. Urutkan temuan dari yang paling serius, sebut file dan baris. Jangan ubah kode sampai aku setuju.
```

### Saat hasil menyimpang dari desain

```
Layar [NN] tidak sesuai design/screens/[NN-Nama].png. Buat golden/screenshot 390x844, bandingkan berdampingan, sebutkan setiap perbedaan (jarak, ukuran font, warna, copy, urutan), perbaiki semuanya, lalu bandingkan lagi.
```
