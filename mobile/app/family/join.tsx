import { Stack, useRouter } from 'expo-router';
import { useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { Text, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Screen } from '@/components/ui/Screen';
import { TextField } from '@/components/ui/TextField';
import { useAuth } from '@/context/AuthContext';
import { familyQueryKey } from '@/context/FamilyContext';
import { InviteCodeNotFoundError, joinFamily } from '@/services/family';

// FAMILY-003（仕様書 18）
export default function JoinFamilyScreen() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { userId } = useAuth();
  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onJoin() {
    setError(null);
    const normalized = code.trim().toUpperCase();
    if (!normalized) {
      setError('招待コードを入力してください。');
      return;
    }
    setLoading(true);
    try {
      await joinFamily(normalized);
      await queryClient.invalidateQueries({ queryKey: familyQueryKey(userId) });
      router.replace('/(tabs)');
    } catch (e) {
      setError(
        e instanceof InviteCodeNotFoundError
          ? '招待コードが見つかりません。'
          : '参加できませんでした。\nもう一度お試しください。',
      );
    } finally {
      setLoading(false);
    }
  }

  return (
    <Screen className="items-center px-6 pt-10" edges={['bottom']}>
      <Stack.Screen options={{ title: '家族に参加' }} />
      <Text className="text-xl font-bold text-black dark:text-white">家族に参加する</Text>
      <Text className="mt-2 text-sm text-neutral-500 dark:text-neutral-400">
        招待コードを入力してください
      </Text>

      <TextField
        className="mt-6 w-full"
        placeholder="例）ABCD1234"
        value={code}
        onChangeText={setCode}
        autoCapitalize="characters"
        autoCorrect={false}
        style={{ textAlign: 'center', fontFamily: 'Courier', letterSpacing: 2 }}
      />

      {error ? (
        <Text className="mt-3 text-center text-sm text-red-500">{error}</Text>
      ) : null}

      <View className="mt-6 w-full">
        <Button title="参加する" onPress={onJoin} loading={loading} />
      </View>
    </Screen>
  );
}
