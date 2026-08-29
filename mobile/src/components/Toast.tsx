import { useEffect } from 'react';
import { Text, View } from 'react-native';

export type ToastState = { kind: 'success' | 'failure'; message: string } | null;

/** 「報告しました ✓」/「報告できませんでした。」の一時表示（2秒で自動非表示）。 */
export function Toast({
  state,
  onDismiss,
}: {
  state: ToastState;
  onDismiss: () => void;
}) {
  useEffect(() => {
    if (!state) return;
    const t = setTimeout(onDismiss, 2000);
    return () => clearTimeout(t);
  }, [state, onDismiss]);

  if (!state) return null;

  return (
    <View className="absolute inset-x-0 bottom-6 items-center">
      <View
        className={`rounded-full px-5 py-3 ${
          state.kind === 'success' ? 'bg-neutral-800' : 'bg-red-600'
        }`}
      >
        <Text className="text-sm font-semibold text-white">{state.message}</Text>
      </View>
    </View>
  );
}
