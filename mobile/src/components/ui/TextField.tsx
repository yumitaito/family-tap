import { Text, TextInput, View, type TextInputProps } from 'react-native';

export function TextField({
  label,
  className = '',
  ...props
}: TextInputProps & { label?: string }) {
  return (
    <View className={className}>
      {label ? (
        <Text className="mb-1.5 text-sm font-medium text-neutral-600 dark:text-neutral-300">
          {label}
        </Text>
      ) : null}
      <TextInput
        placeholderTextColor="#9ca3af"
        className="h-12 rounded-field border border-neutral-300 bg-white px-3 text-base text-black dark:border-neutral-700 dark:bg-neutral-900 dark:text-white"
        {...props}
      />
    </View>
  );
}
