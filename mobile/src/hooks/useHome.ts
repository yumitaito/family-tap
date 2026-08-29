import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { useCallback, useEffect, useRef, useState } from 'react';

import { todayRange } from '@/lib/japanCalendar';
import { currentUserId } from '@/services/auth';
import { subscribeToFamilyReports } from '@/services/realtime';
import { fetchActiveButtons } from '@/services/reportButtons';
import { createReport, fetchTodayReports } from '@/services/reports';
import { notifyFamily } from '@/services/push';
import type { DailyReportStatus, ReportButton } from '@/types/models';

export const homeButtonsKey = (familyId: string) => ['reportButtons', familyId];
export const dailyStatusKey = (familyId: string) => ['dailyStatus', familyId];

/**
 * reports の Realtime 変更で、渡された queryKey 群を再取得させる（仕様書 36）。
 * ホーム・履歴の両方から使う。
 */
export function useFamilyReportsRealtime(familyId: string, keys: unknown[][]) {
  const queryClient = useQueryClient();
  useEffect(() => {
    if (!familyId) return;
    const unsubscribe = subscribeToFamilyReports(familyId, () => {
      for (const key of keys) {
        queryClient.invalidateQueries({ queryKey: key });
      }
    });
    return unsubscribe;
    // keys は呼び出し側でリテラル配列を渡す前提（毎回同一内容）
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [familyId, queryClient]);
}

export function useReportButtons(familyId: string) {
  return useQuery({
    queryKey: homeButtonsKey(familyId),
    queryFn: () => fetchActiveButtons(familyId),
  });
}

/** DAILY ボタンの「今日（JST）」の報告状況。button_id → status。 */
export function useDailyStatuses(familyId: string, buttons: ReportButton[] | undefined) {
  const dailyIds = (buttons ?? []).filter((b) => b.type === 'daily').map((b) => b.id);
  return useQuery({
    queryKey: [...dailyStatusKey(familyId), dailyIds.sort().join(',')],
    enabled: dailyIds.length > 0,
    queryFn: async (): Promise<Record<string, DailyReportStatus>> => {
      const rows = await fetchTodayReports({
        familyId,
        buttonIds: dailyIds,
        range: todayRange(),
      });
      const out: Record<string, DailyReportStatus> = {};
      for (const r of rows) {
        // rows は古い順なので、各 button_id 最初の1件が「今日最初に報告した人」
        if (!out[r.button_id]) {
          out[r.button_id] = {
            reported: true,
            reporter_name: r.reporter_name,
            reported_at: r.created_at,
          };
        }
      }
      return out;
    },
  });
}

/**
 * タップ→報告（仕様書 11）。連打対策として、報告中のボタン id を保持し
 * 最低 1.5 秒は disabled にする（ネットワーク待ちと並行）。
 */
export function useReportMutation(
  familyId: string,
  opts?: { onResult?: (ok: boolean) => void },
) {
  const queryClient = useQueryClient();
  const [reportingIds, setReportingIds] = useState<Set<string>>(new Set());
  const timers = useRef<Record<string, ReturnType<typeof setTimeout>>>({});

  const mutation = useMutation({
    mutationFn: async (button: ReportButton) => {
      const userId = await currentUserId();
      const report = await createReport({ familyId, buttonId: button.id, userId });
      // fire-and-forget（仕様書 11 step6）: push 失敗を報告失敗にしない
      notifyFamily(report.id).catch(() => {});
      return { button, report };
    },
    onSuccess: ({ button }) => {
      if (button.type === 'daily') {
        queryClient.invalidateQueries({ queryKey: dailyStatusKey(familyId) });
      }
      opts?.onResult?.(true);
    },
    onError: () => opts?.onResult?.(false),
  });

  const report = useCallback(
    (button: ReportButton) => {
      if (reportingIds.has(button.id)) return;
      setReportingIds((s) => new Set(s).add(button.id));
      timers.current[button.id] = setTimeout(() => {
        setReportingIds((s) => {
          const next = new Set(s);
          next.delete(button.id);
          return next;
        });
      }, 1500);
      mutation.mutate(button);
    },
    [reportingIds, mutation],
  );

  return { report, reportingIds, isError: mutation.isError, reset: mutation.reset };
}
