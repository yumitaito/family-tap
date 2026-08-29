import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { ActivityIndicator, Alert, ScrollView, Text } from 'react-native';

import { ReportButtonForm } from '@/components/ReportButtonForm';
import { Screen } from '@/components/ui/Screen';
import { useFamily } from '@/context/FamilyContext';
import { homeButtonsKey, useReportButtons } from '@/hooks/useHome';
import { deleteButton, updateButton } from '@/services/reportButtons';

// BUTTON-002（仕様書 14）。Home のカード長押しで開く。
export default function EditButtonScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const queryClient = useQueryClient();
  const { family } = useFamily();
  const familyId = family?.id ?? '';

  const buttonsQuery = useReportButtons(familyId);
  const button = buttonsQuery.data?.find((b) => b.id === id);

  const invalidate = () =>
    queryClient.invalidateQueries({ queryKey: homeButtonsKey(familyId) });

  const save = useMutation({
    mutationFn: (v: {
      label: string;
      icon: string;
      type: 'normal' | 'daily';
      sortOrder: number;
    }) =>
      updateButton({
        id: id!,
        label: v.label,
        icon: v.icon,
        type: v.type,
        sortOrder: v.sortOrder,
      }),
    onSuccess: () => {
      invalidate();
      router.back();
    },
  });

  const remove = useMutation({
    mutationFn: () => deleteButton(id!),
    onSuccess: () => {
      invalidate();
      router.back();
    },
  });

  if (buttonsQuery.isLoading) {
    return (
      <Screen className="items-center justify-center">
        <ActivityIndicator />
      </Screen>
    );
  }

  if (!button) {
    return (
      <Screen className="items-center justify-center px-6">
        <Text className="text-neutral-500">ボタンが見つかりませんでした。</Text>
      </Screen>
    );
  }

  return (
    <Screen className="px-6 pt-6" edges={['bottom']}>
      <Stack.Screen options={{ title: 'ボタンを編集' }} />
      <ScrollView contentContainerClassName="pb-10">
        <ReportButtonForm
          initial={{
            label: button.label,
            icon: button.icon ?? undefined,
            type: button.type,
            sortOrder: button.sort_order,
          }}
          submitLabel="保存する"
          loading={save.isPending || remove.isPending}
          showSortOrder
          onSubmit={(v) => save.mutate(v)}
          onDelete={() =>
            Alert.alert('このボタンを削除しますか？', undefined, [
              { text: 'キャンセル', style: 'cancel' },
              {
                text: '削除する',
                style: 'destructive',
                onPress: () => remove.mutate(),
              },
            ])
          }
        />
        {(save.isError || remove.isError) && (
          <Text className="mt-3 text-sm text-red-500">
            処理できませんでした。もう一度お試しください。
          </Text>
        )}
      </ScrollView>
    </Screen>
  );
}
