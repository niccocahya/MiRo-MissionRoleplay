# MiRO v2 — Developer Handoff Spec

> Sumber desain: kanvas **MiRO v2 — Redesign** (https://claude.ai/artifact/8HFtR7L83ai4o76JioKwZV), halaman **"v1 — Final"**, 54 layar 390×844 (lihat `design/SCREENS.md`). Halaman "v2.1" adalah eksperimen yang tidak dipakai.
> Platform: **Flutter** (lihat `docs/DECISIONS.md` A1). Token di `lib/core/theme/miro_tokens.dart` (salinan `design/miro_tokens.dart`).
> Dokumen ini awalnya ditulis dengan notasi Tailwind/CSS. Notasi itu **hanya cara menulis nilai**; terjemahkan ke Flutter dengan tabel konversi di bawah. 1 px = 1 logical pixel.
>
> | Notasi di dokumen | Flutter |
> |---|---|
> | `px-5`, `p-4`, `gap-3` (kelipatan 4) | `EdgeInsets.symmetric(horizontal: 20)`, `EdgeInsets.all(16)`, `SizedBox(width/height: 12)` / `MiroSpace` |
> | `h-14`, `size-11` | tinggi 56, 44 (`MiroSize`) |
> | `rounded-lg/xl/2xl` | `MiroRadius.lg/xl/sheet` (16/20/28) |
> | `bg-navy-900`, `text-ink-2`, `border-line` | `MiroColors.navy900`, `MiroColors.ink2`, `MiroColors.line` |
> | `.pressable`, lip | `MiroPressable` |
> | `:active`, `:focus-visible`, `aria-*` | state tekan, ring fokus, `Semantics` |
> | `spring-soft`, `ease-out-soft` | `MiroMotion.easeOut` + durasi token |
> | `env(safe-area-inset-bottom)` | `MediaQuery.paddingOf(context).bottom` / `SafeArea` |

---

## 0. Aturan global (berlaku untuk semua layar)

### Layout

| Hal | Spesifikasi |
|---|---|
| Lebar desain | 390. Harus rapi di 360 sampai 430 dan dengan teks 1.3×. |
| Margin layar | `px-5` (20px) |
| Top bar | 64px (`h-16`) termasuk 8px atas; isi 44–48px |
| Footer aksi | `px-5 pt-4 pb-7` + `env(safe-area-inset-bottom)`; tombol L 56px |
| Bottom nav | 80px, latar `surface`, `border-t-2 border-navy-100` |
| Latar | `bg-app` kecuali onboarding & perayaan (`bg-mood` + overlay salju opacity 0.45–0.5) |

### Breakpoint

| Lebar | Perubahan |
|---|---|
| < 360px | Grid peserta tetap 3 kolom, avatar 64px; judul `h1` turun ke `h2` |
| 360–430px | Desain dasar |
| Tablet (≥ 600) | Konten dibatasi lebar maksimum 480 di tengah |

### Token yang paling sering dipakai

| Token | Nilai | Pemakaian |
|---|---|---|
| `action-primary` / lip | `coral-600` #D9654E / `coral-700` #B24A34 | Tombol utama |
| `action-secondary` (dark) / lip | `navy-900` #0A264F / `navy-950` #04152E | Tombol utama di `bg-mood`, hero card |
| `feedback-success` / lip | `green-600` #17843F / `green-800` #0F582A | Tombol "SUDAH!" |
| `selected` | `amber-100` #FFE8B6 + border `coral-500` | Kartu terpilih |
| `line` | `navy-200` #D5DEEA | Border 2px & lip kartu putih |
| `ink` / `ink-2` / `ink-3` | navy-900 / navy-600 / navy-500 | Teks primer / sekunder / tersier |
| `radius-lg` / `radius-xl` / `radius-2xl` | 16 / 20 / 28 | Tombol / kartu / hero |
| `text-button` | 17/20, 800, uppercase, tracking .04em | Label tombol |

### Interaksi global

| Elemen | State | Perilaku |
|---|---|---|
| Semua elemen ber-lip (`.pressable`) | `:active` | `translateY(lip-h)`, lip → 0, 80 ms `ease-out` |
| Semua elemen interaktif | `:focus-visible` | outline 3px `sky-500`, offset 2px |
| Tombol | `disabled` | latar `navy-100`, lip `navy-200`, teks `navy-300`; bukan opacity |
| Tombol | `loading` | 3 titik memantul, lebar tetap, `aria-busy="true"` |
| Transisi layar maju | — | masuk dari kanan 24px + fade, `spring-soft` |
| Reduced motion | — | semua gerak jadi fade 150 ms; konfeti mati |

---

## 1. Onboarding — Tipe akun (`01 · TipeAkun`)

### Ringkasan
Langkah ke-2 dari 7 onboarding. Pengguna memilih **Orang Tua** atau **Guru**. Pilihan ini menentukan seluruh alur berikutnya dan tidak bisa diubah setelah akun dibuat (PRD F1).

### Komponen

| Komponen | Varian | Props | Catatan |
|---|---|---|---|
| `IconButton` | `onMood` | `icon=ArrowLeft`, `aria-label="Kembali"` | 44px, latar `white/75` |
| `ProgressBar` | `lesson` | `value=2 max=7` | flex-1, tinggi 16 |
| `Mascot` + `SpeechBubble` | pose `wave` | `text` | Gambar 104×160; balon `radius-xl`, ekor kiri |
| `ChoiceCard` | `list` | `icon`, `title`, `description`, `perks[]`, `selected` | Single-select; 2 item, gap 14. `perks` = 3 keunggulan (13px 800 + ikon centang 14px; centang `chef` saat tidak terpilih, `coral-700` saat terpilih; garis pemisah 2px `navy-100` / `amber-300`). Orang Tua: Hingga 6 anak, Statistik per anak, Kolase memori. Guru: Hingga 10 kelas, Statistik per kelas, Mode kelompok. Ditampilkan sebagai daftar centang selebar kartu di bawah garis pemisah, bukan chip yang menumpuk |
| `Button` | `primary` L | `disabled` sampai ada pilihan | Footer |

### State & interaksi

| Elemen | State | Perilaku |
|---|---|---|
| ChoiceCard | default | `surface`, border 2 `line`, lip-md `line` |
| ChoiceCard | selected | `selected` + border & lip `coral-500`; ikon wadah → solid `coral-500` dengan pop (scale 1.06, `spring-pop`); centang hijau muncul scale 0 → 1 |
| ChoiceCard | ketuk saat terpilih | batal pilih (tombol kembali disabled) |
| Balon bicara | mount | pop 200 ms, teks muncul per kata 30 ms |
| Lanjut | ketuk | simpan `account.role` lalu ke layar daftar/masuk |

### Konten
- Judul kartu ≤ 12 karakter, deskripsi ≤ 70 karakter (2 baris di 390px).
- Catatan di bawah kartu: `caption` `ink-2`: "Tipe akun tidak bisa diubah setelah dibuat. Akun guru tidak menyimpan data siswa."

### Aksesibilitas
- Kartu pilihan memakai `role="radiogroup"` pada wadah dan `role="radio"` + `aria-checked` pada kartu (mockup memakai `aria-pressed`; di kode gunakan pola radio).
- Urutan fokus: Kembali → Orang Tua → Guru → Lanjut.

---

## 2. Beranda — Peran & daftar misi (`02 · Main`)

### Ringkasan
Layar utama. Menjawab dua pertanyaan: "sudah berapa lama main hari ini?" dan "misi apa berikutnya di peran ini?". Tanpa jalur lingkaran zig-zag: misi tampil sebagai **kartu kotak dalam timeline**, dan peran bisa diganti lewat **tab peran** (PRD F4, DS §7.12).

### Layout (atas → bawah)
1. **TopBar** 64px: `ProfileSwitcher` kiri; kanan `StatPill` Ikan dan `IconButton` notifikasi 40px. Streak **tidak** di top bar Beranda karena sudah jadi kartu utama.
2. **StreakCard** `mt-1.5`: kartu streak + target hari ini (spesifikasi DS §7.12). Angka streak 32px, 7 kristal hari, bar target coral.
3. **RoleTabs** `mt-4`: judul seksi "Pilih peran" `h3` + "5 peran" `caption`; baris tab scroll horizontal, padding kiri-kanan 20.
5. **MissionTimeline** `pt-3.5`, gap 10: garis putus-putus warna peran di x=39px; tiap baris = lencana 40×40 + kartu.
6. **BottomNav** 80px (`z-index` di atas daftar).

### Komponen

| Komponen | Props | Catatan |
|---|---|---|
| `ProfileSwitcher` | `profile`, `onOpen` | Sama seperti sebelumnya |
| `StatPill` | `variant`, `value` | streak (`sky-700`), Ikan (`amber-800`) |
| `NotificationButton` | `hasUnread` | Icon button 40, titik 8px `coral-500` border putih |
| `StreakCard` | `streak`, `record`, `minutes`, `goal`, `week[7]` | Teks kanan bawah dinamis: "{sisa} menit lagi jadi {streak+1}" / "Target tercapai!" (hijau). Ketuk → bottom sheet kalender streak |
| `RoleTabs` | `roles[]`, `active`, `onChange` | `role="tablist"`; tab `role="tab"` + `aria-selected` |
| `MissionTimeline` | `role`, `missions[]` | Render `MissionRow` per misi |
| `MissionRow` | `mission`, `state` | `done` / `perfect` / `active` / `locked`, lihat DS §7.12 |
| `MissionActiveCard` | `mission`, `role` | Latar `-soft`, border & lip warna peran, Mink berkostum 104×128 **tidak terpotong** |
| `BottomNav` | `active="adventure"` | DS §7.11 |

### State & interaksi

| Elemen | State | Perilaku |
|---|---|---|
| Tab peran | ketuk | thumbnail tekan (M1); header, progress, garis, dan daftar misi berganti warna & isi dengan animasi `swap` 280 ms (fade + naik 10px) |
| Kartu misi selesai/sempurna | ketuk | bottom sheet detail misi (bisa diulang) |
| Kartu misi aktif | "MULAI MISI" | ke Pilih peserta (atau langsung ke Mainkan jika hanya 1 anak) |
| Kartu terkunci | ketuk | toast "Selesaikan misi sebelumnya dulu" + kartu bergoyang ±6px |
| StreakCard | ketuk | bottom sheet kalender streak + info Pembeku Streak |

### Data contoh per peran (untuk mockup)

| Peran | Warna `-base` / `-lip` / `-soft` | Misi 1–5 |
|---|---|---|
| Dokter | #5FA873 / #3F8253 / #E8F2E6 | Kuman Takut Sabun · Detak Jantung Boneka · Klinik Boneka · Perban Pahlawan · Puncak: Hari Dokter |
| Koki | #5C9FD6 / #3D7FB8 / #EBF4FA | Salad Pelangi · Roti Isi Wajah Lucu · Membuat Bola Biskuit · Jus Tiga Warna · Puncak: Piknik Koki |
| Seniman | #F08A4B / #C86A30 / #FDF1E8 | Cap Jari Warna-warni · Jalan-jalan Kolase Alam · Topeng Kertas · Lukis Batu · Puncak: Pameran Mini |
| Guru | #9B7FD4 / #7A5FB3 / #F6F0FA | Mengajari Mainan · Kelas Huruf · Dongeng Boneka · Kuis Hewan · Puncak: Hari Guru Kecil |
| Atlet | #E56B7E / #BF4C5F / #FAF0F0 | Lari Estafet Bantal · Yoga Hewan · Lempar Tangkap · Lompat Melewati Warna · Puncak: Olimpiade Rumah |

Judul misi selain yang sudah ada di repo (Kuman Takut Sabun, Membuat Bola Biskuit, Jalan-jalan Kolase Alam, Mengajari Mainan, Lompat Melewati Warna) adalah **contoh** dan perlu konten langkahnya ditulis.

### Edge case
- **Belum ada misi selesai:** misi 1 menjadi kartu aktif; garis timeline tetap tampil.
- **Semua misi peran selesai:** kartu aktif diganti kartu sertifikat ("Rafi resmi jadi Koki Kecil!") + tombol "Lihat sertifikat".
- **Profil "Semua anak":** status kartu mengikuti anak yang paling tertinggal; badge kecil avatar di kartu selesai menunjukkan siapa saja yang sudah.
- **Judul misi panjang:** 2 baris, lalu "…".
- **Loading:** skeleton kartu target + 5 tab + 3 baris kartu.

### Aksesibilitas
- Tab: panah kiri/kanan berpindah tab; isi daftar diumumkan lewat `aria-live="polite"` ("Koki Kecil, 2 dari 5 misi selesai").
- Kartu misi = `<button>` dengan label lengkap ("Misi 4: Jus Tiga Warna, terkunci").
- Garis timeline & dekorasi `aria-hidden`.

---

## 3. Pilih peserta (`03 · Peserta`)

### Ringkasan
Muncul setelah "MULAI MISI" **hanya jika akun punya ≥ 2 anak** (PRD F5). Multi-select; default = anak aktif di switcher.

### Layout
TopBar (IconButton kembali + `overline` "Misi 3 dari 5") → **kartu ringkasan misi** 96px (latar peran `-soft`, border & lip warna peran, Mink berkostum 96×118 di kanan, label "Koki Kecil" (13px 800) + judul `h3` + chip "15 menit") → `h2` "Siapa yang ikut main?" + `body` `ink-2` → baris "{n} dari {total} anak dipilih" + tautan ghost "Pilih semua" → grid 3 kolom gap 12 → kartu ringkasan hadiah → footer.

### Komponen

| Komponen | Varian | Props | Catatan |
|---|---|---|---|
| `ParticipantCard` | — | `child`, `selected`, `outOfRange` | Kartu pilihan vertikal; avatar 76 dengan ring 4px; centang 26 di pojok kanan bawah avatar |
| `Chip` | `warning` | "Untuk 4–8 th" | `amber-100` / teks `amber-800`; informasi saja, tidak memblokir |
| `RewardSummary` | — | `xp`, `skills[]` | Kartu `info`; chip XP (`amber-50` + `amber-800`) dan chip keahlian |
| `Button` | primary L | label dinamis | Disabled: "Pilih minimal 1 anak" |

### State & interaksi

| Elemen | State | Perilaku |
|---|---|---|
| ParticipantCard | selected | latar `selected`, border/lip `coral-500`, avatar scale 1.04 + ring coral, centang pop |
| "Pilih semua" | semua terpilih | label menjadi "Batal pilih semua" |
| Tombol utama | n ≥ 1 | "MULAI DENGAN {n} ANAK" (n = 1 → "MULAI DENGAN RAFI") |
| Tombol utama | ketuk | buat `MissionRun` + `RunParticipant[]`, ke layar Mainkan |

### Akun Guru (layar yang sama, isi berbeda)
Grid diganti `Stepper` "Berapa siswa yang hadir?" (default `est_students`, min 1, maks 60) + toggle "Kerja kelompok" → stepper jumlah kelompok (2–10). Kartu ringkasan: "Kelas TK B Melati dapat +20 XP".

### Edge case
- 6 anak: grid 3×2; kartu tetap 76px.
- Semua anak di luar rentang usia: tetap boleh, chip muncul di semua kartu.
- Anak diarsipkan tidak tampil.

### Aksesibilitas
Grup `role="group" aria-label="Pilih anak yang ikut"`; kartu `role="checkbox"` + `aria-checked`. Pembaca layar mengumumkan perubahan jumlah lewat `aria-live="polite"` pada baris hitungan.

---

## 4. Mainkan misi (`04 · Misi`)

### Ringkasan
Satu langkah per layar. Orang dewasa membaca, anak bermain, lalu tekan "SUDAH!" (PRD F5, DS §7.13).

### Layout
TopBar: icon `X` 44 (warna `navy-300`) · `ProgressBar lesson` flex-1 · tumpukan avatar peserta 32px (overlap −10). Kartu langkah mengisi sisa tinggi: `surface`, border 2 `line`, `radius-2xl`, padding 20, gap 14. Di atas kartu: pita latar warna peran `-soft` 200px (sudut bawah 36px) dan baris **"Siapkan dulu"**: judul "Siapkan dulu" (15px 900) + penghitung "2 dari 4 siap" di kanan, lalu chip bahan yang bisa dicentang dan **dibungkus ke baris berikutnya** (tinggi 36, kotak centang 18px; tercentang = border/isi warna peran). Bagian bawah kartu langkah: baris "Berikutnya: {judul langkah berikutnya}" di atas garis putus-putus. Isi kartu: panel ilustrasi 150px (`sky-50`, `radius-xl`, label langkah `overline` di pojok), `h2`, `body-lg`, panel Tips (`sky-50`, `radius-lg`, tombol lipat 48px, ikon custom balon bicara + hati 32px, bukan bola lampu). Footer: `Button success` L.

### State & interaksi

| Elemen | State | Perilaku |
|---|---|---|
| "SUDAH!" | ketuk | (1) tombol morph jadi centang 250 ms; (2) lesson bar terisi ke `(i+1)/n` 450 ms `ease-out-soft` + kilau; (3) Mink acungan muncul 600 ms di pojok kanan bawah kartu; (4) suara `step`, getar 20; (5) kartu berikutnya masuk dari kanan 320 ms |
| "SUDAH!" | langkah terakhir | label "SUDAH! SELESAIKAN MISI" → layar Abadikan Momen (PRD F6), lalu Perayaan |
| Tips | default | terbuka di langkah 1, terlipat di langkah 2+ |
| Tips | toggle | chevron rotate 180°, tinggi beranimasi `spring-soft` |
| `X` | ketuk | bottom sheet konfirmasi: Mink sedih, "Yakin berhenti? Progres misi ini belum tersimpan.", `Button secondary` "Lanjut main" + `danger` "Berhenti" |
| Timer (jika misi punya) | — | icon button `Timer` di top bar kanan menggantikan avatar; membuka hitung mundur di dalam kartu |

### Konten
- Judul langkah ≤ 24 karakter. Instruksi ≤ 180 karakter (≤ 5 baris). Tip ≤ 140 karakter.
- Copy tips berganti otomatis untuk akun Guru ("Tips untuk Guru", `tips_teacher`).

### Edge case
- Instruksi lebih panjang dari ruang: kartu bisa di-scroll di dalam, footer tetap.
- Layar terkunci/aplikasi ditutup di tengah misi: simpan `activeStep` di storage lokal; saat dibuka lagi tampil "Lanjutkan misi Membuat Bola Biskuit?".

### Aksesibilitas
`role="progressbar"` dengan `aria-valuenow/max` dan label "1 dari 3 langkah selesai". Saat langkah berganti, fokus pindah ke judul langkah (`tabIndex=-1`) dan diumumkan.

---

## 5. Perayaan (`05 · Perayaan`)

### Ringkasan
Momen reward setelah misi (DS §8.4). Satu tombol, satu konfeti.

### Urutan animasi

| t (ms) | Elemen | Animasi | Durasi | Easing |
|---|---|---|---|---|
| 0 | Latar `bg-mood` | circular reveal dari tombol terakhir | 400 | `ease-out-soft` |
| 0 | Mink pose menang (190×234) | pop 0.6 → 1 | 520 | `spring-pop` |
| 300–550 | Konfeti (7 kepingan) | jatuh 420px + rotasi 540°, sekali | 1600 | custom |
| 350 | `display` "Misi selesai!" + subjudul nama anak | rise 16px + fade | 420 | `ease-out-soft` |
| 900 / 1020 / 1140 | 3 stat tile (XP, Bermain, Peserta) | rise berurutan; angka odometer | 420 | `ease-out-soft` |
| 1600 | Kartu target harian & streak | rise + kristal grow (0.6 → 1.15 → 1) | 600 | `spring-pop` |
| 1800 | Baris poin keahlian | rise | 420 | `ease-out-soft` |
| 2000 | Tombol "LANJUT" + tautan | rise | 420 | `ease-out-soft` |

Ketuk di mana saja = lompat ke state akhir (semua elemen tampil).

### Komponen

| Komponen | Varian | Catatan |
|---|---|---|
| `StatTile` | `xp` (amber), `time` (sky-500), `people` (coral-500) | Bingkai berwarna 3px + label `overline` navy di atas + isi putih 52px; lip-md warna masing-masing |
| `StreakCard` | — | Kartu `info`; ikon kristal 40; angka `h2` `sky-700` |
| `SkillGainRow` | `skills[]`, `badgeProgress` | `overline` "Poin keahlian untuk {nama}" + chip keahlian (ikon 24px dalam lingkaran `-soft`) + chip progres lencana (`amber-50`, teks `amber-800`) |
| `Button` | dark L | "LANJUT" → layar Refleksi/Hasil |
| Tautan ghost | — | "Lihat perkembangan anak" → Perkembangan |

### Edge case
- Target harian belum tercapai: kartu streak menampilkan ring progres "10/15 menit hari ini".
- Level naik / lencana baru: setelah "LANJUT" tampil layar masing-masing (DS §8.4 langkah 6) sebelum kembali ke Beranda.
- 1 peserta: subjudul "Rafi jadi koki hebat hari ini."; ≥ 3 peserta: "Rafi, Nara, dan Dimas …".
- Akun guru: "Kelas TK B Melati hebat hari ini!" dan tile Peserta berisi angka "24 siswa".

### Aksesibilitas
Gunakan `aria-live="polite"` untuk ringkasan ("Misi selesai. Plus 25 XP. Streak 13 hari."). Hormati reduced motion.

---

## 6. Profil (`06 · Profil`)

### Layout
Header (avatar akun 72, `h2` nama, `Button secondary S` "UBAH PROFIL", icon button pengaturan 44) → 3 stat tile berwarna (streak `sky-50`/border `sky-300`, misi `coral-100`/`coral-200`, waktu `amber-50`/`amber-300`) → kartu **"Main bersama minggu ini"** (7 batang tinggi maks 64px, skala 30 menit; hari ini `coral-500`, hari aktif `chef`, hari kosong `navy-100`; total menit di kanan atas; satu kalimat insight `caption`) → seksi "Anak-anak": `ChildRow` × n + tombol dashed "Tambah anak" → (di bawah fold) Lencana, Paket, Pengaturan, Keluar → BottomNav (aktif: Profil).

### Komponen

| Komponen | Props | Catatan |
|---|---|---|
| `ChildRow` | `child` | Kartu interactive: avatar 52, nama `title`, "Level n" `amber-800`, XP bar 12px, caption "70 / 140 XP ke level 7". Ketuk → Perkembangan anak |
| `AddChildButton` | — | Border 2px dashed `navy-300`, tinggi 56, `radius-xl`; disembunyikan bila sudah 6 anak (ganti caption "Maksimal 6 anak") |

### Aturan data
XP ke level berikutnya = `40 + 20 × (level − 1)` (PRD F8): Level 6 → 140, Level 3 → 80, Level 8 → 180.

### Akun Guru
"Anak-anak" → "Kelas"; `ChildRow` → `ClassRow` (ikon kelas di lingkaran warna kelas, nama kelas, rentang usia, level kelas); "Tambah anak" → "Tambah kelas" (maks 10). Tambah kartu "Statistik mengajar" (total sesi, menit) di atas.

### Edge case
- Nama akun panjang: `h2` maks 2 baris, lalu "…".
- Anak tanpa misi: XP bar kosong + caption "Belum ada misi. Ayo mulai!".

---

## 7. Abadikan momen (`07 Abadikan`)

Muncul setelah langkah terakhir misi, sebelum Perayaan.
- Pita atas `sky-50` 246px. Judul `h1` 28px "Abadikan momen ini?" + keterangan (foto masuk ke Kolase Memori anak peserta, privat). Mink utama 84×118 di kanan (`floaty`).
- **3 slot foto** (grid 3 kolom, tinggi 150). Kosong: border 2px putus-putus `sky-400`, ikon kamera + "Tambah". Terisi: polaroid putih (padding 8/8/6, radius 10, lip `navy-200`), miring −3°/2°/−1.5°, animasi `popr`. Ketuk foto terisi = hapus (dengan konfirmasi di kode).
- Kartu tips (ikon tips custom) dan pita bonus "Dengan foto, tiap anak dapat +5 XP" (`amber-50`).
- Footer: primary "SIMPAN" (nonaktif jika 0 foto) + tautan "Lewati, tanpa foto". Keduanya ke Perayaan.

## 8. Refleksi (`08 Refleksi`)

Dibuka dari tombol "LANJUT" di Perayaan.
- Pill misi (thumbnail Mink berkostum + judul) + tautan "Lewati". Judul "Bagaimana misinya?" + chip "+5 XP".
- **Perasaan Bunda/Guru:** 5 wajah pinguin SVG 48px dalam tombol 56px (`role="radio"`). Terpilih: latar `amber-100`, border 2px `coral-500`, scale 1.08; tidak terpilih: `grayscale(1)` + opacity 0.55. Label perasaan terpilih di kanan judul (`coral-700`).
- **Perasaan anak:** satu baris per anak peserta (avatar 36 + nama) dengan wajah 36px; switch "Sama untuk semua" (40×24) menyamakan nilai semua anak.
- Textarea catatan opsional (maks 280 karakter), kotak info "Jawabanmu membantu Mink memilih misi…", footer "SIMPAN" → Beranda.
- Wajah: 1 kurang seru (alis turun, paruh terbalik), 2 biasa, 3 seru (senyum kecil), 4 seru banget (mata melengkung + pipi), 5 luar biasa (mata besar berbinar + pipi).

## 9. Memori (`09 Memori`)

- Judul `h1` + "{n} momen". Chip filter: Semua, lalu satu per anak (avatar 24 + nama); aktif = `navy-900` teks putih.
- Kartu **Kolase November** (`coral-100`, border/lip `coral-200`): 2 polaroid kecil miring + judul + keterangan + chevron.
- Judul bulan `h3`, lalu grid **masonry 2 kolom** (gap 12). Kartu momen: polaroid putih radius 16, foto tinggi bervariasi (130–170), tag peran di pojok kiri atas (pill putih, teks warna peran `-lip`), judul misi 15px 900, tanggal + tumpukan avatar peserta 22px.
- Filter mengubah isi dengan animasi `rise`. Empty state: Mink utama + "Belum ada momen. Mainkan misi pertama dan abadikan keseruannya."

## 10. Tantangan (`10 Tantangan`)

- Judul + saldo Ikan (pill putih).
- **Peti harian** (`amber-50`, border/lip `amber-300`, radius 24): ilustrasi peti 84×72 (`floaty`), judul + keterangan, tombol `reward` "BUKA PETI" (aktif saat 3/3). Setelah diketuk: peti terbuka (`popin`), tombol berganti kotak putus-putus "+25 Ikan masuk ke tabunganmu", saldo naik.
- "Hari ini" + "Reset 5 jam lagi", 3 kartu tantangan: ikon 44 (latar `-soft` sesuai jenis) + lencana centang hijau, judul, bar progres hijau (`grow-x`), hadiah Ikan.
- Tantangan mingguan: kartu `navy-900` dengan bar `sky-400`.
- Toko **Pembeku Streak**: kartu putih, ikon kristal + kepingan salju, keterangan, tombol kecil "100 Ikan".

## 11. Kalender streak (`11 Kalender streak`)

Bottom sheet dari kartu streak Beranda (top 196px, radius 28, backdrop `navy-950/55`).
- Kotak kristal 64 (`floaty`) + "12 hari beruntun" + kalimat rekor; tombol tutup 40.
- Kalender bulan (Senin di kiri): tercapai = kotak `sky-500` teks putih + lip `sky-700`; hari ini = putih dengan cincin 3px `coral-500`; pembeku dipakai = `sky-50` + ikon kepingan salju; hari lewat tanpa target = teks `navy-500`; hari mendatang = `navy-300`. Legenda di bawah.
- Info "1 Pembeku Streak tersimpan" (`sky-50`) + primary "MAIN 5 MENIT LAGI".

## 12. Beranda Guru (`12 Beranda Guru`)

Sama dengan Beranda (§2) dengan perbedaan:
- Switcher kelas: ikon kelas (bintang putih di lingkaran warna kelas) + nama kelas.
- Kartu streak tanpa baris 7 hari (detail di kalender) dengan sapaan "Bu/Pak {nama}".
- Baris **3 info kelas**: Level kelas (`teacher-soft`), Siswa terdaftar, Sesi minggu ini.
- Tombol kartu misi aktif: "MULAI DI KELAS" → layar 13.

## 13. Mulai misi di kelas (`13 Mulai misi di kelas`)

Pengganti Pilih peserta untuk akun Guru.
- Kartu ringkasan misi ("Koki Kecil di TK B Melati").
- "Berapa siswa yang hadir?" + "Cukup jumlahnya. Nama siswa tidak dicatat." **Stepper** besar: tombol 52px, angka 44px (`popin` setiap berubah, `aria-live`), "dari {total} siswa"; batas 1–60.
- Kartu **Kerja kelompok**: switch 48×28; saat aktif muncul stepper kelompok (2–10) + "5 sampai 6 siswa per kelompok" (dihitung otomatis).
- Pita hadiah kelas (`teacher-soft`), info izin foto, primary "MULAI DENGAN {n} SISWA".

---

## 13b. Gelombang A: onboarding, detail, dan progres (layar 14 sampai 22)

| No | Layar | Inti spesifikasi |
|---|---|---|
| 14 | **Splash** | Latar `bg-mood` + salju. Logo aplikasi MiRO 72×72 (radius 20, bayangan `0 4px 0 rgba(4,21,46,.35)`, `popin`), "MiRO" 56px 900, tagline 20px. Mink melambai 250×306 kanan bawah (`floaty`). Indikator 3 titik + "Memuat petualangan...". Lanjut otomatis 1,8 s ke Tipe akun. |
| 15 | **Daftar atau masuk** | Segmented control 2 tab (`navy-100`, tab aktif putih + lip). Field: Nama panggilan (hanya Daftar), Email, Kata sandi dengan tombol mata 44px yang berfungsi. Contoh state error email: border `red-500` + pesan `red-700` dengan ikon. Footer: primary "BUAT AKUN"/"MASUK", pemisah "atau", tombol Google (`secondary`, logo Google asli). |
| 16 | **Setup anak** (langkah nama, avatar, usia) | Mink utama + balon "Siapa nama pahlawan kecilmu?". 6 avatar 42px + tombol unggah foto (border putus-putus). Input nama dengan keterangan "Cukup nama panggilan". Usia: grid 5 kolom tombol 48px (2 sampai 10) + label "tahun". Langkah kesukaan, gaya belajar, dan keahlian memakai pola ChoiceCard yang sama. |
| 17 | **Target harian** | 4 kartu radio (Santai 10, Rutin 15 + chip "Disarankan" hijau, Serius 30, Penuh 45). Kotak menit 52px di kiri (terpilih `coral-500`, scale 1.06). Catatan: "Target ini mengisi kristal streak." |
| 18 | **Detail misi** (bottom sheet, top 70px) | Panel ilustrasi 168px `-soft` peran + pill "Koki Kecil, misi 3" + tombol tutup. Judul `h2`, chip (durasi, usia, keahlian), deskripsi, kotak "Yang dibutuhkan" (grid 2 kolom), "3 langkah" bernomor (kotak 28px). Primary "MULAI MISI". Dibuka dari kartu misi di Beranda. |
| 19 | **Ganti anak** (bottom sheet, top 300px) | "Main bersama siapa?" + tautan "Kelola anak". Kartu radio per anak (avatar 44, nama, "6 tahun, level 6", lingkaran centang) + "Semua anak" (2 avatar bertumpuk). Tombol putus-putus "Tambah anak". Dibuka dari switcher di top bar Beranda. |
| 20 | **Perkembangan anak** | Header avatar 56 + level + XP bar. Segmented "Minggu ini / Bulan ini". **Radar 5 keahlian** (segi lima, DECISIONS §F2) (SVG 340×256, 4 cincin grid `navy-100`, data sekarang: isi `chef` 25% + garis `navy-900` 2.5px + titik 4px; pembanding: garis putus-putus `navy-300`; label 12px 900). Kartu insight `sky-50` + Mink Atlet. Daftar 6 keahlian dengan bar warna khas + selisih hijau. Dibuka dari kartu anak di Profil. |
| 21 | **Level naik** | Latar `bg-mood` + salju turun sekali. Mahkota 88×60 + kotak level 132px (`navy-900`, radius 40, lip 8px), keduanya `popin` bertahap. Judul + subjudul, 3 tile ringkasan (misi, peran, lencana baru), progres menuju level berikutnya. Mink + kartu hadiah (avatar dengan syal). Primary dark "PAKAI SYAL DAN LANJUT" + "Nanti saja". |
| 22 | **Koleksi lencana** | Kartu sertifikat berikutnya (`navy-900`, Mink koki, bar amber). Grid 3 kolom lencana segi enam 76×80: bingkai warna tingkat (Perunggu `#C8865A`, Perak `#AFC0D3`, Emas `amber-500`) + lip lebih gelap, isi putih, ikon garis 24px. Terkunci: bingkai `navy-200`, ikon `navy-300`, progres "1 dari 5". Label tingkat memakai warna gelap agar kontras: Perunggu `#8E5530`, Perak `navy-500`, Emas `amber-800`. |

## 13c. Gelombang B: onboarding lanjutan dan versi Guru (layar 23 sampai 30)

| No | Layar | Inti spesifikasi |
|---|---|---|
| 23 | **Pilih bahasa** | Layar pertama setelah Splash. 2 kartu radio besar dengan kode teks "ID" dan "EN" di kotak 48px (bukan ikon globe atau bendera). Primary "LANJUT" nonaktif sampai ada pilihan. Bisa diubah lagi di Pengaturan. |
| 24 | **Kesukaan anak** | Pola ChoiceCard dari Setup anak, pilih banyak (maks 3). Grid 2 kolom kartu 72px: ikon garis 24px di kotak warna peran + label. Penghitung "2 dari 3 dipilih". Tiap pilihan mengurutkan peran di tab Beranda. |
| 25 | **Gaya belajar** | Boleh lebih dari satu: Visual, Auditori, Kinestetik. Kartu pilihan dengan ikon + satu kalimat contoh, plus kartu info "Belum yakin? Tidak apa-apa". Dipakai untuk memilih varian langkah misi (lebih banyak gambar, suara, atau gerak). |
| 26 | **Keahlian yang ingin dilatih** | Pilih banyak dari 5 keahlian (sama dengan radar Perkembangan). Chip besar yang membungkus ke baris baru, tidak boleh terpotong. Ikon tiap keahlian berbeda dan tidak boleh sama dengan ikon kesukaan di layar 24 (di 24, Memasak memakai ikon panci khusus). |
| 27 | **Tambah anak lain** | Ringkasan anak yang sudah dibuat (kartu avatar + nama + usia) + tombol putus-putus "Tambah anak". Secondary "Nanti saja" lanjut ke Target harian. |
| 28 | **Izin notifikasi** | Mink + bel, judul, 3 manfaat dalam daftar centang lebar penuh, pratinjau notifikasi mirip sistem. Primary "IZINKAN" memicu dialog OS; "Nanti saja" tetap lanjut. Jangan meminta izin sebelum layar ini. |
| 29 | **Setup kelas (Guru)** | Stepper 3 langkah: nama kelas, rentang usia, jumlah murid (stepper angka, tanpa nama murid). Kode kelas otomatis ditampilkan di akhir. |
| 30 | **Statistik kelas (Guru)** | Hanya data anonim per kelas: total misi, menit main, keterlibatan rata-rata, sebaran keahlian (bar), peran favorit. Tidak ada daftar nama murid di mana pun. Dibuka dari baris info di Beranda Guru. |

## 13d. Gelombang B: lencana, memori, dan akun (layar 31 sampai 38)

| No | Layar | Inti spesifikasi |
|---|---|---|
| 31 | **Lencana baru** (layar penuh `navy-900`) | Muncul setelah Refleksi jika ada lencana baru. Lencana segi enam 150px `popin`, sinar amber berputar 90° sekali (8 s, 1 iterasi). Label "Lencana baru untuk {nama}" `amber-400`, judul 36px, pill tingkat, progres ke tingkat berikutnya. Primary amber "LANJUT" ke Beranda + tautan "Lihat koleksi lencana". Bila lebih dari satu lencana, tampilkan berurutan. |
| 32 | **Sertifikat peran** | Kertas krem `#FFF8E9`, bingkai amber 3px + garis putus-putus dalam, logo MiRO 40px, nama anak 40px 900, pose menang peran, kalimat capaian, footer tanggal dan pendamping. Tombol "BAGIKAN" (secondary) dan "UNDUH" (primary, ekspor PNG 1080×1350). Dibuka dari kartu "Sertifikat berikutnya" di Koleksi lencana setelah Misi Puncak selesai. |
| 33 | **Konfirmasi keluar misi** (bottom sheet, `role="alertdialog"`) | Dibuka dari tombol X di layar Misi. Scrim `rgba(4,21,46,.55)`. Mink bingung + tanda tanya, progres langkah saat ini. "BERHENTI" (teks `red-700`, secondary) ke Beranda; "LANJUT MAIN" (success, lebih lebar) menutup sheet. Fokus awal di "Lanjut main". Tombol kembali Android = Lanjut main. |
| 34 | **Detail momen** | Foto 300px radius 24 + pill peran + indikator halaman bila foto lebih dari satu. Judul, avatar anak bertumpuk + tanggal. Kartu kutipan anak (tanpa rekaman suara di v2). Chip ringkas (XP, keahlian, durasi). Primary "MASUKKAN KE KOLASE". Dibuka dari kartu di Memori. |
| 35 | **Kolase bulanan** | Kanvas `cream-200` radius 24 dengan lip, judul bulan, nama anak, Mink melambai, grid 3×2 polaroid miring (−5° sampai 5°, `popr` bertahap 50 ms), footer jumlah momen. Pilihan gaya: Ceria, Grid, Album (segmented). "SIMPAN" dan "KIRIM". Bulan dengan kurang dari 3 momen: tampilkan kolase dengan slot kosong bertuliskan "Abadikan momen berikutnya". |
| 36 | **Kelola anak** | Info Mink tentang batas paket, penghitung "3 dari 5 anak", kartu per anak (avatar 52, nama, usia, kesukaan, pill level, tombol ubah 44px) yang membuka Perkembangan. Tombol putus-putus "Tambah anak", baris "Pendamping lain". Hapus anak ada di layar ubah, dengan konfirmasi dua langkah. Dibuka dari "Kelola" di Profil dan Ganti anak. |
| 37 | **Pengaturan** | Grup kartu: Pengingat (toggle + jam, Target harian), Suara dan gerak (Suara Mink, Getar, Kurangi animasi yang default mengikuti perangkat), Akun (Bahasa, Paket langganan, Privasi dan data anak). Toggle 48×28, aktif `success-600`, `role="switch"`. "Keluar dari akun" teks `red-700`. Versi + tautan Bantuan di bawah. |
| 38 | **Paket Keluarga** (desain ulang) | Tanpa kartu harga gaya SaaS. Atas: panel `sky-50` "Tiga peran baru menunggu {anak}" berisi 5 tile peran 56px; peran yang sudah ada abu, yang terbuka diberi bingkai warna peran + lencana gembok amber. Dua baris manfaat dengan visual nyata (avatar anak bertumpuk, polaroid mini). Pilihan bayar `role="radiogroup"`: Tahunan (default, Rp299.000, setara Rp24.900 per bulan, hemat 36%) dan Bulanan (Rp39.000). Garis waktu uji coba 3 titik: hari ini, pengingat H-2, tagihan pertama. CTA "COBA GRATIS 7 HARI" + teks tanggal tagihan dan cara batal. Harga masih contoh. |

### Alur prototipe tambahan
- Misi (X) → Konfirmasi keluar → Beranda atau kembali ke Misi
- Refleksi (Simpan) → Lencana baru → Beranda
- Memori: kartu kolase → Kolase bulanan; kartu momen → Detail momen → Kolase bulanan
- Profil: ikon gerigi → Pengaturan → Paket langganan; "Kelola" → Kelola anak → Tambah anak / Perkembangan
- Koleksi lencana: kartu sertifikat → Sertifikat

## 13e. Gelombang C: akun, keamanan, streak, dan paket (layar 39 sampai 46)

| No | Layar | Inti spesifikasi |
|---|---|---|
| 39 | **Ubah data anak** | Avatar 88 dengan tombol kamera, 5 pilihan avatar 48px (terpilih: ring 3px `chef-500`), field nama, stepper usia (tombol 44px), chip kesukaan maks 3 yang membungkus baris. Tautan merah "Hapus profil {nama}" di bawah. Dibuka dari kartu anak di Kelola anak. |
| 40 | **Hapus profil anak** (bottom sheet, 2 langkah) | Ikon tempat sampah di kotak `red-50`. Ringkasan yang ikut terhapus (misi, lencana, foto). Tautan "Unduh semua foto dulu". Konfirmasi dengan mengetik nama anak; tombol "HAPUS" nonaktif (`navy-100`, teks `navy-400`) sampai cocok, lalu `danger` (`#C2362B`, lip `#8F2219`). Setelah hapus: toast "Profil Rafi dihapus" tanpa undo (data sudah hilang). |
| 41 | **Undang pendamping** | Kode 6 karakter di kartu `navy-900` (sel 40×52), berlaku 48 jam. "SALIN KODE" dan "KIRIM LINK" (share sheet OS). Daftar pendamping 2 dari 3 dengan peran; pemilik akun tidak bisa dihapus. Paket Gratis: 1 pendamping tambahan; Keluarga: 3. |
| 42 | **Privasi dan data anak** | Kartu jaminan `green-50`. Grup Izin (toggle foto, laporan email; tanpa suara di v2) dan Data (unduh ZIP, kebijakan privasi, hapus akun keluarga merah). Catatan tanggal persetujuan orang tua. Mematikan "Simpan foto momen" menyembunyikan langkah Abadikan. Wajib untuk UU PDP. |
| 43 | **Lupa kata sandi** | Field email terisi dari layar Masuk. Setelah kirim: kartu sukses `green-50` `role="status"` dengan hitung mundur kirim ulang 60 s. Jangan beri tahu apakah email terdaftar (keamanan): pesan sama untuk semua email. |
| 44 | **Ubah profil orang tua** | Avatar inisial 88, nama panggilan dengan pratinjau sapaan Mink, segmented sapaan (Bunda, Ayah, Lainnya), email, baris "Ganti kata sandi". Dibuka dari "Ubah profil" di Profil. |
| 45 | **Streak terhenti** (layar penuh `navy-900`) | Muncul sekali saat aplikasi dibuka setelah hari terlewat tanpa Pembeku. Nada tidak menyalahkan. Mink + kristal retak (terpisah, tidak menimpa). Baris 7 hari dengan hari terlewat abu `#3B4E6B`. Opsi pulihkan dengan 200 ikan, hanya 24 jam pertama. Primary "MULAI MISI HARI INI". |
| 46 | **Peran terkunci (paket Gratis)** | Beranda dengan tab Seniman, Guru, dan Atlet berisi lencana gembok 24px dan gambar `grayscale(.6) opacity(.7)`. Tab tetap bisa dipilih: isi daftar misi diganti kartu pratinjau `-soft` peran (3 misi pertama bergembok) + CTA "COBA GRATIS 7 HARI" ke Paket. Label kanan judul jadi "Paket Keluarga". |

## 13f. Gelombang C: Misi Puncak, state kosong dan error, versi Guru (layar 47 sampai 53)

| No | Layar | Inti spesifikasi |
|---|---|---|
| 47 | **Detail Misi Puncak** | Varian Detail misi: header `navy-900` + salju, pill amber dengan ikon mahkota. Kotak "Syarat membuka" `cream` dengan centang per syarat. Tile hadiah (sertifikat, +60 XP). Tombol nonaktif bergembok "SELESAIKAN 2 MISI LAGI" sampai syarat terpenuhi. Di daftar Beranda, Misi Puncak yang terkunci memakai kartu `#FFF8E9` garis putus-putus `amber-500`, status "Misi Puncak" `amber-800`, badge `amber-50`. |
| 48 | **Beranda pengguna baru** | Kartu streak diganti sapaan "Halo {anak}, ayo mulai!" + Mink melambai + 7 kristal kosong. Ikan 0. Misi 1 aktif dengan tag "Misi pertama", sisanya terkunci. Berganti ke kartu streak normal setelah misi pertama selesai. |
| 49 | **Memori kosong** | Filter anak tetap tampil. Ilustrasi 3 polaroid kosong + Mink, judul "Album masih kosong", 3 langkah bernomor, primary "MULAI MISI PERTAMA". Varian per anak: "Belum ada momen Nara" dengan CTA sama. Pola ini juga dipakai Koleksi lencana kosong (semua lencana tampil terkunci, tanpa layar khusus). |
| 50 | **Abadikan offline dan gagal unggah** | Banner `navy-900` `role="status"` dengan ikon wifi silang saat offline. Slot foto punya 3 state: menunggu (overlay navy 45% + jam), gagal (border `red-500`, overlay merah 55% + ikon ulang, label merah), normal. Pesan error `role="alert"` menyebut penyebab (ukuran lebih dari 15 MB, format, server) + "Coba lagi". Primary jadi "SIMPAN, UNGGAH NANTI": misi tetap tercatat, foto masuk antrean. |
| 51 | **Abadikan versi Guru** | Foto tetap ada. Latar atas `teacher-soft`, judul "Abadikan karya kelas". Toggle "Buramkan wajah otomatis" default aktif (deteksi wajah di perangkat sebelum unggah). Peringatan `cream`: hanya untuk Memori kelas, tanpa nama murid, sekolah wajib punya izin foto orang tua. Foto tidak bisa diberi tag nama murid. |
| 52 | **Pilih dan kelola kelas** (bottom sheet) | Dibuka dari switcher kelas di Beranda Guru. Kartu radio per kelas (ikon bintang di lingkaran warna kelas, jumlah siswa, usia, level kelas). "Tambah kelas" ke Setup kelas. Kode kelas untuk guru pendamping + tombol salin. |
| 53 | **Statistik belum cukup data** | Grafik bayangan dengan overlay putih 72% + pill gembok "Terbuka setelah 3 sesi". Penjelasan kenapa (anonimitas: angka tidak bisa menunjuk satu anak). Checklist progres 4 langkah dengan bar `teacher-500`. Primary "MULAI SESI KEDUA". |

| 54 | **Notifikasi** | Dibuka dari ikon lonceng di Beranda. Grup "Hari ini" dan "Minggu ini" dalam kartu. Item: ikon 40px di kotak warna konteks (kristal streak, avatar anak, lencana, kolase, peti), judul, kalimat, waktu. Belum dibaca: latar `#FFFBF2`, judul 900, titik coral 10px. Tiap item membuka layar terkait. "Tandai dibaca" di kanan atas. Maksimal 1 notifikasi push per hari (lihat Izin notifikasi). |

### Revisi audit AI slop (27 Nov)
- Tipe akun: daftar fitur bercentang diganti satu contoh konkret per tipe (avatar anak bertumpuk / ikon kelas).
- Profil: 3 tile statistik berwarna diganti kartu `cream` "6 jam main bersama bulan ini" + baris angka pendukung.
- Detail momen: 3 tile diganti chip.
- Lencana baru: sinar berputar diganti cincin putus-putus.
- Peserta: "4–8 th" diganti "Misi 4+ tahun".

### Alur prototipe tambahan (gelombang C)
- Masuk ("Lupa kata sandi?") → Lupa kata sandi
- Profil ("Ubah profil") → Ubah profil orang tua
- Kelola anak: kartu anak → Ubah data anak → Hapus profil anak; "Pendamping lain" → Undang pendamping
- Pengaturan: "Privasi dan data anak" → Privasi
- Peran terkunci → Paket; Beranda Guru (switcher kelas) → Pilih kelas

### Aturan pemicu state (untuk developer)
| State | Pemicu |
|---|---|
| Streak terhenti | Saat app dibuka, hari kemarin target tidak tercapai dan Pembeku = 0. Tampil sekali per kejadian. |
| Beranda pengguna baru | Anak aktif belum pernah menyelesaikan misi. |
| Peran terkunci | Paket = Gratis dan peran bukan Koki atau Dokter. |
| Statistik belum cukup data | Kelas punya kurang dari 3 sesi selesai. |
| Abadikan offline | `navigator.onLine === false` atau unggah timeout 15 s. |

---

## 14. Aset

| Aset | Lokasi di repo Flutter | Catatan |
|---|---|---|
| Mink utama, melambai, peek, cooking, 5 pose menang, salju | `assets/mascot/*.webp` | Gantikan `assets/images/penguin_*.png` bertahap |
| Logo | `assets/brand/` | Ikon aplikasi: `miro-launcher-1024.png`, adaptive foreground `miro-adaptive-foreground-1024.png`, latar `#FFE8B6` |
| Ikon game (kristal, ikan, peti, mahkota, tip, wajah perasaan) | `lib/shared/icons/` | `CustomPainter`/SVG, bentuk dari `design/source/*.html` |
| Ikon UI | `phosphor_flutter` | Bold untuk garis, fill untuk aktif |
| Avatar anak (12 pinguin bayi) | belum ada | Sementara `maro-peek.webp` di lingkaran warna (DECISIONS E) |

## 15. Checklist implementasi per layar

- [ ] Widget diambil dari `lib/shared/widgets/` (COMPONENTS.md), tanpa dekorasi ad-hoc
- [ ] Semua state di tabel layar diimplementasikan
- [ ] Copy otomatis untuk akun Guru
- [ ] Edge case di atas ditangani
- [ ] Label aksesibilitas sesuai
- [ ] Lolos Definition of Done (`standards/CODE_QUALITY.md` §7)
