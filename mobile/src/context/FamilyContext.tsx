import { useQuery } from '@tanstack/react-query';
import { createContext, useContext, type ReactNode } from 'react';

import { useAuth } from '@/context/AuthContext';
import { fetchCurrentFamily } from '@/services/family';
import type { Family } from '@/types/models';

/**
 * サインイン中ユーザーの「今の家族」状態（Swift 版 FamilyStore と 1:1）。
 * 家族の作成・参加後は queryClient.invalidateQueries(['family']) で更新する。
 */

interface FamilyContextValue {
  family: Family | null;
  isLoading: boolean;
  refetch: () => void;
}

const FamilyContext = createContext<FamilyContextValue>({
  family: null,
  isLoading: true,
  refetch: () => {},
});

export const familyQueryKey = (userId: string | null) => ['family', userId];

export function FamilyProvider({ children }: { children: ReactNode }) {
  const { userId } = useAuth();

  const { data, isLoading, refetch } = useQuery({
    queryKey: familyQueryKey(userId),
    queryFn: () => fetchCurrentFamily(userId!),
    enabled: userId != null,
  });

  return (
    <FamilyContext.Provider
      value={{
        family: data ?? null,
        isLoading: userId != null && isLoading,
        refetch,
      }}
    >
      {children}
    </FamilyContext.Provider>
  );
}

export function useFamily() {
  return useContext(FamilyContext);
}
