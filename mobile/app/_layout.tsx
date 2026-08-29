import '../global.css';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Stack, useRouter, useSegments } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect } from 'react';
import { ActivityIndicator, View } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { AuthProvider, useAuth } from '@/context/AuthContext';
import { FamilyProvider, useFamily } from '@/context/FamilyContext';

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: 1, staleTime: 30_000 } },
});

/**
 * 認証 / 家族参加の状態に応じて行き先を強制する（Swift 版 RootView の分岐）。
 *  - 未ログイン           → /login
 *  - ログイン済み・未参加  → /family-gate
 *  - ログイン済み・参加済み → /(tabs)
 */
function AuthGate() {
  const { session, isLoading: authLoading } = useAuth();
  const { family, isLoading: familyLoading } = useFamily();
  const segments = useSegments();
  const router = useRouter();

  const ready = !authLoading && (!session || !familyLoading);

  useEffect(() => {
    if (!ready) return;

    const group = segments[0] as string | undefined;
    // '(tabs)' | 'login' | 'signup' | 'family-gate' | 'family' | 'button' | 'settings' | undefined(=ルート)
    const inAuth = group === 'login' || group === 'signup';
    const inGate = group === 'family-gate';
    // ログイン済み・家族参加済みで居てよい場所
    const inApp =
      group === '(tabs)' || group === 'button' || group === 'settings';

    if (!session) {
      if (!inAuth) router.replace('/login');
      return;
    }
    if (!family) {
      // 家族未参加中は family-gate と family/create・family/join のみ許可
      if (!inGate && group !== 'family') router.replace('/family-gate');
      return;
    }
    // 家族参加済み: 認証画面・ゲート・ルートに居たらメインへ
    if (!inApp && group !== 'family') router.replace('/(tabs)');
  }, [ready, session, family, segments, router]);

  if (!ready) {
    return (
      <View className="flex-1 items-center justify-center bg-white dark:bg-black">
        <ActivityIndicator />
      </View>
    );
  }

  return (
    <Stack screenOptions={{ headerBackTitle: '戻る' }}>
      <Stack.Screen name="index" options={{ headerShown: false }} />
      <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
      <Stack.Screen name="login" options={{ headerShown: false }} />
      <Stack.Screen name="signup" options={{ title: '新規登録' }} />
      <Stack.Screen name="family-gate" options={{ headerShown: false }} />
    </Stack>
  );
}

export default function RootLayout() {
  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <AuthProvider>
            <FamilyProvider>
              <StatusBar style="auto" />
              <AuthGate />
            </FamilyProvider>
          </AuthProvider>
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}
