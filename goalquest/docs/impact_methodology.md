# How SDG Journey estimates impact

Every mission can carry a rough estimate of the real-world effect of doing it once
(`impact` in `assets/content/missions.json`). The app adds these up on the Impact
page and in the weekly summary. It always shows them with "≈".

## Principles

1. **Typical, not measured.** We don't know how long *your* shower was, so each
   estimate describes a typical completion of the mission.
2. **Stated, simple assumptions.** Each estimate is a short multiplication of the
   assumptions below. It is written in the mission's `impact.basis` field and shown
   in the app under "How we estimate this".
3. **Round down when unsure.** Where a range is plausible we pick a modest value,
   so totals are more likely to understate than overstate.
4. **Counted, not estimated.** People reached, minutes of learning or activity, and
   nature actions are counts of what the person did. They have no basis.

## Shared assumptions

| Quantity | Value used | Notes |
| --- | --- | --- |
| Electricity carbon intensity | ≈0.4 kg CO₂ / kWh | Real grids range from near 0 (mostly renewable) to about 1 (mostly coal). |
| Petrol car | ≈0.17 kg CO₂ / km | Average car, one occupant. |
| Bus passenger | ≈0.03 kg CO₂ / km | Average occupancy; varies widely. |
| Shower flow | ≈8 L / min | Older or power showers use more; eco heads use less. |
| Tap flow | ≈6 L / min | |
| Bath | ≈80 L | Used only for the "bathtubs" comparison. |
| Meal | ≈0.5 kg of food | Used only for the "meals" comparison. |

These are planning-level figures for teaching, not audited carbon accounting.
**Before release, have a reviewer check them against a current national source for
your main audience** (for example, your country's official greenhouse-gas
conversion factors and water-utility guidance), then update this table and the
affected `basis` strings together.

## Estimates with the most uncertainty

- `m_meat_free_meal` (1.5 kg CO₂): this depends heavily on which meat is replaced.
- `m_no_impulse_buy` (0.5 kg CO₂): only an order of magnitude.
- `m_check_leaks` (20 L): counts one day of a leak found, not the leak's lifetime.

## Changing an estimate

1. Edit `amount` and `basis` in `assets/content/missions.json`. The server reads the
   same file, so stored impact uses the new value from the next completion.
2. Past completions keep the value they were recorded with.
3. Run `flutter test test/mission_catalog_test.dart` and the server tests.
