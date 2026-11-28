# Standar Animasi (Flutter)

Animasi punya tiga tugas: **umpan balik** (tombol benar-benar tertekan), **menjelaskan perubahan** (bar terisi, kartu berganti), dan **merayakan** (misi selesai). Animasi yang tidak melakukan salah satunya dihapus.

Target: tetap 60 fps (frame ≤ 16 ms) di Android kelas menengah ke bawah dalam mode `--profile`, tidak menunda pengguna, dan bisa dimatikan sepenuhnya.

## 1. Token

Semua durasi dan kurva dari `MiroMotion` (`miro_tokens.dart`). Angka `Duration(...)` atau `Curves.xxx` lepas di widget dilarang; tambahkan ke `MiroMotion` dengan nama jika perlu nilai baru.

| Token | Nilai | Untuk |
|---|---|---|
| `instant` | 80 ms | Tekan (lip) |
| `fast` | 150 ms | Perubahan kecil, fade saat kurangi animasi |
| `base` | 250 ms | Toggle, chip, sheet |
| `rise` | 420 ms + `easeOut` | Elemen masuk (naik 14 + fade) |
| `pop` | 460 ms + `easePop` | Elemen bintang (scale 0.6 → 1) |
| `slow` | 400 ms | Transisi layar |
| `grow` | 900 ms + `easeOut`, jeda 350 ms | Bar progres terisi |
| `stagger` | 60 ms (tight 40, loose 120) | Jeda antar elemen berurutan |

## 2. Alat yang dipakai

| Kebutuhan | Pakai |
|---|---|
| Masuk layar (rise, pop) | Widget helper `MiroRise`, `MiroPopIn` (di `lib/shared/widgets/motion/`) berbasis `TweenAnimationBuilder`, parameter `delay` dan `index` untuk stagger |
| Tekan | `MiroPressable` (`AnimatedSlide`/`Transform.translate`, 80 ms) |
| Perubahan state kecil | Implicit: `AnimatedOpacity`, `AnimatedScale`, `AnimatedSlide`, `AnimatedSwitcher` |
| Bar progres | `TweenAnimationBuilder<double>` + `Transform.scale(scaleX:)` dengan `alignment: Alignment.centerLeft` |
| Angka bergulir | `Odometer` (per digit `AnimatedSwitcher` dengan `SlideTransition` vertikal) |
| Loop dekoratif (floaty, pulse) | `AnimationController` di `MiroFloat`/`MiroPulse`, `repeat(count: 3)` lalu berhenti |
| Sheet | `showMiroSheet` (`showModalBottomSheet` dengan `AnimationStyle` kurva `easeOut`, durasi `base`) |
| Transisi layar | `app_page_transition.dart`: maju = geser 24 + fade (`slow`), tab = crossfade `fast` |
| Wadah tab aktif | `AnimatedAlign`/`AnimatedPositioned` di `MiroBottomNav` |
| Konfeti | Paket `confetti` yang sudah ada, satu `ConfettiController` per layar perayaan |

Tidak menambah paket animasi lain (Lottie, Rive, flutter_animate) tanpa persetujuan.

## 3. Aturan teknis

1. **Hanya transform dan opacity:** `Transform`, `ScaleTransition`, `SlideTransition`, `FadeTransition`, `Opacity`/`AnimatedOpacity`. Dilarang menganimasikan `width`, `height`, `padding`, `BoxShadow`, `blur` (memicu layout atau repaint mahal). Pengecualian: lip 80 ms.
2. Gunakan widget `*Transition` (tanpa rebuild) untuk animasi yang berjalan lama, dan bungkus area yang beranimasi dengan `RepaintBoundary`.
3. `Opacity` di atas subtree besar diganti `FadeTransition`.
4. Setiap `AnimationController` di-`dispose`. Gunakan `SingleTickerProviderStateMixin`.
5. **Loop maksimal 3 putaran.** Tidak ada animasi tanpa akhir kecuali indikator memuat dan skeleton.
6. Maksimal ±6 elemen beranimasi bersamaan di layar biasa.
7. Animasi tidak memblokir input; tombol bisa ditekan sejak terlihat (kecuali CTA perayaan yang sengaja muncul terakhir).
8. Gambar besar di layar perayaan di-`precacheImage` saat misi dimulai (04) agar animasi tidak tersendat menunggu decode.

## 4. Anggaran waktu

| Situasi | Batas |
|---|---|
| Umpan balik tekan | 80 ms |
| Perubahan kecil (chip, toggle) | 150 sampai 250 ms |
| Masuk layar biasa | ≤ 600 ms total, stagger 40 sampai 80 ms |
| Sheet buka/tutup | 250 sampai 350 ms |
| Transisi layar | ≤ 400 ms |
| Urutan perayaan (05, 21, 31) | ≤ 2,4 s, **bisa dilewati dengan ketuk** |

## 5. Koreografi

- Urutan baca = urutan animasi (atas ke bawah, kiri ke kanan).
- Satu elemen "bintang" per layar yang memakai `MiroPopIn` besar atau `MiroFloat`. Sisanya hanya `MiroRise` kecil.
- CTA di layar perayaan muncul terakhir. Di layar lain CTA tidak dianimasikan.
- Maksimal satu konfeti per layar.

## 6. Peta animasi per layar

Detail interaksi M1 sampai M17 di DESIGN_SYSTEM §8.3.

| Layar | Animasi |
|---|---|
| 02 Beranda | Angka streak pop, kristal per hari pop bertahap 60 ms, cincin hari ini pulse ×3, bar target grow, daftar misi crossfade + rise saat ganti peran |
| 04 Mainkan | SegmentBar terisi, tombol "Sudah!" berubah jadi centang, kartu langkah berikutnya masuk dari kanan |
| 05 Perayaan | Maro masuk dari bawah, judul pop, 3 StatTile bertahap 120 ms, angka odometer, konfeti 1×, CTA terakhir |
| 07 / 50 / 51 Abadikan | Foto baru pop dengan rotasi tetap; slot gagal shake 1× |
| 09 Memori | Kartu rise bertahap, polaroid pop |
| 10 Tantangan | Bar grow, peti float ×3, buka peti (M11) |
| Sheet (11, 18, 19, 33, 40, 47, 52) | Naik dari bawah, scrim fade 250 ms |
| 21 Level naik | Mahkota dan kotak level pop bertahap, konfeti |
| 31 Lencana baru | Lencana pop, cincin putus-putus pop, teks rise bertahap |
| 45 Streak terhenti | Kristal retak pop, teks rise. **Tanpa** konfeti dan suara riang |
| Bottom nav | Wadah aktif bergeser |

## 7. Kurangi animasi

```dart
final reduce = MiroMotion.reduced(context) || ref.watch(settingsProvider.select((s) => s.reduceMotion));
```

Saat `reduce` true:
- Semua helper (`MiroRise`, `MiroPopIn`, `MiroFloat`, `MiroPulse`, `Odometer`) langsung menampilkan keadaan akhir, atau fade `fast` saja.
- Konfeti, float, pulse, shine mati.
- Transisi layar jadi fade `fast`.
- Suara dan getar mengikuti pengaturannya sendiri.

Helper animasi wajib membaca `reduce` sendiri, supaya layar tidak perlu mengecek satu per satu.

## 8. Suara dan getar

- Suara via `audioplayers` hanya jika disetujui; untuk v2 cukup getar (`HapticFeedback`) dan TTS yang sudah ada.
- Getar: langkah selesai `lightImpact`, target tercapai `mediumImpact`, level naik `heavyImpact`, batas pilihan `selectionClick`. Tidak untuk navigasi biasa.
- Getar dimulai bersamaan dengan frame pertama animasi terkait.

## 9. Cara menguji

- [ ] `flutter run --profile` di HP Android sungguhan, buka DevTools → Performance: tidak ada frame merah saat membuka Beranda, ganti tab peran, buka sheet, dan layar perayaan.
- [ ] "Highlight repaints" (DevTools): tidak ada repaint layar penuh selama animasi kecil.
- [ ] Aktifkan "Kurangi animasi" di app **dan** "Hapus animasi" di opsi developer Android: semua layar tetap bisa dipakai.
- [ ] Ketuk cepat berkali-kali: animasi tidak menumpuk atau macet.
- [ ] Golden test dijalankan dengan `disableAnimations: true` agar stabil.
