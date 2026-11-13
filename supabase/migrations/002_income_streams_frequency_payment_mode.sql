-- =============================================================================
-- Keel — Migration 002
-- Adds flexible frequency columns and payment_mode to keel_income_streams.
--
-- frequency_unit     : 'day' | 'week' | 'month'
-- frequency_interval : how many units between payments (0 = irregular)
-- payment_mode       : 'regular' | 'milestone'
--
-- The legacy `frequency` text column is kept for backward compatibility.
-- =============================================================================

alter table keel_income_streams
  add column if not exists frequency_unit     text,
  add column if not exists frequency_interval integer,
  add column if not exists payment_mode       text not null default 'regular';
