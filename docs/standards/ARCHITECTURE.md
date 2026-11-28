# Standar Arsitektur (Flutter)

Tujuan: setiap bagian bisa diubah tanpa merusak bagian lain, dan redesign bisa dikerjakan layar demi layar tanpa menghentikan aplikasi yang sudah dipakai.

## 1. Prinsip

1. **Tiga lapis terpisah:** tampilan (widget), aturan (fungsi murni di `lib/core/game/`), data (repository di `lib/data/`). Widget tidak memanggil `Supabase.instance.client` langsung.
2. **Feature-first** seperti struktur sekarang: setiap fitur punya folder sendiri berisi layar, widget khusus fitur, dan provider-nya.
3. **Satu sumber kebenaran:** token di `miro_tokens.dart`, motion di `MiroMotion`, aturan XP di `lib/core/game/xp.dart`, kamus teks di `lib/core/utils/localization.dart`.
4. **Ubah bertahap dengan aman:** layar baru menggantikan layar lama di route yang sama. Kode lama dihapus hanya setelah penggantinya selesai dan dites.

## 2. Struktur folder

```
lib/
├─ main.dart                        ← init Supabase, ProviderScope, MaterialApp.router
├─ core/
│  ├─ app_info.dart                 ← kMascotName, versi
│  ├─ theme/
│  │  ├─ miro_tokens.dart           ← dari design/miro_tokens.dart
│  │  ├─ miro_theme.dart            ← ThemeData (Nunito, warna, input, sheet) dari token
│  │  └─ (app_colors.dart, app_text_styles.dart, app_spacing.dart → alias sementara, hapus Fase 9)
│  ├─ router/
│  │  ├─ app_router.dart            ← GoRouter + redirect (lihat §3)
│  │  └─ app_page_transition.dart
│  ├─ game/                         ← FUNGSI MURNI + test: xp, level, streak, badges, quests, recommend, class_stats
│  ├─ providers/                    ← provider lintas fitur (akun, anak aktif, pengaturan, streak)
│  ├─ services/                     ← image (kompres + EXIF), tts, pdf, share, haptics, sound, deletion, export
│  ├─ constants/                    ← skills, roles (tanpa emoji), batas input
│  └─ utils/                        ← tanggal (Asia/Jakarta), localization, copy (istilah Guru)
├─ data/
│  ├─ models/                       ← kelas data immutable (fromJson/toJson)
│  └─ repositories/                 ← satu repository per domain (lihat §5)
├─ features/
│  ├─ onboarding/      splash 14, bahasa 23, tipe akun 01, auth 15, lupa sandi 43
│  ├─ setup/           anak 16, 24, 25, 26, 27; target 17; notifikasi 28; kelas 29
│  ├─ adventure/       beranda 02/12/46/48, cari misi
│  ├─ mission/         peserta 03/13, main 04, abadikan 07/50/51, perayaan 05, refleksi 08
│  ├─ celebrate/       level 21, lencana baru 31, streak terhenti 45
│  ├─ challenges/      10
│  ├─ memories/        09/49, detail 34, kolase 35
│  ├─ profile/         06, ubah profil 44, lencana 22, sertifikat 32, perkembangan 20,
│  │                   kelola anak 36, ubah anak 39, pendamping 41
│  ├─ classroom/       statistik 30/53
│  ├─ settings/        37, privasi 42, paket 38, bantuan, legal
│  ├─ notifications/   54
│  └─ dev/             galeri widget (hanya kDebugMode)
└─ shared/
   ├─ widgets/                      ← widget reusable (COMPONENTS.md)
   ├─ sheets/                       ← isi bottom sheet yang dibuka dari banyak tempat
   └─ icons/                        ← ikon game kustom + wajah perasaan
```

## 3. Route (go_router)

```dart
// Ringkas. Detail per layar di design/SCREENS.md.
GoRouter(
  initialLocation: '/',
  redirect: appRedirect,          // §3.1
  routes: [
    GoRoute(path: '/', builder: SplashPage),                       // 14
    GoRoute(path: '/welcome/language', …),                         // 23
    GoRoute(path: '/welcome/account-type', …),                     // 01
    GoRoute(path: '/auth', …, routes: [GoRoute(path: 'forgot')]),  // 15, 43
    GoRoute(path: '/setup/:step', …),                              // 16, 24 sampai 29
    StatefulShellRoute.indexedStack(                               // 4 tab, state tiap tab terjaga
      builder: (c, s, shell) => MiroTabScaffold(shell: shell),
      branches: [
        branch('/adventure', routes: ['search']),                  // 02/12/46/48
        branch('/challenges'),                                     // 10
        branch('/memories', routes: [':id', 'collage/:month']),    // 09/49, 34, 35
        branch('/profile', routes: ['edit', 'badges', 'badges/certificate/:role',
            'children', 'children/:id/edit', 'children/:id/progress', 'companions']),
      ],
    ),
    GoRoute(path: '/mission/:id/participants' | 'play' | 'capture' | 'done' | 'reflect'),
    GoRoute(path: '/celebrate/level' | '/celebrate/badge' | '/streak/restart'),
    GoRoute(path: '/class/stats'), GoRoute(path: '/settings', routes: ['privacy']),
    GoRoute(path: '/plans'), GoRoute(path: '/notifications'),
  ],
);
```

- Layar alur penuh (misi, perayaan, onboarding) berada **di luar** shell (tanpa bottom nav).
- **Bottom sheet bukan route.** Buka lewat `showMiroSheet(context, MissionDetailSheet(...))`. Tombol kembali Android menutup sheet.
- **Variasi layar = state, bukan route.** 02, 12, 46, 48 adalah `/adventure` dengan isi berbeda menurut tipe akun, paket, dan progres.
- Route lama (`/home`, `/missions`, `/progress`, `/identify`, `/onboarding`) diarahkan ke route baru dengan `redirect` selama transisi agar deep link dan notifikasi lama tidak putus.

### 3.1 Redirect

Belum pilih bahasa → 23; belum login → 01; login tapi belum ada anak/kelas → setup; ada streak terhenti yang belum ditampilkan → 45; selain itu → `/adventure`.

## 4. State (Riverpod 3)

| Jenis | Provider | Contoh |
|---|---|---|
| Sesi dan akun | `accountProvider` (`AsyncNotifier`) | profil orang tua/guru, tipe akun, paket, ikan |
| Anak/kelas aktif | `activeProfileProvider` (`Notifier`, disimpan di `shared_preferences`) | anak aktif atau "Semua anak" |
| Pengaturan | `settingsProvider` | kurangi animasi, suara, getar, ukuran teks, kecepatan TTS, bahasa |
| Data layar | `FutureProvider`/`StreamProvider` per kebutuhan, `.family` per id | daftar misi peran, memori per bulan |
| Alur misi | `missionRunControllerProvider(missionId)` (`Notifier`, `autoDispose`) | langkah aktif, peserta, foto antre |

Aturan:
- `ref.watch` di `build`, `ref.read` di callback. Jangan `watch` provider besar jika butuh satu field: pakai `.select`.
- Provider data memakai `autoDispose` kecuali dipakai lintas layar.
- Tidak menambah library state lain.

## 5. Repository

```dart
abstract interface class MissionRepository {
  Future<List<Mission>> missionsForRole(String roleId);
  Future<MissionRunResult> completeMissionRun(MissionRunInput input); // RPC atomik
}
```

- Satu repository per domain: `AccountRepository`, `ChildRepository`, `MissionRepository`, `MemoryRepository`, `BadgeRepository`, `NotificationRepository`, `ClassroomRepository`, `InviteRepository`. `supabase_repository.dart` yang sekarang dipecah ke sini secara bertahap.
- Repository mengembalikan **model**, bukan `Map<String, dynamic>`.
- Error dibungkus `AppException` dengan `code` (`offline`, `auth`, `notFound`, `quota`, `unknown`) agar UI bisa memilih pesan.
- `completeMissionRun` mengembalikan semua data yang dibutuhkan urutan 05 → 08 → 21 → 31 (XP per anak, level baru, lencana baru, streak baru), supaya layar perayaan tidak menghitung sendiri.
- Untuk tes, setiap repository punya implementasi palsu (`FakeMissionRepository`) yang di-override lewat `ProviderScope(overrides: …)`.

## 6. Konten

Konten misi tetap di Supabase (`missions_master`, `roles_master`) karena sudah ada dan bisa diubah tanpa rilis ulang. Teks UI di kamus `localization.dart` (ID/EN). Istilah yang berubah untuk Guru lewat `lib/core/utils/copy.dart`.

## 7. Error dan loading

- Setiap layar data menangani `AsyncValue` dengan tiga cabang: `loading` (skeleton berbentuk konten), `error` (`MiroErrorView`: Maro + pesan + coba lagi), `data` (termasuk kosong → `MiroEmptyState`).
- Jangan menampilkan pesan error mentah dari Supabase.

## 8. Lingkungan

- `env.json` (tidak di-commit) berisi `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Kunci rahasia (Groq, service role) **hanya** di Supabase secrets, tidak pernah di app.
- Build selalu dengan `--dart-define-from-file=env.json`.
