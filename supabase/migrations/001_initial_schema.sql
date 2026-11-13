-- =============================================================================
-- Keel — Supabase schema migration
-- Run this in the Supabase SQL editor for your project.
-- =============================================================================

-- Enable RLS helper
create extension if not exists "uuid-ossp";

-- =============================================================================
-- ACCOUNTS
-- =============================================================================
create table if not exists keel_accounts (
  id           text primary key,
  user_id      uuid not null references auth.users(id) on delete cascade,
  name         text not null,
  type         text not null,
  currency     text not null default 'KES',
  liquidity    text not null default 'instant',
  is_active    boolean not null default true,
  overdraft_limit_minor bigint,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);

alter table keel_accounts enable row level security;
create policy "Users manage own accounts"
  on keel_accounts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- JOURNAL ENTRIES
-- =============================================================================
create table if not exists keel_journal_entries (
  id           text primary key,
  user_id      uuid not null references auth.users(id) on delete cascade,
  date         text not null,
  description  text not null,
  reference    text,
  payee        text,
  notes        text,
  location     text,
  contact_id   text,
  period       text not null,
  is_locked    boolean not null default false,
  tags         text not null default '',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);

alter table keel_journal_entries enable row level security;
create policy "Users manage own journal entries"
  on keel_journal_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists idx_keel_journal_entries_period
  on keel_journal_entries(user_id, period);

-- =============================================================================
-- JOURNAL LINES
-- =============================================================================
create table if not exists keel_journal_lines (
  id           text primary key,
  user_id      uuid not null references auth.users(id) on delete cascade,
  entry_id     text not null,
  account_id   text not null,
  amount_minor bigint not null,
  currency     text not null default 'KES',
  side         text not null,
  memo         text,
  updated_at   timestamptz not null default now(),
  deleted_at   timestamptz
);

alter table keel_journal_lines enable row level security;
create policy "Users manage own journal lines"
  on keel_journal_lines for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists idx_keel_journal_lines_entry
  on keel_journal_lines(user_id, entry_id);

-- =============================================================================
-- BUDGET PLANS
-- =============================================================================
create table if not exists keel_budget_plans (
  id                  text primary key,
  user_id             uuid not null references auth.users(id) on delete cascade,
  period              text not null,
  strategy_id         text not null,
  strategy_version    integer not null,
  base_amount_minor   bigint not null,
  currency            text not null default 'KES',
  is_template         boolean not null default false,
  template_name       text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

alter table keel_budget_plans enable row level security;
create policy "Users manage own budget plans"
  on keel_budget_plans for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- BUDGET LINES
-- =============================================================================
create table if not exists keel_budget_lines (
  id              text primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  plan_id         text not null,
  account_id      text not null,
  bucket          text not null,
  planned_minor   bigint not null,
  currency        text not null default 'KES',
  rollover_minor  bigint not null default 0,
  notes           text,
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz
);

alter table keel_budget_lines enable row level security;
create policy "Users manage own budget lines"
  on keel_budget_lines for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- STRATEGIES
-- =============================================================================
create table if not exists keel_strategies (
  id          text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  version     integer not null,
  name        text not null,
  is_builtin  boolean not null default false,
  definition  text not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

alter table keel_strategies enable row level security;
create policy "Users manage own strategies"
  on keel_strategies for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- STRATEGY BUCKETS
-- =============================================================================
create table if not exists keel_strategy_buckets (
  id               text primary key,
  user_id          uuid not null references auth.users(id) on delete cascade,
  strategy_id      text not null,
  name             text not null,
  target_pct       integer not null default 0,
  account_ids      text not null default '',
  account_weights  text not null default '',
  updated_at       timestamptz not null default now(),
  deleted_at       timestamptz
);

alter table keel_strategy_buckets enable row level security;
create policy "Users manage own strategy buckets"
  on keel_strategy_buckets for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- LOANS
-- =============================================================================
create table if not exists keel_loans (
  id                  text primary key,
  user_id             uuid not null references auth.users(id) on delete cascade,
  direction           text not null,
  counterparty        text not null,
  principal_minor     bigint not null,
  currency            text not null default 'KES',
  interest_method     text not null,
  annual_rate_bp      integer not null,
  rate_period         text not null default 'annual',
  term_months         integer not null,
  disbursement_date   text not null,
  first_due_date      text not null,
  instalment_minor    bigint not null,
  is_salary_deducted  boolean not null default false,
  status              text not null default 'active',
  account_id          text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

alter table keel_loans enable row level security;
create policy "Users manage own loans"
  on keel_loans for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- LOAN EVENTS
-- =============================================================================
create table if not exists keel_loan_events (
  id            text primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  loan_id       text not null,
  type          text not null,
  date          text not null,
  amount_minor  bigint not null,
  currency      text not null default 'KES',
  note          text,
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

alter table keel_loan_events enable row level security;
create policy "Users manage own loan events"
  on keel_loan_events for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists idx_keel_loan_events_loan
  on keel_loan_events(user_id, loan_id);

-- =============================================================================
-- INCOME STREAMS
-- =============================================================================
create table if not exists keel_income_streams (
  id                      text primary key,
  user_id                 uuid not null references auth.users(id) on delete cascade,
  name                    text not null,
  type                    text not null,
  account_id              text not null,
  frequency               text not null,
  frequency_unit          text,
  frequency_interval      integer,
  payment_mode            text not null default 'regular',
  amount_minor            bigint not null,
  reliable_amount_minor   bigint,
  currency                text not null default 'KES',
  is_active               boolean not null default true,
  start_date              text,
  end_date                text,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),
  deleted_at              timestamptz
);

alter table keel_income_streams enable row level security;
create policy "Users manage own income streams"
  on keel_income_streams for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- ASSETS
-- =============================================================================
create table if not exists keel_assets (
  id                    text primary key,
  user_id               uuid not null references auth.users(id) on delete cascade,
  name                  text not null,
  class                 text not null,
  acquisition_date      text not null,
  cost_minor            bigint not null,
  currency              text not null default 'KES',
  ownership_share_bp    integer not null default 10000,
  current_value_minor   bigint,
  valuation_date        text,
  valuation_source      text,
  depreciation_method   text,
  annual_rate_bp        integer,
  salvage_minor         bigint not null default 0,
  linked_loan_id        text,
  insurance_expiry      text,
  status                text not null default 'in_use',
  location              text,
  notes                 text,
  holding_id            text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  deleted_at            timestamptz
);

alter table keel_assets enable row level security;
create policy "Users manage own assets"
  on keel_assets for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- HOLDINGS
-- =============================================================================
create table if not exists keel_holdings (
  id                  text primary key,
  user_id             uuid not null references auth.users(id) on delete cascade,
  name                text not null,
  type                text not null,
  institution         text not null,
  account_id          text not null,
  currency            text not null default 'KES',
  liquidity           text not null default 'days',
  is_active           boolean not null default true,
  current_price_minor bigint,
  annual_rate_bp      integer,
  compounding_freq    text not null default 'none',
  maturity_date       text,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz
);

alter table keel_holdings enable row level security;
create policy "Users manage own holdings"
  on keel_holdings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- HOLDING LOTS
-- =============================================================================
create table if not exists keel_holding_lots (
  id            text primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  holding_id    text not null,
  date          text not null,
  units         numeric not null,
  price_minor   bigint not null,
  fees_minor    bigint not null default 0,
  currency      text not null default 'KES',
  lot_type      text not null default 'purchase',
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

alter table keel_holding_lots enable row level security;
create policy "Users manage own holding lots"
  on keel_holding_lots for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index if not exists idx_keel_holding_lots_holding
  on keel_holding_lots(user_id, holding_id);

-- =============================================================================
-- CONTACTS
-- =============================================================================
create table if not exists keel_contacts (
  id            text primary key,
  user_id       uuid not null references auth.users(id) on delete cascade,
  name          text not null,
  phone         text,
  email         text,
  notes         text,
  relationship  text not null default 'other',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  deleted_at    timestamptz
);

alter table keel_contacts enable row level security;
create policy "Users manage own contacts"
  on keel_contacts for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- PROJECTS
-- =============================================================================
create table if not exists keel_projects (
  id                    text primary key,
  user_id               uuid not null references auth.users(id) on delete cascade,
  name                  text not null,
  description           text,
  type                  text not null,
  status                text not null default 'planning',
  budget_minor          bigint not null default 0,
  revenue_target_minor  bigint,
  currency              text not null default 'KES',
  funding_account_id    text,
  asset_account_id      text,
  asset_id              text,
  start_date            text not null,
  end_date              text,
  tags                  text not null default '',
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now(),
  deleted_at            timestamptz
);

alter table keel_projects enable row level security;
create policy "Users manage own projects"
  on keel_projects for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- PROJECT ENTRIES (join table)
-- =============================================================================
create table if not exists keel_project_entries (
  project_id        text not null,
  journal_entry_id  text not null,
  user_id           uuid not null references auth.users(id) on delete cascade,
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,
  primary key (project_id, journal_entry_id)
);

alter table keel_project_entries enable row level security;
create policy "Users manage own project entries"
  on keel_project_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- ENTRY ATTACHMENTS
-- =============================================================================
create table if not exists keel_entry_attachments (
  id          text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  entry_id    text not null,
  file_path   text not null,
  file_name   text not null,
  mime_type   text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

alter table keel_entry_attachments enable row level security;
create policy "Users manage own entry attachments"
  on keel_entry_attachments for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- ASSET ATTACHMENTS
-- =============================================================================
create table if not exists keel_asset_attachments (
  id          text primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  asset_id    text not null,
  file_path   text not null,
  file_name   text not null,
  mime_type   text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  deleted_at  timestamptz
);

alter table keel_asset_attachments enable row level security;
create policy "Users manage own asset attachments"
  on keel_asset_attachments for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

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

alter table keel_tariffs enable row level security;
create policy "Users manage own tariffs"
  on keel_tariffs for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
-- =============================================================================
create table if not exists keel_period_snapshots (
  id                        text primary key,
  user_id                   uuid not null references auth.users(id) on delete cascade,
  period                    text not null,
  opening_net_worth_minor   bigint not null,
  closing_net_worth_minor   bigint not null,
  currency                  text not null default 'KES',
  is_locked                 boolean not null default false,
  closed_at                 timestamptz,
  updated_at                timestamptz not null default now(),
  deleted_at                timestamptz,
  unique (user_id, period)
);

alter table keel_period_snapshots enable row level security;
create policy "Users manage own period snapshots"
  on keel_period_snapshots for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- SETTINGS
-- =============================================================================
create table if not exists keel_settings (
  key         text not null,
  user_id     uuid not null references auth.users(id) on delete cascade,
  value       text not null,
  updated_at  timestamptz not null default now(),
  primary key (user_id, key)
);

alter table keel_settings enable row level security;
create policy "Users manage own settings"
  on keel_settings for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- =============================================================================
-- updated_at trigger function (auto-updates on every row change)
-- =============================================================================
create or replace function keel_set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Apply trigger to every table that has updated_at
do $$
declare
  t text;
begin
  foreach t in array array[
    'keel_accounts', 'keel_journal_entries', 'keel_journal_lines',
    'keel_budget_plans', 'keel_budget_lines', 'keel_strategies',
    'keel_strategy_buckets', 'keel_loans', 'keel_loan_events',
    'keel_income_streams', 'keel_assets', 'keel_holdings',
    'keel_holding_lots', 'keel_contacts', 'keel_projects',
    'keel_project_entries', 'keel_entry_attachments',
    'keel_asset_attachments', 'keel_period_snapshots', 'keel_settings'
  ]
  loop
    execute format(
      'create or replace trigger trg_%s_updated_at
       before update on %s
       for each row execute function keel_set_updated_at()',
      replace(t, 'keel_', ''), t
    );
  end loop;
end;
$$;
