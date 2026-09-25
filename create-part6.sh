#!/data/data/com.termux/files/usr/bin/bash
cd ~/Hoshyar

echo "📦 مرحله ۶: components..."

cat > components/screen-state.tsx << 'EOF'
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { colors, fonts } from '@/constants/Theme';
import { PrimaryButton } from './nexus-ui';

export function LoadingState({ label = 'Syncing local workspace' }: { label?: string }) {
  return (
    <View style={styles.container}>
      <ActivityIndicator color={colors.cyan} size="large" />
      <Text style={styles.label}>{label}</Text>
    </View>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <View style={styles.container}>
      <Text style={styles.errorTitle}>Workspace unavailable</Text>
      <Text selectable style={styles.errorMessage}>{message}</Text>
      <PrimaryButton label="Try again" icon="refresh-outline" onPress={onRetry} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 12, padding: 28, backgroundColor: colors.background },
  label: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 13 },
  errorTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 18 },
  errorMessage: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 13, textAlign: 'center', lineHeight: 20 },
});
EOF
echo "✅ components/screen-state.tsx"

cat > components/nexus-ui.tsx << 'EOF'
import { Ionicons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import { useEffect } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import type { BottomTabBarProps } from 'expo-router/build/react-navigation/bottom-tabs/types';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Animated, { cancelAnimation, useAnimatedStyle, useSharedValue, withRepeat, withTiming } from 'react-native-reanimated';
import { colors, fonts, radii } from '@/constants/Theme';
import type { LogStatus } from '@/store/types';

export type IconName = keyof typeof Ionicons.glyphMap;

export function Icon({ name, size = 20, color = colors.textMuted }: { name: IconName; size?: number; color?: string }) {
  return <Ionicons name={name} size={size} color={color} />;
}

export function GlowDot({ color = colors.cyan, size = 8 }: { color?: string; size?: number }) {
  return <View style={[styles.glowDot, { width: size, height: size, borderRadius: size / 2, backgroundColor: color, shadowColor: color }]} />;
}

export function GlassCard({ children, style, onPress, accessibilityLabel }: { children: React.ReactNode; style?: object; onPress?: () => void; accessibilityLabel?: string }) {
  if (onPress) {
    return (
      <Pressable accessibilityRole="button" accessibilityLabel={accessibilityLabel} onPress={onPress} style={({ pressed }) => [styles.card, style, pressed && styles.pressed]}>
        {children}
      </Pressable>
    );
  }
  return <View style={[styles.card, style]}>{children}</View>;
}

export function SectionLabel({ children, action, onAction }: { children: React.ReactNode; action?: string; onAction?: () => void }) {
  return (
    <View style={styles.sectionHeader}>
      <Text style={styles.sectionLabel}>{children}</Text>
      {action && onAction ? (
        <Pressable accessibilityRole="button" onPress={onAction} hitSlop={10}>
          <Text style={styles.sectionAction}>{action}</Text>
        </Pressable>
      ) : null}
    </View>
  );
}

export function StatusBadge({ status }: { status: LogStatus }) {
  const config: Record<LogStatus, { label: string; color: string; icon: IconName }> = {
    success: { label: 'Success', color: colors.emerald, icon: 'checkmark-circle' },
    warning: { label: 'Warning', color: colors.amber, icon: 'warning' },
    pending: { label: 'Pending', color: colors.cyan, icon: 'time' },
    failed: { label: 'Failed', color: colors.red, icon: 'close-circle' },
  };
  const item = config[status];
  return (
    <View style={[styles.statusBadge, { borderColor: `${item.color}70`, backgroundColor: `${item.color}18` }]}>
      <Icon name={item.icon} size={13} color={item.color} />
      <Text style={[styles.statusText, { color: item.color }]}>{item.label}</Text>
    </View>
  );
}

export function PrimaryButton({ label, icon, onPress, variant = 'primary', disabled = false }: { label: string; icon?: IconName; onPress: () => void; variant?: 'primary' | 'secondary' | 'quiet'; disabled?: boolean }) {
  return (
    <Pressable accessibilityRole="button" accessibilityState={{ disabled }} disabled={disabled} onPress={onPress} style={({ pressed }) => [styles.button, styles[`button_${variant}`], disabled && styles.buttonDisabled, pressed && styles.pressed]}>
      {icon ? <Icon name={icon} size={16} color={variant === 'primary' ? colors.background : colors.text} /> : null}
      <Text style={[styles.buttonText, variant === 'primary' && styles.buttonTextPrimary]}>{label}</Text>
    </Pressable>
  );
}

export function VoiceOrb({ size = 64, onPress }: { size?: number; onPress?: () => void }) {
  const pulse = useSharedValue(1);
  useEffect(() => {
    pulse.value = withRepeat(withTiming(1.08, { duration: 1500 }), -1, true);
    return () => cancelAnimation(pulse);
  }, [pulse]);
  const animatedStyle = useAnimatedStyle(() => ({ transform: [{ scale: pulse.value }] }));
  const content = (
    <Animated.View style={[styles.orbOuter, { width: size + 18, height: size + 18, borderRadius: (size + 18) / 2 }, animatedStyle]}>
      <View style={[styles.orb, { width: size, height: size, borderRadius: size / 2 }]}>
        <View style={styles.waveform}>
          {[12, 21, 30, 18, 26, 14, 23].map((height, index) => <View key={`${height}-${index}`} style={[styles.waveBar, { height }]} />)}
        </View>
      </View>
    </Animated.View>
  );
  return onPress ? <Pressable accessibilityRole="button" accessibilityLabel="Open voice assistant" onPress={onPress}>{content}</Pressable> : content;
}

const TAB_CONFIG: Record<string, { label: string; icon: IconName; activeIcon: IconName }> = {
  index: { label: 'Assistant', icon: 'chatbubble-ellipses-outline', activeIcon: 'chatbubble-ellipses' },
  routines: { label: 'Routines', icon: 'time-outline', activeIcon: 'time' },
  skills: { label: 'Skills', icon: 'rocket-outline', activeIcon: 'rocket' },
  activity: { label: 'Activity', icon: 'list-outline', activeIcon: 'list' },
};

export function NexusTabBar({ state, descriptors, navigation }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const leftRoutes = state.routes.slice(0, 2);
  const rightRoutes = state.routes.slice(2);
  const renderTab = (route: (typeof state.routes)[number]) => {
    const config = TAB_CONFIG[route.name] ?? TAB_CONFIG.index;
    const isFocused = state.index === state.routes.indexOf(route);
    const onPress = () => {
      const event = navigation.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
      if (!isFocused && !event.defaultPrevented) navigation.navigate(route.name);
    };
    return (
      <Pressable key={route.key} accessibilityRole="tab" accessibilityState={{ selected: isFocused }} accessibilityLabel={descriptors[route.key]?.options.tabBarAccessibilityLabel ?? config.label} onPress={onPress} style={styles.tabItem}>
        <Icon name={isFocused ? config.activeIcon : config.icon} size={22} color={isFocused ? colors.cyan : colors.textMuted} />
        <Text style={[styles.tabLabel, isFocused && styles.tabLabelActive]}>{config.label}</Text>
      </Pressable>
    );
  };
  return (
    <View testID="tab-bar" style={[styles.tabBar, { paddingBottom: Math.max(insets.bottom, 10) }]}>
      <View style={styles.tabGroup}>{leftRoutes.map(renderTab)}</View>
      <View style={styles.orbTab}><VoiceOrb size={54} onPress={() => router.push('/voice')} /></View>
      <View style={styles.tabGroup}>{rightRoutes.map(renderTab)}</View>
    </View>
  );
}

export const uiStyles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: colors.background },
  scrollContent: { paddingHorizontal: 18, paddingTop: 12, paddingBottom: 120, gap: 18 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 18, paddingTop: 12, paddingBottom: 10 },
  headerTitle: { color: colors.text, fontFamily: fonts.bold, fontSize: 28, letterSpacing: -0.8 },
  headerSubtitle: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 13, marginTop: 4 },
  iconButton: { width: 42, height: 42, borderRadius: 14, alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: colors.border, backgroundColor: colors.card },
  card: { backgroundColor: colors.card, borderRadius: radii.medium, borderWidth: 1, borderColor: colors.border, padding: 16 },
  cardTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 17 },
  muted: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 13 },
  mono: { color: colors.cyanSoft, fontFamily: 'monospace', fontSize: 12 },
});

const styles = StyleSheet.create({
  glowDot: { shadowOpacity: 0.95, shadowRadius: 8, elevation: 5 },
  card: uiStyles.card,
  pressed: { opacity: 0.82 },
  sectionHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  sectionLabel: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 12, letterSpacing: 1.2, textTransform: 'uppercase' },
  sectionAction: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 12 },
  statusBadge: { alignSelf: 'flex-start', flexDirection: 'row', alignItems: 'center', gap: 5, paddingHorizontal: 8, paddingVertical: 5, borderRadius: radii.pill, borderWidth: 1 },
  statusText: { fontFamily: fonts.medium, fontSize: 11 },
  button: { minHeight: 42, paddingHorizontal: 15, borderRadius: 12, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 7, borderWidth: 1 },
  button_primary: { backgroundColor: colors.cyan, borderColor: colors.cyan },
  button_secondary: { backgroundColor: colors.cardRaised, borderColor: colors.borderBright },
  button_quiet: { backgroundColor: 'transparent', borderColor: colors.border },
  buttonDisabled: { opacity: 0.45 },
  buttonText: { color: colors.text, fontFamily: fonts.semibold, fontSize: 13 },
  buttonTextPrimary: { color: colors.background },
  orbOuter: { alignItems: 'center', justifyContent: 'center', backgroundColor: '#242051', borderWidth: 1, borderColor: '#A66CFF', shadowColor: colors.violetSoft, shadowOpacity: 0.9, shadowRadius: 18, elevation: 8 },
  orb: { alignItems: 'center', justifyContent: 'center', backgroundColor: colors.violet, borderWidth: 3, borderColor: colors.cyan },
  waveform: { height: 32, flexDirection: 'row', alignItems: 'center', gap: 3 },
  waveBar: { width: 3, borderRadius: 3, backgroundColor: colors.white },
  tabBar: { position: 'absolute', bottom: 0, left: 0, right: 0, minHeight: 82, paddingTop: 10, flexDirection: 'row', alignItems: 'flex-start', backgroundColor: '#111827F2', borderTopWidth: 1, borderTopColor: '#364158' },
  tabGroup: { flex: 1, flexDirection: 'row' },
  tabItem: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 4, minHeight: 54 },
  tabLabel: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 10 },
  tabLabelActive: { color: colors.cyan },
  orbTab: { width: 76, alignItems: 'center', marginTop: -32 },
});
EOF
echo "✅ components/nexus-ui.tsx"

echo ""
echo "🎉 مرحله ۶ تمام شد! components کامل شد."
echo ""
echo "➡️ مرحله بعد: app (صفحات اصلی)"
