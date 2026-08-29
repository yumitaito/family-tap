import type { ReactNode } from 'react';
import { View } from 'react-native';
import { SafeAreaView, type Edge } from 'react-native-safe-area-context';

/** 画面の外枠。SafeArea + 背景色をまとめる。 */
export function Screen({
  children,
  edges = ['top', 'bottom'],
  className = '',
}: {
  children: ReactNode;
  edges?: Edge[];
  className?: string;
}) {
  return (
    <SafeAreaView edges={edges} className="flex-1 bg-white dark:bg-black">
      <View className={`flex-1 ${className}`}>{children}</View>
    </SafeAreaView>
  );
}
