// Supabase のテーブル形状に対応（Swift 版 Models/ と 1:1）。

export type FamilyRole = 'owner' | 'member';
export type ReportButtonType = 'normal' | 'daily';

export interface Family {
  id: string;
  name: string;
  invite_code: string;
  created_by: string;
  created_at: string;
}

export interface Profile {
  id: string;
  display_name: string;
}

export interface FamilyMemberWithProfile {
  id: string;
  role: FamilyRole;
  joined_at: string;
  profile: Profile;
}

export interface ReportButton {
  id: string;
  family_id: string;
  label: string;
  icon: string | null;
  type: ReportButtonType;
  sort_order: number;
  is_active: boolean;
  created_by: string | null;
  created_at: string;
  updated_at: string;
}

export interface Report {
  id: string;
  family_id: string;
  button_id: string;
  user_id: string;
  created_at: string;
  cancelled_at: string | null;
}

export interface HistoryEntry {
  id: string;
  created_at: string;
  reporter_id: string;
  reporter_name: string;
  button_label: string;
  button_icon: string;
}

export interface DailyReportStatus {
  reported: boolean;
  reporter_name: string | null;
  reported_at: string | null;
}
