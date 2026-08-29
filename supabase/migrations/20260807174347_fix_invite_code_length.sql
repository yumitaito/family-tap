-- Fixes a real bug caught during Phase 15 end-to-end testing: invite codes
-- were sometimes only 7 characters instead of the intended 8.
--
-- Root cause: `create_family` picked each character with
-- `substr(charset, (random() * 32)::int + 1, 1)`. Postgres's `::int` cast
-- from `double precision` ROUNDS to the nearest integer, not truncates.
-- `random()` returns `[0, 1)`, so `random() * 32` is `[0, 32)` — but a
-- value like 0.999... rounds UP to 32 (not down to 31), giving an index of
-- 33 for a 32-character charset. `substr` silently returns an empty
-- string for an out-of-range start position rather than erroring, so that
-- position just contributed nothing, shortening the code.
--
-- Fix: wrap in `floor(...)` before the `::int` cast, so the value is
-- truncated toward zero *before* casting (an already-whole-number double
-- casts to int exactly, with no rounding ambiguity) — index is always in
-- `[1, 32]`.

create or replace function public.create_family(family_name text)
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
      select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', floor(random() * 32)::int + 1, 1), '')
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
