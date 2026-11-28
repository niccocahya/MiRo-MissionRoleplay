# Baseline `flutter analyze`

DECISIONS §H12: aturan lint baru (CODE_QUALITY §1) aktif untuk semua file, tetapi pelanggaran di kode lama hanya diperbaiki saat file itu disentuh. Angka di bawah adalah batas atas; **tidak boleh naik**. Setiap kali angka turun karena file lama dirapikan, perbarui angka ini di commit yang sama.

| Tanggal | Fase | Total | `prefer_const_constructors` | `prefer_final_locals` | `require_trailing_commas` | warning | error |
|---|---|---|---|---|---|---|---|
| 2026-11-28 | 0 | 252 | 190 | 53 | 9 | 0 | 0 |
| 2026-11-28 | 1 | **251** | 189 | 53 | 9 | 0 | 0 |

Sebelum aturan baru aktif, `flutter analyze` di kode yang sama: 0 temuan.

Semua temuan ada di file lama yang belum disentuh redesign (misalnya `profile_page.dart`, `home_page.dart`, `mission_journal_screen.dart`). File yang dibuat atau diubah sejak Fase 0 wajib bersih.

## Cara cek

```bash
dart run tool/check_lint_baseline.dart
```

Skrip ini menjalankan `flutter analyze`, menghitung temuan, dan gagal jika jumlahnya melebihi angka **Batas** di bawah atau jika ada `warning`/`error`. CI menjalankan skrip yang sama.

Batas: 251
