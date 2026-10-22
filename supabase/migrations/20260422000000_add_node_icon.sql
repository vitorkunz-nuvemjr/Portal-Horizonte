-- Migration: Add icon column to nodes table
-- Allows Values (and other nodes) to store custom Material Symbols icon names
alter table public.nodes add column if not exists icon text;
