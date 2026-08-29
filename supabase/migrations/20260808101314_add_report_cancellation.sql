-- Adds "取り消し" (cancel) for a report, long-pressed from HISTORY-001.
--
-- This is a soft-cancel, not a real DELETE — `reports` stays an
-- append-only log at the storage layer (spec section 10/37: "報告履歴自体
-- は削除しない"), mirroring how report_buttons is "deleted" (Phase 8:
-- `is_active = false`, never a real DELETE). `cancelled_at` being non-null
-- means the app's own queries (fetchHistory, fetchTodayReports) exclude
-- the row, so it disappears from History and stops counting toward a
-- DAILY button's "reported today?" check — without ever actually deleting
-- the underlying record.
--
-- Only the reporter can cancel their own report — mirrors
-- reports_insert_member's "user_id = auth.uid()" self-only shape. Other
-- family members can still SEE it in history (reports_select_member,
-- unchanged) but cannot touch it; the iOS client also only shows the
-- cancel affordance for the current user's own entries, per the app's
-- "報告するカードは個人管理" design (only 今日の状態/DAILY status is
-- family-shared).

alter table public.reports add column cancelled_at timestamptz;

create policy "reports_cancel_own"
  on public.reports for update
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));
