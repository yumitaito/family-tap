import * as Device from 'expo-device';
import * as Notifications from 'expo-notifications';

import { supabase } from '@/lib/supabase';

/**
 * Push 通知（仕様書 28/35）。
 *
 * ⚠️ 移行中: Swift 版は APNs に直接叩く Edge Function を使っていたが、
 * Expo 版では Expo Push API 経由に切り替える予定。
 *  - registerForPushNotifications(): Expo push token を取得し device_tokens に保存
 *  - notifyFamily(): Edge Function `send-family-notification` を呼ぶ（要書き換え）
 *
 * 現状は token 登録まで実装。Edge Function 側の Expo 対応は別タスク（PROGRESS.md 参照）。
 */

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
});

/** 通知許可を要求し、Expo push token を device_tokens に upsert する。 */
export async function registerForPushNotifications(userId: string): Promise<void> {
  if (!Device.isDevice) return; // シミュレータ/エミュレータでは取得不可

  const { status: existing } = await Notifications.getPermissionsAsync();
  let status = existing;
  if (status !== 'granted') {
    status = (await Notifications.requestPermissionsAsync()).status;
  }
  if (status !== 'granted') return;

  const projectId =
    // app.json の extra.eas.projectId（EAS 設定後に入る）
    (await import('expo-constants')).default.expoConfig?.extra?.eas?.projectId;

  const token = (
    await Notifications.getExpoPushTokenAsync(projectId ? { projectId } : undefined)
  ).data;

  await supabase
    .from('device_tokens')
    .upsert(
      { user_id: userId, token, platform: 'expo' },
      { onConflict: 'token' },
    );
}

/**
 * 報告成功後に家族へ通知（fire-and-forget）。
 * TODO: Edge Function を Expo Push API 対応に書き換えるまではダミー。
 */
export async function notifyFamily(reportId: string): Promise<void> {
  try {
    await supabase.functions.invoke('send-family-notification', {
      body: { report_id: reportId },
    });
  } catch {
    // 通知失敗は握りつぶす（報告自体は成功しているため）
  }
}
