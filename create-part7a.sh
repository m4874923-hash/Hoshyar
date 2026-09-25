#!/data/data/com.termux/files/usr/bin/bash
cd ~/Hoshyar

echo "📦 مرحله ۷a: app layouts + index..."

cat > app/_layout.tsx << 'EOF'
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
EOF
echo "✅ app/_layout.tsx"

cat > app/index.tsx << 'EOF'
import { Redirect } from 'expo-router';

export default function Index() {
  return <Redirect href="/(tabs)" />;
}
EOF
echo "✅ app/index.tsx"

mkdir -p app/\(tabs\)

cat > app/\(tabs\)/_layout.tsx << 'EOF'
import { Tabs } from 'expo-router';
import { StyleSheet, View } from 'react-native';
import { NexusTabBar } from '@/components/nexus-ui';
import { colors } from '@/constants/Theme';

export default function TabsLayout() {
  return (
    <View testID="tab-navigator" style={styles.navigator}>
      <Tabs tabBar={(props) => <NexusTabBar {...props} />} screenOptions={{ headerShown: false, sceneStyle: { backgroundColor: colors.background } }}>
        <Tabs.Screen name="index" options={{ title: 'Assistant' }} />
        <Tabs.Screen name="routines" options={{ title: 'Routines' }} />
        <Tabs.Screen name="skills" options={{ title: 'Skills' }} />
        <Tabs.Screen name="activity" options={{ title: 'Activity' }} />
      </Tabs>
    </View>
  );
}

const styles = StyleSheet.create({
  navigator: { flex: 1 },
});
EOF
echo "✅ app/(tabs)/_layout.tsx"

echo ""
echo "🎉 مرحله ۷a تمام شد! ۳ فایل ساخته شد."
