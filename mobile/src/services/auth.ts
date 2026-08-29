import { supabase } from '@/lib/supabase';

/**
 * Supabase Auth のラッパー（Swift 版 AuthService と 1:1）。
 * `profiles` 行はここでは作らない — `handle_new_user` DB トリガーが
 * signUp の `display_name` メタデータを読んでサーバー側で作る
 * （メール確認必須設定でクライアントセッションがまだ無いケースにも対応するため）。
 */

/** サインアップ。即座にセッションが張られたら true（=メール確認不要）、
 *  確認待ちなら false を返す。 */
export async function signUp(
  email: string,
  password: string,
  displayName: string,
): Promise<boolean> {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { display_name: displayName } },
  });
  if (error) throw error;
  return data.session != null;
}

export async function signIn(email: string, password: string): Promise<void> {
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
}

export async function signOut(): Promise<void> {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

/** サインイン中ユーザーの id。セッションが無ければ throw。 */
export async function currentUserId(): Promise<string> {
  const { data, error } = await supabase.auth.getSession();
  if (error) throw error;
  const id = data.session?.user.id;
  if (!id) throw new Error('セッションがありません');
  return id;
}
