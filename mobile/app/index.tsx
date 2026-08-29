import { ActivityIndicator, View } from 'react-native';

// ルート。AuthGate（app/_layout.tsx）が状態に応じて即座にリダイレクトするので、
// ここは一瞬だけ表示されるローディング画面。
export default function Index() {
  return (
    <View className="flex-1 items-center justify-center bg-white dark:bg-black">
      <ActivityIndicator />
    </View>
  );
}
