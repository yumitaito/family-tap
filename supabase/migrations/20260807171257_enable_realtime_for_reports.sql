-- Adds `reports` to the `supabase_realtime` publication (spec section 36:
-- other devices' 履歴/DAILYステータス should update live when someone
-- reports). Postgres change events don't fire for a table until it's
-- explicitly added here — RLS (already in place via
-- reports_select_member) still governs who each subscriber actually
-- receives events for.

alter publication supabase_realtime add table public.reports;
