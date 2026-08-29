import { supabase } from '@/lib/supabase';
import type { ReportButton, ReportButtonType } from '@/types/models';

/**
 * report_buttons の CRUD（Swift 版 ReportButtonService と 1:1）。
 * 家族に所属した状態からしか呼ばれないので RPC 迂回は不要。
 *
 * 注意: INSERT 時は `created_by` を必ず明示的に渡すこと。省略すると NULL が入り、
 * INSERT ポリシーの WITH CHECK (`created_by = auth.uid()`) が NULL 評価で
 * 通らず、RLS に静かに弾かれる。
 */

/** アクティブなボタンを sort_order 順で取得。 */
export async function fetchActiveButtons(
  familyId: string,
): Promise<ReportButton[]> {
  const { data, error } = await supabase
    .from('report_buttons')
    .select('*')
    .eq('family_id', familyId)
    .eq('is_active', true)
    .order('sort_order', { ascending: true });
  if (error) throw error;
  return (data ?? []) as ReportButton[];
}

export async function createButton(params: {
  familyId: string;
  label: string;
  icon: string | null;
  type: ReportButtonType;
  createdBy: string;
}): Promise<ReportButton> {
  const { data, error } = await supabase
    .from('report_buttons')
    .insert({
      family_id: params.familyId,
      label: params.label,
      icon: params.icon,
      type: params.type,
      created_by: params.createdBy,
    })
    .select()
    .single();
  if (error) throw error;
  return data as ReportButton;
}

export async function updateButton(params: {
  id: string;
  label: string;
  icon: string | null;
  type: ReportButtonType;
  sortOrder: number;
}): Promise<ReportButton> {
  const { data, error } = await supabase
    .from('report_buttons')
    .update({
      label: params.label,
      icon: params.icon,
      type: params.type,
      sort_order: params.sortOrder,
    })
    .eq('id', params.id)
    .select()
    .single();
  if (error) throw error;
  return data as ReportButton;
}

/**
 * ボタンの「削除」— 実際にはソフトデリート（`is_active = false`）。
 * `reports.button_id` が ON DELETE CASCADE のため、本当に DELETE すると
 * 紐づく報告履歴まで消える（仕様書 10/37「履歴は削除しない」に反する）。
 */
export async function deleteButton(id: string): Promise<void> {
  const { error } = await supabase
    .from('report_buttons')
    .update({ is_active: false })
    .eq('id', id);
  if (error) throw error;
}
