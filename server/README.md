# SDG Journey API

TypeScript API for the SDG Journey app, built with [Hono](https://hono.dev).
Data lives in **Neon** (Postgres). The same code runs on **Cloudflare Workers**
or **Node**.

The app never talks to the database directly. This API owns:

- **Accounts.** Email and password, with passwords hashed using PBKDF2.
  Sessions use short-lived access tokens plus refresh tokens that are replaced
  each time they're used. Password reset works by emailed link.
- **Rewards.** Mission and game XP, streaks and level-ups are decided here,
  not in the app:
  - each mission can be completed once per day, and at most 5 missions per day;
  - game XP is calculated from the score;
  - only the first 3 plays of each game per day earn XP.
- **Feeds** for the map, impact and community screens. Locations are rounded
  to about 1 km for privacy.
- **Photo uploads** to S3-compatible storage (Neon Object Storage or
  Cloudflare R2), using temporary signed upload links.
- **AI photo check** (optional, needs `ANTHROPIC_API_KEY`). Claude
  (`claude-opus-5-5`, low effort) checks whether a mission photo matches the
  mission and whether it's safe to show publicly (no faces or personal
  details). It also writes a short encouraging note.
  - A matching photo earns +5 XP. A non-matching photo is never penalised.
  - Only safe photos appear in the community feed; without the key, no photo
    is ever public.
  - Only the image and the mission text are sent to Claude.

## Run locally

```bash
cd server
npm install
npm run dev          # http://localhost:8787
```

If `DATABASE_URL` is not set, the server uses an **embedded Postgres**
(PGlite) stored in `.data/pglite`, so no install is needed. Password reset
links are printed to the console.

Run the app against it (from `goalquest/`):

```bash
flutter run                                    # iOS simulator → localhost:8787
flutter run --dart-define=API_URL=http://<ip>:8787   # physical device
```

The Android emulator reaches your machine at `10.0.2.2:8787` automatically.

## Connect Neon

1. Create a project at <https://console.neon.tech>. Copy the **pooled**
   connection string from **Connect**.
2. `cp .env.example .env` and set `DATABASE_URL`. Set `JWT_SECRET` to the
   output of `openssl rand -hex 32`.
3. `npm run migrate` creates the tables. It's safe to re-run, because each
   migration file is applied once.
4. `npm run dev` now uses Neon.

## Deploy to Cloudflare Workers (when ready)

```bash
npx wrangler login
npx wrangler secret put DATABASE_URL
npx wrangler secret put JWT_SECRET
# optional: RESEND_API_KEY, EMAIL_FROM, S3_* (see .env.example)
npm run deploy
```

Then build the app with `--dart-define=API_URL=https://<your-worker>.workers.dev`.

## Tests

```bash
npm test          # API tests against an in-memory Postgres
npm run typecheck
```

They cover auth, refresh token rotation, password reset, mission and game
reward rules and caps, streaks across days, and feed privacy.

To test the app's Dart services end to end against a running API:

```bash
cd goalquest
flutter test test/api_integration_test.dart --dart-define=API_URL=http://localhost:8787
```

## Layout

| Path | What it holds |
|---|---|
| `migrations/` | SQL schema, applied in order. Includes the `award_xp` function. |
| `src/app.ts` | Builds the app from its routes. |
| `src/routes/` | `auth`, `me`, `activity` (missions and games), `feed`, `uploads`. |
| `src/rules.ts` | XP values, caps and game rules. Missions come from `goalquest/assets/content/missions.json`, which the app also reads. |
| `src/worker.ts` / `src/node.ts` | Entry points for Cloudflare and Node. |
