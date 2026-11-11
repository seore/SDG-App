-- Up to three SDGs the user wants to focus on (biases their daily missions).
alter table users
  add column focus_sdgs smallint[] not null default '{}'
    check (cardinality(focus_sdgs) <= 3
           and focus_sdgs <@ array[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]::smallint[]);
