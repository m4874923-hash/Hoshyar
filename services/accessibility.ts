import { Platform } from 'react-native';
import { openSystemTarget } from './device-actions';

export type AccessibilityServiceState = 'native-build-ready' | 'expo-go-limited' | 'web-unavailable';

export function getAccessibilityServiceState(): AccessibilityServiceState {
  if (Platform.OS === 'android') return 'native-build-ready';
  if (Platform.OS === 'web') return 'web-unavailable';
  return 'expo-go-limited';
}

export async function openAccessibilitySettings(): Promise<void> {
  try {
    await openSystemTarget('accessibility');
  } catch (cause: unknown) {
    console.error('Accessibility settings could not open', cause);
    throw new Error(cause instanceof Error ? cause.message : 'Accessibility settings are unavailable.');
  }
}
