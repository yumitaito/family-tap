-- Fixes security advisor warnings "anon_security_definer_function_executable"
-- and "authenticated_security_definer_function_executable": Postgres grants
-- EXECUTE to PUBLIC by default, which PostgREST turns into a callable
-- /rest/v1/rpc/handle_new_user endpoint. The function is only ever meant to
-- run as the auth.users AFTER INSERT trigger, so revoke direct EXECUTE from
-- every API-facing role. (Trigger functions can't be invoked directly via
-- SQL/RPC anyway — Postgres rejects that — but this closes the advisory and
-- is correct defense in depth.)

revoke execute on function public.handle_new_user() from public, anon, authenticated;
