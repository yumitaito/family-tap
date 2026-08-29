import { ActivityIndicator, Pressable, Text, View } from 'react-native';

import { timeString } from '@/lib/japanCalendar';
import type { DailyReportStatus, ReportButton } from '@/types/models';

/**
 * HOME-001「今日の状態」の DAILY ボタン1行（仕様書 8/10/40）。
 * タップ=報告（今日報告済みなら Home 側で確認ダイアログ）、長押し=編集。
 */
export function DailyStatusCard({
  button,
  status,
  isReporting = false,
  onTap,
  onLongPress,
}: {
  button: ReportButton;
  status: DailyReportStatus | undefined;
  isReporting?: boolean;
  onTap: () => void;
  onLongPress: () => void;
}) {
  return (
    <Pressable
      onPress={() => !isReporting && onTap()}
      onLongPress={onLongPress}
      className={`flex-row items-center gap-4 rounded-card bg-neutral-100 p-4 active:opacity-70 dark:bg-neutral-900 ${
        isReporting ? 'opacity-60' : ''
      }`}
    >
      <Text className="text-3xl">{button.icon ?? '📌'}</Text>
      <View className="flex-1">
        <Text className="text-base font-semibold text-black dark:text-white">
          {button.label}
        </Text>
        {status?.reported ? (
          <Text className="mt-0.5 text-sm text-neutral-500 dark:text-neutral-400">
            ✅ {status.reported_at ? timeString(status.reported_at) : ''}{' '}
            {status.reporter_name}
          </Text>
        ) : (
          <Text className="mt-0.5 text-sm text-neutral-500 dark:text-neutral-400">
            ◯ 未報告
          </Text>
        )}
      </View>
      {isReporting ? <ActivityIndicator /> : null}
    </Pressable>
  );
}
