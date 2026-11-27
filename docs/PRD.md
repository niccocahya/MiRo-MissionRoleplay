# MiRO — Product Requirements Document (PRD)

> **Versi:** 2.1 (sinkron dengan 54 layar final, 27 Nov 2026)  •  **Status:** Disetujui untuk implementasi  •  **Pemilik:** Nicco Cahya Permana
> **Dokumen pasangan:** [`DESIGN_SYSTEM.md`](./DESIGN_SYSTEM.md) mengatur *bagaimana tampilannya*. Dokumen ini mengatur *apa yang dibangun dan kenapa*.
> **Lainnya:** [`HANDOFF.md`](./HANDOFF.md) (spesifikasi layar), [`standards/`](./standards/) (arsitektur, komponen, animasi, UX, keamanan, performa, kualitas kode), [`../design/SCREENS.md`](../design/SCREENS.md) (54 layar). Kanvas desain: https://claude.ai/artifact/8HFtR7L83ai4o76JioKwZV

---

## 0. Ringkasan

MiRO adalah aplikasi pendamping untuk **orang dewasa** (orang tua atau guru) yang memandu **misi bermain peran tanpa gawai** untuk anak usia 2 sampai 10 tahun, dalam bentuk **aplikasi Flutter** (Android dan iOS) dengan backend Supabase: Dokter Kecil, Koki Kecil, Seniman Kecil, Guru Kecil, dan Atlet Kecil. HP dipakai orang dewasa untuk membaca langkah, mencatat, dan merayakan. Anak bermain di dunia nyata.

Redesign v2 punya tiga tujuan:

1. **Kualitas rasa (feel).** Tampilan dan interaksi setara Duolingo: tombol yang "tebal", font tegas, maskot yang hidup, animasi kecil yang memberi umpan balik di setiap aksi.
2. **Sistem yang saling terhubung.** Misi → XP → level → lencana → streak → tantangan harian → rekomendasi. Setiap fitur memberi makan fitur lain, bukan berdiri sendiri.
3. **Model pengguna yang benar.** Satu akun orang tua bisa punya banyak anak; satu sesi misi bisa diikuti satu, beberapa, atau semua anak; ada juga akun **Guru** yang bekerja per kelas tanpa data anak individual.

### Prinsip produk (tidak boleh dilanggar)

| # | Prinsip | Konsekuensi desain |
|---|---|---|
| P1 | **Layar adalah pemandu, bukan tujuan.** | Waktu aktif di layar per misi harus kurang dari 2 menit di luar membaca langkah. Tidak ada feed, tidak ada scroll tanpa akhir. |
| P2 | **Tidak ada hukuman.** | Tidak ada sistem nyawa/hati, tidak ada "gagal". Streak yang putus dipulihkan dengan lembut. |
| P3 | **Gamifikasi untuk kebiasaan orang dewasa, pujian untuk anak.** | Streak dan target harian milik akun (kebiasaan orang dewasa). XP, level, poin keahlian, dan lencana milik profil anak. |
| P4 | **Data anak minimal.** | Hanya nama panggilan, usia, dan avatar. Akun guru tidak menyimpan data siswa individual. |
| P5 | **Satu aksi utama per layar.** | Setiap layar punya tepat satu tombol utama. |

---

## 1. Kondisi aplikasi Flutter saat ini

Hasil membaca repo `niccocahya/MiRo-MissionRoleplay` (±22 ribu baris Dart, uji coba privat).

### 1.1 Yang sudah ada dan dipertahankan

- Backend Supabase berjalan: akun orang tua, multi-anak, kuesioner, statistik per anak, progres per peran, log misi, jurnal foto, refleksi, lencana, sertifikat, notifikasi, hapus akun (Edge Function), ekspor data.
- Jalur misi berurutan per peran, XP dan 5 skill, streak dengan kalender, grafik tren skill, Memory Book, sertifikat yang bisa diunduh, laporan PDF.
- Narasi suara (TTS) dengan pilihan kecepatan, cari misi, misi favorit, ukuran teks, dua bahasa (ID/EN).
- Chat AI Mink lewat Edge Function (sedang disembunyikan).
- Fondasi kode yang baik: Riverpod, go_router, token warna/spacing awal, beberapa widget bersama.

### 1.2 Yang diubah oleh v2

| Hal | Sekarang | v2 |
|---|---|---|
| Tampilan | Poppins, kartu dengan bayangan, ikon emoji dan PNG, warna tersebar | Nunito, sistem lip, ikon Phosphor/kustom, token lengkap, 54 layar |
| Navigasi | Home, Misi, Progres, Profil | Petualangan, Tantangan, Memori, Profil |
| Level | 4 level, berhenti di 500 XP | Tanpa batas, `40 + 20 × (n − 1)` |
| Streak | Per anak | Per akun, berdasarkan target menit harian |
| Foto | Satu per langkah | Abadikan setelah misi, maks 3, kolase bulanan |
| Peserta misi | Satu anak | Satu, beberapa, atau semua anak |
| Akun | Orang tua saja | Orang tua + Guru (per kelas, tanpa data siswa) + pendamping |
| Gamifikasi | XP, lencana | + tantangan harian, peti, ikan, pembeku streak, Misi Puncak |
| Paket | Belum ada | Gratis dan Keluarga |

### 1.3 Utang teknis yang dibereskan sambil jalan

- Beberapa file layar 1.000 sampai 2.600 baris (`profile_page.dart`, `progress_page.dart`, `home_page.dart`, `mission_journal_screen.dart`). Dipecah saat layarnya di-redesign.
- `supabase_repository.dart` tunggal dan banyak query langsung di provider. Dipecah per domain (ARCHITECTURE §5).
- Skema database belum ada di repo. Ditarik ke `supabase/migrations/` di Fase 2.
- Emoji di konstanta (`feeling_emojis.dart`, `skills.dart`).

---

## 2. Pengguna & tipe akun

Saat daftar, pengguna memilih tipe akun. Tipe akun **tidak bisa diubah** setelah dibuat (agar data tidak tercampur). Orang yang berperan ganda bisa membuat dua akun.

| | **Orang Tua** | **Guru** |
|---|---|---|
| Siapa | Ayah/Bunda/pengasuh | Guru PAUD/TK/SD kelas awal, pendamping sanggar |
| Unit yang dikelola | **Profil Anak** (Gratis 1 anak, Keluarga sampai 5 anak) | **Kelas** (sampai 10 kelas) |
| Data yang disimpan | Nama panggilan, usia, avatar, minat, gaya belajar, target keahlian | Nama kelas, rentang usia, perkiraan jumlah siswa. **Tanpa nama siswa.** |
| Peserta misi | Pilih anak: satu, beberapa, atau semua | Satu kelas per sesi + jumlah siswa yang hadir |
| Statistik | Per anak (level, poin keahlian, lencana) | Per kelas (cakupan keahlian, jumlah sesi) + statistik guru |
| Sapaan default | "Ayah/Bunda {nama}" | "Bu/Pak {nama}" |

Anak **bukan pengguna** dan tidak login. Anak adalah profil di bawah akun orang tua.

---

## 3. Core loop

```
            ┌───────────────────────────────────────────────┐
            ▼                                               │
  [Beranda: Jalur Petualangan]                              │
      │  (misi berikutnya disorot + target harian)           │
      ▼                                                     │
  [Detail Misi] → [Pilih Peserta] → [Mainkan: langkah 1..n] │
                                         │                  │
                                         ▼                  │
                    [Abadikan Momen (foto, opsional)]       │
                                         │                  │
                                         ▼                  │
                    [Perayaan: XP, poin keahlian, streak]   │
                                         │                  │
                                         ▼                  │
                    [Refleksi singkat (opsional, +XP)]      │
                                         │                  │
                                         ▼                  │
      ┌──────────── [Hasil: lencana baru? tantangan selesai? peti?]
      │                                  │
      ▼                                  ▼
  Kolase Memori                    Perkembangan  ──► rekomendasi misi berikutnya
```

Setiap panah adalah hubungan data yang nyata. Misalnya **target keahlian** yang dipilih saat onboarding menentukan **rekomendasi misi** di Beranda, dan **waktu bermain** yang dipilih saat onboarding menjadi **target harian** yang mengisi **streak**.

---

## 4. Arsitektur informasi

### 4.1 Navigasi bawah (4 tab, sama untuk kedua tipe akun, isinya menyesuaikan)

| Tab | Orang Tua | Guru |
|---|---|---|
| **Petualangan** (ikon: peta) | Jalur misi untuk anak yang dipilih di switcher | Jalur misi untuk kelas yang dipilih |
| **Tantangan** (ikon: target) | Tantangan harian + mingguan, peti hadiah | Sama, dengan tantangan versi guru |
| **Memori** (ikon: galeri) | Kolase Memori per anak / semua anak | Kolase Memori per kelas |
| **Profil** (ikon: wajah pinguin) | Profil akun, anak-anak, lencana, perkembangan, pengaturan | Profil guru, kelas-kelas, statistik, pengaturan |

**Perkembangan** tidak lagi menjadi tab tersendiri. Ia masuk ke Profil → kartu anak/kelas, dan juga muncul sebagai ringkasan di layar hasil misi. Alasannya: orang tua membuka perkembangan beberapa kali seminggu, sedangkan Memori dibuka setelah hampir setiap misi.

### 4.2 Top bar (persisten di tab Petualangan & Tantangan)

```
[Avatar anak/kelas ▾]          [❄ 12]  [Ikan 340]  [Target ●○]
```
- **Switcher** profil anak/kelas (lihat F2/F3).
- **Streak** (ikon kristal es, khas pinguin; *bukan* api Duolingo).
- **Ikan**: mata uang dalam aplikasi.
- **Cincin target harian**.

Setiap elemen bisa diketuk dan membuka bottom sheet penjelasan.

### 4.3 Peta layar

```
Splash
└─ Onboarding
   ├─ Pilih bahasa
   ├─ Pilih tipe akun (Orang Tua / Guru)
   ├─ Daftar / Masuk
   ├─ [Orang Tua] Setup anak pertama (4 langkah) → "Tambah anak lain?"
   ├─ [Guru] Setup kelas pertama (3 langkah)
   ├─ Pilih target harian
   └─ Izin notifikasi (dengan pinguin)
Petualangan (home)
├─ Detail misi (bottom sheet) → Pilih peserta → Mainkan → Abadikan → Perayaan → Refleksi → Hasil
└─ Detail unit/peran
Tantangan
Memori
├─ Kolase per anak/kelas
└─ Detail momen
Profil
├─ Kelola anak / Kelola kelas (tambah, ubah, arsipkan)
├─ Perkembangan anak / Statistik kelas
├─ Koleksi lencana & sertifikat
├─ Statistik guru (khusus guru)
├─ Paket & langganan
└─ Pengaturan (bahasa, notifikasi, suara, getar, animasi, privasi, keluar)
```

---

## 5. Daftar fitur

Prioritas: **P0** = wajib untuk rilis v2, **P1** = rilis v2.1, **P2** = nanti.

### F1. Onboarding & tipe akun (P0)

- Layar "Siapa yang akan menggunakan MiRO?" dengan dua kartu pilihan besar: **Orang Tua** (ilustrasi pinguin menggendong anak pinguin) dan **Guru** (pinguin guru `penguin_teacher.png`).
- Pilihan disimpan sebagai `account.role` dan menentukan seluruh alur berikutnya.
- Daftar: nama, email, kata sandi (tombol lihat sandi berfungsi), atau Google.
- Validasi inline: email valid, sandi minimal 8 karakter, konfirmasi sandi cocok. Pesan error di bawah field, bukan alert.
- **Pilih target harian** menggantikan 12 opsi waktu lama:

| Pilihan | Menit/hari | Label |
|---|---|---|
| Santai | 10 | "Sedikit tapi rutin" |
| Rutin | 15 | Default, disarankan |
| Serius | 30 | — |
| Penuh | 45 | — |

**Kriteria terima:** pengguna baru bisa sampai Beranda dalam ≤ 90 detik; tombol "Lanjut" nonaktif sampai input wajib terisi; progress bar onboarding beranimasi di setiap langkah.

### F2. Profil anak (multi-anak) — khusus Orang Tua (P0)

- Satu akun: **1 anak** di paket Gratis, **sampai 5 anak** di paket Keluarga.
- Data per anak: nama panggilan (wajib), usia 2–10 (wajib), avatar (pilih dari 12 avatar pinguin bergaya MiRO **atau** unggah foto), kegiatan kesukaan (opsional, maks 3), gaya belajar (opsional), keahlian yang ingin dikembangkan (opsional, maks 3).
- Setup anak = 4 langkah (Nama & usia → Kesukaan → Gaya belajar → Keahlian). Setelah anak pertama selesai muncul layar: "Ada si kecil lain di rumah?" dengan tombol **Tambah anak** dan **Nanti saja**.
- **Kelola anak** (layar 36): tambah, ubah (39), hapus (40). Hapus bersifat permanen: profil, progres, dan foto yang hanya berisi anak itu dihapus (termasuk dari cadangan dalam 30 hari). Sebelum menghapus, pengguna ditawari mengunduh foto dan wajib mengetik nama anak.
- **Switcher anak** di top bar: bottom sheet berisi daftar avatar + opsi **"Semua anak"**. Pilihan ini memfilter Beranda (rekomendasi misi), Memori, dan Perkembangan.

**Kriteria terima:** menambah anak ke-2 dari Profil butuh ≤ 4 layar; switcher bisa dipakai dengan satu tangan; menghapus anak meminta konfirmasi dua langkah.

### F3. Kelas — khusus Guru (P0)

- Satu akun guru: maksimal **10 kelas** aktif.
- Data kelas: nama kelas (mis. "TK B Melati"), rentang usia (pilih: 3–4, 4–5, 5–6, 6–7, 7–8), perkiraan jumlah siswa (angka), warna/ikon kelas (dari 8 pilihan).
- Setup kelas = 3 langkah: Nama & usia → Jumlah siswa → Keahlian fokus semester ini.
- **Tidak ada input nama siswa.** Ini disengaja (lihat §7).
- Switcher kelas di top bar, sama seperti switcher anak.

### F4. Jalur Petualangan (P0)

Pengganti layar Home saat ini. Diadaptasi dari learning path Duolingo.

- **Unit = Peran** (Dokter Kecil, Koki Kecil, dst). Setiap unit punya warna sendiri (lihat Design System §1.4), header unit berisi nama peran + ilustrasi pinguin berkostum.
- **Tab peran** di bagian atas untuk berpindah antar peran (Dokter, Koki, Seniman, Guru, Atlet).
- **Misi = kartu kotak dalam timeline vertikal** (bukan lingkaran zig-zag, agar tidak identik dengan Duolingo). Satu peran berisi 5 misi; misi ke-5 adalah **Misi Puncak** (memberi sertifikat). Peti hadiah muncul setelah misi ke-3.
- Status kartu: terkunci (putus-putus), berikutnya (kartu besar berwarna peran + Maro + tombol Mulai), selesai (centang), sempurna (selesai + foto + refleksi → lencana emas).
- Di atas tab peran: kartu **Target hari ini** (menit bermain vs target, 7 hari minggu ini). Peran yang terbuka pertama kali dihitung dari keahlian target anak yang paling rendah poinnya.
- **Misi Puncak** (misi ke-5, layar 47): kartu bergaya amber di daftar, detail dengan syarat membuka (misi 1 sampai 4 selesai), hadiah sertifikat dan +60 XP.
- Misi tidak dikunci secara keras: pengguna bisa melompat ke unit lain kapan saja, tetapi urutan di dalam unit berurutan.
- Mode "Semua anak": rekomendasi memakai irisan usia semua anak (misi yang cocok untuk anak termuda).

### F5. Menjalankan misi + pilih peserta (P0)

**Alur:** Detail Misi (bottom sheet) → **Pilih Peserta** → Mainkan → Abadikan → Perayaan → Refleksi → Hasil.

**Pilih Peserta (Orang Tua):**
- Muncul **hanya jika akun punya ≥ 2 anak**. Jika hanya 1 anak, langkah ini dilewati otomatis.
- Grid avatar anak sebagai kartu pilihan multi-select, ditambah tombol **"Pilih semua"**.
- Default: anak yang sedang aktif di switcher (atau semua jika switcher = Semua anak).
- Anak yang usianya di luar rentang misi tetap bisa dipilih, tetapi diberi label kecil "Misi 4+ tahun" (informasi, bukan larangan).
- Tombol utama: "Mulai dengan {n} anak".

**Pilih Peserta (Guru):**
- Kelas aktif sudah terpilih. Satu input: **"Berapa siswa yang hadir?"** berupa stepper (−/+) dengan default = jumlah siswa kelas.
- Opsi "Kerja kelompok" → jumlah kelompok (stepper). Langkah misi versi kelas menampilkan tips untuk kelompok.

**Mainkan:**
- Langkah tampil sebagai kartu bertumpuk; satu langkah aktif dalam satu waktu (bukan accordion yang semuanya bisa dibuka seperti sekarang).
- Setiap langkah: judul, instruksi, ilustrasi, "Tips untuk Ayah/Bunda" (atau "Tips untuk Guru"), tombol **"Sudah!"**.
- Bar progres segmen di atas (Duolingo lesson bar) yang terisi dengan animasi setiap langkah selesai.
- Tombol keluar (X) di kiri atas → konfirmasi (layar 33) yang menyebut progres langkah, dengan "Lanjut main" sebagai tombol paling menonjol.
- Opsi **timer** opsional per langkah untuk misi yang butuh durasi (mis. Atlet Kecil).

**Kriteria terima:** sesi misi tersimpan sebagai `MissionRun` dengan daftar peserta; XP dan poin keahlian diberikan ke **setiap** anak peserta (tidak dibagi).

### F6. Abadikan Momen & Kolase Memori (P0)

- Setelah langkah terakhir: layar **"Abadikan momen ini?"** dengan pratinjau kamera/galeri. Maksimal 3 foto per sesi. Tombol sekunder "Lewati".
- Foto otomatis ditandai dengan: misi, peran, tanggal, **semua anak peserta** (orang tua) atau **kelas** (guru).
- **Tab Memori:**
  - Tampilan **kolase** (masonry 2 kolom) dikelompokkan per bulan, dengan stiker peran (kostum pinguin) di pojok foto.
  - Filter: anak (atau kelas), peran, bulan.
  - Ketuk foto → detail momen: foto, misi, peserta, refleksi singkat jika ada, tombol **Bagikan** (menghasilkan kartu bergaya MiRO).
  - **Kolase bulanan otomatis** (P1): di akhir bulan, MiRO menyusun 1 gambar kolase (6–9 foto terbaik) + ringkasan "Bulan ini {nama} jadi Dokter 3x, Koki 2x" yang bisa diunduh/dibagikan.
- Foto dengan beberapa anak muncul di kolase **setiap** anak yang ikut.
- Untuk guru (layar 51): foto tetap tersedia dan fokus ke hasil karya. **Buram wajah otomatis** aktif default (diproses di perangkat sebelum unggah). Tidak ada tag nama murid. Peringatan izin foto sekolah tampil di layar. Foto kelas privat dan tidak bisa dibagikan ke publik dari aplikasi.
- **Offline dan gagal unggah** (layar 50): misi tetap tercatat; foto masuk antrean dan diunggah otomatis saat tersambung. Penyebab gagal disebutkan (ukuran > 15 MB, format, server) dengan tombol "Coba lagi".

### F7. Refleksi (P1)

- Dua skala perasaan (orang dewasa, anak) memakai **5 ekspresi wajah pinguin** (ilustrasi khusus, bukan emoji).
- Jika peserta > 1 anak: perasaan anak bisa diisi **per anak** (baris avatar + skala) atau "sama untuk semua".
- Catatan teks opsional, maks 280 karakter.
- Mengisi refleksi memberi **+5 XP** dan menjadi syarat status "sempurna" pada node.

### F8. XP, level & poin keahlian (P0)

Milik **profil anak** (orang tua) atau **kelas** (guru).

| Aksi | XP |
|---|---|
| Menyelesaikan misi | 20 |
| Menambah foto momen | +5 (sekali per sesi) |
| Mengisi refleksi | +5 |
| Misi pertama hari itu | +5 |
| Misi Puncak unit | 60 (menggantikan 20 untuk misi biasa) |

**Kurva level:** XP untuk naik dari level *n* ke *n+1* = `40 + 20 × (n − 1)`. Jadi L1→2 = 40 XP (2 misi), L4→5 = 100 XP, L9→10 = 200 XP. Level tidak punya batas atas.

**Poin keahlian:** setiap misi punya bobot keahlian (mis. "Kuman Takut Sabun": Kognitif 3, Empati 2, Motorik 1). Setiap peserta menerima poin sebesar bobot tersebut. Keahlian: **Kognitif, Motorik, Kreativitas, Empati, Literasi, Komunikasi** (6 sumbu radar; "Kesabaran" digabung ke Empati agar radar konsisten).

### F9. Streak & target harian (P0)

Milik **akun** (kebiasaan orang dewasa), bukan per anak, supaya orang tua dengan 3 anak tidak dibebani 3 streak.

- Streak bertambah jika **target harian tercapai** (menit misi yang diselesaikan ≥ target). Durasi misi diambil dari data misi, bukan timer nyata, sehingga tidak perlu membiarkan layar menyala.
- Ikon streak: **kristal es**. Saat target tercapai: animasi kristal "tumbuh" + angka berputar naik.
- **Pembeku Streak** (Streak Freeze): otomatis melindungi 1 hari yang terlewat. Maksimal 2 disimpan. Dibeli dengan 100 Ikan.
- **Streak terhenti** (layar 45): muncul sekali saat aplikasi dibuka setelah hari terlewat tanpa Pembeku. Nada tenang, ajakan "Mulai misi hari ini". Opsi **pulihkan dengan 200 Ikan** dalam 24 jam pertama.
- Kalender streak di bottom sheet (titik terisi per hari, minggu ini disorot).

### F10. Tantangan harian & Peti (P1)

- 3 tantangan harian, reset pukul 00.00 waktu lokal. Contoh: "Selesaikan 1 misi", "Tambahkan 1 foto momen", "Coba peran yang belum pernah dimainkan minggu ini", "Mainkan misi bersama 2 anak" (orang tua multi-anak), "Jalankan misi kerja kelompok" (guru).
- Setiap tantangan selesai → bar terisi + Ikan. Ketiganya selesai → **Peti Harian** bisa dibuka (animasi buka peti, hadiah acak 10–30 Ikan atau Pembeku Streak).
- 1 tantangan mingguan (P2) dengan hadiah lebih besar.

### F11. Lencana & sertifikat (P1)

- **Lencana pencapaian** bertingkat (Perunggu → Perak → Emas), mis. "Koki Rajin" 3/10/25 misi Koki, "Pengabadi Momen" 5/25/100 foto, "Konsisten" streak 7/30/100.
- **Sertifikat peran** (32): menyelesaikan Misi Puncak suatu unit → sertifikat "{Nama}, Dokter Kecil Tersertifikasi" (gambar kartu yang bisa diunduh dan dibagikan; sudah ada konsepnya di `settings/page.js`).
- Lencana baru muncul di layar Hasil dengan animasi buka/flip; bisa dilihat di Profil → Koleksi.
- Lencana per anak; lencana kebiasaan (streak) milik akun.

### F12. Perkembangan & statistik (P0)

**Per anak (orang tua):**
- Radar 6 keahlian (dibandingkan bulan lalu sebagai garis putus-putus).
- "Keahlian paling berkembang bulan ini" + kalimat insight + tombol misi rekomendasi.
- Riwayat misi (daftar), total menit bermain, jumlah momen.
- Mode **Semua anak**: kartu per anak berdampingan (perbandingan ringan, tanpa peringkat).

**Per kelas & guru:** lihat §7.

### F13. Notifikasi & pengingat (P1)

- Izin diminta di layar 28 (setelah onboarding), dengan pilihan jam 07.00, 16.30, atau 19.00.
- Push hanya jika target hari ini belum tercapai, maksimal 1 per hari, tidak di jam tenang 20.30 sampai 07.00, kalimat bervariasi dari Maro, tidak pernah menyalahkan.
- **Pusat notifikasi** (layar 54, dari ikon lonceng): "Hari ini" dan "Minggu ini"; jenis: pengingat target, aktivitas pendamping, lencana baru, kolase bulanan siap, peti harian. Setiap item membuka layar terkait.

### F14. Profil, paket & pengaturan (P0)

- **Profil** (06): ringkasan "jam main bersama bulan ini", grafik minggu ini, daftar anak dengan level, tautan Kelola, ubah profil (44).
- **Paket** (38):

| | Gratis | Keluarga |
|---|---|---|
| Anak | 1 | sampai 5 |
| Pendamping tambahan | 1 | 3 |
| Peran | Koki dan Dokter | Semua 5 peran, termasuk Misi Puncak dan sertifikat |
| Kolase bulanan | 6 foto | tanpa batas |
| Harga (contoh, belum final) | 0 | Rp39.000 per bulan atau Rp299.000 per tahun |

  Uji coba 7 hari, pengingat H-2, tanggal tagihan pertama dan cara batal tertulis jelas. Akun Guru gratis untuk satu kelas (detail paket guru menyusul).
  Peran terkunci di paket Gratis tetap terlihat di tab peran (layar 46) dengan pratinjau misi dan tombol uji coba.
- **Pengaturan** (37): pengingat dan jam, target harian, suara Maro, getar, kurangi animasi, bahasa, paket, privasi, bantuan, keluar.

### F15. Pendamping (P0)

- Pemilik akun bisa mengundang pendamping (pasangan, kakek-nenek, pengasuh) lewat kode 6 karakter atau link, berlaku 48 jam, sekali pakai (layar 41).
- Pendamping bisa memulai misi, mengabadikan momen, dan melihat memori serta perkembangan anak yang sama.
- Pendamping **tidak** bisa menghapus anak, menghapus akun, atau mengubah paket.
- Aktivitas pendamping muncul di Notifikasi ("Ayah Bima main bersama Nara").

### F16. Privasi dan data anak (P0)

- Layar 42: izin simpan foto, laporan email; unduh semua data (ZIP); kebijakan privasi versi singkat; hapus akun keluarga.
- Persetujuan orang tua dicatat dengan tanggal dan versi kebijakan.
- Standar teknis lengkap di `standards/SECURITY_PRIVACY.md`.

### F17. Akun dan keamanan (P0)

- Lupa kata sandi (43): link reset via email, pesan sama untuk email terdaftar atau tidak, kirim ulang setelah 60 detik.
- Ubah profil orang tua (44): nama panggilan, sapaan Maro (Bunda, Ayah, Lainnya), email, ganti kata sandi.

### F18. State kosong dan pengguna baru (P0)

- Beranda pengguna baru (48): sapaan + 7 kristal kosong, misi 1 berlabel "Misi pertama".
- Memori kosong (49), statistik kelas belum cukup data (53, terbuka setelah 3 sesi).

### Fitur Duolingo yang sengaja TIDAK diadopsi

| Fitur Duolingo | Alasan tidak dipakai |
|---|---|
| Hati/nyawa | Melanggar P2. Bermain peran tidak punya jawaban salah. |
| Liga/papan peringkat | Membandingkan anak atau keluarga bertentangan dengan tujuan pengasuhan; berisiko memicu orang tua "mengejar poin". |
| Iklan dan *double XP* berbayar | Tidak sesuai untuk produk anak. |

---

## 6. Aturan keterhubungan fitur

Tabel ini adalah "kontrak" antar fitur. Jika satu fitur diubah, cek baris yang terdampak.

| Sumber | Memengaruhi | Aturan |
|---|---|---|
| Onboarding: keahlian target anak | Rekomendasi misi (F4) | Rekomendasikan misi dengan bobot tertinggi pada keahlian target yang poinnya paling rendah. |
| Onboarding: kegiatan kesukaan | Urutan unit di jalur | Peran yang cocok dengan kesukaan ditampilkan lebih dulu. |
| Onboarding: target harian | Streak (F9), cincin top bar | Target tercapai = streak +1. |
| MissionRun selesai | XP & poin keahlian (F8), tantangan (F10), streak (F9), lencana (F11) | Diproses berurutan; layar Hasil menampilkan semua perubahan satu per satu. |
| Foto momen | Kolase (F6), XP, tantangan, lencana "Pengabadi Momen" | — |
| Refleksi | XP, status node "sempurna", insight perkembangan | Rata-rata perasaan anak per peran → "{Nama} paling senang jadi Koki". |
| Level naik | Membuka avatar/kostum pinguin baru (P2) | Setiap 5 level. |
| Ikan | Pembeku Streak, kostum (P2) | — |

---

## 7. Akun Guru: rekomendasi statistik

Pertanyaanmu: apakah akun guru perlu statistik, dan bentuknya seperti apa? Ini perbandingan opsinya:

| Opsi | Isi | Kelebihan | Kekurangan |
|---|---|---|---|
| A. Tanpa statistik | Guru hanya membuka misi | Paling sederhana | Guru tidak punya alasan kembali; tidak ada rasa progres |
| B. Statistik guru saja | Jumlah sesi, menit, streak guru | Ringan, tanpa data siswa | Tidak terhubung ke kelas yang diajar |
| **C. Statistik per kelas (anonim)** | Sesi, menit, cakupan keahlian, partisipasi per kelas | Berguna untuk laporan ke sekolah/orang tua; tanpa data siswa | Perlu entitas Kelas |
| D. Statistik per siswa | Seperti orang tua | Paling detail | Input 20–30 nama tiap kelas sangat merepotkan; menyimpan data anak dalam jumlah besar memperbesar kewajiban perlindungan data (UU PDP No. 27/2022 menggolongkan data anak sebagai data pribadi spesifik) |

### Rekomendasi: **C + B** (per kelas anonim + profil guru)

**Statistik kelas** (Profil → kelas → Statistik):
- **Cakupan keahlian** (radar 6 sumbu): total poin keahlian dari misi yang dijalankan di kelas itu. Labelnya harus jujur: *"Keahlian yang sudah dilatih"*, **bukan** "kemampuan kelas". Tanpa observasi per siswa, aplikasi tidak bisa mengklaim siswa berkembang; yang bisa diukur adalah **paparan latihan**.
- Jumlah sesi & total menit per minggu/bulan.
- Rata-rata kehadiran per sesi (dari stepper jumlah siswa).
- Suasana kelas: rata-rata skala perasaan dari refleksi guru ("Bagaimana antusiasme kelas?").
- Peran yang paling sering dan yang belum pernah dimainkan → rekomendasi.
- **Laporan bulanan kelas** (P1): satu kartu/PDF berisi ringkasan + 4–6 foto kolase, siap dibagikan ke grup orang tua murid.

**Profil guru** (B):
- Streak, target harian, Ikan, dan tantangan harian berlaku seperti orang tua (motivasi kebiasaan guru).
- Total sesi di semua kelas, lencana guru (mis. "Guru Petualang": jalankan 5 peran berbeda).

**Kelas juga punya XP & level** (gamifikasi kolektif): "TK B Melati — Level 7". Ini memberi guru sesuatu untuk dirayakan bersama siswa ("Kelas kita naik level!") tanpa mencatat siswa individu.

**Penempatan di UI:** guru tidak melihat kata "anak" sama sekali. Copy otomatis berganti ("siswa", "kelas", "Tips untuk Guru").

---

## 8. Model data

Skema Supabase yang sudah ada dipertahankan. Tambahan yang dibutuhkan desain v2 (akun guru, pendamping, sesi misi multi-anak, memori, tantangan, pembeku streak, paket, persetujuan) beserta aturannya ada di [`DECISIONS.md`](./DECISIONS.md) §D. Bentuk konseptual entitas di bawah tetap menjadi acuan:

```
Account (parents)  role parent|teacher, plan, daily_goal_minutes, fish, streak_freezes
Child (children)   nickname, age, avatar, interests, learning_styles, focus_skills
Classroom          name, age_range, est_students, color  (tanpa data siswa)
MissionRun         mission, completed_at, classroom | participants[]
Memory             run, photo_path (Storage privat)
Reflection         adult_feeling, child_feelings{child: 1..5} | class_mood, note
XP / Skill         tetap di child_stats + mission_logs per anak
Badge, Certificate tetap di child_achievements / certifications_master
DailyQuest, StreakEvent, AccountMember, Invite, Consent  (baru)
```

---

## 9. Roadmap implementasi

Prompt siap pakai untuk setiap fase ada di [`prompts/CLAUDE_CODE_PROMPTS.md`](./prompts/CLAUDE_CODE_PROMPTS.md). Setiap fase harus bisa di-build dan dipakai.

| Fase | Isi | Layar |
|---|---|---|
| 0. Fondasi | Token, tema Nunito, aset baru, ikon aplikasi, struktur folder, lint, tes golden, galeri widget | |
| 1. Widget | Primitif, layout, ikon kustom, helper animasi | galeri |
| 2. Data dan logika | Tarik skema, migrasi tambahan, repository per domain, `lib/core/game` + tes, level dan streak baru | |
| 3. Onboarding dan akun | | 01, 14 sampai 17, 23 sampai 28, 43 |
| 4. Loop inti misi | Nav baru 4 tab, Beranda, misi multi-anak | 02 sampai 05, 07, 08, 11, 18, 19, 21, 31, 33, 45, 47, 48 |
| 5. Memori, tantangan, lencana | | 09, 10, 20, 22, 32, 34, 35, 49 |
| 6. Profil, akun, paket | | 06, 36 sampai 42, 44, 46, 54 |
| 7. Versi Guru | | 12, 13, 29, 30, 51 sampai 53 |
| 8. Offline dan pembayaran | Antrean offline, langganan Play/App Store | 50, 38 |
| 9. Poles dan audit | Aksesibilitas, performa, animasi, AI slop, hapus kode dan aset lama | semua |

---

## 10. Metrik keberhasilan

| Metrik | Target awal |
|---|---|
| Onboarding selesai (daftar → misi pertama dimulai) | ≥ 70% |
| Misi dimulai → misi selesai | ≥ 80% |
| Sesi yang menyertakan foto momen | ≥ 40% |
| Retensi D7 akun | ≥ 30% |
| Rata-rata waktu layar aktif per misi (di luar membaca langkah) | ≤ 2 menit |
| Akun orang tua dengan ≥ 2 anak yang pernah memakai "pilih peserta" lebih dari 1 anak | ≥ 50% |

---

## 11. Pertanyaan terbuka

1. ~~Nama pinguin maskot~~ → **Maro** (nama sementara, ditetapkan 27 Nov 2026).
2. Apakah konten misi untuk guru perlu versi langkah tersendiri, atau cukup tips tambahan? (Rekomendasi: cukup `tips_teacher` + opsi kelompok untuk v2.)
3. ~~Isi paket~~ → Paket Keluarga (F14). Harga final masih menunggu keputusan; angka di desain adalah contoh.
4. Apakah satu akun guru boleh dipakai bersama oleh beberapa guru (co-teacher)? (Rekomendasi: tidak untuk v2.)
