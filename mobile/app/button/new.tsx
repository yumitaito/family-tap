import { useMutation, useQueryClient } from '@tanstack/react-query';
import { Stack, useRouter } from 'expo-router';
import { ScrollView, Text } from 'react-native';

import { ReportButtonForm } from '@/components/ReportButtonForm';
import { Screen } from '@/components/ui/Screen';
import { useFamily } from '@/context/FamilyContext';
import { homeButtonsKey } from '@/hooks/useHome';
import { currentUserId } from '@/services/auth';
import { createButton } from '@/services/reportButtons';

// BUTTON-001（仕様書 13）
export default function NewButtonScreen() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const { family } = useFamily();
  const familyId = family?.id ?? '';

  const mutation = useMutation({
    mutationFn: async (v: { label: string; icon: string; type: 'normal' | 'daily' }) => {
      const userId = await currentUserId();
      return createButton({
        familyId,
        label: v.label,
        icon: v.icon,
        type: v.type,
        createdBy: userId,
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: homeButtonsKey(familyId) });
      router.back();
    },
  });

  return (
    <Screen className="px-6 pt-6" edges={['bottom']}>
      <Stack.Screen options={{ title: '新しいボタンを追加' }} />
      <ScrollView contentContainerClassName="pb-10">
        <ReportButtonForm
          submitLabel="作成する"
          loading={mutation.isPending}
          onSubmit={(v) => mutation.mutate(v)}
        />
        {mutation.isError ? (
          <Text className="mt-3 text-sm text-red-500">
            作成できませんでした。もう一度お試しください。
          </Text>
        ) : null}
      </ScrollView>
    </Screen>
  );
}
