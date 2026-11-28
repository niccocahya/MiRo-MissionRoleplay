# Dokumentasi MiRO v2 (Flutter)

## Peta dokumen

| Dokumen | Pertanyaan yang dijawab |
|---|---|
| [`DECISIONS.md`](./DECISIONS.md) | Keputusan final, termasuk cara menggabungkan fitur lama dengan desain baru (prioritas tertinggi) |
| [`PRD.md`](./PRD.md) | Apa yang dibangun, untuk siapa, aturan bisnis, roadmap |
| [`DESIGN_SYSTEM.md`](./DESIGN_SYSTEM.md) | Warna, tipografi, spacing, lip, ikon, maskot, komponen, motion, copy, logo (§13 versi web tidak berlaku) |
| [`HANDOFF.md`](./HANDOFF.md) | Spesifikasi detail layar 01 sampai 54 (notasi CSS diterjemahkan lewat tabel di awal dokumen) |
| [`standards/DESIGN.md`](./standards/DESIGN.md) | Ringkasan aturan visual, larangan AI slop, daftar periksa per layar |
| [`standards/ARCHITECTURE.md`](./standards/ARCHITECTURE.md) | Struktur `lib/`, go_router, Riverpod, repository, konten |
| [`standards/COMPONENTS.md`](./standards/COMPONENTS.md) | Katalog widget reusable, kontrak state, aturan membuat widget baru |
| [`standards/ANIMATION.md`](./standards/ANIMATION.md) | Token motion, alat animasi Flutter, anggaran, koreografi, kurangi animasi |
| [`standards/UX_COMFORT.md`](./standards/UX_COMFORT.md) | Kenyamanan, aksesibilitas, form, state, copy, notifikasi |
| [`standards/SECURITY_PRIVACY.md`](./standards/SECURITY_PRIVACY.md) | Data anak, auth, RLS, foto, pembayaran, UU PDP |
| [`standards/PERFORMANCE.md`](./standards/PERFORMANCE.md) | Anggaran performa, gambar, font, rebuild, offline |
| [`standards/CODE_QUALITY.md`](./standards/CODE_QUALITY.md) | Konvensi, unit/golden/integration test, git, Definition of Done |
| [`standards/RESPONSIVE.md`](./standards/RESPONSIVE.md) | Matriks ukuran layar, layar pendek, ukuran teks, safe area, keyboard, tes golden 3 ukuran |
| [`standards/QA.md`](./standards/QA.md) | CI, Sentry, parsing tahan banting, error handling, aksi ganda, lifecycle, uji manual |
| [`prompts/CLAUDE_CODE_PROMPTS.md`](./prompts/CLAUDE_CODE_PROMPTS.md) | Prompt siap pakai per fase |

## Folder `design/`

| Path | Isi |
|---|---|
| `design/SCREENS.md` | 54 layar: route, file Dart baru, file lama yang diganti, widget, fase |
| `design/screens/` | PNG final tiap layar (780×1688 = 390×844 @2x) |
| `design/source/` | HTML mockup: sumber nilai px, warna, copy yang persis (bukan kode produksi) |
| `design/miro_tokens.dart` | Token siap salin ke `lib/core/theme/miro_tokens.dart` |
| Kanvas interaktif | https://claude.ai/artifact/8HFtR7L83ai4o76JioKwZV |

## Aset baru

| Path | Isi |
|---|---|
| `assets/brand/` | Logo MiRO (SVG, PNG), ikon launcher 1024, adaptive foreground |
| `assets/mascot/` | Maro WebP: `maro-main`, `maro-wave`, `maro-peek`, `maro-cooking`, `maro-{doctor,chef,artist,teacher,athlete}-win`, `snow` |

## Urutan baca

1. `DECISIONS.md` (wajib, 10 menit)
2. PRD §0 sampai §6
3. Lihat semua gambar di `design/screens/` berurutan
4. DESIGN_SYSTEM §0 sampai §12
5. `standards/COMPONENTS.md` dan `standards/ARCHITECTURE.md`
6. HANDOFF bagian layar yang sedang dikerjakan
