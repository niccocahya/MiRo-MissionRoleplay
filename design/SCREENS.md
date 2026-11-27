# Daftar Layar MiRO v2 (Flutter)

54 layar. Gambar di `screens/NN-Nama.png`, sumber mockup di `source/NN-Nama.html` (gambar di HTML memakai path `/mascot/…` dan `/brand/…` = `assets/mascot/…` dan `assets/brand/…`).

- **Variasi layar** (mis. 02, 12, 46, 48) adalah satu route dengan state berbeda.
- **"sheet:"** = bottom sheet lewat `showMiroSheet`, bukan route.
- Kolom **"Menggantikan"** = file lama di `lib/features/**` yang isinya dipindah/diganti. File lama dihapus hanya setelah penggantinya selesai.

| No | Layar | Desain | Route | File baru (di `lib/`) | Menggantikan | Widget utama | Fase |
|---|---|---|---|---|---|---|---|
| 01 | Onboarding: tipe akun | `01-TipeAkun` | `/welcome/account-type` | `features/onboarding/account_type_page.dart` | onboarding_page.dart | OnboardingShell, SpeechBubble, ChoiceCard, AvatarStack | 3 |
| 02 | Beranda: peran dan misi | `02-Main` | `/adventure` | `features/adventure/adventure_page.dart` | home_page.dart, missions_page.dart, mission_path_screen.dart | MiroTopBar, StreakCard, CrystalWeek, RoleTabs, MissionTimeline | 4 |
| 03 | Pilih peserta | `03-Peserta` | `/mission/:id/participants` | `features/mission/participants_page.dart` | (baru) | MiroPageHeader, ParticipantPicker, RewardChip | 4 |
| 04 | Mainkan misi | `04-Misi` | `/mission/:id/play` | `features/mission/play_page.dart` | mission_play_screen.dart | SegmentBar, StepCard (+TTS), MaroTip | 4 |
| 05 | Perayaan | `05-Perayaan` | `/mission/:id/done` | `features/mission/done_page.dart` | mission_win_screen.dart | CelebrationLayout, StatTile, RewardChip | 4 |
| 06 | Profil | `06-Profil` | `/profile` | `features/profile/profile_page.dart` | profile_page.dart (sebagian), progress_page.dart (grafik minggu) | MiroCard (krem), WeekBars, MiroAvatar, MiroProgressBar | 6 |
| 07 | Abadikan momen | `07-Abadikan` | `/mission/:id/capture` | `features/mission/capture_page.dart` | mission_journal_screen.dart | ScreenHero, PhotoSlot, MaroTip | 4 |
| 08 | Refleksi | `08-Refleksi` | `/mission/:id/reflect` | `features/mission/reflect_page.dart` | mission_reflection_screen.dart | FeelingScale, MiroSwitch, MiroTextField | 4 |
| 09 | Memori | `09-Memori` | `/memories` | `features/memories/memories_page.dart` | memory_book_page.dart | MiroChip, MemoryTile, Polaroid | 5 |
| 10 | Tantangan | `10-Tantangan` | `/challenges` | `features/challenges/challenges_page.dart` | (baru) | ChestWidget, QuestRow, FishCounter | 5 |
| 11 | Kalender streak | `11-StreakSheet` | `sheet: StreakCalendarSheet` | `shared/sheets/streak_calendar_sheet.dart` | streak_calendar_page.dart | MiroSheet, StreakCalendar | 4 |
| 12 | Beranda Guru | `12-GuruBeranda` | `/adventure (Guru)` | `features/adventure/adventure_page.dart` | (baru) | MiroTopBar, StreakCard, StatTile, RoleTabs, MissionTimeline | 7 |
| 13 | Mulai misi di kelas | `13-GuruPeserta` | `/mission/:id/participants (Guru)` | `features/mission/participants_page.dart` | (baru) | MiroStepper, MiroSwitch, MiroBanner | 7 |
| 14 | Splash | `14-Splash` | `/` | `features/onboarding/splash_page.dart` | onboarding_page.dart | MaroImage, logo | 3 |
| 15 | Daftar atau masuk | `15-Masuk` | `/auth` | `features/onboarding/auth_page.dart` | onboarding_page.dart | MiroSegmented, MiroTextField, MiroButton, akun terakhir | 3 |
| 16 | Setup anak | `16-SetupAnak` | `/setup/child` | `features/setup/child_basic_page.dart` | identify_page.dart | SpeechBubble, MiroAvatar, MiroTextField, grid usia | 3 |
| 17 | Target harian | `17-TargetHarian` | `/setup/daily-goal` | `features/setup/daily_goal_page.dart` | identify_page.dart (timePreference) | RadioCard, MiroPill | 3 |
| 18 | Detail misi | `18-DetailMisi` | `sheet: MissionDetailSheet` | `shared/sheets/mission_detail_sheet.dart` | mission_intro_screen.dart | MiroSheet, MissionHero, MiroChip, ikon favorit | 4 |
| 19 | Ganti anak | `19-GantiAnak` | `sheet: ChildSwitcherSheet` | `shared/sheets/child_switcher_sheet.dart` | (switcher lama) | MiroSheet, RadioCard | 4 |
| 20 | Perkembangan anak | `20-Perkembangan` | `/profile/children/:id/progress` | `features/profile/child_progress_page.dart` | progress_page.dart | MiroSegmented, SkillRadar, SkillBars, tombol laporan PDF | 5 |
| 21 | Level naik | `21-LevelNaik` | `/celebrate/level` | `features/celebrate/level_up_page.dart` | (baru) | CelebrationLayout, LevelBox, StatTile | 4 |
| 22 | Koleksi lencana | `22-Lencana` | `/profile/badges` | `features/profile/badges_page.dart` | all_badges_page.dart | BadgeHex, MiroProgressBar | 5 |
| 23 | Pilih bahasa | `23-Bahasa` | `/welcome/language` | `features/onboarding/language_page.dart` | (baru) | OnboardingShell, ChoiceCard | 3 |
| 24 | Setup anak: kesukaan | `24-Kesukaan` | `/setup/child/interests` | `features/setup/child_interests_page.dart` | identify_page.dart | ChoiceCard multi (maks 3) | 3 |
| 25 | Setup anak: gaya belajar | `25-GayaBelajar` | `/setup/child/learning-style` | `features/setup/child_learning_style_page.dart` | identify_page.dart | ChoiceCard multi | 3 |
| 26 | Setup anak: keahlian | `26-Keahlian` | `/setup/child/skills` | `features/setup/child_skills_page.dart` | identify_page.dart (parentGoals) | ChoiceCard multi (maks 3, 5 skill) | 3 |
| 27 | Ada si kecil lain? | `27-TambahAnak` | `/setup/more-children` | `features/setup/more_children_page.dart` | (baru) | MiroCard, MiroChip, SpeechBubble | 3 |
| 28 | Izin notifikasi | `28-IzinNotif` | `/setup/notifications` | `features/setup/notifications_permission_page.dart` | (baru) | MaroImage, NotificationItem, RadioCard jam | 3 |
| 29 | Setup kelas (Guru) | `29-SetupKelas` | `/setup/class` | `features/setup/class_setup_page.dart` | (baru) | MiroTextField, MiroChip, MiroStepper | 7 |
| 30 | Statistik kelas (Guru) | `30-StatistikKelas` | `/class/stats` | `features/classroom/class_stats_page.dart` | (baru) | StatTile, SkillRadar, SkillBars | 7 |
| 31 | Lencana baru | `31-LencanaBaru` | `/celebrate/badge` | `features/celebrate/new_badge_page.dart` | (baru) | CelebrationLayout, BadgeHex | 4 |
| 32 | Sertifikat peran | `32-Sertifikat` | `/profile/badges/certificate/:role` | `features/profile/certificate_page.dart` | certificate_detail_page.dart, all_certificates_page.dart | CertificateCard | 5 |
| 33 | Konfirmasi keluar misi | `33-KonfirmasiKeluar` | `sheet: ConfirmExitSheet` | `shared/sheets/confirm_exit_sheet.dart` | (dialog lama di play) | MiroAlertSheet, MiroProgressBar | 4 |
| 34 | Detail momen | `34-DetailMomen` | `/memories/:id` | `features/memories/memory_detail_page.dart` | memory_book_page.dart | Polaroid/foto, AvatarStack, MiroChip | 5 |
| 35 | Kolase bulanan | `35-KolaseBulanan` | `/memories/collage/:month` | `features/memories/collage_page.dart` | (baru) | CollageCanvas, MiroSegmented | 5 |
| 36 | Kelola anak | `36-KelolaAnak` | `/profile/children` | `features/profile/children_page.dart` | profile_page.dart | MiroBanner, MiroCard, MiroListRow | 6 |
| 37 | Pengaturan | `37-Pengaturan` | `/settings` | `features/settings/settings_page.dart` | profile_page.dart (bagian pengaturan) | MiroListGroup, MiroSwitch, ukuran teks, kecepatan TTS | 6 |
| 38 | Paket Keluarga | `38-Paket` | `/plans` | `features/settings/plans_page.dart` | (baru) | PlanOption, TrialTimeline, AvatarStack | 6 |
| 39 | Ubah data anak | `39-UbahAnak` | `/profile/children/:id/edit` | `features/profile/child_edit_page.dart` | edit_questionnaire_page.dart | MiroAvatar, MiroTextField, MiroStepper, MiroChip | 6 |
| 40 | Hapus profil anak | `40-HapusAnak` | `sheet: DeleteChildSheet` | `shared/sheets/delete_child_sheet.dart` | child_deletion_service.dart (logika) | MiroAlertSheet, MiroTextField | 6 |
| 41 | Undang pendamping | `41-UndangPendamping` | `/profile/companions` | `features/profile/companions_page.dart` | (baru) | ScreenHero, CodeBoxes, MiroListRow | 6 |
| 42 | Privasi dan data anak | `42-Privasi` | `/settings/privacy` | `features/settings/privacy_page.dart` | profile_page.dart + data_export_service + account_deletion_service | MiroBanner, MiroListGroup, MiroSwitch | 6 |
| 43 | Lupa kata sandi | `43-LupaSandi` | `/auth/forgot` | `features/onboarding/forgot_password_page.dart` | (baru) | ScreenHero, MiroTextField, MiroBanner | 3 |
| 44 | Ubah profil orang tua | `44-UbahProfil` | `/profile/edit` | `features/profile/edit_profile_page.dart` | profile_page.dart | MiroAvatar, MiroTextField, MiroSegmented | 6 |
| 45 | Streak terhenti | `45-StreakPutus` | `/streak/restart` | `features/celebrate/streak_restart_page.dart` | (baru) | CelebrationLayout (navy), CrystalWeek | 4 |
| 46 | Peran terkunci (Gratis) | `46-PeranTerkunci` | `/adventure (Gratis, peran terkunci)` | `features/adventure/adventure_page.dart` | (baru) | RoleTabs(locked), MiroCard, MiroButton | 6 |
| 47 | Detail Misi Puncak | `47-MisiPuncak` | `sheet: MissionDetailSheet (puncak)` | `shared/sheets/mission_detail_sheet.dart` | (baru) | MiroSheet, MissionHero(peak) | 4 |
| 48 | Beranda pengguna baru | `48-BerandaKosong` | `/adventure (pengguna baru)` | `features/adventure/adventure_page.dart` | (baru) | StreakCard(newUser), MissionTimeline | 4 |
| 49 | Memori kosong | `49-MemoriKosong` | `/memories (kosong)` | `features/memories/memories_page.dart` | (baru) | MiroEmptyState, Polaroid kosong | 5 |
| 50 | Abadikan offline dan gagal | `50-UploadGagal` | `/mission/:id/capture (offline/gagal)` | `features/mission/capture_page.dart` | (baru) | MiroBanner, PhotoSlot(waiting/failed) | 8 |
| 51 | Abadikan versi Guru | `51-GuruAbadikan` | `/mission/:id/capture (Guru)` | `features/mission/capture_page.dart` | (baru) | PhotoSlot(blurred), MiroSwitch, MiroBanner | 7 |
| 52 | Pilih dan kelola kelas | `52-KelolaKelas` | `sheet: ClassSwitcherSheet` | `shared/sheets/class_switcher_sheet.dart` | (baru) | MiroSheet, RadioCard (kode kelas disembunyikan) | 7 |
| 53 | Statistik belum cukup data | `53-StatistikKosong` | `/class/stats (kosong)` | `features/classroom/class_stats_page.dart` | (baru) | MiroEmptyState, MiroProgressBar | 7 |
| 54 | Notifikasi | `54-Notifikasi` | `/notifications` | `features/notifications/notifications_page.dart` | notifications_page.dart | MiroPageHeader, MiroListGroup, NotificationItem | 6 |

## Layar lama yang dipertahankan tanpa mockup

Restyle dengan widget dan token yang sama (DECISIONS §B):

| Layar | File | Dibuka dari | Fase |
|---|---|---|---|
| Cari misi | `features/adventure/search_page.dart` (dari `mission_search_screen.dart`) | ikon cari di top bar 02 | 4 |
| Pusat bantuan | `features/settings/help_page.dart` (dari `help_center_page.dart`) | Pengaturan 37 | 6 |
| Legal / kebijakan privasi | `features/settings/legal_page.dart` (dari `legal_page.dart`) | Privasi 42 | 6 |
| Chat AI | `penguin_chat_bot.dart` | tetap disembunyikan | - |

## Alur utama

- **Onboarding orang tua:** 14 → 23 → 01 → 15 (43) → 16 → 24 → 25 → 26 → 27 → 17 → 28 → 02 (48)
- **Onboarding guru:** 14 → 23 → 01 → 15 → 29 → 17 → 28 → 12
- **Misi:** 02 → 18 / 47 → 03 → 04 (33) → 07 (50) → 05 → 08 → 21 → 31 → 02
- **Misi kelas:** 12 → 18 → 13 → 04 → 51 → 05 → 08 → 21 → 31 → 12
- **Memori:** 09 (49) → 34 → 35
- **Profil:** 06 → 44 / 36 → 39 → 40 / 41 / 37 → 42 / 38 / 22 → 32 / 20
- **Lainnya:** lonceng → 54; kartu streak → 11; buka app setelah hari terlewat → 45; tab peran terkunci → 46 → 38; switcher kelas → 52; statistik kelas → 30 (53)
