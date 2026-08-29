import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'expo-router';
import { ActivityIndicator, Pressable, ScrollView, Text, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Screen } from '@/components/ui/Screen';
import { useAuth } from '@/context/AuthContext';
import { useFamily } from '@/context/FamilyContext';
import { signOut } from '@/services/auth';
import { fetchProfile } from '@/services/profile';

function Row({
  label,
  value,
  onPress,
}: {
  label: string;
  value?: string;
  onPress?: () => void;
}) {
  return (
    <Pressable
      onPress={onPress}
      disabled={!onPress}
      className="flex-row items-center justify-between border-b border-neutral-200 py-4 active:opacity-60 dark:border-neutral-800"
    >
      <Text className="text-base text-black dark:text-white">{label}</Text>
      <View className="flex-row items-center gap-2">
        {value ? (
          <Text className="text-base text-neutral-500 dark:text-neutral-400">{value}</Text>
        ) : null}
        {onPress ? <Text className="text-neutral-400">›</Text> : null}
      </View>
    </Pressable>
  );
}

// SETTINGS-001（仕様書 44）
export default function SettingsScreen() {
  const router = useRouter();
  const { userId } = useAuth();
  const { family } = useFamily();

  const profileQuery = useQuery({
    queryKey: ['profile', userId],
    queryFn: () => fetchProfile(userId!),
    enabled: userId != null,
  });

  return (
    <Screen edges={['bottom']}>
      <ScrollView contentContainerClassName="px-6 py-2">
        <Text className="mt-4 mb-1 text-xs font-bold uppercase text-neutral-400">
          プロフィール
        </Text>
        <Row
          label="表示名"
          value={profileQuery.data?.display_name ?? '-'}
          onPress={() =>
            router.push({
              pathname: '/settings/display-name',
              params: { current: profileQuery.data?.display_name ?? '' },
            })
          }
        />

        <Text className="mt-6 mb-1 text-xs font-bold uppercase text-neutral-400">
          家族
        </Text>
        <Row
          label="家族"
          value={family?.name ?? '-'}
          onPress={
            family
              ? () =>
                  router.push({
                    pathname: '/settings/family-name',
                    params: { current: family.name },
                  })
              : undefined
          }
        />
        {family ? (
          <Row label="家族メンバー" onPress={() => router.push('/family/members')} />
        ) : null}

        <View className="mt-12">
          {profileQuery.isLoading ? <ActivityIndicator /> : null}
          <Button
            title="ログアウト"
            variant="destructive"
            onPress={() => signOut()}
          />
        </View>
      </ScrollView>
    </Screen>
  );
}
