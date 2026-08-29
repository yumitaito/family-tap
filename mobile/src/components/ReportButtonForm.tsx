import { useState } from 'react';
import { Pressable, Text, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { TextField } from '@/components/ui/TextField';
import { REPORT_BUTTON_ICONS } from '@/lib/icons';
import type { ReportButtonType } from '@/types/models';

export interface ReportButtonFormValues {
  label: string;
  icon: string;
  type: ReportButtonType;
  sortOrder: number;
}

/**
 * BUTTON-001 / BUTTON-002 共通フォーム（Swift 版 ReportButtonFormViewModel 相当）。
 * バリデーション: 空文字 / 50文字超で弾く。
 */
export function ReportButtonForm({
  initial,
  submitLabel,
  loading,
  showSortOrder = false,
  onSubmit,
  onDelete,
}: {
  initial?: Partial<ReportButtonFormValues>;
  submitLabel: string;
  loading: boolean;
  showSortOrder?: boolean;
  onSubmit: (values: ReportButtonFormValues) => void;
  onDelete?: () => void;
}) {
  const [label, setLabel] = useState(initial?.label ?? '');
  const [icon, setIcon] = useState(initial?.icon ?? REPORT_BUTTON_ICONS[0]);
  const [type, setType] = useState<ReportButtonType>(initial?.type ?? 'normal');
  const [sortOrder, setSortOrder] = useState(initial?.sortOrder ?? 0);
  const [error, setError] = useState<string | null>(null);

  function submit() {
    const trimmed = label.trim();
    if (!trimmed) return setError('ボタン名を入力してください。');
    if (trimmed.length > 50) return setError('ボタン名は50文字以内で入力してください。');
    setError(null);
    onSubmit({ label: trimmed, icon, type, sortOrder });
  }

  return (
    <View className="gap-6">
      <TextField
        label="ボタン名"
        placeholder="例）犬に朝ごはんあげた"
        value={label}
        onChangeText={setLabel}
      />

      <View>
        <Text className="mb-2 text-sm font-medium text-neutral-600 dark:text-neutral-300">
          アイコン（絵文字）
        </Text>
        <View className="flex-row flex-wrap gap-2">
          {REPORT_BUTTON_ICONS.map((emoji) => (
            <Pressable
              key={emoji}
              onPress={() => setIcon(emoji)}
              className={`h-12 w-12 items-center justify-center rounded-cell border ${
                icon === emoji
                  ? 'border-brand bg-brand/10'
                  : 'border-neutral-300 dark:border-neutral-700'
              }`}
            >
              <Text className="text-2xl">{emoji}</Text>
            </Pressable>
          ))}
        </View>
      </View>

      <View>
        <Text className="mb-2 text-sm font-medium text-neutral-600 dark:text-neutral-300">
          ボタン種別
        </Text>
        <View className="flex-row gap-2">
          {(['normal', 'daily'] as const).map((t) => (
            <Pressable
              key={t}
              onPress={() => setType(t)}
              className={`flex-1 items-center rounded-field border py-3 ${
                type === t
                  ? 'border-brand bg-brand/10'
                  : 'border-neutral-300 dark:border-neutral-700'
              }`}
            >
              <Text className="text-sm font-semibold text-black dark:text-white">
                {t === 'normal' ? '通常' : '毎日リセット'}
              </Text>
              <Text className="mt-0.5 text-xs text-neutral-500 dark:text-neutral-400">
                {t === 'normal' ? '押すたびに記録' : '今日やったかを管理'}
              </Text>
            </Pressable>
          ))}
        </View>
      </View>

      {showSortOrder && (
        <View className="flex-row items-center justify-between">
          <Text className="text-sm font-medium text-neutral-600 dark:text-neutral-300">
            表示順: {sortOrder}
          </Text>
          <View className="flex-row gap-2">
            <Pressable
              onPress={() => setSortOrder((n) => Math.max(0, n - 1))}
              className="h-9 w-9 items-center justify-center rounded-cell bg-neutral-200 dark:bg-neutral-800"
            >
              <Text className="text-lg text-black dark:text-white">−</Text>
            </Pressable>
            <Pressable
              onPress={() => setSortOrder((n) => Math.min(99, n + 1))}
              className="h-9 w-9 items-center justify-center rounded-cell bg-neutral-200 dark:bg-neutral-800"
            >
              <Text className="text-lg text-black dark:text-white">＋</Text>
            </Pressable>
          </View>
        </View>
      )}

      {error ? <Text className="text-sm text-red-500">{error}</Text> : null}

      <Button title={submitLabel} onPress={submit} loading={loading} />

      {onDelete && (
        <Button title="削除する" variant="destructive" onPress={onDelete} disabled={loading} />
      )}
    </View>
  );
}
