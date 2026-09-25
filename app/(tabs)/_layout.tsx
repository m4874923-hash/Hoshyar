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
