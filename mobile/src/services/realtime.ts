import type { RealtimeChannel } from '@supabase/supabase-js';

import { supabase } from '@/lib/supabase';

/**
 * `reports` テーブルの変更を family_id で絞って購読する（Swift 版
 * RealtimeReportsService と 1:1、仕様書 36）。
 *
 * - INSERT: 他端末からの新規報告 → ホームの「今日の状態」・履歴一覧を更新
 * - UPDATE: 履歴からの取り消し（cancelled_at）→ 別タブの DAILY カードが未報告に戻る
 * - DELETE: 一応購読（現状 DELETE は使っていない）
 *
 * 事前に `supabase/migrations/..._enable_realtime_for_reports.sql` で
 * `reports` が `supabase_realtime` パブリケーションに入っている必要がある（設定済み）。
 * 配信範囲は RLS の `reports_select_member` がどのみち家族内に絞る。
 */
export function subscribeToFamilyReports(
  familyId: string,
  onChange: () => void,
): () => void {
  // チャンネル名は購読ごとにユニークにする。同名だと supabase-js が既存の
  // （すでに subscribe 済みの）チャンネルを返し、そこに .on() を足そうとして
  // 「cannot add postgres_changes callbacks after subscribe()」で落ちる
  // （ホームと履歴が同じ family_id を購読するため実際に衝突していた）。
  const uniqueId = `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
  const channel: RealtimeChannel = supabase
    .channel(`reports:${familyId}:${uniqueId}`)
    .on(
      'postgres_changes',
      {
        event: '*',
        schema: 'public',
        table: 'reports',
        filter: `family_id=eq.${familyId}`,
      },
      () => onChange(),
    )
    .subscribe();

  return () => {
    supabase.removeChannel(channel);
  };
}
