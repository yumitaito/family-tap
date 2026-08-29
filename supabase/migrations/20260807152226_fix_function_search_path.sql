-- Fixes Supabase security advisor warning "function_search_path_mutable" on
-- public.set_updated_at: without a pinned search_path, a function is
-- resolved against whatever search_path the calling session has, which is a
-- known privilege-escalation vector for SECURITY DEFINER-style functions.
-- This function doesn't reference any schema-qualified objects, so pinning
-- search_path to empty is safe and closes the warning.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
