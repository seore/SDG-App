-- Real-world impact estimate recorded with each mission completion
-- (e.g. water_l = 40). Values come from goalquest/assets/content/missions.json.
alter table mission_completions
  add column impact_metric text,
  add column impact_amount real not null default 0 check (impact_amount >= 0);

create index mission_completions_impact_idx
  on mission_completions (impact_metric) where impact_metric is not null;
