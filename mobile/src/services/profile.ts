import { supabase } from '@/lib/supabase';
import type { Profile } from '@/types/models';

export async function fetchProfile(userId: string): Promise<Profile> {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, display_name')
    .eq('id', userId)
    .single();
  if (error) throw error;
  return data as Profile;
}

/** 自分の表示名を変更。`profiles_update_own`（Phase 4）で本人のみ許可。 */
export async function updateDisplayName(
  userId: string,
  displayName: string,
): Promise<void> {
  const { error } = await supabase
    .from('profiles')
    .update({ display_name: displayName })
    .eq('id', userId);
  if (error) throw error;
}
