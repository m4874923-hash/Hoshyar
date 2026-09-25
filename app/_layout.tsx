import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useFonts } from 'expo-font';
import * as SplashScreen from 'expo-splash-screen';
import { useEffect } from 'react';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { FontMap } from '@/constants/Typography';

void SplashScreen.preventAutoHideAsync().catch((cause: unknown) => console.error('Splash screen could not initialize', cause));

export default function RootLayout() {
  const [loaded, error] = useFonts(FontMap);

  useEffect(() => {
    if (loaded || error) {
      void SplashScreen.hideAsync().catch((cause: unknown) => console.error('Splash screen could not hide', cause));
    }
  }, [loaded, error]);

  if (!loaded && !error) return null;

  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: '#080C18' } }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="(tabs)" />
        <Stack.Screen name="routine-builder" options={{ presentation: 'modal' }} />
        <Stack.Screen name="command-detail" options={{ presentation: 'modal' }} />
        <Stack.Screen name="voice" options={{ presentation: 'formSheet', sheetAllowedDetents: [0.86, 1], sheetGrabberVisible: true }} />
        <Stack.Screen name="contacts" options={{ presentation: 'modal' }} />
      </Stack>
    </SafeAreaProvider>
  );
}
