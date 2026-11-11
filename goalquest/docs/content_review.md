# Content review (for teachers and subject experts)

SDG Journey is used by young people, so lessons, missions, quiz questions and impact
estimates should be checked by a teacher before release and once a year after that.

## 1. Export everything to a spreadsheet

```sh
cd goalquest
flutter test tool/export_content.dart
```

This writes `build/content_review.csv` with one row per item: lessons (17), missions,
quiz questions and impact estimates. The `reviewer`, `status` and `notes` columns are
left empty for the reviewer to fill in. The file opens in Excel, Numbers or Google Sheets.

## 2. Review checklist

For every item:

- [ ] **Accurate.** Facts are correct and up to date. Statistics name a year.
- [ ] **Matches the goal.** It belongs to the SDG it is tagged with. Compare with that goal's official targets, shown in the lesson under "Official UN targets".
- [ ] **Age-appropriate.** It is suitable for 10–16 year olds and does not frighten or blame.
- [ ] **Safe to do.** Missions can be done safely, without spending money, and without an adult unless the mission says so. No mission asks children to share personal data, meet strangers or go somewhere unsafe.
- [ ] **Inclusive.** It works for different family situations, incomes, abilities and cultures.
- [ ] **Clear.** It reads easily (aim for a reading age of about 11) and has no jargon.
- [ ] **Quiz questions** have exactly one clearly correct answer and believable wrong answers.
- [ ] **Impact estimates** have a stated basis. See `impact_methodology.md`.

Set `status` to `approved`, `needs change` or `remove`, and explain in `notes`.

## 3. Reports from the app

Learners and teachers can tap **Report a problem** on any lesson, mission or the
impact method page. Reports are stored in the `content_reports` table:

```sql
-- Open reports, newest first, grouped by item
select content_type, content_id, reason, count(*) as reports,
       max(created_at) as latest,
       string_agg(message, ' | ') filter (where message is not null) as messages
  from content_reports
 where status = 'open'
 group by content_type, content_id, reason
 order by latest desc;

-- After fixing or deciding not to change something
update content_reports set status = 'fixed'     where content_type = 'mission' and content_id = 'm_short_shower';
update content_reports set status = 'dismissed' where id = '…';
```

## 4. Where content lives

| Content | File |
| --- | --- |
| Lessons | `lib/data/sdg_data.dart` |
| Quiz questions | `lib/data/quiz_questions.dart` |
| Missions and impact estimates | `assets/content/missions.json` (shared with the server) |
| Monthly challenges | `assets/content/monthly_challenges.json` (shared with the server) |
| Official goals and targets | `assets/content/sdg_targets.json`, from the UN Statistics Division SDG API. Do not edit by hand. |

Record who reviewed which version in the pull request that applies the changes.
