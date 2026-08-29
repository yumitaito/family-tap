import * as Clipboard from 'expo-clipboard';
import { useRouter, Stack } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { Text, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Screen } from '@/components/ui/Screen';
import { TextField } from '@/components/ui/TextField';
import { useAuth } from '@/context/AuthContext';
import { familyQueryKey } from '@/context/FamilyContext';
import { createFamily } from '@/services/family';
import type { Family } from '@/types/models';

// FAMILY-002（仕様書 17）
export default function CreateFamilyScreen() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { userId } = useAuth();
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [created, setCreated] = useState<Family | null>(null);
  const [copied, setCopied] = useState(false);

  async function onCreate() {
    setError(null);
    if (!name.trim()) {
      setError('家族名を入力してください。');
      return;
    }
    setLoading(true);
    try {
      setCreated(await createFamily(name.trim()));
    } catch {
      setError('家族を作成できませんでした。\nもう一度お試しください。');
    } finally {
      setLoading(false);
    }
  }

  async function finish() {
    // FamilyContext を再取得 → メイン画面へ
    await queryClient.invalidateQueries({ queryKey: familyQueryKey(userId) });
    router.replace('/(tabs)');
  }

  if (created) {
    return (
      <Screen className="items-center justify-center px-6">
        <Stack.Screen options={{ headerBackVisible: false, title: '' }} />
        <Text className="text-5xl">🎉</Text>
        <Text className="mt-4 text-center text-xl font-bold text-black dark:text-white">
          {created.name} を作成しました！
        </Text>
        <Text className="mt-2 text-center text-sm text-neutral-500 dark:text-neutral-400">
          この招待コードを家族に共有して{'\n'}参加してもらいましょう。
        </Text>

        <View className="mt-6 w-full items-center rounded-card bg-neutral-100 py-6 dark:bg-neutral-900">
          <Text className="text-xs text-neutral-500 dark:text-neutral-400">招待コード</Text>
          <Text className="mt-1 font-mono text-3xl font-bold tracking-widest text-black dark:text-white">
            {created.invite_code}
          </Text>
        </View>

        <View className="mt-4 w-full">
          <Button
            title={copied ? 'コピーしました ✓' : 'コードをコピー'}
            variant="secondary"
            onPress={async () => {
              await Clipboard.setStringAsync(created.invite_code);
              setCopied(true);
            }}
          />
        </View>

        <View className="mt-8 w-full">
          <Button title="完了" onPress={finish} />
        </View>
      </Screen>
    );
  }

  return (
    <Screen className="px-6 pt-6" edges={['bottom']}>
      <Stack.Screen options={{ title: '家族を作成' }} />
      <TextField
        label="家族名"
        placeholder="例）弓田家"
        value={name}
        onChangeText={setName}
      />
      {error ? <Text className="mt-3 text-sm text-red-500">{error}</Text> : null}
      <View className="mt-6">
        <Button title="作成する" onPress={onCreate} loading={loading} />
      </View>
    </Screen>
  );
}
