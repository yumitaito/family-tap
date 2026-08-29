import { useFocusEffect, useNavigation, useRouter } from 'expo-router';
import { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Pressable,
  RefreshControl,
  ScrollView,
  Text,
  View,
} from 'react-native';

import { DailyStatusCard } from '@/components/DailyStatusCard';
import { ReportButtonCard } from '@/components/ReportButtonCard';
import { Toast, type ToastState } from '@/components/Toast';
import { Button } from '@/components/ui/Button';
import { Screen } from '@/components/ui/Screen';
import { useFamily } from '@/context/FamilyContext';
import {
  dailyStatusKey,
  homeButtonsKey,
  useDailyStatuses,
  useFamilyReportsRealtime,
  useReportButtons,
  useReportMutation,
} from '@/hooks/useHome';
import type { ReportButton } from '@/types/models';

// HOME-001（仕様書 8, 40, 47）
export default function HomeScreen() {
  const router = useRouter();
  const navigation = useNavigation();
  const { family } = useFamily();
  const familyId = family?.id ?? '';

  // ヘッダータイトルを家族名に（Swift 版の navigationTitle(familyStore.family?.name)）
  useEffect(() => {
    navigation.setOptions({ headerTitle: family?.name ?? 'Family Tap' });
  }, [navigation, family?.name]);

  const [toast, setToast] = useState<ToastState>(null);
  const buttonsQuery = useReportButtons(familyId);
  const statusesQuery = useDailyStatuses(familyId, buttonsQuery.data);
  useFamilyReportsRealtime(familyId, [
    homeButtonsKey(familyId),
    dailyStatusKey(familyId),
  ]);
  const { report, reportingIds } = useReportMutation(familyId, {
    onResult: (ok) =>
      setToast(
        ok
          ? { kind: 'success', message: '報告しました ✓' }
          : { kind: 'failure', message: '報告できませんでした。' },
      ),
  });

  const { refetch: refetchButtons } = buttonsQuery;
  const { refetch: refetchStatuses } = statusesQuery;
  useFocusEffect(
    useCallback(() => {
      refetchButtons();
      refetchStatuses();
    }, [refetchButtons, refetchStatuses]),
  );

  function onReport(button: ReportButton) {
    report(button);
  }

  function handleDailyTap(button: ReportButton) {
    const already = statusesQuery.data?.[button.id]?.reported;
    if (already) {
      Alert.alert('今日はすでに報告済みです', 'もう一度報告しますか？', [
        { text: 'キャンセル', style: 'cancel' },
        { text: '報告する', onPress: () => onReport(button) },
      ]);
    } else {
      onReport(button);
    }
  }

  const buttons = buttonsQuery.data ?? [];
  const dailyButtons = buttons.filter((b) => b.type === 'daily');
  const normalButtons = buttons.filter((b) => b.type === 'normal');

  return (
    <Screen edges={['bottom']}>
      <ScrollView
        contentContainerClassName="p-4 gap-7"
        refreshControl={
          <RefreshControl
            refreshing={buttonsQuery.isRefetching}
            onRefresh={() => {
              buttonsQuery.refetch();
              statusesQuery.refetch();
            }}
          />
        }
      >
        {buttonsQuery.isLoading ? (
          <ActivityIndicator className="mt-16" />
        ) : buttonsQuery.isError ? (
          <Text className="mt-16 text-center text-red-500">
            報告ボタンを取得できませんでした。
          </Text>
        ) : buttons.length === 0 ? (
          <View className="mt-16 items-center gap-4">
            <Text className="text-lg font-bold text-black dark:text-white">
              まだ報告ボタンがありません
            </Text>
            <Text className="text-center text-sm text-neutral-500 dark:text-neutral-400">
              家族で使う報告ボタンを{'\n'}作ってみましょう。
            </Text>
            <View className="mt-2 w-full px-6">
              <Button
                title="＋ 最初のボタンを作る"
                onPress={() => router.push('/button/new')}
              />
            </View>
          </View>
        ) : (
          <>
            {dailyButtons.length > 0 && (
              <View className="gap-3">
                <Text className="text-base font-bold text-black dark:text-white">
                  今日の状態
                </Text>
                {dailyButtons.map((b) => (
                  <DailyStatusCard
                    key={b.id}
                    button={b}
                    status={statusesQuery.data?.[b.id]}
                    isReporting={reportingIds.has(b.id)}
                    onTap={() => handleDailyTap(b)}
                    onLongPress={() => router.push(`/button/${b.id}`)}
                  />
                ))}
              </View>
            )}

            <View className="gap-3">
              <Text className="text-base font-bold text-black dark:text-white">
                報告する
              </Text>
              <View className="flex-row flex-wrap gap-3">
                {normalButtons.map((b) => (
                  <View key={b.id} className="w-[47%]">
                    <ReportButtonCard
                      button={b}
                      isReporting={reportingIds.has(b.id)}
                      onTap={() => onReport(b)}
                      onLongPress={() => router.push(`/button/${b.id}`)}
                    />
                  </View>
                ))}
                <Pressable
                  onPress={() => router.push('/button/new')}
                  className="min-h-[96px] w-[47%] items-center justify-center rounded-card border border-dashed border-neutral-300 dark:border-neutral-700"
                >
                  <Text className="text-2xl text-neutral-400">＋</Text>
                  <Text className="mt-1 text-xs text-neutral-400">ボタンを追加</Text>
                </Pressable>
              </View>
            </View>
          </>
        )}
      </ScrollView>

      <Toast state={toast} onDismiss={() => setToast(null)} />
    </Screen>
  );
}
