-- Age check and verifiable parental consent for young users (COPPA /
-- UK Age Appropriate Design Code / GDPR-K).
alter table users
  add column birth_year smallint,
  add column consent_status text not null default 'not_required'
    check (consent_status in ('not_required', 'pending', 'granted')),
  add column parent_email text,
  add column consent_token_hash text unique,
  add column consent_requested_at timestamptz,
  add column consent_granted_at timestamptz,
  add column privacy_accepted_at timestamptz;
