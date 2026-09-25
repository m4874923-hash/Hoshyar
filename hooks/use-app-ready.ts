import { useCallback, useEffect, useState } from 'react';
import { useAppStore } from '@/store/useAppStore';

export function useAppReady() {
  const [ready, setReady] = useState(useAppStore.persist.hasHydrated());
  const [error, setError] = useState<string | null>(null);

  const handleHydrationError = useCallback((cause: unknown) => {
    console.error('Hoshyar storage hydration failed', cause);
    setError(cause instanceof Error ? cause.message : 'Local storage could not be loaded.');
  }, []);

  const retry = useCallback(() => {
    setReady(false);
    setError(null);
    void Promise.resolve(useAppStore.persist.rehydrate()).catch(handleHydrationError);
  }, [handleHydrationError]);

  useEffect(() => {
    let mounted = true;
    const unsubscribe = useAppStore.persist.onFinishHydration(() => {
      if (mounted) setReady(true);
    });
    if (!useAppStore.persist.hasHydrated()) {
      retry();
    }
    return () => {
      mounted = false;
      unsubscribe();
    };
  }, [retry]);

  return { ready, error, retry };
}
