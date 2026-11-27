# Standar Widget Reusable (Flutter)

54 layar MiRO dibangun dari sekitar 45 widget. Kalau sebuah layar butuh dekorasi yang belum ada di katalog ini, berhenti dan periksa ulang, jangan menulis `Container(decoration: …)` baru di halaman.

## 1. Tingkatan

| Tingkat | Folder | Boleh tahu tentang | Contoh |
|---|---|---|---|
| **Primitif** | `lib/shared/widgets/` | Token saja | `MiroButton`, `MiroCard`, `MiroChip` |
| **Layout** | `lib/shared/widgets/layout/` | Struktur layar | `MiroScaffold`, `MiroStickyFooter`, `MiroPageHeader` |
| **Domain** | `lib/shared/widgets/game/`, `lib/shared/sheets/`, `lib/shared/icons/` | Model MiRO | `MissionCard`, `StreakCard`, `Polaroid` |
| **Khusus fitur** | `lib/features/<fitur>/widgets/` | Satu fitur saja | `QuestRow` (hanya Tantangan) |
| **Layar** | `lib/features/<fitur>/<nama>_page.dart` | Menyusun widget + membaca provider | `AdventurePage` |

Arah ketergantungan hanya ke bawah. Primitif tidak mengimpor model domain.

## 2. Aturan kapan membuat widget

1. **Aturan dua kali:** dekorasi/struktur yang muncul di dua tempat atau lebih wajib jadi widget.
2. **Cek katalog dulu** (§5). Jika ada yang 80% cocok, tambahkan varian (`enum`) atau parameter.
3. **Varian lewat `enum`, bukan parameter warna bebas.** `MiroButton(variant: MiroButtonVariant.reward)`, bukan `MiroButton(color: Colors.amber)`.
4. **Komposisi lewat `child`/`children`/slot** (`leading`, `trailing`), bukan boolean yang terus bertambah. Lebih dari ±8 parameter = pecah.
5. Semua widget **`const` constructor** bila memungkinkan, `StatelessWidget` bila tidak butuh state.
6. Widget baru masuk galeri debug `/dev/gallery` dengan semua varian dan state, dan didaftarkan di tabel §5.

## 3. Kontrak widget interaktif

| State | Aturan |
|---|---|
| Default | Sesuai gambar |
| Pressed | Sistem lip: konten turun setinggi lip, lip hilang, 80 ms (`MiroPressable`) |
| Focus | Ring 3px `sky500` saat navigasi keyboard/switch access (`FocusableActionDetector`) |
| Disabled | Latar `navy100`, teks `navy400`, lip `navy200`, tidak menerima ketukan, `Semantics(enabled: false)` |
| Loading | Isi diganti titik memuat, ukuran tetap, tidak bisa ditekan |
| Error (form) | Border `red500`, pesan `red700` + ikon di bawah field, diumumkan ke pembaca layar |

Plus:
- Target sentuh ≥ 44×44 (`MiroSize.touch`), perluas area dengan padding.
- Setiap ikon tanpa teks dibungkus `Semantics(label: …, button: true)` atau `tooltip`.
- Pilihan memakai semantik yang benar: `Semantics(selected: …, inMutuallyExclusiveGroup: true)` untuk radio, `toggled` untuk switch.

### 3.1 Inti sistem lip

```dart
/// Dasar semua elemen yang bisa ditekan (tombol, kartu pilihan, tile).
class MiroPressable extends StatefulWidget {
  const MiroPressable({super.key, required this.child, required this.onTap,
    required this.color, required this.lipColor, this.lip = MiroLip.button,
    this.radius = MiroRadius.lg, this.border, this.semanticsLabel});
  // build: Stack berisi lapisan lip (warna lipColor) di bawah, dan konten di atas
  // yang digeser Transform.translate(0, pressed ? lip : 0) dengan
  // AnimatedContainer/TweenAnimationBuilder durasi MiroMotion.instant.
  // Tinggi total = tinggi konten + lip, agar layout tidak melompat saat ditekan.
}
```

Gunakan `MiroPressable` untuk semua yang punya lip. Jangan membuat lip dengan `BoxShadow` blur.

## 4. Konvensi file

```
lib/shared/widgets/miro_button.dart       ← satu widget publik per file, nama file snake_case
lib/shared/widgets/miro_button_test.dart  ← di test/shared/widgets/, golden + perilaku
```

- Nama kelas berawalan `Miro` untuk primitif dan layout (hindari bentrok dengan Material), nama domain tanpa awalan (`MissionCard`).
- Parameter konsisten: `variant`, `size`, `role` (`MiroRole`), `selected`, `enabled`, `loading`, `onTap`, `onChanged`, `icon`, `label`.
- Doc comment `///` satu kalimat + rujukan layar: `/// Kartu misi di timeline Beranda (HANDOFF 02).`

## 5. Katalog

Nomor layar dari `design/SCREENS.md`.

### 5.1 Primitif (`lib/shared/widgets/`)

| Widget | Varian / parameter utama | Layar | Catatan |
|---|---|---|---|
| `MiroPressable` | `color`, `lipColor`, `lip`, `radius`, `border` | dasar | §3.1 |
| `MiroButton` | `variant`: primary, secondary, dark, reward, success, danger, dangerOutline; `size`: l 56 / m 48 / s 40; `icon`, `expand`, `loading` | hampir semua | Label uppercase, 1 `primary` per layar. Menggantikan `app_button.dart` |
| `MiroIconButton` | `variant`: surface, ghost; `size` 44/40; `label` wajib | top bar | Lingkaran, border 2 `line`, lip 2 |
| `MiroTextLink` | `tone`: coral, sky, danger | 01, 15, 27, 43 | Tinggi 44 |
| `MiroCard` | `variant`: surface, muted, selected, tinted(`role`), cream; `onTap` opsional | banyak | Radius 20, border 2, lip 3. Menggantikan `app_card.dart` |
| `ChoiceCard` | `selected`, `icon`, `title`, `subtitle`, `multi` | 01, 17, 23 sampai 26 | Centang hijau pop-in |
| `RadioCard` | `selected`, `leading`, `trailing` | 19, 38, 52 | Pilih satu dari daftar |
| `MiroChip` | `selected`, `role`, `size` 32/36 | 16, 29, 34, 39 | `Wrap`, tidak pernah terpotong. Menggantikan `app_choice_chip.dart` |
| `MiroPill` | `tone`: amber, sky, green, coral, navy, role | banyak | Label non-interaktif |
| `MiroTextField` | `label`, `icon`, `hint`, `error`, `obscure` (+ tombol mata 44) | 15, 16, 39, 43, 44 | Tinggi 52, radius 12 |
| `MiroStepper` | `value`, `min`, `max`, `format` | 13, 29, 39 | Angka bergulir |
| `MiroSegmented` | `options`, `value` | 15, 20, 35, 37, 44 | Tab aktif putih + lip |
| `MiroSwitch` | `value`, `label`, `description` | 37, 42, 51 | 48×28, aktif `green600` |
| `MiroProgressBar` | `value`, `color`, `height` 8/10/12, `animate` | 02, 05, 20, 22, 31, 33 | Isi tumbuh dengan `scaleX`. Menggantikan `step_progress_bar.dart` |
| `SegmentBar` | `steps`, `current` | 04, onboarding | |
| `MiroAvatar` | `size`, `bg`, `image`, `initial`, `ring` | banyak | Crop Maro peek: `Alignment(0, -1)` + padding atas 16%. Menggantikan `child_avatar.dart` |
| `AvatarStack` | `items`, `size`, `overlap` | 03, 05, 34, 38 | |
| `MiroListGroup` + `MiroListRow` | `icon`, `iconTone`, `title`, `subtitle`, `trailing`, `onTap` | 36, 37, 41, 42 | Pembatas 2 `divider` |
| `showMiroSheet()` + `MiroSheet` | `title`, `child`, `heightFactor` | 11, 18, 19, 33, 40, 47, 52 | Radius 28, handle 40×5, scrim `MiroColors.scrim`. Menggantikan `app_bottom_sheet.dart` |
| `MiroAlertSheet` | aksi aman + aksi bahaya | 33, 40 | Fokus awal di aksi aman |
| `showMiroToast()` | `tone`, `action` | global | Maks 1 tampil, 4 detik |
| `MiroBanner` | `tone`: info(navy), success, warning, danger | 42, 43, 50, 51 | Diumumkan ke pembaca layar |
| `MiroEmptyState` | `illustration`, `title`, `body`, `steps`, `action` | 48, 49, 53 | Menggantikan sebagian `app_state_views.dart` |
| `MiroErrorView`, `MiroSkeleton` | | semua layar data | Skeleton berbentuk konten |
| `CodeBoxes` | `code` | 41 | Sel 40×52 |

### 5.2 Layout (`lib/shared/widgets/layout/`)

| Widget | Fungsi | Layar |
|---|---|---|
| `MiroScaffold` | Latar `app`, safe area, padding samping 20, slot `header`, `body`, `footer` | semua |
| `OnboardingShell` | Latar `moodGradient` + salju, tombol kembali, `SegmentBar` | 01, 15 sampai 17, 23 sampai 29 |
| `MiroTopBar` | Kiri: switcher anak/kelas; kanan: ikan, cari, lonceng | 02, 10, 12, 46, 48 |
| `MiroPageHeader` | Tombol kembali + judul 17 + slot kanan | layar detail. Menggantikan `app_screen_header.dart`, `back_button.dart` |
| `ScreenHero` | Judul besar + paragraf + Maro di kanan | 07, 43, 50, 51, 53 |
| `MiroStickyFooter` | Area CTA bawah: tombol utama + tautan sekunder opsional, ikut `viewInsets` | hampir semua |
| `MiroTabScaffold` + `MiroBottomNav` | 4 tab, wadah aktif bergeser | shell. Menggantikan `custom_bottom_nav_bar.dart` |
| `CelebrationLayout` | Latar penuh (mood atau navy), visual tengah, judul, CTA terakhir | 05, 21, 31, 45 |

### 5.3 Domain

| Widget | Parameter utama | Layar |
|---|---|---|
| `StreakCard` | `count`, `record`, `week`, `todayMinutes`, `goal`, `variant`: normal/newUser | 02, 12, 46, 48 |
| `CrystalWeek` | `days` (`done/today/missed/future/freeze`) | 02, 45, 48 |
| `StreakCalendar` | `month`, `days` | 11 |
| `RoleTabs` | `roles`, `value`, `locked` | 02, 12, 46, 48 |
| `MissionTimeline` + `MissionCard` | `status`: done, perfect, active, locked, peak; `role` | 02, 12, 46, 48, cari misi |
| `MissionHero` | header sheet detail, varian `peak` | 18, 47 |
| `StepCard` | `step`, `tips`, `onDone`, `onSpeak` (TTS) | 04 |
| `ParticipantPicker` | `children`, `value`, `ageRange` | 03 |
| `PhotoSlot` | `state`: empty, filled, uploading, waiting, failed, blurred | 07, 50, 51 |
| `Polaroid` | `image`, `caption`, `rotation` | 09, 34, 35, 49 |
| `MemoryTile` | `memory` | 09 |
| `CollageCanvas` | `memories`, `style` | 35 (ekspor PNG lewat `RepaintBoundary.toImage`) |
| `FeelingScale` | `value`, `size` | 08 |
| `StatTile` | `label`, `value`, `tone` | **hanya** 05, 21, 30 |
| `RewardChip` | `kind`: xp, skill, badge | 03, 05, 34 |
| `FishCounter`, `Odometer` | `value` | top bar, 10 |
| `QuestRow`, `ChestWidget` | | 10 |
| `BadgeHex` | `tier`, `icon`, `size` | 22, 31, 54 |
| `LevelBox` | `level` | 21 |
| `SkillRadar` | `data`, `compare` (fl_chart `RadarChart`, 5 sumbu, gaya token) | 20, 30 |
| `WeekBars`, `SkillBars` | | 06, 20, 30 |
| `CertificateCard` | `child`, `role`, `date` | 32 |
| `PlanOption`, `TrialTimeline` | | 38 |
| `NotificationItem` | `kind`, `unread`, `onTap` | 54 |
| `MaroImage` | `pose`: main, wave, peek, cooking, `<role>Win`; `height`; `float` | banyak |
| `SpeechBubble` | `text` | 01, 16, 23 sampai 27, 29 |
| `MaroTip` | `title`, `body` (ikon `TipIcon`, bukan bola lampu) | 04, 07 |

### 5.4 Ikon (`lib/shared/icons/`)

`StreakCrystal`, `FishIcon`, `ChestIcon`, `CrownIcon`, `TipIcon`, `ChefHatIcon`, `PotIcon`, `CrystalBrokenIcon`, `SnowflakeIcon`, `FeelingFace(level: 1..5)`. Digambar dengan `CustomPainter` atau SVG (`flutter_svg`), warna lewat parameter.

## 6. Pola yang dilarang

| Jangan | Lakukan |
|---|---|
| `Container(decoration: BoxDecoration(color: Colors.white, borderRadius: …))` di halaman | `MiroCard` |
| `MiroButton(color: …)` | `MiroButton(variant: …)` |
| `BoxShadow(blurRadius: …)` untuk kedalaman | Lip lewat `MiroPressable` |
| Menyalin baris 7 kristal | `CrystalWeek` |
| `MissionCardLocked`, `MissionCardDone` terpisah | `MissionCard(status: …)` |
| `Image.asset('assets/images/penguin_splash2.png')` di layar | `MaroImage(pose: MaroPose.wave)` |
| `Text('🧠 Kognitif')` | Ikon Phosphor + `Text` |
| `showModalBottomSheet` langsung | `showMiroSheet` |
| `GestureDetector` untuk tombol | `MiroPressable` / `MiroButton` (semantik + fokus) |

## 7. Galeri debug

- Route `/dev/gallery`, hanya terdaftar saat `kDebugMode`.
- Semua widget dengan semua varian dan state, lebar 390.
- Golden test mengambil gambar galeri per bagian (CODE_QUALITY §3).
