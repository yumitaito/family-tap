-- Wraps family creation and joining in SECURITY DEFINER RPCs, fixing two
-- chicken-and-egg problems with plain client-side inserts under RLS:
--
-- 1. create: `INSERT INTO families ... RETURNING *` requires the inserted
--    row to satisfy families' SELECT policy (is_family_member(id)) for the
--    RETURNING clause to succeed — but the creator isn't a family_members
--    row yet at that point (that's the *next* insert), so Postgres raises
--    "new row violates row-level security policy for table families".
--    Doing both inserts in one SECURITY DEFINER function sidesteps this:
--    the function's internal statements run with the definer's privileges
--    (bypassing RLS), and only the final return value goes back to the
--    client.
--
-- 2. join: looking up a family by invite code needs a SELECT on
--    `families`, but families_select_member only allows that once you're
--    already a member — which is exactly what redeeming an invite code is
--    supposed to grant. A SECURITY DEFINER function that takes the code as
--    a parameter (rather than a general table SELECT) is also the more
--    secure shape here: it only reveals the one family whose exact code
--    you already know, not an enumerable view of the table.

create function public.create_family(family_name text)
returns public.families
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_family public.families;
  generated_code text;
  attempt int := 0;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  loop
    generated_code := (
      select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', (random() * 32)::int + 1, 1), '')
      from generate_series(1, 8)
    );
    exit when not exists (select 1 from public.families f where f.invite_code = generated_code);
    attempt := attempt + 1;
    if attempt > 10 then
      raise exception 'could_not_generate_invite_code';
    end if;
  end loop;

  insert into public.families (name, invite_code, created_by)
  values (family_name, generated_code, auth.uid())
  returning * into new_family;

  insert into public.family_members (family_id, user_id, role)
  values (new_family.id, auth.uid(), 'owner');

  return new_family;
end;
$$;

create function public.join_family(invite_code_input text)
returns public.families
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_family public.families;
begin
  if auth.uid() is null then
    raise exception 'not_authenticated';
  end if;

  select * into target_family
  from public.families f
  where f.invite_code = invite_code_input;

  if not found then
    raise exception 'invite_code_not_found';
  end if;

  if exists (
    select 1 from public.family_members fm
    where fm.family_id = target_family.id
      and fm.user_id = auth.uid()
  ) then
    return target_family; -- already a member: idempotent, not an error
  end if;

  insert into public.family_members (family_id, user_id, role)
  values (target_family.id, auth.uid(), 'member');

  return target_family;
end;
$$;

revoke execute on function public.create_family(text) from public, anon;
revoke execute on function public.join_family(text) from public, anon;
grant execute on function public.create_family(text) to authenticated;
grant execute on function public.join_family(text) to authenticated;
