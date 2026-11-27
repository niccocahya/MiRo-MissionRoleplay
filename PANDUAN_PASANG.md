# Cara memasang kit ini ke repo Flutter MiRO

Repo: `niccocahya/MiRo-MissionRoleplay` (folder di komputermu: `Flutter/miro2/miro_app` atau di mana pun repo itu di-clone).

## 1. Isi kit

```
CLAUDE.md                     ← baru (repo Flutter belum punya)
docs/
  README.md  DECISIONS.md  PRD.md  DESIGN_SYSTEM.md  HANDOFF.md
  standards/                  ← DESIGN, ARCHITECTURE, COMPONENTS, ANIMATION, UX_COMFORT,
                                 SECURITY_PRIVACY, PERFORMANCE, CODE_QUALITY (versi Flutter)
  prompts/CLAUDE_CODE_PROMPTS.md
design/
  SCREENS.md                  ← 54 layar + route + file Dart + fase
  screens/  source/           ← 54 PNG + 54 HTML mockup
  miro_tokens.dart            ← token Flutter (disalin ke lib/ di Fase 0)
assets/
  brand/                      ← logo + ikon launcher
  mascot/                     ← Maro WebP
```

Kit ini **tidak** menyentuh `lib/`, `pubspec.yaml`, `android/`, `ios/`, atau `assets/images/`. Semua perubahan kode dikerjakan Claude Code mulai Fase 0.

## 2. Langkah

1. Ekstrak ZIP, salin **isi** folder `miro-kit/` ke root repo Flutter (sejajar dengan `pubspec.yaml`).
2. Di terminal folder repo:

   ```bash
   git checkout dev-nicco
   git pull
   git checkout -b docs/v2-design-kit
   git add CLAUDE.md PANDUAN_PASANG.md docs design assets/brand assets/mascot
   git commit -m "docs: kit desain MiRO v2.1 (Flutter)"
   git push -u origin docs/v2-design-kit
   ```

3. Buat Pull Request `docs/v2-design-kit` → `dev-nicco` di GitHub, merge.

## 3. Repo Next.js

PR #2 di repo `niccocahya/miro-app` (Next.js) **tidak perlu di-merge**. Tutup saja PR-nya di GitHub ("Close pull request"). Branch `docs/v2-design-kit` di repo itu boleh dihapus.

## 4. Setelah di-merge

1. Buka terminal di folder repo **Flutter**, `git checkout dev-nicco && git pull`, lalu `claude`.
2. Kirim **Prompt 0** dari `docs/prompts/CLAUDE_CODE_PROMPTS.md`.
3. Satu fase per sesi, `/clear` di antara fase. Setelah tiap fase: jalankan di HP, cek, commit.
