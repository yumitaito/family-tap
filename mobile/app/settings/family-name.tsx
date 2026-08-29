import { useMutation } from '@tanstack/react-query';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useState } from 'react';
import { Text, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Screen } from '@/components/ui/Screen';
import { TextField } from '@/components/ui/TextField';
import { useFamily } from '@/context/FamilyContext';
import { NotOwnerError, updateFamilyName } from '@/services/family';

// 家族名の変更（仕様書 44）。RLS 上オーナーのみ可能。
export default function EditFamilyNameScreen() {
  const { current } = useLocalSearchParams<{ current?: string }>();
  const router = useRouter();
  const { family, refetch } = useFamily();
  const [name, setName] = useState(current ?? '');
  const [error, setError] = useState<string | null>(null);

  const mutation = useMutation({
    mutationFn: (value: string) => updateFamilyName(family!.id, value),
    onSuccess: () => {
      refetch();
      router.back();
    },
    onError: (e) =>
      setError(
        e instanceof NotOwnerError
          ? '家族名を変更できるのはオーナーだけです。'
          : '保存できませんでした。もう一度お試しください。',
      ),
  });

  function save() {
    const trimmed = name.trim();
    if (!trimmed) return setError('家族名を入力してください。');
    setError(null);
    mutation.mutate(trimmed);
  }

  return (
    <Screen className="px-6 pt-6" edges={['bottom']}>
      <Stack.Screen options={{ title: '家族名を編集' }} />
      <TextField label="家族名" placeholder="例）弓田家" value={name} onChangeText={setName} />
      {error ? <Text className="mt-3 text-sm text-red-500">{error}</Text> : null}
      <View className="mt-6">
        <Button title="保存する" onPress={save} loading={mutation.isPending} />
      </View>
    </Screen>
  );
}
