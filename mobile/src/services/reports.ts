import { supabase } from '@/lib/supabase';
import type { HistoryEntry, Report } from '@/types/models';

/**
 * reports の作成・当日取得・履歴取得・取り消し（Swift 版 ReportService と 1:1）。
 * reports は追記専用ログ。行は消さず、取り消しは `cancelled_at` のソフト更新。
 */

export async function createReport(params: {
  familyId: string;
  buttonId: string;
  userId: string;
}): Promise<Report> {
  const { data, error } = await supabase
    .from('reports')
    .insert({
      family_id: params.familyId,
      button_id: params.buttonId,
      user_id: params.userId,
    })
    .select()
    .single();
  if (error) throw error;
  return data as Report;
}

/**
 * 報告の「取り消し」— 実削除ではなく `cancelled_at = now()` のソフト更新。
 * `reports_cancel_own` により本人以外が呼ぶと 0 行マッチ（エラーにならない）。
 * 呼び出し側で本人の行だけに導線を出す前提。
 */
export async function cancelReport(id: string): Promise<void> {
  const { error } = await supabase
    .from('reports')
    .update({ cancelled_at: new Date().toISOString() })
    .eq('id', id);
  if (error) throw error;
}

export interface TodayReportEntry {
  button_id: string;
  created_at: string;
  reporter_name: string;
}

/**
 * 指定ボタン群の「今日（JST）」の報告一覧、古い順。
 * 各 button_id の最初の 1 件 = 「今日最初に報告した人」。取り消し済みは除外。
 */
export async function fetchTodayReports(params: {
  familyId: string;
  buttonIds: string[];
  range: { start: string; end: string };
}): Promise<TodayReportEntry[]> {
  if (params.buttonIds.length === 0) return [];
  const { data, error } = await supabase
    .from('reports')
    .select('button_id, created_at, reporter:profiles(display_name)')
    .eq('family_id', params.familyId)
    .in('button_id', params.buttonIds)
    .gte('created_at', params.range.start)
    .lt('created_at', params.range.end)
    .is('cancelled_at', null)
    .order('created_at', { ascending: true });
  if (error) throw error;
  return (data ?? []).map((row: any) => ({
    button_id: row.button_id,
    created_at: row.created_at,
    reporter_name: row.reporter?.display_name ?? '',
  }));
}

/**
 * 家族の全報告履歴、新しい順（仕様書 15）。取り消し済みは除外。
 * report_buttons は非アクティブ（ソフト削除済み）でも JOIN するので
 * 古い履歴のラベル/アイコンが欠けない。
 */
export async function fetchHistory(
  familyId: string,
  limit = 200,
): Promise<HistoryEntry[]> {
  const { data, error } = await supabase
    .from('reports')
    .select(
      'id, created_at, reporter:profiles(id, display_name), button:report_buttons(label, icon)',
    )
    .eq('family_id', familyId)
    .is('cancelled_at', null)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw error;
  return (data ?? []).map((row: any) => ({
    id: row.id,
    created_at: row.created_at,
    reporter_id: row.reporter?.id ?? '',
    reporter_name: row.reporter?.display_name ?? '',
    button_label: row.button?.label ?? '',
    button_icon: row.button?.icon ?? null,
  }));
}
