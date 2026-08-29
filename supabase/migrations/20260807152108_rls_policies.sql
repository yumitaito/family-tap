-- Family Tap RLS policies (spec section 37).
-- RLS was already enabled (no policies) in 20260807151906_initial_schema.sql,
-- so every table has been fully locked down since then. This migration adds
-- the policies that open up exactly the access the app needs.
--
-- Core rule everywhere: a user may only see/write data belonging to a family
-- they are a member of (public.family_members), and may only write rows that
-- are "theirs" (their own profile, their own device tokens, reports/buttons
-- they're allowed to touch because they share the family).

-- ============================================================
-- profiles
-- ============================================================

-- Spec section 19: the family members screen needs to show every member's
-- display name, not just the current user's own profile.
create policy "profiles_select_own_or_shared_family"
  on public.profiles for select
  using (
    id = (select auth.uid())
    or exists (
      select 1
      from public.family_members my_membership
      join public.family_members their_membership
        on their_membership.family_id = my_membership.family_id
      where my_membership.user_id = (select auth.uid())
        and their_membership.user_id = profiles.id
    )
  );

-- A user creates their own profile row right after sign up (spec section 20).
create policy "profiles_insert_own"
  on public.profiles for insert
  with check (id = (select auth.uid()));

create policy "profiles_update_own"
  on public.profiles for update
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- ============================================================
-- families
-- ============================================================

create policy "families_select_member"
  on public.families for select
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = families.id
        and fm.user_id = (select auth.uid())
    )
  );

-- Anyone signed in can create a family (spec section 17); membership as
-- 'owner' is added separately via family_members right after.
create policy "families_insert_self_as_creator"
  on public.families for insert
  with check (created_by = (select auth.uid()));

-- Only the family's owner can rename it / other future settings.
create policy "families_update_owner"
  on public.families for update
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = families.id
        and fm.user_id = (select auth.uid())
        and fm.role = 'owner'
    )
  )
  with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = families.id
        and fm.user_id = (select auth.uid())
        and fm.role = 'owner'
    )
  );

-- ============================================================
-- family_members
-- ============================================================

-- Spec section 37: "自身が所属しているfamilyのみ閲覧可能" — this also lets a
-- user see their *fellow* members' rows (needed for FAMILY-004), not just
-- their own, since the check is "does the current user belong to this row's
-- family" rather than "is this row's user_id me".
create policy "family_members_select_same_family"
  on public.family_members for select
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = family_members.family_id
        and fm.user_id = (select auth.uid())
    )
  );

-- A user can only ever add *themselves* to a family — either as the owner
-- right after creating it, or as a member after redeeming an invite code
-- (spec section 18). Nobody can add another user on their behalf.
create policy "family_members_insert_self"
  on public.family_members for insert
  with check (user_id = (select auth.uid()));

-- ============================================================
-- report_buttons (spec section 37)
-- ============================================================

create policy "report_buttons_select_member"
  on public.report_buttons for select
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = report_buttons.family_id
        and fm.user_id = (select auth.uid())
    )
  );

create policy "report_buttons_insert_member"
  on public.report_buttons for insert
  with check (
    created_by = (select auth.uid())
    and exists (
      select 1 from public.family_members fm
      where fm.family_id = report_buttons.family_id
        and fm.user_id = (select auth.uid())
    )
  );

-- Any family member can edit/delete a button (spec section 14 gives no
-- "creator only" restriction — buttons are shared family config).
create policy "report_buttons_update_member"
  on public.report_buttons for update
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = report_buttons.family_id
        and fm.user_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = report_buttons.family_id
        and fm.user_id = (select auth.uid())
    )
  );

create policy "report_buttons_delete_member"
  on public.report_buttons for delete
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = report_buttons.family_id
        and fm.user_id = (select auth.uid())
    )
  );

-- ============================================================
-- reports (spec section 37)
-- ============================================================

create policy "reports_select_member"
  on public.reports for select
  using (
    exists (
      select 1 from public.family_members fm
      where fm.family_id = reports.family_id
        and fm.user_id = (select auth.uid())
    )
  );

create policy "reports_insert_member"
  on public.reports for insert
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.family_members fm
      where fm.family_id = reports.family_id
        and fm.user_id = (select auth.uid())
    )
  );

-- No update/delete policy: reports are an append-only log by design (spec
-- section 10 — "DB上の報告履歴自体は削除しない"). With no policy for those
-- commands, they're simply denied.

-- ============================================================
-- device_tokens (not covered explicitly in spec section 37, kept strictly
-- private — only the owning user's client ever needs to read/write it; the
-- send-family-notification Edge Function reads across users with the
-- service_role key, which bypasses RLS entirely).
-- ============================================================

create policy "device_tokens_select_own"
  on public.device_tokens for select
  using (user_id = (select auth.uid()));

create policy "device_tokens_insert_own"
  on public.device_tokens for insert
  with check (user_id = (select auth.uid()));

create policy "device_tokens_update_own"
  on public.device_tokens for update
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "device_tokens_delete_own"
  on public.device_tokens for delete
  using (user_id = (select auth.uid()));
