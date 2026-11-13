-- =============================================================================
-- Keel — Migration 004
-- Creates keel_tariffs and adds account_id / fee_account_id.
-- Safe to run on projects that never had the table (create) and on projects
-- that had the old schema without those columns (alter).
-- =============================================================================

create table if not exists keel_tariffs (
  id             text primary key,
  user_id        uuid not null references auth.users(id) on delete cascade,
  provider       text not null,
  account_id     text not null default '',
  fee_account_id text,
  channel        text not null,
  operation      text not null,
  effective_from text not null,
  effective_to   text,
  tiers          text not null,
  tax_rate_bp    integer not null default 0,
  updated_at     timestamptz not null default now(),
  deleted_at     timestamptz
);

-- Add columns only if the table already existed without them
alter table keel_tariffs
  add column if not exists account_id     text not null default '',
  add column if not exists fee_account_id text;

alter table keel_tariffs enable row level security;

-- Policy is idempotent via drop-if-exists + recreate
drop policy if exists "Users manage own tariffs" on keel_tariffs;
create policy "Users manage own tariffs"
  on keel_tariffs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- updated_at trigger
create or replace trigger trg_tariffs_updated_at
  before update on keel_tariffs
  for each row execute function keel_set_updated_at();
