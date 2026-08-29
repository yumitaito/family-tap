import { ActivityIndicator, Pressable, Text, View } from 'react-native';

import type { ReportButton } from '@/types/models';

/**
 * HOME-001 グリッドの1カード（仕様書 8/40）。
 * タップ=報告（仕様書 11）、長押し=編集（BUTTON-002）。
 */
export function ReportButtonCard({
  button,
  isReporting = false,
  onTap,
  onLongPress,
}: {
  button: ReportButton;
  isReporting?: boolean;
  onTap: () => void;
  onLongPress: () => void;
}) {
  return (
    <Pressable
      onPress={() => !isReporting && onTap()}
      onLongPress={onLongPress}
      className={`min-h-[96px] flex-1 items-center justify-center rounded-card bg-neutral-100 p-4 active:opacity-70 dark:bg-neutral-900 ${
        isReporting ? 'opacity-60' : ''
      }`}
    >
      <View className="items-center gap-2">
        {isReporting ? (
          <ActivityIndicator />
        ) : (
          <Text className="text-3xl">{button.icon ?? '📌'}</Text>
        )}
        <Text
          numberOfLines={2}
          className="text-center text-sm font-semibold text-black dark:text-white"
        >
          {button.label}
        </Text>
      </View>
    </Pressable>
  );
}
