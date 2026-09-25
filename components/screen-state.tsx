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
