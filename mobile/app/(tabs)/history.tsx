import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useMemo } from 'react';
import { ActivityIndicator, Alert, Pressable, SectionList, Text, View } from 'react-native';

import { Screen } from '@/components/ui/Screen';
import { useAuth } from '@/context/AuthContext';
import { useFamily } from '@/context/FamilyContext';
import { useFamilyReportsRealtime } from '@/hooks/useHome';
import { dayLabel, timeString } from '@/lib/japanCalendar';
import { cancelReport, fetchHistory } from '@/services/reports';
import type { HistoryEntry } from '@/types/models';

export const historyKey = (familyId: string) => ['history', familyId];

// HISTORY-001（仕様書 15, 47）
export default function HistoryScreen() {
  const { userId } = useAuth();
  const { family } = useFamily();
  const familyId = family?.id ?? '';
  const queryClient = useQueryClient();

  const query = useQuery({
    queryKey: historyKey(familyId),
    queryFn: () => fetchHistory(familyId),
  });

  useFamilyReportsRealtime(familyId, [historyKey(familyId)]);

  const cancel = useMutation({
    mutationFn: (id: string) => cancelReport(id),
    onSuccess: () =>
      queryClient.invalidateQueries({ queryKey: historyKey(familyId) }),
  });

  const sections = useMemo(() => {
    const entries = query.data ?? [];
    const out: { title: string; data: HistoryEntry[] }[] = [];
    for (const e of entries) {
      const label = dayLabel(e.created_at);
      const last = out[out.length - 1];
      if (last && last.title === label) last.data.push(e);
      else out.push({ title: label, data: [e] });
    }
    return out;
  }, [query.data]);

  function onLongPress(entry: HistoryEntry) {
    if (entry.reporter_id !== userId) return; // 自分の報告だけ取り消せる
    Alert.alert('この報告を取り消しますか？', undefined, [
      { text: 'キャンセル', style: 'cancel' },
      { text: '取り消す', style: 'destructive', onPress: () => cancel.mutate(entry.id) },
    ]);
  }

  if (query.isLoading) {
    return (
      <Screen className="items-center justify-center">
        <ActivityIndicator />
      </Screen>
    );
  }

  if ((query.data ?? []).length === 0) {
    return (
      <Screen className="items-center justify-center">
        <Text className="text-neutral-500 dark:text-neutral-400">
          まだ報告はありません
        </Text>
      </Screen>
    );
  }

  return (
    <Screen edges={['bottom']}>
      <SectionList
        sections={sections}
        keyExtractor={(item) => item.id}
        contentContainerClassName="px-4 pb-8"
        refreshing={query.isRefetching}
        onRefresh={() => query.refetch()}
        renderSectionHeader={({ section }) => (
          <Text className="bg-white py-2 text-sm font-bold text-neutral-500 dark:bg-black dark:text-neutral-400">
            {section.title}
          </Text>
        )}
        renderItem={({ item }) => (
          <Pressable
            onLongPress={() => onLongPress(item)}
            className="flex-row items-center gap-3 py-3 active:opacity-60"
          >
            <Text className="text-2xl">{item.button_icon ?? '📌'}</Text>
            <View className="flex-1">
              <Text className="text-base text-black dark:text-white">
                {item.button_label}
              </Text>
              <Text className="text-xs text-neutral-500 dark:text-neutral-400">
                {item.reporter_name}
              </Text>
            </View>
            <Text className="text-sm text-neutral-500 dark:text-neutral-400">
              {timeString(item.created_at)}
            </Text>
          </Pressable>
        )}
      />
    </Screen>
  );
}
