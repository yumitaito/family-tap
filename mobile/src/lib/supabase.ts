import AsyncStorageFallback from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'EXPO_PUBLIC_SUPABASE_URL / EXPO_PUBLIC_SUPABASE_ANON_KEY が未設定です。mobile/.env を確認してください。',
  );
}

/**
 * SecureStore はキーあたり 2KB 制限があり、Supabase のセッション JSON は
 * それを超えることがある。超えた場合は AsyncStorage にフォールバックする。
 * （トークンはいずれ短命なのと、端末ローカルなので実用上の妥協）
 */
const LargeSecureStore = {
  getItem: async (key: string) => {
    try {
      const v = await SecureStore.getItemAsync(key);
      if (v !== null) return v;
    } catch {
      // 破損時などは無視してフォールバックへ
    }
    return AsyncStorageFallback.getItem(key);
  },
  setItem: async (key: string, value: string) => {
    if (value.length <= 2000) {
      try {
        await SecureStore.setItemAsync(key, value);
        return;
      } catch {
        // フォールバックへ
      }
    }
    await AsyncStorageFallback.setItem(key, value);
  },
  removeItem: async (key: string) => {
    try {
      await SecureStore.deleteItemAsync(key);
    } catch {
      // 無視
    }
    await AsyncStorageFallback.removeItem(key);
  },
};

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: Platform.OS === 'web' ? undefined : LargeSecureStore,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
