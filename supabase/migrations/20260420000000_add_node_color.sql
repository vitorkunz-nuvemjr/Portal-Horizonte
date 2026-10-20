-- Migration: Add color column to nodes table
-- Allows OKRs (objectives, key results) and KPIs to store custom folder/card accent colors
alter table public.nodes add column if not exists color text;
