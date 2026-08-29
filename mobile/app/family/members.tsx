import * as Clipboard from 'expo-clipboard';
import { useQuery } from '@tanstack/react-query';
import { Stack } from 'expo-router';
import { useState } from 'react';
import { ActivityIndicator, Pressable, ScrollView, Text, View } from 'react-native';

import { Screen } from '@/components/ui/Screen';
import { useFamily } from '@/context/FamilyContext';
import { fetchMembers } from '@/services/family';

// FAMILY-004（仕様書 19）。招待コードの再確認もここ。
export default function FamilyMembersScreen() {
  const { family } = useFamily();
  const [copied, setCopied] = useState(false);

  const query = useQuery({
    queryKey: ['members', family?.id],
    queryFn: () => fetchMembers(family!.id),
    enabled: family != null,
  });

  if (!family) return null;

  return (
    <Screen edges={['bottom']}>
      <Stack.Screen options={{ title: '家族メンバー' }} />
      <ScrollView contentContainerClassName="px-6 py-4">
        <Text className="text-xs font-bold uppercase text-neutral-400">家族名</Text>
        <Text className="mt-1 text-lg text-black dark:text-white">{family.name}</Text>

        <Text className="mt-6 text-xs font-bold uppercase text-neutral-400">招待コード</Text>
        <View className="mt-2 flex-row items-center justify-between rounded-card bg-neutral-100 px-4 py-3 dark:bg-neutral-900">
          <Text className="font-mono text-lg tracking-wide text-black dark:text-white">
            {family.invite_code}
          </Text>
          <Pressable
            onPress={async () => {
              await Clipboard.setStringAsync(family.invite_code);
              setCopied(true);
            }}
          >
            <Text className="text-sm font-semibold text-brand">
              {copied ? 'コピーしました' : 'コピー'}
            </Text>
          </Pressable>
        </View>
        <Text className="mt-2 text-xs text-neutral-500 dark:text-neutral-400">
          このコードを家族に共有すると、新しいメンバーが参加できます。
        </Text>

        <Text className="mt-8 text-xs font-bold uppercase text-neutral-400">メンバー一覧</Text>
        {query.isLoading ? (
          <ActivityIndicator className="mt-4" />
        ) : query.isError ? (
          <Text className="mt-4 text-sm text-red-500">メンバーを取得できませんでした。</Text>
        ) : (
          <View className="mt-2">
            {(query.data ?? []).map((m) => (
              <View
                key={m.id}
                className="flex-row items-center justify-between border-b border-neutral-200 py-3 dark:border-neutral-800"
              >
                <Text className="text-base text-black dark:text-white">
                  {m.profile.display_name}
                </Text>
                {m.role === 'owner' ? (
                  <Text className="text-xs text-neutral-500 dark:text-neutral-400">オーナー</Text>
                ) : null}
              </View>
            ))}
          </View>
        )}
      </ScrollView>
    </Screen>
  );
}
