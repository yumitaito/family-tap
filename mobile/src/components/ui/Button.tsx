import { ActivityIndicator, Pressable, Text } from 'react-native';

type Variant = 'primary' | 'secondary' | 'destructive';

/** アプリ共通ボタン。UI をいじるときはここ1箇所で全画面に効く。 */
export function Button({
  title,
  onPress,
  variant = 'primary',
  loading = false,
  disabled = false,
}: {
  title: string;
  onPress: () => void;
  variant?: Variant;
  loading?: boolean;
  disabled?: boolean;
}) {
  const isDisabled = disabled || loading;

  const base =
    'h-12 rounded-field items-center justify-center flex-row px-4';
  const byVariant: Record<Variant, string> = {
    primary: 'bg-brand',
    secondary: 'bg-neutral-200 dark:bg-neutral-800',
    destructive: 'bg-red-500',
  };
  const textByVariant: Record<Variant, string> = {
    primary: 'text-brand-fg',
    secondary: 'text-black dark:text-white',
    destructive: 'text-white',
  };

  return (
    <Pressable
      onPress={onPress}
      disabled={isDisabled}
      className={`${base} ${byVariant[variant]} ${isDisabled ? 'opacity-40' : 'active:opacity-80'}`}
    >
      {loading ? (
        <ActivityIndicator color={variant === 'secondary' ? undefined : '#fff'} />
      ) : (
        <Text className={`text-base font-semibold ${textByVariant[variant]}`}>
          {title}
        </Text>
      )}
    </Pressable>
  );
}
