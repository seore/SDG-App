# Translations

The app UI is available in English, Spanish and French. People can choose a
language in **Profile → Language**; by default the app follows the device language.

## Adding or changing a string

1. Add the English text to `lib/l10n/app_en.arb` (with `@key` placeholders if it
   has `{values}`), then add the same key to `app_es.arb` and `app_fr.arb`.
2. Run `flutter gen-l10n` (it also runs automatically with `flutter run`).
3. Use it in a widget with `context.l10n.yourKey`. Where there is no `BuildContext`
   (e.g. after an `await`), use `l10nNow().yourKey`.

`test/l10n_test.dart` fails if a Spanish or French string is missing. It also renders
the translated screens at 320px wide and at 2× text size to catch overflow.

## Status

- Translated: navigation, sign-in/sign-up, onboarding, Home, today's missions, the
  celebration card and Profile (including settings).
- Still English: games, map, impact, community, teams, rewards, lesson text,
  mission text, quiz questions, achievements and error messages from the server.
- Spanish and French use the informal "tú"/"tu" register for a young audience. The
  first drafts were machine-assisted: **have a native speaker review them before
  release.** Lesson and mission content also needs a subject review in each language
  (see `content_review.md`).
