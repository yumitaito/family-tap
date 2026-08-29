-- Fixes "infinite recursion detected in policy for relation family_members"
-- (Postgres error 42P17), hit live while testing Phase 6.
--
-- The bug: `family_members_select_same_family` (from
-- 20260807152108_rls_policies.sql) queries `family_members` from within
-- its own USING clause. Evaluating that inner query re-applies the same
-- RLS policy to its candidate rows, which queries `family_members` again,
-- forever. Every OTHER policy that checked membership by querying
-- `family_members` directly (profiles, families, report_buttons, reports)
-- was equally broken, since family_members' own SELECT policy still
-- applies whenever it's queried, even as a subquery from another table's
-- policy.
--
-- Fix: move the "does auth.uid() belong to this family" check into
-- SECURITY DEFINER helper functions. Those run as their owner (postgres,
-- since migrations run as postgres — which bypasses RLS in Supabase),
-- so the internal family_members lookup no longer re-triggers RLS at all,
-- breaking the cycle. This is the standard fix for self-referential
-- membership-table RLS.

create function public.is_family_member(target_family_id uuid)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = target_family_id
      and fm.user_id = auth.uid()
  );
$$;

create function public.is_family_owner(target_family_id uuid)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.family_members fm
    where fm.family_id = target_family_id
      and fm.user_id = auth.uid()
      and fm.role = 'owner'
  );
$$;

create function public.shares_family_with(target_user_id uuid)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select exists (
    select 1
    from public.family_members my_membership
    join public.family_members their_membership
      on their_membership.family_id = my_membership.family_id
    where my_membership.user_id = auth.uid()
      and their_membership.user_id = target_user_id
  );
$$;

-- These should only ever be called from within RLS policies (evaluated as
-- the querying user), not invoked directly via RPC.
revoke execute on function public.is_family_member(uuid) from public, anon, authenticated;
revoke execute on function public.is_family_owner(uuid) from public, anon, authenticated;
revoke execute on function public.shares_family_with(uuid) from public, anon, authenticated;
grant execute on function public.is_family_member(uuid) to authenticated;
grant execute on function public.is_family_owner(uuid) to authenticated;
grant execute on function public.shares_family_with(uuid) to authenticated;

-- ============================================================
-- Recreate the affected policies using the helper functions.
-- ============================================================

drop policy "profiles_select_own_or_shared_family" on public.profiles;
create policy "profiles_select_own_or_shared_family"
  on public.profiles for select
  using (
    id = (select auth.uid())
    or public.shares_family_with(profiles.id)
  );

drop policy "families_select_member" on public.families;
create policy "families_select_member"
  on public.families for select
  using (public.is_family_member(families.id));

drop policy "families_update_owner" on public.families;
create policy "families_update_owner"
  on public.families for update
  using (public.is_family_owner(families.id))
  with check (public.is_family_owner(families.id));

drop policy "family_members_select_same_family" on public.family_members;
create policy "family_members_select_same_family"
  on public.family_members for select
  using (public.is_family_member(family_members.family_id));

drop policy "report_buttons_select_member" on public.report_buttons;
create policy "report_buttons_select_member"
  on public.report_buttons for select
  using (public.is_family_member(report_buttons.family_id));

drop policy "report_buttons_insert_member" on public.report_buttons;
create policy "report_buttons_insert_member"
  on public.report_buttons for insert
  with check (
    created_by = (select auth.uid())
    and public.is_family_member(report_buttons.family_id)
  );

drop policy "report_buttons_update_member" on public.report_buttons;
create policy "report_buttons_update_member"
  on public.report_buttons for update
  using (public.is_family_member(report_buttons.family_id))
  with check (public.is_family_member(report_buttons.family_id));

drop policy "report_buttons_delete_member" on public.report_buttons;
create policy "report_buttons_delete_member"
  on public.report_buttons for delete
  using (public.is_family_member(report_buttons.family_id));

drop policy "reports_select_member" on public.reports;
create policy "reports_select_member"
  on public.reports for select
  using (public.is_family_member(reports.family_id));

drop policy "reports_insert_member" on public.reports;
create policy "reports_insert_member"
  on public.reports for insert
  with check (
    user_id = (select auth.uid())
    and public.is_family_member(reports.family_id)
  );

-- family_members_insert_self and families_insert_self_as_creator are
-- untouched: neither queries family_members inside its own check, so
-- neither was ever part of the recursion.
