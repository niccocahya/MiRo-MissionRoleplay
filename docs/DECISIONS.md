# Keputusan Final (v2.1 Flutter, 27 Nov 2026)

Dokumen ini mengalahkan dokumen lain, termasuk gambar layar, untuk hal yang disebut di sini.

## A. Platform dan cara kerja

| # | Topik | Keputusan |
|---|---|---|
| A1 | Platform | **Flutter** (repo `niccocahya/MiRo-MissionRoleplay`). Semua isi lama tentang Next.js, Tailwind, CSS, dan `public/` tidak berlaku. DESIGN_SYSTEM §13 diganti oleh `docs/standards/`. |
| A2 | Pendekatan | **Redesign bertahap di atas aplikasi yang sudah jalan**, bukan tulis ulang. Setiap fase harus bisa di-build dan dipakai. Data Supabase yang ada dipertahankan. |
| A3 | Branch | Kerja di branch per fase dari `dev-nicco` (sama dengan `master` saat ini), merge ke `master` setelah dicek. |
| A4 | Ukuran desain | Frame 390×844. 1 px di mockup HTML = 1 logical pixel Flutter. Top bar 64, bottom nav 80 tanpa label (aktif ditandai wadah coral muda; `Semantics` label tetap wajib). |

## B. Fitur lama vs desain baru

| # | Fitur di aplikasi sekarang | Keputusan |
|---|---|---|
| B1 | **Nama maskot "Mink"** vs "Maro" di desain | **FINAL: "Mink"** (lihat §F1). Satu konstanta `kMascotName = 'Mink'` di `lib/core/app_info.dart`. Semua copy memakai konstanta ini, bukan nama tertulis. Widget memakai awalan netral `Mascot` (`MascotImage`, `MascotTip`, `MascotPose`). |
| B2 | **Bottom nav lama** (Home, Misi, Progres, Profil) | Diganti 4 tab desain: **Petualangan** (gabungan Home + Misi), **Tantangan**, **Memori**, **Profil**. Isi Progres pindah ke Perkembangan anak (20) dan Profil (06). |
| B3 | **5 skill** di data (cognitive, empathy, creativity, literacy, motoric) vs 6 di desain (+Komunikasi) | **FINAL: 5 skill** (lihat §F2), tanpa Komunikasi. Radar jadi segi lima. Teks "Komunikasi" di mockup diganti skill yang setara di data misi. |
| B4 | **Kurva level** lama (4 level, berhenti di 500 XP) | Ganti ke rumus desain: XP level n→n+1 = `40 + 20 × (n − 1)`, tanpa batas. Level dihitung ulang dari `child_stats.total_xp`, tidak disimpan. Level pengguna uji coba bisa berubah; tidak apa-apa. |
| B5 | **Streak per anak** (dihitung dari `mission_logs`) | Streak menjadi **milik akun** (PRD F9): hari dihitung tercapai jika total menit misi selesai (dari `missions_master.duration`) dari semua anak ≥ target harian. Tetap dihitung dari `mission_logs`, tanpa tabel baru, kecuali untuk pembeku dan pemulihan (lihat §D). |
| B6 | **Jurnal: foto per langkah + rating bintang** | Ikut desain: **Abadikan setelah misi, maksimal 3 foto** (07), rating bintang dihapus dari alur (refleksi 08 sudah menangkap perasaan). Baris `journals` lama tetap tampil di Memori. |
| B7 | **Chat AI Mink** (`penguin_chat_bot.dart`, Edge Function `mink-chat`) | Tetap **disembunyikan** seperti sekarang. Kode dipertahankan, tidak di-redesign di v2. |
| B8 | **Narasi suara (TTS) + pilihan kecepatan** | **Dipertahankan.** Tombol speaker 44px di `StepCard` (04), kecepatan di Pengaturan (37) sebagai `SegmentedControl` Lambat/Normal/Cepat. |
| B9 | **Cari misi** (`mission_search_screen.dart`) | Dipertahankan. Ikon cari di `TopBar` Beranda (02), layar memakai komponen desain (`PageHeader`, `MiroTextField`, `MissionCard`). |
| B10 | **Misi favorit** | Dipertahankan sebagai ikon hati di sheet Detail misi (18). |
| B11 | **Laporan PDF** | Dipertahankan. Tombol "Unduh laporan" di Perkembangan anak (20), gaya PDF memakai warna dan font token. |
| B12 | **Pusat bantuan, halaman legal** | Dipertahankan, dibuka dari Pengaturan (37) dan Privasi (42), di-restyle dengan `PageHeader` + teks token. |
| B13 | **Ukuran teks** (`text_size_provider`) | Dipertahankan di Pengaturan (37). Layout harus tahan sampai 1.3×. |
| B14 | **Akun terakhir** (`recent_accounts_provider`) | Dipertahankan di layar Masuk (15) sebagai daftar akun di atas form. |
| B15 | **Kuesioner anak** (`questionnaires`) | Dipetakan ke setup anak 16, 24, 25, 26. Kolom yang ada dipakai; `parentGoals` = keahlian (26), `timePreference` = target harian (17). |
| B16 | **Font Poppins** | Diganti **Nunito** 600 sampai 900, dibundel di `assets/google_fonts/` (`GoogleFonts.config.allowRuntimeFetching = false`). |
| B17 | **`AppColors`, `AppSpacing`, `AppTextStyles` lama** | Diganti `miro_tokens.dart`. Selama transisi, kelas lama diarahkan ke token baru (alias) lalu dihapus di Fase 9. |
| B18 | **Ikon aplikasi** (sekarang Maro di navy) | Diganti logo baru: `assets/brand/miro-launcher-1024.png`, adaptive foreground `miro-adaptive-foreground-1024.png`, background `#FFE8B6`. |

## C. Konflik dokumen (sama seperti versi web)

| # | Topik | Keputusan |
|---|---|---|
| C1 | Maksimal anak | Gratis 1, Keluarga 5 |
| C2 | Urutan setelah misi | 07 Abadikan → 05 Perayaan → 08 Refleksi → 21 Level naik (jika ada) → 31 Lencana baru (jika ada) → 02. Level dan lencana dihitung setelah refleksi |
| C3 | Kode kelas guru pendamping | Tidak masuk v2 |
| C4 | Rekaman suara di memori | Tidak masuk v2 (baris suara di 34 dan 42 dihapus) |
| C5 | Gaya belajar (25) | Visual, Auditori, Kinestetik; boleh lebih dari satu |
| C6 | Setup kelas (29) | Satu layar: nama, 6 warna, usia, jumlah siswa |
| C7 | XP Misi Puncak | 60 |
| C8 | Lip | Tombol 4, kartu 3, tombol ikon 2, kartu hero 6 |
| C9 | Input usia (16) | Grid tombol 48px |
| C10 | Tombol bahaya | `red600` / lip `red800` |
| C11 | Splash | 14 → 23 Bahasa → 01 Tipe akun (bahasa sudah tersimpan → lewati 23) |
| C12 | Token yang tidak ada di HANDOFF | `chef-500` → `MiroRole.chef.base`, `teacher-500` → `MiroRole.teacher.base`, `success-600` → `green600`, `cream-200` → `MiroColors.cream200` |
| C13 | Jumlah avatar | Ikut gambar tiap layar; data 6 warna |

## D. Data (Supabase)

1. **Langkah pertama Fase 2:** tarik skema yang sekarang ke repo (`supabase db pull` atau ekspor SQL dari dashboard) ke `supabase/migrations/0000_baseline.sql`. Semua perubahan setelahnya lewat file migrasi bernomor.
2. Tabel lama dipertahankan: `parents`, `children`, `questionnaires`, `child_stats`, `child_role_progress`, `mission_logs`, `missions_master`, `roles_master`, `achievements_master`, `child_achievements`, `certifications_master`, `journals`, `reflections`, `notifications`, `ai_chats`, `feedback`.
3. Tambahan yang dibutuhkan desain (nama boleh disesuaikan, laporkan):
   - `parents.account_type` (`parent`/`teacher`, default `parent`), `parents.plan` (`free`/`family`, default `free`), `parents.daily_goal_minutes`, `parents.fish`, `parents.streak_freezes`, `parents.honorific` (Bunda/Ayah/Lainnya)
   - `mission_runs` (satu sesi misi) + `mission_run_participants` (anak peserta). `mission_logs` tetap ditulis per anak agar kode lama dan statistik tetap jalan.
   - `memories` (foto setelah misi, maks 3 per run) dengan path Storage privat
   - `account_members` (pemilik + pendamping) dan `invites` (kode pendamping)
   - `classrooms` dan `class_sessions` (akun Guru, tanpa data siswa)
   - `daily_quests` (tantangan harian) dan `streak_events` (pembeku dipakai, pemulihan dengan ikan)
   - `consents` (persetujuan orang tua + versi kebijakan)
4. Perhitungan XP, level, lencana, streak, dan ikan saat misi selesai dipindah ke **satu RPC** `complete_mission_run` (atomik). Logika harus identik dengan `lib/core/game/`; ada tes pembanding.
5. RLS wajib di semua tabel baru, dan periksa ulang tabel lama (SECURITY_PRIVACY §3).

## E. Aset

| Aset | Lokasi / pengganti |
|---|---|
| Logo | `assets/brand/` |
| Maro (main, wave, peek, cooking, 5 pose menang, snow) | `assets/mascot/*.webp`. Pose lama `assets/images/penguin_*.png` diganti bertahap |
| 12 avatar bayi pinguin | Sementara `maro-peek.webp` di lingkaran warna (6 warna), seperti mockup |
| 5 wajah perasaan | Widget kustom `CustomPainter` di `lib/shared/icons/feeling_face.dart`, bentuk dari `design/source/08-Refleksi.html` |
| Pose sedih, berpikir, buka peti | Sementara `maro-main` (sedih: saturasi 0.75) |
| Ikon PNG bergaya emoji (`lamp.png`, `drawing.png`, `thinking.png`, dst.) | Diganti ikon Phosphor, dihapus di Fase 9 |

Catat semua pengganti sementara di `docs/ASSET_TODO.md`.

## F. Keputusan Nic

1. **Nama maskot: FINAL "Mink".** `kMascotName = 'Mink'`. Semua tulisan "Maro" di dokumen, mockup, dan copy desain dibaca sebagai Mink. Nama widget di kode memakai awalan netral `Mascot` (`MascotImage`, `MascotTip`, `MascotPose`), bukan `Maro`. Nama file aset `maro-*.webp` boleh tetap.
2. **Skill: FINAL 5 skill** (`cognitive`, `empathy`, `creativity`, `literacy`, `motoric`), tanpa Komunikasi. Radar segi lima.
3. **Harga paket (masih menunggu keputusan):** Rp39.000/bulan dan Rp299.000/tahun masih contoh.

## G. Backlog v2.2

Co-teacher dan kode kelas, rekaman suara, tantangan mingguan, laporan bulanan kelas, paket guru berbayar, redesign chat AI.
