# MiRO Design System

> **Versi:** 2.0  •  **Acuan rasa:** Duolingo (chunky, tactile, playful)  •  **Palet:** tetap palet MiRO saat ini
> **Dokumen pasangan:** [`PRD.md`](./PRD.md)
>
> Dokumen ini adalah **sumber kebenaran tunggal** untuk tampilan dan interaksi MiRO. Jika kode bertentangan dengan dokumen ini, kode yang salah. Jika dokumen ini kurang, perbarui dokumennya dulu baru kodenya.

---

## Daftar isi

0. [Prinsip desain](#0-prinsip-desain)
1. [Warna](#1-warna)
2. [Tipografi](#2-tipografi)
3. [Spacing, layout, radius](#3-spacing-layout-radius)
4. [Kedalaman: sistem "lip"](#4-kedalaman-sistem-lip)
5. [Ikon & ilustrasi (tanpa emoji)](#5-ikon--ilustrasi-tanpa-emoji)
6. [Maskot](#6-maskot)
7. [Komponen](#7-komponen)
8. [Motion & micro-interaction](#8-motion--micro-interaction)
9. [Suara & getar](#9-suara--getar)
10. [Copywriting](#10-copywriting)
11. [Aksesibilitas](#11-aksesibilitas)
12. [Spesifikasi layar](#12-spesifikasi-layar)
13. [Panduan implementasi](#13-panduan-implementasi)
14. [Definition of Done](#14-definition-of-done)

---

## 0. Prinsip desain

| # | Prinsip | Artinya dalam praktik |
|---|---|---|
| D1 | **Bisa ditekan.** | Semua yang bisa diketuk terlihat "timbul" (punya *lip* di bawah) dan benar-benar turun saat ditekan. Yang tidak bisa diketuk terlihat datar. |
| D2 | **Satu bintang per layar.** | Tepat satu tombol utama berwarna penuh. Aksi lain berupa tombol sekunder, ghost, atau tautan. |
| D3 | **Besar dan tegas.** | Font tebal (800–900 untuk judul), target sentuh besar, sedikit teks per layar. |
| D4 | **Setiap aksi dibalas.** | Tidak ada ketukan tanpa umpan balik visual dalam 100 ms. |
| D5 | **Pinguin adalah pemandu.** | Maskot muncul di momen emosional (sambutan, keberhasilan, kosong, keluar), bukan sebagai hiasan di setiap layar. |
| D6 | **Tenang di mata.** | Ini aplikasi anti-gawai: tidak ada animasi berulang tanpa henti, tidak ada warna neon, latar dominan terang dan lembut. |

---

## 1. Warna

Palet **tidak diganti**. Semua warna dasar diambil langsung dari kode saat ini; yang ditambahkan hanya turunan (gelap/terang) agar sistem *lip*, status, dan kontras teks bisa bekerja.

### 1.1 Palet brand

| Token | Hex | Asal di kode lama | Peran |
|---|---|---|---|
| `navy-900` | `#0A264F` | warna utama di seluruh app | Brand, teks utama, tombol sekunder gelap, bottom nav |
| `coral-500` | `#E57B65` | CTA, aksen | Aksen brand, status terpilih, highlight |
| `sky-300` | `#A5CBEB` | latar onboarding, kartu misi | Latar suasana "salju", permukaan sekunder |
| `amber-500` | `#F1A22F` | progress bar, tombol misi | Reward: XP, progres, peti |
| `cream-100` | `#FFE8B6` | kartu terpilih | Latar kartu terpilih |
| `sand-300` | `#E9DFCE` | ujung gradien onboarding | Latar hangat |
| `ice-50` | `#F5F8FB` | latar halaman | Latar aplikasi |

### 1.2 Skala lengkap

```
navy    50 #F5F8FB  100 #E8EEF5  200 #D5DEEA  300 #A3B1C4  500 #5B6F8A
        600 #3D5677  700 #1E467A  900 #0A264F  950 #04152E
coral   100 #FBEBE8  200 #F4C6BC  300 #ECA091  500 #E57B65  600 #D9654E  700 #B24A34
sky      50 #EBF4FA  100 #D3E3F2  300 #A5CBEB  400 #8BBCE6  500 #6FA6D6  700 #3D7FB8
amber    50 #FEF7EE  100 #FFE8B6  300 #F5B555  500 #F1A22F  600 #C67B0D  800 #8A5608
sand    100 #F9F6F1  300 #E9DFCE
green   100 #DCFCE7  500 #22C55E  600 #17843F  700 #15803D  800 #0F582A
red     100 #FDE7E7  500 #E5484D  600 #C93A3F  700 #B42318  800 #9A2A2F
```

`navy-50` = `ice-50`, `amber-100` = `cream-100` (alias, warna sama).

### 1.3 Token semantik (yang dipakai komponen)

Komponen **tidak boleh** memakai token skala langsung; selalu lewat token semantik ini.

| Token semantik | Nilai | Dipakai untuk |
|---|---|---|
| `bg-app` | `navy-50` | Latar halaman |
| `bg-surface` | `#FFFFFF` | Kartu, sheet, input |
| `bg-surface-muted` | `navy-100` | Kartu nonaktif, track progress |
| `bg-mood` | gradien `sky-300 → sky-100 → sand-300` | Splash, onboarding, perayaan |
| `bg-selected` | `cream-100` | Kartu pilihan yang terpilih |
| `text-primary` | `navy-900` | Teks utama (14,0:1 di `bg-app`) |
| `text-secondary` | `navy-600` | Teks pendukung (7,0:1) |
| `text-tertiary` | `navy-500` | Caption, placeholder (4,8:1) |
| `text-disabled` | `navy-300` | Hanya untuk elemen nonaktif |
| `text-link` | `coral-700` | Tautan teks (5,0:1) |
| `border-default` | `navy-200` | Garis kartu & input |
| `border-selected` | `coral-500` | Kartu terpilih |
| `action-primary` / `-lip` | `coral-600` / `coral-700` | Tombol utama |
| `action-secondary` / `-lip` | `navy-900` / `navy-950` | Tombol alternatif kuat |
| `action-reward` / `-lip` | `amber-500` / `amber-600` | Tombol klaim hadiah, buka peti |
| `feedback-success` / `-lip` | `green-600` / `green-800` | Tombol "Sudah!" (putih 4,8:1). `green-500` hanya untuk ikon centang & isi progress |
| `feedback-danger` / `-lip` | `red-600` / `red-800` | Hapus, keluar akun (putih 5,1:1). `red-500` untuk border error |
| `xp` | `amber-500` | Semua angka & ikon XP |
| `streak` | `sky-500` | Kristal es streak |

### 1.4 Warna unit (per peran)

Diturunkan dari latar kartu peran yang sudah ada di `home/page.js` (`cardBg`). Dipakai **hanya** untuk header unit, node jalur, dan latar ilustrasi. **Tidak boleh** untuk tombol yang berisi teks.

| Peran | Latar (`-soft`) | Warna node (`-base`) | Lip (`-lip`) |
|---|---|---|---|
| Dokter Kecil | `#E8F2E6` | `#5FA873` | `#3F8253` |
| Koki Kecil | `#EBF4FA` | `#5C9FD6` | `#3D7FB8` |
| Seniman Kecil | `#FDF1E8` | `#F08A4B` | `#C86A30` |
| Guru Kecil | `#F6F0FA` | `#9B7FD4` | `#7A5FB3` |
| Atlet Kecil | `#FAF0F0` | `#E56B7E` | `#BF4C5F` |

### 1.5 Aturan pemakaian warna

1. **Proporsi 60-30-10:** 60% `bg-app`/putih, 30% navy (teks, nav), 10% coral/amber (aksi dan reward).
2. **Coral = aksi. Amber = hadiah.** Jangan tukar. Tombol "Mulai misi" berwarna coral; tombol "Klaim" dan semua XP berwarna amber.
3. **Teks di atas amber selalu `navy-900`** (7,1:1). Teks putih di atas amber dilarang (2,1:1, ini bug di kode lama).
4. **Teks putih di atas coral hanya untuk label tombol** ≥ 17px weight 800, dan tombol memakai `coral-600` (3,6:1, lolos AA teks besar), bukan `coral-500` (2,9:1, gagal).
5. **Hijau hanya untuk umpan balik berhasil**, bukan dekorasi.
6. Gradien hanya boleh: `bg-mood`, highlight di progress bar (lihat §7.7), dan latar unit. Tidak ada gradien di tombol.

---

## 2. Tipografi

### 2.1 Font

**Nunito** (Google Fonts, gratis) — huruf bulat dan ramah, paling mendekati karakter font Duolingo. Dimuat lewat `next/font/google`, weight `600, 700, 800, 900`.

Hapus `font-family: Arial` dari `globals.css` dan hapus Geist.

### 2.2 Skala tipe

| Token | Ukuran / line-height | Weight | Tracking | Dipakai untuk |
|---|---|---|---|---|
| `display` | 40 / 44 | 900 | −0.02em | Judul perayaan, judul misi di intro |
| `h1` | 32 / 38 | 900 | −0.015em | Judul halaman |
| `h2` | 24 / 30 | 800 | −0.01em | Judul seksi, pertanyaan onboarding |
| `h3` | 20 / 26 | 800 | 0 | Judul kartu besar, judul langkah |
| `title` | 17 / 24 | 800 | 0 | Judul kartu kecil, item list |
| `button` | 17 / 20 | 800 | 0.04em, **UPPERCASE** | Label tombol L & M |
| `body-lg` | 17 / 26 | 600 | 0 | Instruksi langkah misi |
| `body` | 15 / 22 | 600 | 0 | Teks umum |
| `caption` | 13 / 18 | 700 | 0 | Keterangan, label chip, label nav |
| `overline` | 13 / 18 | 800 | 0, **huruf kalimat** | Label kategori ("Koki Kecil", "Misi 3 dari 5"). Huruf kapital berjarak lebar hanya untuk label tombol |
| `number-xl` | 32 / 36 | 900 | −0.02em, `tabular-nums` | Angka statistik |
| `number-md` | 17 / 20 | 900 | 0, `tabular-nums` | Angka di top bar |

### 2.3 Aturan

- **Ukuran minimum 12px.** Label 9px dan 10px di kode lama dihapus semua.
- Maksimal **3 ukuran berbeda** dalam satu layar (di luar angka).
- Body tidak pernah di bawah weight 600 (Nunito 400 terlalu tipis di latar terang dan tidak cocok dengan gaya chunky).
- Jangan gunakan `<br />` untuk memecah judul. Gunakan `max-width` (`max-w-[14ch]` untuk display) dan `text-wrap: balance`.
- Angka yang berubah (XP, streak, Ikan) selalu `tabular-nums` agar tidak bergoyang saat beranimasi.

---

## 3. Spacing, layout, radius

### 3.1 Spacing (grid 4pt)

| Token | px | | Token | px |
|---|---|---|---|---|
| `1` | 4 | | `6` | 24 |
| `2` | 8 | | `8` | 32 |
| `3` | 12 | | `10` | 40 |
| `4` | 16 | | `12` | 48 |
| `5` | 20 | | `16` | 64 |

Nilai di luar skala ini (mis. `pt-30`, `mt-[37px]`) dilarang.

### 3.2 Layout

- **Lebar dasar desain:** 375px. Harus tetap rapi dari 320px sampai 430px.
- **Margin layar:** 20px (`px-5`).
- **Jarak antar seksi:** 32px. **Jarak di dalam kartu:** 16px (kartu kecil) / 20px (kartu besar).
- **Safe area:** konten bawah memakai `pb-[calc(env(safe-area-inset-bottom)+16px)]`; top bar memakai `pt-[env(safe-area-inset-top)]`.
- **Zona jempol:** tombol utama selalu di sepertiga bawah layar, di dalam *footer sticky*.
- Struktur layar standar:

```
┌───────────────────────────┐
│ TopBar (56px)              │  ← sticky
├───────────────────────────┤
│                           │
│ Konten (scroll)           │
│                           │
├───────────────────────────┤
│ Footer aksi (sticky)       │  ← tombol utama
│ atau BottomNav (72px)      │
└───────────────────────────┘
```

### 3.3 Radius

| Token | px | Untuk |
|---|---|---|
| `radius-sm` | 8 | Badge kecil, tag |
| `radius-md` | 12 | Input, chip persegi |
| `radius-lg` | 16 | **Tombol**, kartu kecil |
| `radius-xl` | 20 | Kartu besar, kartu pilihan |
| `radius-2xl` | 28 | Bottom sheet (sudut atas), kartu hero |
| `radius-full` | 9999 | Avatar, node jalur, chip pill, icon button |

Catatan: tombol berubah dari pill (`rounded-full`) menjadi `radius-lg` 16px. Ini ciri tombol Duolingo dan membuat *lip* terlihat jelas.

### 3.4 Border

Lebar border standar **2px** (bukan 1px). Kartu interaktif: `border-2 border-default` + lip.

---

## 4. Kedalaman: sistem "lip"

Ini **inti rasa Duolingo**. Elemen yang bisa ditekan punya "bibir" berwarna lebih gelap di bawahnya (dibuat dengan `box-shadow` padat tanpa blur), bukan bayangan buram.

| Level | Lip | Untuk |
|---|---|---|
| `lip-0` | — | Elemen statis (teks, kartu info non-interaktif) |
| `lip-sm` | `0 2px 0` | Chip, icon button kecil |
| `lip-md` | `0 4px 0` | **Tombol, kartu pilihan, kartu interaktif** |
| `lip-lg` | `0 6px 0` | Node jalur petualangan, tombol peti |

Warna lip = token `*-lip` warna tersebut. Untuk permukaan putih: lip `navy-200`.

**Perilaku tekan (wajib untuk semua elemen ber-lip):**
```css
.pressable            { box-shadow: 0 4px 0 var(--lip); transform: translateY(0); transition: transform 80ms, box-shadow 80ms; }
.pressable:active     { box-shadow: 0 0 0 var(--lip);   transform: translateY(4px); }
```

**Bayangan buram** (`shadow-lg`, `shadow-xl`, `shadow-2xl`) hanya boleh untuk overlay: bottom sheet, modal, toast. Hapus semua `shadow-*` di kartu biasa.

**Dilarang:** `hover:scale-105`, `active:scale-95` pada tombol. Skala diganti dengan efek tekan lip.

---

## 5. Ikon & ilustrasi (tanpa emoji)

### 5.1 Aturan utama

> **Tidak ada emoji di UI.** Tidak di label, tidak di chip, tidak di copy, tidak sebagai avatar, tidak sebagai skala perasaan. Termasuk PNG yang bergaya emoji (`drawing.png`, `reading.png`, `speaking.png`, `music.png`, `sport.png`, `visual.png`, `auditory.png`, `kinesthetic.png`, `motor.png`, `creativity.png`, `empathy.png`, `literacy.png`, `thinking.png`, `little_doctor.png`, `young_painter.png`) yang harus diganti.

Ada tiga lapis visual, masing-masing dengan gaya yang tegas:

| Lapis | Gaya | Sumber |
|---|---|---|
| **A. Ikon UI** (nav, tombol, input, panah) | Garis tebal, ujung bulat, satu warna | [Phosphor Icons](https://phosphoricons.com) `@phosphor-icons/react`, weight **`bold`**; state aktif **`fill`** |
| **B. Ikon fitur** (keahlian, kegiatan, gaya belajar, lencana) | Dua warna (*duotone*), isi solid, bentuk bulat dan "gemuk" | Phosphor weight **`duotone`** diwarnai token, di dalam "ikon wadah" (§5.3) |
| **C. Ikon gamifikasi** (streak, XP, Ikan, peti, mahkota level) | Custom SVG, 2–3 tone + highlight putih, mirip ikon Duolingo | Dibuat khusus, disimpan di `src/components/icons/game/` |
| **D. Ilustrasi** (pinguin, adegan peran) | 3D *clay*, pastel, cahaya lembut dari kiri atas | Aset PNG/WebP yang sudah ada + pose baru (§6) |

Jangan mencampur gaya dalam satu kelompok: semua ikon nav = lapis A, semua ikon keahlian = lapis B.

### 5.2 Ukuran ikon

| Token | px | Untuk |
|---|---|---|
| `icon-sm` | 16 | Di dalam chip, caption |
| `icon-md` | 20 | Di dalam tombol, list item |
| `icon-lg` | 24 | Bottom nav, top bar, icon button |
| `icon-xl` | 32 | Di dalam ikon wadah kartu pilihan |
| `icon-2xl` | 48 | Lencana, empty state kecil |

### 5.3 Ikon wadah (*icon tile*)

Ikon fitur selalu dibungkus wadah agar terasa "chunky":
- Wadah lingkaran 56px (`radius-full`), latar warna `-soft`, ikon 32px duotone warna `-base`.
- Saat kartu terpilih: wadah berubah ke latar `-base`, ikon putih, dengan animasi *pop* (§8.3).

### 5.4 Pemetaan ikon

**Keahlian** (dipakai di chip, radar, poin):

| Keahlian | Phosphor | Warna |
|---|---|---|
| Kognitif | `Brain` | navy |
| Motorik | `HandGrabbing` | sky |
| Kreativitas | `PaintBrushBroad` | coral |
| Empati | `HandHeart` | role Guru (lavender) |
| Literasi | `BookOpenText` | green |

**Kegiatan kesukaan** (onboarding): Menggambar `Palette`, Membaca `BookOpen`, Berbicara `Microphone`, Musik `MusicNotes`, Olahraga `SoccerBall`.

**Gaya belajar:** Visual `Eye`, Auditori `Ear`, Kinestetik `PersonSimpleRun`.

**Bottom nav:** Petualangan `MapTrifold`, Tantangan `Target`, Memori `Images`, Profil = avatar akun (lingkaran 28px).

**Tips untuk orang tua:** ikon custom "balon bicara + hati" (garis `sky-700` 2.2px, hati `coral-500`) di dalam kotak putih 32px ber-border `sky-300`. **Bukan** bola lampu kuning, karena terlihat seperti emoji.

**Lainnya:** Kembali `ArrowLeft`, Tutup `X`, Kamera `Camera`, Durasi `Timer`, Kunci `LockSimple`, Centang `Check` (weight bold, di lingkaran hijau), Notifikasi `Bell`, Edit `PencilSimple`, Bagikan `ShareFat`, Unduh `DownloadSimple`, Lihat sandi `Eye`/`EyeSlash`, Email `EnvelopeSimple`, Sandi `LockKey`, Nama `User`.

**Gamifikasi (custom):** `StreakCrystal` (kristal es biru), `XpStar` (bintang amber dengan kilau), `Fish` (ikan oranye-amber), `Chest` (peti tertutup/terbuka), `Crown` (level), `Shield` (pembeku streak), `Medal` (lencana tier).

### 5.5 Skala perasaan (pengganti 😞😐🙂😀🤩)

5 ilustrasi **wajah pinguin** (kepala saja, 64px, gaya 3D clay yang sama dengan maskot):

| Nilai | Ekspresi | Label |
|---|---|---|
| 1 | Mata sayu, paruh turun | "Kurang seru" |
| 2 | Datar | "Biasa" |
| 3 | Senyum kecil | "Seru" |
| 4 | Tertawa, mata tertutup | "Seru banget" |
| 5 | Mata berbinar, sayap terangkat | "Luar biasa!" |

Tidak terpilih: grayscale 100%, opacity 0.5. Terpilih: berwarna penuh, animasi *pop* + label muncul di bawah.

### 5.6 Avatar

- **Avatar anak:** 12 avatar pinguin bayi (variasi warna syal/topi/kacamata) dengan gaya 3D clay yang sama, atau foto unggahan dipotong lingkaran. **Bukan emoji 👦🏻.**
- **Avatar akun:** inisial nama di lingkaran warna (default), atau foto.
- **Avatar kelas:** ikon kelas (8 pilihan Phosphor duotone: `Cherries`, `Star`, `Sun`, `Flower`, `Rocket`, `Leaf`, `Rainbow`, `Snowflake`) di lingkaran warna kelas.

---

## 6. Maskot

Nama maskot: **Mink** (si pinguin; FINAL, DECISIONS §F1). Nama lama "Mink" di mockup dibaca sebagai Mink. File aset `maro-*.webp` tetap.

### 6.1 Kapan muncul

| Momen | Pose | Ukuran |
|---|---|---|
| Splash | Melambai (`penguin_splash1`) | Besar, 60% tinggi layar |
| Pilih tipe akun / sambutan | Melambai (`penguin_splash2`) | Besar |
| Onboarding (setiap langkah) | Mengintip dari bawah (`penguin_identify1`) + **balon bicara** berisi pertanyaan | Sedang |
| Jalur: node aktif | Berdiri kecil di samping node | 64px |
| Selesai langkah misi | Mengacungkan sayap (pose baru) | Kecil, muncul 600 ms |
| Perayaan misi | Pose menang per peran (`{role}_win`) | Besar |
| Level naik | Melompat senang (pose baru dari zip `1.png`–`5.png`) | Besar |
| Konfirmasi keluar misi | Sedih (pose baru) | Sedang |
| Empty state | Berpikir / mencari (pose baru) | Sedang |
| Streak putus | Selimut, kedinginan (pose baru) | Sedang |

### 6.2 Balon bicara

Pinguin di onboarding dan empty state "berbicara" lewat balon: latar putih, `border-2 border-default`, `radius-xl`, ekor segitiga ke arah pinguin, teks `body` weight 700. Teks muncul dengan efek ketik cepat (§8.3).

### 6.3 Daftar pose yang perlu dibuat

Sudah ada: splash ×2, identify, 5 kostum peran, 5 pose menang. **Perlu dibuat** (gaya, pencahayaan, dan sudut kamera harus sama dengan aset yang ada):

1. Acungan sayap (jempol) 2. Melompat senang 3. Sedih 4. Berpikir 5. Kedinginan berselimut 6. Membuka peti 7. 5 wajah perasaan (§5.5) 8. 12 avatar pinguin bayi (§5.6) 9. Pinguin orang tua menggendong anak (kartu tipe akun "Orang Tua").

**Spesifikasi aset:** latar transparan, sumber 1024×1024, ekspor WebP 512px (`@1x`) dan 1024px (`@2x`), nama `penguin-{pose}.webp`, `kebab-case` (bukan spasi seperti nama zip saat ini).

### 6.4 Animasi maskot

- **Idle:** "bernapas" (`scaleY 1 → 1.02`, 3 s, ease-in-out), **berhenti setelah 3 siklus** (prinsip D6).
- **Masuk:** dari bawah + sedikit *overshoot* (spring, §8.1).
- **Diketuk:** lompatan kecil (`translateY −8px`, 300 ms) + pergantian ke pose acungan selama 1 s.
- **Fase lanjut (P2):** ganti aset statis dengan **Rive** state machine (idle, blink, happy, sad) agar mata bisa berkedip.

---

## 7. Komponen

Semua komponen berada di `src/components/ui/`. Setiap komponen wajib punya state: **default, pressed, disabled, focus-visible**, dan bila relevan **selected, loading, error**.

### 7.1 Button

| Varian | Latar / lip | Teks | Pemakaian |
|---|---|---|---|
| `primary` | `action-primary` / `-lip` | putih | Satu aksi utama per layar |
| `secondary` | putih / `navy-200`, border 2px `navy-200` | `navy-900` | Aksi alternatif ("Lewati", "Kembali") |
| `dark` | `navy-900` / `navy-950` | putih | Aksi utama di atas latar `bg-mood` (biru) |
| `reward` | `amber-500` / `amber-600` | `navy-900` | Klaim, buka peti |
| `success` | `green-600` / `green-800` | putih | "Sudah!" di langkah misi |
| `danger` | `red-600` / `red-800` | putih | Hapus, keluar akun |
| `ghost` | transparan | `coral-700` | Tautan aksi ("Lupa kata sandi?") |

| Ukuran | Tinggi | Padding X | Font | Ikon |
|---|---|---|---|---|
| `L` | 56px | 24px | `button` | 20px |
| `M` | 48px | 20px | `button` | 20px |
| `S` | 40px | 16px | `caption` 800 uppercase | 16px |

- Default lebar penuh (`w-full`) di footer; lebar konten di dalam kartu.
- **Disabled:** latar `navy-100`, lip `navy-200`, teks `navy-300`, tidak bisa ditekan, *tidak* memakai opacity.
- **Loading:** label diganti 3 titik yang memantul bergantian, lebar tombol tetap.
- **Dua tombol berdampingan dilarang** di footer. Pola yang benar: tombol utama penuh + tautan ghost di atas/bawahnya. Pengecualian: dialog konfirmasi (secondary + danger/primary, sama lebar).

### 7.2 Icon button

Lingkaran 44px (`radius-full`), latar putih, border 2px `navy-200`, lip-sm, ikon 24px `navy-900`. Varian `onMood` (di latar biru): latar `white/70`. Pengganti `BackButton` lama yang 32px (terlalu kecil).

### 7.3 Choice card (kartu pilihan)

Dipakai di onboarding, pilih peserta, pilih tipe akun.

```
┌──────────────────────┐
│      ( ikon 56 )      │   default : bg-surface, border 2 navy-200, lip-md navy-200
│                      │   selected: bg-selected, border 2 coral-500, lip-md coral-500,
│     Menggambar        │             ikon wadah jadi solid + pop, centang kecil di pojok kanan atas
└──────────────────────┘   pressed : turun 4px
```

- Grid 2 kolom, gap 12px, tinggi minimum 120px. Item ganjil terakhir **tidak** dilebarkan dengan margin aneh (`mx-10` di kode lama); gunakan grid normal atau satu baris penuh dengan layout horizontal.
- Multi-select dengan batas (mis. "pilih hingga 3"): saat batas tercapai, kartu lain bergoyang pelan (shake 200 ms) bila diketuk + caption "Maksimal 3 pilihan" berkedip.
- Varian **list** (horizontal: ikon kiri, judul + subjudul, radio/checkbox kanan) untuk pilihan dengan teks panjang (bahasa, target harian).

### 7.4 Chip

Tinggi 36px, `radius-full`, padding 12/14px, ikon 16px + `caption`. Default: putih, border 2px `navy-200`, lip-sm. Selected: latar `navy-900`, teks putih. Dipakai untuk usia (2–10), filter memori, label keahlian.

**Chip keahlian (read-only):** latar `-soft` warna keahlian, ikon duotone, tanpa lip (karena tidak bisa ditekan, prinsip D1).

### 7.5 Input

- Tinggi 52px, `radius-md`, latar putih, border 2px `navy-200`, `body` weight 700, padding 16px.
- Label di atas field (`caption`, `navy-600`) dengan ikon 16px. Placeholder `navy-500`, kalimat biasa ("contoh: bunda@email.com"), **tanpa tanda kurung**.
- Focus: border `navy-900` + ring 4px `sky-100`.
- Error: border `red-500`, pesan di bawah (`caption`, `red-700`) dengan ikon `WarningCircle`, field bergoyang (shake) sekali.
- Password: ikon mata berfungsi (`Eye`/`EyeSlash`) sebagai icon button 44px transparan.

### 7.6 Stepper

Untuk jumlah siswa dan jumlah kelompok (guru). `[ − ]  24  [ + ]` dengan icon button 44px dan angka `number-xl`. Tahan tombol = bertambah cepat. Angka beranimasi bergulir (§8.3).

### 7.7 Progress

| Varian | Bentuk | Pemakaian |
|---|---|---|
| **Lesson bar** | Tinggi 16px, `radius-full`, track `navy-100`, isi `green-500` + garis highlight putih 30% di 1/3 atas | Progres langkah misi & onboarding |
| **XP bar** | Tinggi 12px, isi `amber-500` + highlight | Level anak/kelas |
| **Segmented** | Segmen 8px dengan gap 4px | Tantangan harian (tiap segmen = 1 unit) |
| **Ring** | Lingkaran 28px (top bar) / 120px (detail), stroke 4/10px, isi `coral-500` | Target harian |

Isi bar selalu beranimasi dari nilai lama ke nilai baru (§8.3). Saat penuh: highlight berkilau melintas sekali.

Hapus `ProgressBar` (3 garis tipis) dan `IdentifyProgressBar` lama; gantikan dengan **Lesson bar**.

### 7.8 Card

| Varian | Spesifikasi |
|---|---|
| `info` | Putih, `radius-xl`, border 2px `navy-200`, tanpa lip, padding 20px |
| `interactive` | Sama + lip-md `navy-200` + efek tekan |
| `hero` | Latar warna unit atau `navy-900`, `radius-2xl`, ilustrasi pinguin keluar dari batas kartu (overflow ke atas), padding 24px |
| `stat` | Putih, `radius-lg`, ikon wadah kecil 40px + `number-xl` + `caption` |

### 7.9 Bottom sheet

- `radius-2xl` sudut atas, latar putih, *handle* 40×5px `navy-200` di atas, padding 24px, maksimal 85% tinggi layar.
- Backdrop `navy-950/50` **tanpa** `backdrop-blur` (berat di HP menengah).
- Masuk: slide-up spring; bisa ditutup dengan swipe ke bawah atau ketuk backdrop.
- Dipakai untuk: detail misi, switcher anak/kelas, detail streak/Ikan/target, konfirmasi.

### 7.10 Top bar

```
┌─────────────────────────────────────────────┐
│ (Av)▾                 ❄ 12   ◆ 340   ◔     │  56px
└─────────────────────────────────────────────┘
```
- Kiri: avatar anak/kelas aktif 36px + chevron → switcher.
- Kanan: 3 *stat pill* (ikon custom 24px + `number-md`): streak (`sky-500`), Ikan (`amber-600`), ring target.
- Saat nilai berubah: ikon *bounce* + angka bergulir.
- Latar `bg-app`, border bawah 2px `navy-100` hanya muncul saat konten di-scroll.

### 7.11 Bottom nav

- Tinggi 72px + safe area, latar putih, border atas 2px `navy-100`. **Bukan** kapsul navy melayang seperti sekarang (menutupi konten dan keluar dari frame di desktop).
- 4 item, ikon 28px. Aktif: ikon `fill` warna `coral-500` di dalam wadah 48×40px latar `coral-100` dengan border 2px `coral-200`; label `caption` di bawah. Tidak aktif: ikon `bold` `navy-300`, tanpa label.
- Ketuk: ikon *pop* (scale 0.9 → 1.1 → 1).
- Diposisikan `sticky bottom-0` di dalam frame aplikasi (bukan `fixed` ke viewport).

### 7.12 Tab peran + daftar misi (pengganti jalur bulat)

Jalur berupa lingkaran zig-zag **tidak dipakai** karena terlalu identik dengan Duolingo. Gantinya: tab peran di atas, lalu daftar misi berbentuk **kartu kotak** yang dihubungkan garis timeline.

**Tab peran** (`role="tablist"`, scroll horizontal, gap 10)
- Thumbnail 64×64, `radius-xl` (20), latar `-soft` peran, berisi Mink berkostum (crop kepala-badan, `object-position: 50% 12%`); label `caption` di bawah.
- Tidak aktif: border 2px `navy-200`, lip-sm `navy-200`, label `navy-500` 700.
- Aktif: border 3px warna peran `-base`, lip-md peran `-lip`, label `navy-900` 900.
- Ketuk: warna header, progress, garis timeline, dan isi daftar berganti ke peran tersebut (animasi `swap` 280 ms: fade + naik 10px).

**Progres peran:** di kanan judul "Pilih peran": bar mini 56×8px warna peran + "Koki 2/5" `caption`.

**Daftar misi (timeline)**
- Garis timeline: garis putus-putus 3px warna peran (opacity 0.45) di x = tengah lencana.
- **Lencana nomor:** kotak 40×40, `radius-md` (12), lip-sm.
  - Selesai: latar peran `-base`, centang putih.
  - Sempurna: `amber-500` + lip `amber-600`, bintang putih.
  - Aktif: putih, border 3px peran, angka misi `title` navy.
  - Terkunci: `navy-100`, gembok `navy-300`.
- **Kartu misi biasa:** min-h 56, `radius-lg`, putih + border 2px `navy-200` + lip-sm; judul `body` 900 + meta `caption` (status berwarna + detail dipisah jarak 10px, tanpa titik tengah: **Selesai** (`green-700`) Kreativitas, **Terkunci** 10 menit); chevron kanan. Terkunci: latar `navy-50`, border **putus-putus**, tanpa lip.
- **Kartu misi aktif (berikutnya):** min-h 146, `radius-xl`, latar peran `-soft`, border 2px peran `-base`, lip-md peran `-lip`; tag pill putih "Misi berikutnya" (teks warna peran `-lip`), judul `h3`, chip durasi & keahlian (putih), tombol primary M "MULAI MISI"; Mink berkostum 104×128 di kanan bawah (gambar **utuh**, tidak terpotong).
- Ketuk kartu biasa → bottom sheet detail misi. Ketuk "MULAI MISI" → Pilih peserta.

**Kartu Streak + Target hari ini** (elemen paling menonjol di Beranda, di atas tab peran): kartu `navy-900`, lip-lg `navy-950`, `radius-2xl`, padding 14/16, gap 12.
- Baris 1: kotak kristal 56px (`navy-700`, kristal 38px) + angka streak **32px 900 putih** + "hari beruntun" 17px 900 `sky-300` + kalimat penyemangat 13px; pill "Rekor 21" di kanan atas.
- Baris 2: 7 kolom hari, masing-masing kristal 24px + huruf hari 12px 900. Tercapai: kristal biru penuh. Hari ini: cincin progres coral (sisa `navy-700`). Belum: kristal `navy-700` redup.
- Baris 3 (dipisah garis 2px `navy-700`): "Hari ini 10 dari 15 menit" putih + "5 menit lagi jadi 13" `coral-300`, bar 10px isi `coral-500`.
- Karena streak sudah tampil besar di kartu ini, **top bar Beranda tidak menampilkan pill streak** (hanya Ikan dan notifikasi). Di layar lain pill streak tetap ada.

### 7.13 Mission step card (layar Mainkan)

- Kartu `hero` putih tinggi penuh area konten, satu langkah per kartu.
- Atas: label pill "Langkah 2 dari 3", judul `h2`, ilustrasi langkah (opsional), instruksi `body-lg`.
- Tips: kartu `info` latar `sky-50` dengan ikon custom balon bicara + hati (§5.4), bisa dilipat (default terbuka untuk langkah pertama, terlipat untuk berikutnya).
- Footer: tombol `success` L "SUDAH!" + icon button `Camera` di kirinya **tidak** diperbolehkan (melanggar §7.1); kamera dipindah ke layar "Abadikan Momen" setelah langkah terakhir.
- Transisi antar langkah: kartu lama bergeser ke kiri dan memudar, kartu baru masuk dari kanan (§8.2).

### 7.14 Participant picker

- Grid 3 kolom avatar anak 72px + nama `caption` di bawah. Terpilih: cincin 4px `coral-500` + centang di lingkaran hijau kecil di pojok, avatar *pop*.
- Baris atas: tautan ghost "Pilih semua" / "Batal pilih semua".
- Label usia di luar rentang: chip kecil `amber-100` teks `amber-800` "4–7 th".

### 7.15 Badge (lencana)

- Bentuk segi enam membulat 80px, tier tampak dari warna bingkai: Perunggu `#C8865A`, Perak `#AFC0D3`, Emas `amber-500`.
- Ikon duotone di tengah, nama `caption` di bawah (tidak di bawah 12px, berbeda dengan 9px di kode lama).
- Terkunci: siluet `navy-100` + progres kecil "3/10".

### 7.16 Toast & empty state

- **Toast:** muncul dari atas, `radius-lg`, latar `navy-900`, teks putih, ikon 20px, hilang setelah 2,5 s. Untuk konfirmasi kecil ("Foto tersimpan").
- **Empty state:** pinguin pose berpikir 120px + judul `h3` + 1 kalimat + satu tombol primary. Contoh Memori kosong: "Belum ada momen. Mainkan misi pertama dan abadikan keseruannya."

### 7.17 Skeleton

Blok `navy-100` dengan kilau (*shimmer*) bergerak kiri ke kanan 1,2 s. Bentuk mengikuti komponen aslinya. Tidak memakai spinner kecuali di dalam tombol loading.

---

## 8. Motion & micro-interaction

Library: **[`motion`](https://motion.dev)** (`motion/react`, penerus Framer Motion) untuk spring, `AnimatePresence`, dan animasi layout. **`canvas-confetti`** untuk konfeti.

### 8.1 Token

| Token | Nilai | Untuk |
|---|---|---|
| `dur-instant` | 80 ms | Tekan tombol |
| `dur-fast` | 150 ms | Hover, fade kecil |
| `dur-base` | 250 ms | Transisi komponen, sheet |
| `dur-slow` | 400 ms | Transisi layar |
| `dur-celebrate` | 800–1200 ms | Urutan perayaan |
| `ease-out` | `cubic-bezier(0.22, 1, 0.36, 1)` | Elemen masuk |
| `ease-in` | `cubic-bezier(0.64, 0, 0.78, 0)` | Elemen keluar |
| `spring-pop` | `{ type: "spring", stiffness: 500, damping: 15 }` | Pop, bounce ikon |
| `spring-soft` | `{ type: "spring", stiffness: 260, damping: 26 }` | Sheet, kartu, transisi layar |

### 8.2 Transisi layar

| Navigasi | Animasi |
|---|---|
| Maju dalam alur (onboarding, langkah misi) | Masuk dari kanan 24px + fade, `spring-soft` |
| Mundur | Kebalikannya |
| Pindah tab | Crossfade 150 ms saja (tanpa geser) |
| Buka sheet/modal | Slide-up `spring-soft`, backdrop fade 250 ms |
| Masuk layar perayaan | Latar `bg-mood` mengembang dari tombol yang ditekan (*circular reveal*) 400 ms |

### 8.3 Katalog micro-interaction

| # | Pemicu | Respons |
|---|---|---|
| M1 | Tekan elemen ber-lip | Turun 4px, lip hilang, 80 ms; kembali saat dilepas |
| M2 | Pilih choice card | Kartu pop (1 → 1.04 → 1), ikon wadah berganti solid dengan pop, centang muncul scale 0 → 1, suara `select` |
| M3 | Batas pilihan tercapai | Kartu yang diketuk shake horizontal ±6px 200 ms, getar 30 ms |
| M4 | Input error | Field shake 1x, pesan error fade-in dari atas 4px |
| M5 | Langkah misi "Sudah!" | Tombol berubah jadi centang hijau (morph 250 ms), lesson bar terisi + kilau, pinguin acungan muncul 600 ms di pojok, suara `step`, lalu kartu berikutnya masuk |
| M6 | Angka berubah (XP, Ikan, streak, stepper) | Digit bergulir vertikal (*odometer*), 400 ms |
| M7 | XP didapat | Ikon `XpStar` kecil terbang dari tombol ke XP bar/top bar (kurva busur, 600 ms), bar terisi, angka bergulir |
| M8 | Level naik | Layar penuh: konfeti dari dua sisi, mahkota turun dengan bounce, angka level membesar dari 0.5 → 1.2 → 1, pinguin melompat, suara `levelup`, getar `[40, 60, 40]` |
| M9 | Target harian tercapai | Ring terisi penuh, berdenyut 1x, kristal streak "tumbuh" (scale 0.6 → 1.15 → 1) + berkilau, angka streak bergulir +1 |
| M10 | Lencana baru | Kartu lencana berputar 3D (rotateY 180° → 0), cahaya menyebar di belakang, tier berkilau |
| M11 | Buka peti | Peti bergoyang 3x (antisipasi), tutup terbuka, hadiah melompat keluar, konfeti kecil amber |
| M12 | Ketuk tab peran / kartu misi | Tab: thumbnail tekan (M1), daftar berganti dengan animasi `swap`. Kartu: tekan, lalu sheet detail muncul |
| M13 | Pull-to-refresh (Memori) | Pinguin kecil meluncur turun di atas daftar |
| M14 | Ketuk tab nav | Ikon pop, wadah aktif bergeser (*shared layout*) ke tab baru |
| M15 | Pinguin diketuk | Lompat kecil + pose acungan 1 s (Easter egg; batasi 5x per sesi) |
| M16 | Foto diunggah | Thumbnail "jatuh" ke tumpukan kolase dengan rotasi acak ±4°, efek polaroid |
| M17 | Kalimat pinguin | Balon bicara pop, teks muncul per kata (30 ms/kata) |

### 8.4 Urutan layar Perayaan (setelah misi)

Satu per satu, pengguna bisa mengetuk untuk mempercepat:

1. (0 ms) Latar `bg-mood` reveal, pinguin pose menang masuk dengan spring dari bawah.
2. (400 ms) Judul "Misi selesai!" `display` pop-in, konfeti 1x.
3. (900 ms) 3 kartu stat masuk berurutan (jeda 120 ms): **XP didapat**, **Menit bermain**, **Peserta** (avatar bertumpuk). Angka bergulir.
4. (1600 ms) Jika ada: progres target harian (M9) → streak.
5. Tombol primary "LANJUT" muncul paling akhir (fade-up) agar pengguna tidak melewatkan perayaan.
6. Layar berikutnya (bila ada): level naik (M8) → lencana baru (M10) → tantangan selesai. Masing-masing satu layar dengan satu tombol.

### 8.4b Animasi yang sudah dipakai di mockup (dan siap disalin ke kode)

Semua animasi hanya memakai `transform` dan `opacity` (murah untuk GPU, tidak memicu layout ulang), dan setiap loop berhenti sendiri setelah paling banyak 3 putaran.

| Kelas | Efek | Durasi / easing | Dipakai di |
|---|---|---|---|
| `popin` | scale 0.6 → 1 + fade | 460 ms, `cubic-bezier(.34,1.56,.64,1)` | Angka streak, kristal per hari (bertahap +60 ms), kotak kristal, balon bicara, polaroid |
| `rise` | naik 14px + fade | 420 ms, `ease-out-soft` | Judul layar, sheet, isi yang berganti |
| `grow-x` | `scaleX` 0 → 1 dari kiri | 900 ms, jeda 350 ms | Bar target hari ini, bar tantangan |
| `grow-y` | `scaleY` 0 → 1 dari bawah | 700 ms, bertahap 70 ms | Grafik "Main bersama minggu ini" |
| `floaty` | naik-turun 4px | 2,4 s × 3 putaran | Mink di onboarding/Abadikan, kristal besar, peti |
| `pulse` | scale 1 → 1.14 | 1,4 s × 3 putaran | Cincin "hari ini" di kartu streak |
| `shine` | kilau putih melintas sekali | 1,1 s, jeda 500 ms | Kotak kristal streak |
| `popr` | pop dengan rotasi tetap (`--r`) | 420 ms | Polaroid foto momen |

Implementasi di Next.js: definisikan keyframes ini sekali di `globals.css`; untuk animasi yang dipicu interaksi (peti terbuka, kartu pilihan) pakai `motion/react`. Jangan memuat library animasi tambahan selain `motion`.

### 8.5 Aturan motion

- **`prefers-reduced-motion` dan pengaturan "Kurangi animasi"**: semua gerak/skala diganti fade 150 ms, konfeti dimatikan, odometer langsung menampilkan angka akhir.
- Hanya animasikan `transform` dan `opacity`. Jangan animasikan `width`, `height`, `top`, `box-shadow` lebar (kecuali lip 80 ms).
- Tidak ada animasi loop tanpa batas di luar skeleton dan loading.
- Maksimal satu konfeti per layar.

---

## 9. Suara & getar

**Suara** (default **aktif**, bisa dimatikan di Pengaturan; otomatis senyap jika HP mode senyap tidak bisa dideteksi, jadi gunakan volume rendah 40%):

| Token | Karakter | Kapan |
|---|---|---|
| `tap` | Klik kayu lembut, 40 ms | Tidak dipakai di semua tombol, hanya pada choice card |
| `select` | "Pop" naik | Pilih kartu/peserta |
| `step` | Dua nada naik | Langkah selesai |
| `complete` | Fanfare pendek 1,2 s | Misi selesai |
| `levelup` | Arpeggio naik + kilau | Level naik |
| `chest` | Derit + gemerincing | Buka peti |

File `.mp3` ≤ 30 KB di `public/sounds/`, dimuat lebih awal (*preload*) setelah interaksi pertama pengguna.

**Getar:** `navigator.vibrate` hanya didukung Android (Chrome). iOS Safari tidak mendukung, jadi getar adalah bonus, bukan satu-satunya umpan balik. Pola: pilih `20`, error `[30, 40, 30]`, level naik `[40, 60, 40]`.

---

## 10. Copywriting

### 10.1 Suara MiRO

Hangat, singkat, menyemangati, berbicara kepada orang dewasa tentang si kecil. Pinguin boleh sedikit jenaka.

| Lakukan | Hindari |
|---|---|
| "Misi selesai! Rafi jadi Koki hebat hari ini." | "Kerja bagus telah menyelesaikan misi ini" (kaku) |
| "Siapa yang ikut main?" | "Silakan pilih peserta misi" |
| "Ups, emailnya belum lengkap." | "Error: format email tidak valid" |
| "Streak-nya sempat beku. Main 2 misi untuk memulihkannya." | "Kamu kehilangan streak!" |

### 10.1b Logo
- Bentuk: induk pinguin memeluk anak pinguin (pendamping dan anak bermain bersama).
- Warna utama: badan `navy-900` `#0A264F`, wajah dan latar `cream-200` `#FFE8B6`. Badan gelap dan wajah terang supaya tetap terbaca sebagai pinguin, dan krem membuatnya menonjol di layar Splash yang biru.
- Jangan memakai versi lama (siluet biru muda di atas biru): kontrasnya sekitar 1,4:1 dan hilang di ukuran 48px.
- Area bebas minimal 12,5% sisi ikon. Ukuran terkecil 24px; di bawah itu pakai glyph tanpa kotak.
- Di latar gelap (`navy-900`), pakai ikon berkotak krem, bukan glyph putih, agar wajah tetap terbaca.

### 10.2 Aturan

- **Hindari ciri "AI slop"** yang membuat desain terasa dibuat mesin:
  - Tidak ada titik tengah (·) atau garis pisah panjang (—) sebagai pemisah di UI. Pisahkan info dengan jarak, chip, atau warna berbeda ("**Selesai** Kognitif", bukan "Selesai · Kognitif").
  - Tidak ada label kecil huruf kapital berjarak lebar di atas judul (eyebrow). Gunakan huruf kalimat 13px tebal, atau pill.
  - Tidak ada lingkaran dekoratif buram/transparan, gradien acak, atau kartu dengan garis tepi kiri berwarna.
  - Tidak ada emoji atau ikon bergaya emoji (bola lampu kuning, bintang berkilau, dsb.).
  - Font hanya Nunito; jangan campur Inter, Poppins, atau Space Grotesk.
  - Chip yang tidak muat tidak boleh terpotong di tengah kata: bungkus ke baris berikutnya.
  - **Tidak ada kartu harga gaya SaaS**: kartu gelap dengan daftar centang, pill "Paling populer", dan harga besar di pojok. Tunjukkan apa yang benar-benar terbuka (peran, anak, kolase) dengan elemen aplikasi itu sendiri, dan jadikan pilihan harga sebagai keputusan nyata (Tahunan vs Bulanan).
  - **Tidak ada daftar fitur bercentang** di kartu pilihan. Ganti dengan satu contoh konkret ("Rafi, Nara, dan Dimas main di satu akun").
  - **Hindari baris 3 kotak statistik berwarna** (ikon, angka besar, label) sebagai pola default. Pakai satu kalimat utama + angka pendukung, atau chip. Baris 3 tile hanya boleh di layar perayaan dan ringkasan kelas.
  - Ornamen dekoratif (sinar, partikel) tidak boleh terlihat seperti tanda centang atau jarum jam. Pakai cincin putus-putus atau tidak sama sekali.
  - Teks layanan berbayar wajib jujur: tanggal tagihan pertama, harga setelah uji coba, dan cara membatalkan.
- **Tanpa emoji** di copy (konsisten dengan §5).
- Sapaan: Orang Tua "Ayah/Bunda {nama}", Guru "Bu/Pak {nama}" (sesuai pilihan saat daftar). Bukan "Ibu/Bapak Guest".
- Nama anak dipakai sebanyak mungkin di momen positif.
- Label tombol = kata kerja, maksimal 3 kata: "MULAI MISI", "SUDAH!", "LANJUT", "SIMPAN".
- Judul layar maksimal 2 baris di 375px.
- Kata yang diganti otomatis untuk akun Guru: anak → siswa, si kecil → kelas, Tips untuk Ayah/Bunda → Tips untuk Guru.

---

## 11. Aksesibilitas

- **Hapus `maximumScale: 1` dan `userScalable: false`** dari `layout.js`. Atasi masalah layout akibat font besar dengan unit `rem` dan layout fleksibel, bukan mengunci zoom.
- Target sentuh minimum **44×44px**.
- Kontras teks ≥ 4,5:1 (teks biasa) dan ≥ 3:1 (teks ≥ 18,66px bold & elemen UI). Semua token semantik §1.3 sudah memenuhi ini.
- `focus-visible`: ring 3px `sky-500` offset 2px pada semua elemen interaktif.
- Semua elemen yang bisa diketuk adalah `<button>` atau `<a>`, bukan `<div onClick>` (kode lama memakai `div` untuk kartu peran).
- Gambar dekoratif `alt=""`; ilustrasi bermakna diberi alt deskriptif.
- Status tidak hanya disampaikan lewat warna (node selesai punya ikon centang, kartu terpilih punya centang).
- Konten yang hanya muncul saat hover dilarang.

---

## 12. Spesifikasi layar

Format: **Tujuan** • **Struktur (atas ke bawah)** • **Aksi utama** • **Interaksi kunci**.

### 12.1 Splash
- **Struktur:** latar `bg-mood` + overlay salju (`snow.png`, opacity 0.6), logo 64px kiri atas, `display` "MiRO", `body-lg` tagline, pinguin melambai besar kanan bawah.
- Otomatis lanjut setelah 1,8 s (bukan "ketuk di mana saja"). Logo dan pinguin masuk dengan spring.

### 12.2 Onboarding
Semua layar onboarding: icon button kembali (kiri atas) + **lesson bar** di top bar, pinguin mengintip + balon bicara berisi pertanyaan, konten pilihan, footer sticky dengan satu tombol primary.

1. **Bahasa:** choice card varian list (Bahasa Indonesia / English).
2. **Tipe akun:** 2 choice card besar vertikal (ilustrasi pinguin 96px kiri, judul `h3`, deskripsi 1 baris): "Orang Tua — Untuk bermain bersama anak di rumah" / "Guru — Untuk kegiatan di kelas".
3. **Daftar/Masuk:** satu layar dengan segmented control "Daftar | Masuk" di atas. Field sesuai §7.5. Tombol Google = button `secondary` dengan logo Google asli (satu-satunya ikon brand yang diizinkan). Tautan ghost di bawah.
4. **[Orang Tua] Setup anak:** 4 langkah (§PRD F2). Usia: baris chip 2–10 (wrap, bukan scroll horizontal). Avatar: grid avatar pinguin + opsi "Unggah foto".
   **[Guru] Setup kelas:** 3 langkah (§PRD F3), jumlah siswa memakai stepper.
5. **Tambah anak lain?** (orang tua): pinguin + avatar anak pertama, tombol primary "TAMBAH ANAK", ghost "Nanti saja".
6. **Target harian:** choice card list 4 opsi (§PRD F1), "Rutin" berlabel chip "Disarankan".
7. **Notifikasi:** pinguin memegang lonceng, penjelasan 1 kalimat, primary "IZINKAN", ghost "Nanti".

### 12.3 Petualangan (Beranda)
- **Top bar** (§7.10).
- Top bar kanan: streak, Ikan, **tombol notifikasi** (icon button 40px dengan titik coral).
- **Kartu Streak + Target hari ini** (§7.12), elemen paling menonjol di layar ini.
- **Tab peran** "Pilih peran" (§7.12).
- **Header peran** + **daftar misi timeline** dengan kartu misi aktif sebagai rekomendasi (§7.12). Peran yang ditampilkan pertama kali = peran yang paling cocok dengan keahlian target anak.
- Bottom nav.

### 12.4 Detail misi (bottom sheet)
Ilustrasi peran di atas (latar `-soft`), `overline` peran, judul `h2`, deskripsi `body`, baris chip: durasi, usia, keahlian. Daftar 3 langkah (judul saja, bernomor). Tombol primary "MULAI MISI".

### 12.5 Pilih peserta
Judul `h2` "Siapa yang ikut main?", participant picker (§7.14), footer primary "MULAI DENGAN 2 ANAK" (jumlah dinamis, nonaktif bila 0). Guru: stepper jumlah siswa + toggle "Kerja kelompok" → stepper jumlah kelompok.

### 12.6 Mainkan misi
Top bar khusus: icon button `X` (kiri) + lesson bar (tengah) + icon button `Timer` (kanan, jika misi punya timer). Di antara top bar dan kartu langkah: baris **"Siapkan dulu"** (chip bahan/alat yang bisa dicentang: kotak 18px, aktif = border & isi warna peran). Latar atas layar diberi pita warna peran `-soft` setinggi 200px dengan sudut bawah 36px. Mission step card (§7.13). Footer: button `success` L "SUDAH!".

### 12.7 Abadikan momen
Judul `h2` "Abadikan momen ini?", area foto 3 slot (kotak putus-putus `radius-xl` dengan ikon `Camera`), foto yang ditambahkan tampil sebagai polaroid miring (M16). Footer: primary "SIMPAN" (aktif jika ≥ 1 foto) + ghost "Lewati".

### 12.8 Perayaan → Refleksi → Hasil
Perayaan: urutan §8.4. Refleksi: dua baris skala wajah pinguin (§5.5), per anak jika > 1 anak (avatar kecil di kiri setiap baris), textarea opsional, chip "+5 XP" di samping judul. Hasil: ringkasan perubahan (level, lencana, tantangan) lalu kembali ke Petualangan dengan node berikutnya berdenyut.

### 12.9 Tantangan
Kartu tantangan harian: ikon wadah + judul `title` + segmented progress + jumlah Ikan hadiah. Peti di bawah (terkunci → bisa dibuka dengan tombol `reward`). Hitung mundur reset "Berakhir dalam 5 jam".

### 12.10 Memori
Top: filter chip (anak/kelas, peran, bulan). Grid masonry 2 kolom foto `radius-lg` dengan stiker kostum pinguin 28px di pojok kiri bawah dan avatar peserta bertumpuk di kanan bawah. Header per bulan `h3`. Kartu "Kolase Bulan Ini" (P1) di paling atas jika tersedia.

### 12.11 Profil
Header: avatar akun 80px, nama `h1`, tombol secondary S "UBAH PROFIL". Baris 3 kartu stat berwarna lembut (streak `sky-50`, total misi `coral-100`, waktu bermain `amber-50`). Kartu **"Main bersama minggu ini"**: 7 batang menit per hari (`chef`/sky untuk hari aktif, coral untuk hari ini) + kalimat insight. Seksi **Anak-anak** (kartu per anak: avatar, nama, level, XP bar, ketuk → Perkembangan) + kartu "Tambah anak" (border putus-putus). Guru: seksi **Kelas**. Seksi Lencana (6 terbaru + "Lihat semua"). Kartu Paket. List pengaturan. Tombol `danger` secondary "Keluar" paling bawah.

### 12.12 Perkembangan anak / Statistik kelas
Header avatar + nama + level. Toggle periode "Minggu | Bulan". Radar 5 keahlian (polygon `navy-900` fill 15%, pembanding bulan lalu garis putus `navy-300`, label `caption` minimal 12px di chip putih, sumbu dengan ikon keahlian). Kartu insight + misi rekomendasi. Riwayat misi (list). Guru: label radar "Keahlian yang sudah dilatih", ditambah kartu kehadiran rata-rata dan suasana kelas.

---

## 13. Panduan implementasi (versi web, TIDAK berlaku)

> Bagian ini ditulis untuk prototipe Next.js dan **tidak berlaku** untuk aplikasi Flutter. Panduan implementasi yang berlaku ada di `docs/standards/` (ARCHITECTURE, COMPONENTS, ANIMATION, PERFORMANCE, CODE_QUALITY) dan token di `design/miro_tokens.dart`. Nilai warna, ukuran, dan aturan di §13.3 tetap benar sebagai referensi.


> `AGENTS.md` di repo mengingatkan bahwa Next.js 16 punya perubahan API. Cek `node_modules/next/dist/docs/` sebelum memakai API Next yang baru.

### 13.1 Dependensi

```bash
npm i motion @phosphor-icons/react canvas-confetti clsx
```

### 13.2 Struktur folder

Struktur folder dan route yang berlaku ada di [`standards/ARCHITECTURE.md`](./standards/ARCHITECTURE.md) §2 dan §3. Katalog komponen ada di [`standards/COMPONENTS.md`](./standards/COMPONENTS.md).

### 13.3 Token di Tailwind v4 (`globals.css`)

Versi lengkap yang siap disalin, termasuk keyframes animasi dan mode "Kurangi animasi", ada di `design/miro_tokens.dart`. Di kode produksi kelas animasi memakai awalan `anim-` (`anim-rise`, `anim-popin`, dst.); di mockup HTML namanya tanpa awalan.


```css
@import "tailwindcss";

@theme {
  /* — Font — */
  --font-sans: var(--font-nunito), ui-rounded, system-ui, sans-serif;

  /* — Skala warna — */
  --color-navy-50:#F5F8FB; --color-navy-100:#E8EEF5; --color-navy-200:#D5DEEA;
  --color-navy-300:#A3B1C4; --color-navy-500:#5B6F8A; --color-navy-600:#3D5677;
  --color-navy-700:#1E467A; --color-navy-900:#0A264F; --color-navy-950:#04152E;
  --color-coral-100:#FBEBE8; --color-coral-200:#F4C6BC; --color-coral-300:#ECA091;
  --color-coral-500:#E57B65; --color-coral-600:#D9654E; --color-coral-700:#B24A34;
  --color-sky-50:#EBF4FA; --color-sky-100:#D3E3F2; --color-sky-300:#A5CBEB;
  --color-sky-400:#8BBCE6; --color-sky-500:#6FA6D6; --color-sky-700:#3D7FB8;
  --color-amber-50:#FEF7EE; --color-amber-100:#FFE8B6; --color-amber-300:#F5B555;
  --color-amber-500:#F1A22F; --color-amber-600:#C67B0D; --color-amber-800:#8A5608;
  --color-sand-100:#F9F6F1; --color-sand-300:#E9DFCE;
  --color-green-100:#DCFCE7; --color-green-500:#22C55E; --color-green-600:#17843F; --color-green-700:#15803D; --color-green-800:#0F582A;
  --color-red-100:#FDE7E7; --color-red-500:#E5484D; --color-red-600:#C93A3F; --color-red-700:#B42318; --color-red-800:#9A2A2F;

  /* — Warna unit — */
  --color-doctor:#5FA873;  --color-doctor-lip:#3F8253;  --color-doctor-soft:#E8F2E6;
  --color-chef:#5C9FD6;    --color-chef-lip:#3D7FB8;    --color-chef-soft:#EBF4FA;
  --color-artist:#F08A4B;  --color-artist-lip:#C86A30;  --color-artist-soft:#FDF1E8;
  --color-teacher:#9B7FD4; --color-teacher-lip:#7A5FB3; --color-teacher-soft:#F6F0FA;
  --color-athlete:#E56B7E; --color-athlete-lip:#BF4C5F; --color-athlete-soft:#FAF0F0;

  /* — Semantik — */
  --color-app: var(--color-navy-50);
  --color-surface: #FFFFFF;
  --color-surface-muted: var(--color-navy-100);
  --color-selected: var(--color-amber-100);
  --color-ink: var(--color-navy-900);
  --color-ink-2: var(--color-navy-600);
  --color-ink-3: var(--color-navy-500);
  --color-line: var(--color-navy-200);

  /* — Radius — */
  --radius-sm:8px; --radius-md:12px; --radius-lg:16px; --radius-xl:20px; --radius-2xl:28px;

  /* — Tipografi — */
  --text-display:40px; --text-display--line-height:44px; --text-display--font-weight:900;
  --text-h1:32px;      --text-h1--line-height:38px;      --text-h1--font-weight:900;
  --text-h2:24px;      --text-h2--line-height:30px;      --text-h2--font-weight:800;
  --text-h3:20px;      --text-h3--line-height:26px;      --text-h3--font-weight:800;
  --text-title:17px;   --text-title--line-height:24px;   --text-title--font-weight:800;
  --text-body-lg:17px; --text-body-lg--line-height:26px; --text-body-lg--font-weight:600;
  --text-body:15px;    --text-body--line-height:22px;    --text-body--font-weight:600;
  --text-caption:13px; --text-caption--line-height:18px; --text-caption--font-weight:700;
  --text-overline:13px;--text-overline--line-height:18px;--text-overline--font-weight:800;

  /* — Motion — */
  --ease-out-soft: cubic-bezier(0.22, 1, 0.36, 1);
}

@layer base {
  html { background: var(--color-navy-100); }
  body { background: var(--color-app); color: var(--color-ink); font-family: var(--font-sans); }
}

@layer components {
  /* Sistem lip (§4). Set --lip per varian. */
  .pressable {
    box-shadow: 0 var(--lip-h, 4px) 0 var(--lip, var(--color-navy-200));
    transition: transform 80ms ease-out, box-shadow 80ms ease-out;
  }
  .pressable:active:not(:disabled) {
    transform: translateY(var(--lip-h, 4px));
    box-shadow: 0 0 0 var(--lip, var(--color-navy-200));
  }
  .no-scrollbar { scrollbar-width: none; }
  .no-scrollbar::-webkit-scrollbar { display: none; }
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation-duration: 1ms !important; transition-duration: 1ms !important; }
}
```

`.no-scrollbar` didefinisikan sekali di sini; hapus semua `<style>{hideScrollbarStyle}</style>` di halaman.

### 13.4 Contoh komponen: `Button`

```jsx
// src/components/ui/Button.jsx
import clsx from "clsx";

const VARIANTS = {
  primary:   "bg-coral-600 text-white [--lip:var(--color-coral-700)]",
  secondary: "bg-surface text-ink border-2 border-line [--lip:var(--color-navy-200)]",
  dark:      "bg-navy-900 text-white [--lip:var(--color-navy-950)]",
  reward:    "bg-amber-500 text-navy-900 [--lip:var(--color-amber-600)]",
  success:   "bg-green-600 text-white [--lip:var(--color-green-800)]",
  danger:    "bg-red-600 text-white [--lip:var(--color-red-800)]",
};
const SIZES = { L: "h-14 px-6 gap-2", M: "h-12 px-5 gap-2", S: "h-10 px-4 gap-1.5 text-caption" };

export default function Button({ variant = "primary", size = "L", full = true,
  loading = false, disabled, icon: Icon, children, className, ...props }) {
  const isDisabled = disabled || loading;
  return (
    <button
      disabled={isDisabled}
      className={clsx(
        "pressable inline-flex items-center justify-center rounded-lg select-none",
        "text-title uppercase tracking-[0.04em]",
        "focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-sky-500",
        SIZES[size], full && "w-full",
        isDisabled
          ? "bg-navy-100 text-navy-300 [--lip:var(--color-navy-200)] cursor-not-allowed"
          : VARIANTS[variant],
        className,
      )}
      {...props}
    >
      {loading ? <LoadingDots /> : (<>{Icon && <Icon size={20} weight="bold" />}{children}</>)}
    </button>
  );
}

function LoadingDots() {
  return (
    <span className="flex gap-1" aria-label="Memuat">
      {[0, 1, 2].map((i) => (
        <span key={i} className="size-2 rounded-full bg-current animate-bounce"
              style={{ animationDelay: `${i * 120}ms` }} />
      ))}
    </span>
  );
}
```

### 13.5 Frame aplikasi di desktop

Agar elemen `fixed`/`sticky` (bottom nav, toast, sheet) tetap di dalam bingkai HP saat demo di laptop, tambahkan `transform: translateZ(0)` (`[transform:translateZ(0)]`) pada div frame di `layout.js`. Elemen `fixed` di dalamnya akan memakai frame sebagai acuan, bukan viewport. Perbaiki juga halaman yang memakai `min-h-[100dvh]` di dalam frame menjadi `min-h-full`.

### 13.6 Aturan kode

1. **Dilarang hex di komponen** (`bg-[#0A264F]`). Selalu token (`bg-navy-900`, `text-ink`). Cek: `grep -rn "\[#" src/` harus kosong.
2. **Dilarang emoji di kode UI.** Cek: `grep -rnP "[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]" src/` harus kosong.
3. Ikon UI hanya dari `@phosphor-icons/react` atau `components/icons/game/`. Tidak ada `<svg>` inline di halaman.
4. Konten (peran, misi, lencana) hanya di `src/data/`. Halaman tidak berisi data.
5. Logika gamifikasi (XP, streak, rekomendasi) di `lib/game/` sebagai fungsi murni dan punya unit test.
6. Animasi memakai token dari `lib/motion.js`, bukan angka acak.

---

## 14. Definition of Done

> Yang berlaku: `docs/standards/CODE_QUALITY.md` §7.


Sebuah layar/komponen dianggap selesai jika:

- [ ] Hanya memakai token (warna, ukuran font, spacing, radius); lolos cek `grep` §13.6
- [ ] Tidak ada emoji dan tidak ada PNG ikon bergaya emoji
- [ ] Tepat satu tombol primary
- [ ] Semua elemen interaktif punya lip dan efek tekan, target ≥ 44px, `focus-visible`
- [ ] Semua state ada: default, pressed, disabled, loading, error, empty
- [ ] Micro-interaction sesuai katalog §8.3 diterapkan
- [ ] Mode "Kurangi animasi" diuji
- [ ] Copy sesuai §10 dan otomatis berganti untuk akun Guru
- [ ] Rapi di lebar 320px, 375px, 430px, dan di frame desktop
- [ ] Kontras teks lolos (§11)
- [ ] File halaman ≤ ~200 baris
