import type { Session } from '@supabase/supabase-js';
import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';

import { supabase } from '@/lib/supabase';

/**
 * アプリ全体の認証セッション状態（Swift 版 SessionStore と 1:1）。
 * onAuthStateChange を購読するので、アプリ内のどこで signIn/signOut しても
 * ここが自動で更新される。
 */

interface AuthContextValue {
  session: Session | null;
  userId: string | null;
  isLoading: boolean;
}

const AuthContext = createContext<AuthContextValue>({
  session: null,
  userId: null,
  isLoading: true,
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setIsLoading(false);
    });

    const { data: sub } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
      setIsLoading(false);
    });

    return () => sub.subscription.unsubscribe();
  }, []);

  return (
    <AuthContext.Provider
      value={{ session, userId: session?.user.id ?? null, isLoading }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
