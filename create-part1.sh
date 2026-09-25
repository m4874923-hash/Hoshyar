#!/data/data/com.termux/files/usr/bin/bash
cd ~/Hoshyar

echo "📦 ساخت فایل‌های پایه..."

cat > store/types.ts << 'EOF'
export type SkillId =
  | 'messages'
  | 'calendar'
  | 'reminders'
  | 'smarthome'
  | 'notes'
  | 'system'
  | 'web'
  | 'routine';

export type TriggerType = 'manual' | 'schedule' | 'voice';
export type LogStatus = 'success' | 'pending' | 'failed' | 'warning';
export type StepStatus = 'pending' | 'executing' | 'completed' | 'failed';

export type ParameterValue =
  | string
  | number
  | boolean
  | null
  | ParameterValue[]
  | { [key: string]: ParameterValue };

export interface Preferences {
  hapticsEnabled?: boolean;
  voiceLanguage?: 'fa-IR' | 'en-US';
  speechRate?: number;
  speechPitch?: number;
}

export interface ActionStep {
  id: string;
  skill: SkillId;
  action: string;
  description: string;
  params: Record<string, string | number | boolean>;
}

export interface Routine {
  id: string;
  title: string;
  icon: string;
  color: string;
  triggerType: TriggerType;
  triggerValue: string;
  isEnabled: boolean;
  steps: ActionStep[];
  runningStep?: number;
}

export interface CommandLog {
  id: string;
  userInput: string;
  intent: string;
  skill: SkillId;
  parameters: Record<string, ParameterValue>;
  status: LogStatus;
  timestamp: number;
  executionTimeMs: number;
  summary: string;
}

export interface SkillAdapterConfig {
  id: SkillId;
  name: string;
  icon: string;
  description: string;
  accent: string;
  isAuthorized: boolean;
  sampleCommands: string[];
  capabilities: string[];
}
EOF
echo "✅ store/types.ts"

cat > constants/Theme.ts << 'EOF'
export const colors = {
  background: '#080C18',
  backgroundRaised: '#0D1424',
  card: '#161E2E',
  cardRaised: '#1B2639',
  cardMuted: '#222A3C',
  border: '#303A50',
  borderBright: '#47546D',
  text: '#F4F7FB',
  textMuted: '#98A5B9',
  textDim: '#65728B',
  cyan: '#18D7E8',
  cyanSoft: '#4D9FCE',
  violet: '#8C7CFF',
  violetSoft: '#BD6DFF',
  emerald: '#40D99B',
  amber: '#F5A742',
  red: '#FF687F',
  white: '#FFFFFF',
};

export const fonts = {
  regular: 'Inter_400Regular',
  medium: 'Inter_500Medium',
  semibold: 'Inter_600SemiBold',
  bold: 'Inter_700Bold',
};

export const radii = {
  small: 10,
  medium: 16,
  large: 22,
  pill: 999,
};
EOF
echo "✅ constants/Theme.ts"

cat > constants/Typography.ts << 'EOF'
import {
  Inter_400Regular,
  Inter_500Medium,
  Inter_600SemiBold,
  Inter_700Bold,
} from "@expo-google-fonts/inter";

export const FontMap = {
  Inter_400Regular,
  Inter_500Medium,
  Inter_600SemiBold,
  Inter_700Bold,
};

export const Fonts = {
  regular: "Inter_400Regular",
  medium: "Inter_500Medium",
  semiBold: "Inter_600SemiBold",
  bold: "Inter_700Bold",
} as const;

export type FontWeight = keyof typeof Fonts;
EOF
echo "✅ constants/Typography.ts"

cat > services/notes.ts << 'EOF'
import AsyncStorage from '@react-native-async-storage/async-storage';

const NOTES_KEY = 'hoshyar-notes';

interface StoredNote {
  id: string;
  text: string;
  createdAt: number;
}

export async function saveNote(text: string): Promise<StoredNote> {
  try {
    const existingRaw = await AsyncStorage.getItem(NOTES_KEY);
    const decoded: unknown = existingRaw ? JSON.parse(existingRaw) : [];
    const existing: StoredNote[] = Array.isArray(decoded) ? decoded.filter((item): item is StoredNote => Boolean(item) && typeof item === 'object' && typeof (item as StoredNote).id === 'string' && typeof (item as StoredNote).text === 'string' && typeof (item as StoredNote).createdAt === 'number') : [];
    const note: StoredNote = { id: `note-${Date.now()}`, text, createdAt: Date.now() };
    await AsyncStorage.setItem(NOTES_KEY, JSON.stringify([note, ...existing].slice(0, 100)));
    return note;
  } catch (cause: unknown) {
    console.error('Note could not be saved', cause);
    throw new Error(cause instanceof Error ? cause.message : 'The note could not be saved.');
  }
}
EOF
echo "✅ services/notes.ts"

cat > hooks/use-app-ready.ts << 'EOF'
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
EOF
echo "✅ hooks/use-app-ready.ts"

cat > expo-env.d.ts << 'EOF'
/// <reference types="expo/types" />
EOF
echo "✅ expo-env.d.ts"

echo ""
echo "🎉 مرحله ۱ تمام شد! ۶ فایل ساخته شد."
