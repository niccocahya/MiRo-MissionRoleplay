# Aset yang masih memakai pengganti sementara

DECISIONS §E: pengganti boleh dipakai sampai aset final tersedia. Setiap pengganti dicatat di sini beserta tempat ia dipakai di kode, supaya mudah ditukar.

| Aset final yang dibutuhkan | Pengganti sekarang | Di kode | Status |
|---|---|---|---|
| 12 avatar pinguin bayi (variasi syal/topi/kacamata) | `maro-peek.webp` di lingkaran 6 warna (`kAvatarColors`) | `lib/shared/widgets/miro_avatar.dart` (`MiroAvatar`) | Menunggu aset |
| Pose sedih/bingung (33, 45) | `maro-main.webp` dengan saturasi 0.75 | `MascotPose.sad` di `lib/shared/widgets/mascot/mascot.dart` | Menunggu aset |
| Pose berpikir (state kosong 48, 49, 53) | `maro-main.webp` | `MascotPose.thinking` | Menunggu aset |
| Pose buka peti (10) | `maro-main.webp` (dipakai saat Fase 5) | belum dipakai | Menunggu aset |
| Pose acungan sayap / melompat (04, 21) | belum dipakai; akan memakai `maro-main` | Fase 4 | Menunggu aset |
| 5 wajah perasaan | **Sudah final**: SVG dari `design/source/08-Refleksi.html` | `lib/shared/icons/feeling_face.dart` | Selesai |
| Ikon game (kristal, ikan, peti, mahkota, tips, salju, panci) | **Sudah final**: SVG dari mockup | `lib/shared/icons/game_icons.dart` | Selesai |
| Pinguin menggendong anak | Tidak dipakai di desain final | - | Diabaikan |

Ketika aset final datang: taruh di `assets/mascot/` (WebP 512 dan 1024, latar transparan), ubah `MascotPose.file` atau `MiroAvatar`, jalankan ulang golden (`flutter test --update-goldens`), dan hapus barisnya dari tabel ini.
