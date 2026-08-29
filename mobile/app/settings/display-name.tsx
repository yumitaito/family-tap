import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useState } from 'react';
import { Text, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Screen } from '@/components/ui/Screen';
import { TextField } from '@/components/ui/TextField';
import { useAuth } from '@/context/AuthContext';
import { updateDisplayName } from '@/services/profile';

// 表示名の変更（仕様書 44）
export default function EditDisplayNameScreen() {
  const { current } = useLocalSearchParams<{ current?: string }>();
  const router = useRouter();
  const queryClient = useQueryClient();
  const { userId } = useAuth();
  const [name, setName] = useState(current ?? '');
  const [error, setError] = useState<string | null>(null);

  const mutation = useMutation({
    mutationFn: (value: string) => updateDisplayName(userId!, value),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['profile', userId] });
      router.back();
    },
    onError: () => setError('保存できませんでした。もう一度お試しください。'),
  });

  function save() {
    const trimmed = name.trim();
    if (!trimmed) return setError('表示名を入力してください。');
    setError(null);
    mutation.mutate(trimmed);
  }

  return (
    <Screen className="px-6 pt-6" edges={['bottom']}>
      <Stack.Screen options={{ title: '表示名を編集' }} />
      <TextField label="表示名" placeholder="例）お父さん" value={name} onChangeText={setName} />
      {error ? <Text className="mt-3 text-sm text-red-500">{error}</Text> : null}
      <View className="mt-6">
        <Button title="保存する" onPress={save} loading={mutation.isPending} />
      </View>
    </Screen>
  );
}
