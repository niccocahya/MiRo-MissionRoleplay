# Standar Performa dan Efisiensi (Flutter)

Target perangkat: Android kelas menengah ke bawah (RAM 3 sampai 4 GB), jaringan 4G yang tidak stabil.

## 1. Anggaran

| Metrik | Target |
|---|---|
| Waktu buka sampai Beranda tampil (cold start, `--release`) | ≤ 2,5 s |
| Frame build + raster | ≤ 16 ms (tanpa jank di DevTools mode profile) |
| Ukuran APK (split per ABI) | ≤ 25 MB per ABI |
| Memori saat Memori dibuka (100 foto) | ≤ 250 MB |
| Data per sesi misi (tanpa foto) | ≤ 50 KB |

Ukur dengan `flutter run --profile` + DevTools, dan `flutter build apk --analyze-size --target-platform android-arm64`.

## 2. Build dan rebuild

- `const` di mana pun bisa (lint `prefer_const_constructors` aktif).
- `ref.watch(provider.select(...))` untuk mengambil satu field, agar perubahan lain tidak me-rebuild layar.
- Pecah layar besar jadi widget kecil (bukan method `_buildX()`), supaya rebuild terbatas.
- Daftar panjang selalu `ListView.builder`/`SliverList` (tidak `Column` + `map`).
- `RepaintBoundary` di sekitar elemen yang beranimasi terus dan di sekitar grafik.

## 3. Gambar

- Aset Maro dalam **WebP** (`assets/mascot/`). Hapus PNG lama setelah diganti (Fase 9).
- Selalu set `cacheWidth`/`cacheHeight` sesuai ukuran tampil × `devicePixelRatio` (mis. Maro 120 lebar → `cacheWidth: 360`).
- Foto pengguna dari Storage lewat `CachedNetworkImage` dengan `memCacheWidth` 480 untuk grid; ukuran penuh hanya di Detail momen.
- `precacheImage` untuk pose Maro di layar perayaan saat misi dimulai.
- `gaplessPlayback: true` untuk gambar yang berganti (avatar).

## 4. Font

- Nunito dibundel di `assets/google_fonts/` (600, 700, 800, 900) dan `GoogleFonts.config.allowRuntimeFetching = false`, supaya tidak ada unduhan font saat pertama buka dan teks tidak berkedip.
- Hapus Poppins.

## 5. Paket

- Paket yang sudah ada dipakai ulang (lihat CLAUDE.md). Tambahan baru butuh alasan tertulis dan cek ukuran (`--analyze-size`).
- `pdf`/`printing` dan ekspor kolase dimuat hanya saat dibuka (deferred import jika perlu untuk mengurangi ukuran start).

## 6. Data dan jaringan

- Satu panggilan per layar sebisa mungkin. Beranda memakai satu RPC/view yang mengembalikan streak, anak aktif, dan progres peran sekaligus.
- `select` kolom yang dibutuhkan saja, bukan `select('*')`.
- `StreamProvider` realtime hanya untuk hal yang memang berubah dari perangkat lain (aktivitas pendamping). Streak dan statistik cukup `FutureProvider` + `invalidate` setelah misi selesai.
- Optimistic update untuk aksi yang hampir pasti berhasil (pengaturan, anak aktif), dengan rollback + toast jika gagal.

## 7. Offline

- Misi bisa diselesaikan tanpa internet: `MissionRunDraft` dan foto disimpan lokal (file di `path_provider` + metadata di `shared_preferences`), lalu diunggah ulang saat online dengan retry bertahap (5 s, 30 s, 2 m, 10 m).
- Banner offline (50) muncul hanya selama offline (cek lewat kegagalan request, bukan paket tambahan, kecuali disetujui `connectivity_plus`).
- Konten misi yang pernah dibuka di-cache lokal agar bisa dimainkan ulang tanpa jaringan.

## 8. Foto

- Kompres di perangkat sebelum unggah: sisi terpanjang 1600, JPEG 80, **hapus EXIF** (`flutter_image_compress` dengan `keepExif: false`).
- `image_picker` dengan `maxWidth: 2048` agar file mentah tidak terlalu besar di memori.
- Hapus file sementara setelah unggah berhasil.

## 9. Baterai

- Loop animasi maksimal 3 putaran.
- Timer langkah misi satu `Timer.periodic`, dibatalkan di `dispose`.
- TTS dihentikan saat layar ditinggalkan.

## 10. Checklist

- [ ] DevTools profile: tidak ada jank di Beranda, Mainkan, Perayaan, Memori
- [ ] `--analyze-size`: APK arm64 ≤ 25 MB
- [ ] Mode pesawat: misi bisa diselesaikan dan tersinkron setelah online
- [ ] Memori dengan 100 foto: scroll mulus, memori ≤ 250 MB
