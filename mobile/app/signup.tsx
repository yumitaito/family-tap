import { useRouter } from 'expo-router';
import { useState } from 'react';
import { Alert, Text, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Screen } from '@/components/ui/Screen';
import { TextField } from '@/components/ui/TextField';
import { signUp } from '@/services/auth';

// AUTH-002（仕様書 7, 20, 21）。表示名は profiles.display_name NOT NULL なので先に集める。
export default function SignUpScreen() {
  const router = useRouter();
  const [displayName, setDisplayName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function onSubmit() {
    setError(null);
    if (!email.trim() || !password) {
      setError('メールアドレスとパスワードを入力してください。');
      return;
    }
    if (!displayName.trim()) {
      setError('表示名を入力してください。');
      return;
    }
    setLoading(true);
    try {
      const hasSession = await signUp(email.trim(), password, displayName.trim());
      if (!hasSession) {
        Alert.alert(
          '確認メールを送信しました',
          'メール内のリンクを開いて登録を完了してから、ログインしてください。',
          [{ text: 'OK', onPress: () => router.back() }],
        );
      }
      // セッションが即座に返った場合は AuthGate が自動でメイン画面へ
    } catch {
      setError('登録できませんでした。\n時間をおいてもう一度お試しください。');
    } finally {
      setLoading(false);
    }
  }

  return (
    <Screen className="px-6 pt-6" edges={['bottom']}>
      <View className="gap-4">
        <TextField
          label="表示名"
          placeholder="例）お父さん"
          value={displayName}
          onChangeText={setDisplayName}
          autoCapitalize="none"
        />
        <TextField
          label="メールアドレス"
          placeholder="you@example.com"
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          autoCorrect={false}
          textContentType="username"
        />
        <TextField
          label="パスワード（6文字以上）"
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          textContentType="newPassword"
        />
      </View>

      {error ? (
        <Text className="mt-3 text-sm text-red-500">{error}</Text>
      ) : null}

      <View className="mt-6">
        <Button title="登録する" onPress={onSubmit} loading={loading} />
      </View>
    </Screen>
  );
}
