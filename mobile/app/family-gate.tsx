import { useRouter } from 'expo-router';
import { Text, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Screen } from '@/components/ui/Screen';

// FAMILY-001（仕様書 6/7）: サインイン済みだがまだどの家族にも所属していないとき
export default function FamilyGateScreen() {
  const router = useRouter();
  return (
    <Screen className="items-center justify-center px-6">
      <Text className="text-5xl">🏠</Text>
      <Text className="mt-6 text-center text-xl font-bold text-black dark:text-white">
        家族グループに参加しましょう
      </Text>
      <Text className="mt-2 text-center text-sm text-neutral-500 dark:text-neutral-400">
        家族を作成するか、招待コードで{'\n'}既存の家族に参加してください。
      </Text>

      <View className="mt-10 w-full gap-3">
        <Button title="家族を作る" onPress={() => router.push('/family/create')} />
        <Button
          title="家族に参加する"
          variant="secondary"
          onPress={() => router.push('/family/join')}
        />
      </View>
    </Screen>
  );
}
