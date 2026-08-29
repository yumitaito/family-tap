import { supabase } from '@/lib/supabase';
import type { Family, FamilyMemberWithProfile } from '@/types/models';

/**
 * 家族の作成・参加・メンバー取得（Swift 版 FamilyService と 1:1）。
 * 「自分が所属する family / member しか見えない」の強制は RLS 側（Phase 4）。
 * ここはクエリの形を整えるだけ。
 */

export class InviteCodeNotFoundError extends Error {
  constructor() {
    super('招待コードが見つかりませんでした');
    this.name = 'InviteCodeNotFoundError';
  }
}

export class NotOwnerError extends Error {
  constructor() {
    super('家族名を変更できるのはオーナーだけです');
    this.name = 'NotOwnerError';
  }
}

/** 今そのユーザーが所属している家族（無ければ null）。MVP では 1 ユーザー 1 家族。 */
export async function fetchCurrentFamily(userId: string): Promise<Family | null> {
  const { data, error } = await supabase
    .from('family_members')
    .select('family:families(*)')
    .eq('user_id', userId)
    .limit(1);
  if (error) throw error;
  // PostgREST の埋め込みは配列/オブジェクトどちらの形にもなり得るので緩めに扱う
  const raw = (data?.[0] as { family: Family | Family[] } | undefined)?.family;
  const family = Array.isArray(raw) ? raw[0] : raw;
  return family ?? null;
}

/**
 * 家族を作成し、呼び出し元を owner メンバーとして追加する。
 * families INSERT → family_members INSERT + 招待コード生成をサーバー側の
 * `create_family` SQL 関数（SECURITY DEFINER）で一括実行する。理由は
 * Swift 版のコメント参照（RLS の順序問題を回避するため）。
 */
export async function createFamily(name: string): Promise<Family> {
  const { data, error } = await supabase.rpc('create_family', {
    family_name: name,
  });
  if (error) throw error;
  return data as Family;
}

/** 招待コードで参加。同じくサーバー側 `join_family` 関数で実行。 */
export async function joinFamily(inviteCode: string): Promise<Family> {
  const { data, error } = await supabase.rpc('join_family', {
    invite_code_input: inviteCode,
  });
  if (error) {
    if (String(error.message ?? error).includes('invite_code_not_found')) {
      throw new InviteCodeNotFoundError();
    }
    throw error;
  }
  return data as Family;
}

/**
 * 家族名を変更。`families_update_owner`（Phase 4）で owner だけ許可。
 * member が呼ぶと RLS 上 0 行マッチ（エラーにはならない）なので、
 * `.select().single()` の decode 失敗を NotOwnerError にマップする。
 */
export async function updateFamilyName(
  familyId: string,
  name: string,
): Promise<void> {
  const { data, error } = await supabase
    .from('families')
    .update({ name })
    .eq('id', familyId)
    .select()
    .maybeSingle();
  if (error) throw error;
  if (!data) throw new NotOwnerError();
}

/** 家族メンバー一覧（表示名付き、参加順）。 */
export async function fetchMembers(
  familyId: string,
): Promise<FamilyMemberWithProfile[]> {
  const { data, error } = await supabase
    .from('family_members')
    .select('id, role, joined_at, profile:profiles(id, display_name)')
    .eq('family_id', familyId)
    .order('joined_at', { ascending: true });
  if (error) throw error;
  return (data ?? []) as unknown as FamilyMemberWithProfile[];
}
