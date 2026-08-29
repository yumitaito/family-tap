import { Link } from 'expo-router';
import { useState } from 'react';
import { Text, View } from 'react-native';

import { Button } from '@/components/ui/Button';
import { Screen } from '@/components/ui/Screen';
import { TextField } from '@/components/ui/TextField';
import { signIn } from '@/services/auth';

// AUTH-001（仕様書 7, 21）
export default function LoginScreen() {
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
    setLoading(true);
    try {
      await signIn(email.trim(), password);
      // 成功すると onAuthStateChange → AuthGate が自動で画面を切り替える
    } catch {
      setError('ログインできませんでした。\nメールアドレスとパスワードをご確認ください。');
    } finally {
      setLoading(false);
    }
  }

  return (
    <Screen className="justify-center px-6">
      <View className="mb-8 items-center">
        <Text className="text-3xl font-bold text-black dark:text-white">Family Tap</Text>
        <Text className="mt-1 text-neutral-500 dark:text-neutral-400">
          家族にワンタップで報告しよう
        </Text>
      </View>

      <View className="gap-3">
        <TextField
          placeholder="メールアドレス"
          value={email}
          onChangeText={setEmail}
          keyboardType="email-address"
          autoCapitalize="none"
          autoCorrect={false}
          textContentType="username"
        />
        <TextField
          placeholder="パスワード"
          value={password}
          onChangeText={setPassword}
          secureTextEntry
          textContentType="password"
        />
      </View>

      {error ? (
        <Text className="mt-3 text-center text-sm text-red-500">{error}</Text>
      ) : null}

      <View className="mt-5">
        <Button title="ログイン" onPress={onSubmit} loading={loading} />
      </View>

      <Link href="/signup" className="mt-6 text-center text-sm text-brand">
        アカウントをお持ちでない方はこちら
      </Link>
    </Screen>
  );
}
