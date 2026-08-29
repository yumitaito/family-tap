-- Auto-creates the public.profiles row the moment a new auth.users row
-- appears, using the display_name passed as signUp() metadata (spec section
-- 20/21). This runs as SECURITY DEFINER, so it works even when Supabase's
-- "confirm email" setting means the client has no session yet right after
-- signUp — inserting via a client-authenticated RLS policy wouldn't be
-- possible at that point.

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', new.email, 'New User')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
