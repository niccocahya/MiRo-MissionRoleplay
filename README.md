<div align="center">
  <img src="assets/images/logo_splash1.png" width="72" alt="MiRO logo" />

  # MiRO

  **Turn everyday parenting moments into guided missions.**

  <img src="assets/images/penguin_splash1.png" width="220" alt="Mink, the MiRO penguin companion" />

  <sub>Mink — MiRO's in-app penguin companion</sub>

  ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
  ![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
  ![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase&logoColor=white)
  ![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)
  ![Status](https://img.shields.io/badge/Status-Private%20Testing-orange)
</div>

---

## What is MiRO?

MiRO is a mobile app that helps parents turn ordinary time with their kids into short, real-world missions — cooking together, a pretend check-up, a quick drawing session — organized around five roles: **Chef**, **Doctor**, **Artist**, **Athlete**, and **Teacher**.

Each role has a short, ordered path of missions. Finishing one unlocks the next, so a child always knows what's coming — no overwhelming menu of choices. Every mission rewards XP and skill points across five areas (motor skills, creativity, empathy, literacy, thinking skills), which feed into levels, a daily streak, unlockable badges, and role certificates a parent can download or share.

The whole thing is guided by **Mink**, a penguin companion who narrates mission instructions out loud (with an adjustable reading speed) and can field parenting questions through an in-app AI chat.

## Features

- **Five mission roles**, each with an ordered, unlockable mission path and real-world (offline) activities
- **Progress system** — XP, levels, daily streaks with a GitHub-style activity calendar, skill radar/trend charts
- **Badges & certificates**, unlocked automatically as missions and roles are completed
- **Mission journal** — capture a photo per step, rate the mission, and record how both parent and child felt about it afterward
- **Memory Book** — a combined photo gallery across every completed mission
- **Multi-child support** per parent account, with a quick child switcher
- **Mink, the AI companion** — in-app chat for parenting questions, powered by a Groq-backed Edge Function (proxied so the API key never ships in the app)
- **Text-to-speech mission narration** with a Slow / Normal / Fast speed picker, remembered across sessions
- **PDF progress reports** parents can export and share (e.g. with a teacher or pediatrician)
- **Full data export & account deletion**, in line with the in-app Privacy Policy
- **Bilingual** — Indonesian and English, switchable anytime from Settings
- **Adjustable text size** for accessibility
- Realtime sync throughout — progress, badges, and notifications update live via Supabase Realtime, not just on refresh

## Tech stack

| Layer | Choice |
|---|---|
| Framework | [Flutter](https://flutter.dev) (Dart) |
| State management | [Riverpod](https://riverpod.dev) |
| Routing | [go_router](https://pub.dev/packages/go_router) |
| Backend | [Supabase](https://supabase.com) — Postgres, Auth, Storage, Realtime, Edge Functions |
| AI chat | [Groq](https://groq.com) API, called from a Supabase Edge Function |
| PDF export | [`pdf`](https://pub.dev/packages/pdf) + [`printing`](https://pub.dev/packages/printing) |
| Text-to-speech | [`flutter_tts`](https://pub.dev/packages/flutter_tts) |

## Project structure

```
lib/
├── core/              # Providers, services, theme, router, shared constants/utils
├── data/              # Repository layer for Supabase access
├── features/          # One folder per feature area (onboarding, home, missions,
│                       # progress, profile, notifications, help, legal)
└── shared/widgets/     # Reusable UI building blocks (buttons, cards, bottom sheets, …)

supabase/functions/    # Edge Functions (Mink's AI proxy, account deletion)
android/ · ios/         # Platform projects
assets/images/          # Illustrations, mascot, icons
```

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x)
- A [Supabase](https://supabase.com) project (free tier is enough for development)
- A [Groq](https://console.groq.com) API key, only if you want Mink's chat working (see step 4)

### Setup

1. **Clone and install dependencies**

   ```bash
   git clone <this-repo-url>
   cd miro_app
   flutter pub get
   ```

2. **Configure environment variables**

   Copy the example file and fill in your own Supabase project's credentials:

   ```bash
   cp env.example.json env.json
   ```

   ```json
   {
     "SUPABASE_URL": "https://<your-project-ref>.supabase.co",
     "SUPABASE_ANON_KEY": "<your-anon-or-publishable-key>"
   }
   ```

   `env.json` is gitignored — never commit real credentials.

   > [!NOTE]
   > `GROQ_API_KEY` is **not** part of `env.json`. Mink's chat calls a Supabase Edge Function (`supabase/functions/mink-chat`) that holds the Groq key server-side, so it never ships inside the app build — see step 4.

3. **Run the app**

   > [!IMPORTANT]
   > Always pass `--dart-define-from-file`. Without it, `SUPABASE_URL`/`SUPABASE_ANON_KEY` silently compile to empty strings and the app will build and launch fine, but **every** Supabase call will fail — a mistake that's easy to make and painful to debug, so don't skip this flag for either `run` or `build`.

   ```bash
   flutter run --dart-define-from-file=env.json
   ```

4. **Build a release APK**

   ```bash
   flutter build apk --release --dart-define-from-file=env.json
   ```

### Database & Edge Functions

Table schemas, RLS policies, and storage buckets live in the linked Supabase project — set up a new project from the Supabase dashboard and recreate the schema (`parents`, `children`, `missions_master`, `mission_logs`, `child_stats`, `child_achievements`, etc.) before pointing the app at it.

`supabase/functions/` in this repo tracks the two Edge Functions the app depends on:

- **`mink-chat`** — proxies Mink's AI chat to Groq. Needs the Groq key set as a function secret, never in the client:
  ```bash
  supabase secrets set GROQ_API_KEY=<your-key> --project-ref <your-project-ref>
  ```
- **`delete-account`** — handles permanent account deletion (storage cleanup + `auth.users` removal) with the service role key, which only exists inside the function's runtime.

Deploy both with the [Supabase CLI](https://supabase.com/docs/guides/cli):

```bash
supabase functions deploy mink-chat --project-ref <your-project-ref>
supabase functions deploy delete-account --project-ref <your-project-ref>
```

## Status

MiRO is currently in **private testing** with a small group of parents before a wider release. Not yet published on the Play Store or App Store.

## License

Private project — all rights reserved. Not currently open for external contributions.
