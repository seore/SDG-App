# SDG Journey

A mobile app that helps young people learn about the UN **Sustainable
Development Goals (SDGs)** and act on them through small daily missions, short
lessons, games and team challenges.

> Small actions. Global impact.

## What it does

| | |
|---|---|
| **Daily missions** | Five small real-world actions a day (53 in total, at least 3 per SDG). Each shows an estimated real-world impact, such as "≈ 40 L of water saved". |
| **Learn** | A lesson for each of the 17 goals: what it means in everyday life, a real-world example, and what you can do. |
| **Play** | Quiz (51 questions), SDG Match-Up, Trash Sorter, Water Guardian and Fix the City. |
| **Progress** | XP, levels, streaks and achievements. Rewards are calculated on the server, with daily caps. |
| **Impact** | Your totals and the community's (water, CO₂, plastics and more), charts, and a shareable "Your week" card. |
| **Team challenges** | Classes or friends join with a code, share a weekly mission target and see a leaderboard. |
| **Live map & community** | Actions taken around the world (locations rounded to about 1 km) and a story feed. |
| **AI photo check** | Optional. Claude checks that a mission photo matches the mission and is safe to share before it appears publicly. |
| **Personalisation** | Pick up to 3 focus SDGs to shape your daily missions; light or dark mode. |

## Repository layout

| Path | What it is |
|---|---|
| `goalquest/` | The Flutter app (iOS, Android; also builds for web and desktop). |
| `server/` | The API: TypeScript + [Hono](https://hono.dev) on **Neon** Postgres. Runs on Cloudflare Workers or Node. See [server/README.md](server/README.md). |

## Getting started

**1. Run the API locally.** If `DATABASE_URL` isn't set, it uses an embedded
Postgres, so nothing else needs installing:

```bash
cd server
npm install
npm run dev            # http://localhost:8787
```

**2. Run the app** against it:

```bash
cd goalquest
flutter pub get
flutter run            # iOS simulator / Android emulator reach the local API automatically
```

To try the UI without any backend, run in demo mode with a fake signed-in
profile:

```bash
flutter run --dart-define=DEMO=true
# optional: --dart-define=DEMO_TAB=2  or  --dart-define=DEMO_ROUTE=/onboarding
```

To connect Neon, set up photo storage and email, or deploy to Cloudflare,
see [server/README.md](server/README.md).

## Tests

```bash
cd server && npm test                    # API tests (in-memory Postgres)
cd goalquest && flutter test             # app tests
cd goalquest && flutter test test/api_integration_test.dart \
    --dart-define=API_URL=http://localhost:8787   # app ↔ API end to end
```

## Design notes

- **Look and feel:** neutral surfaces, one teal accent, and SDG colours used
  as accents. The font is Inter. Animations use spring physics, and they're
  turned off when the device's "reduce motion" setting is on.
- **Content sources:**
  - Missions, with their XP and impact estimates, live in
    `goalquest/assets/content/missions.json`. The app and the server both
    read this file.
  - Lessons are in `lib/data/sdg_data.dart`.
  - Quiz questions are in `lib/data/quiz_questions.dart`.
- **Impact figures** are rough per-action estimates for awareness, and the
  app labels them that way.
