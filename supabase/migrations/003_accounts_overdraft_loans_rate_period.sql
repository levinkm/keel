-- =============================================================================
-- Keel — Migration 003
-- Accounts: adds overdraft_limit_minor — the maximum negative balance allowed.
--           null or 0 means no overdraft facility.
-- Loans:    adds rate_period — 'annual' (default) or 'monthly'.
--           The existing annual_rate_bp column stores the stated rate in basis
--           points; rate_period tells the engine how to interpret it.
-- =============================================================================

alter table keel_accounts
  add column if not exists overdraft_limit_minor bigint;

alter table keel_loans
  add column if not exists rate_period text not null default 'annual';
