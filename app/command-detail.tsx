import { useCallback, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { colors, fonts } from '@/constants/Theme';
import { ErrorState, LoadingState } from '@/components/screen-state';
import { GlassCard, Icon, PrimaryButton, StatusBadge, uiStyles } from '@/components/nexus-ui';
import { useAppReady } from '@/hooks/use-app-ready';
import { useAppStore } from '@/store/useAppStore';
import type { CommandLog } from '@/store/types';

export default function CommandDetailScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ logId?: string | string[] }>();
  const { ready, error, retry } = useAppReady();
  const logs = useAppStore((state) => state.logs);
  const addLog = useAppStore((state) => state.addLog);
  const [rerunError, setRerunError] = useState<string | null>(null);
  const logId = typeof params.logId === 'string' ? params.logId : params.logId?.[0];
  const log = useMemo(() => logs.find((item) => item.id === logId), [logId, logs]);

  const rerun = useCallback(() => {
    if (!log) return;
    try {
      addLog({ userInput: log.userInput, intent: log.intent, skill: log.skill, parameters: log.parameters, status: 'success', executionTimeMs: log.executionTimeMs, summary: `${log.summary} · re-run` });
      router.back();
    } catch (cause: unknown) {
      console.error('Command re-run failed', cause);
      setRerunError(cause instanceof Error ? cause.message : 'This action could not be re-run.');
    }
  }, [addLog, log, router]);

  if (!ready && !error) return <LoadingState />;
  if (error) return <ErrorState message={error} onRetry={retry} />;
  if (!log) return <ErrorState message="That execution log is no longer available in local storage." onRetry={() => router.back()} />;

  return <DetailContent log={log} onClose={() => router.back()} onRerun={rerun} error={rerunError} />;
}

function DetailContent({ log, onClose, onRerun, error }: { log: CommandLog; onClose: () => void; onRerun: () => void; error: string | null }) {
  const accent = log.status === 'success' ? colors.emerald : log.status === 'warning' ? colors.amber : log.status === 'failed' ? colors.red : colors.cyan;
  return (
    <View style={uiStyles.screen}>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
        <View style={styles.header}><Pressable accessibilityRole="button" accessibilityLabel="Close command details" onPress={onClose} style={styles.closeButton}><Icon name="close" size={20} color={colors.text} /></Pressable><View style={styles.headerCopy}><Text style={styles.kicker}>EXECUTION DETAIL</Text><Text numberOfLines={1} style={styles.title}>Command payload</Text></View><View style={[styles.statusDot, { backgroundColor: accent }]} /></View>
        <GlassCard style={[styles.hero, { borderColor: `${accent}70` }]}><View style={[styles.heroIcon, { backgroundColor: `${accent}18` }]}><Icon name={log.skill === 'calendar' ? 'calendar-outline' : log.skill === 'messages' ? 'chatbubble-outline' : log.skill === 'routine' ? 'sparkles-outline' : 'pulse-outline'} size={23} color={accent} /></View><Text style={styles.intent}>{log.intent}</Text><Text style={styles.userInput}>"{log.userInput}"</Text><View style={styles.heroMeta}><StatusBadge status={log.status} /><Text style={styles.metaText}>{log.executionTimeMs}ms</Text><Text style={styles.metaText}>{new Intl.DateTimeFormat('en-US', { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(log.timestamp))}</Text></View></GlassCard>
        <View style={styles.section}><Text style={styles.sectionLabel}>Resolved parameters</Text><GlassCard style={styles.codeCard}>{Object.entries(log.parameters).map(([key, value]) => <View key={key} style={styles.codeRow}><Text selectable style={styles.codeKey}>{key}</Text><Text selectable style={styles.codeValue}>{JSON.stringify(value)}</Text></View>)}</GlassCard></View>
        <View style={styles.section}><Text style={styles.sectionLabel}>Dispatch response</Text><GlassCard style={styles.responseCard}><View style={styles.responseLine}><Icon name="checkmark-circle" size={18} color={colors.emerald} /><Text style={styles.responseTitle}>Adapter acknowledged the action</Text></View><Text style={styles.responseText}>The local skill adapter received the payload and returned a {log.status} result. This entry remains available for audit and re-run.</Text></GlassCard></View>
        {error ? <Text selectable style={styles.errorText}>{error}</Text> : null}
        <PrimaryButton label="Re-run exact payload" icon="refresh-outline" onPress={onRerun} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  content: { padding: 18, paddingTop: 16, paddingBottom: 42, gap: 20 },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingBottom: 4 },
  closeButton: { width: 42, height: 42, borderRadius: 13, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.card, borderWidth: 1, borderColor: colors.border },
  headerCopy: { flex: 1, gap: 3 },
  kicker: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 10, letterSpacing: 1.3 },
  title: { color: colors.text, fontFamily: fonts.bold, fontSize: 23 },
  statusDot: { width: 10, height: 10, borderRadius: 5 },
  hero: { alignItems: 'center', paddingVertical: 23, borderWidth: 1 },
  heroIcon: { width: 48, height: 48, borderRadius: 16, alignItems: 'center', justifyContent: 'center', marginBottom: 12 },
  intent: { color: colors.text, fontFamily: 'monospace', fontSize: 15 },
  userInput: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 13, textAlign: 'center', marginTop: 8 },
  heroMeta: { flexDirection: 'row', alignItems: 'center', gap: 9, marginTop: 16 },
  metaText: { color: colors.textDim, fontFamily: fonts.medium, fontSize: 10 },
  section: { gap: 10 },
  sectionLabel: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 11, letterSpacing: 1, textTransform: 'uppercase' },
  codeCard: { gap: 12, backgroundColor: '#0C1220' },
  codeRow: { flexDirection: 'row', gap: 14 },
  codeKey: { color: colors.violetSoft, fontFamily: 'monospace', fontSize: 12, width: 105 },
  codeValue: { color: colors.cyanSoft, fontFamily: 'monospace', fontSize: 12, flex: 1 },
  responseCard: { gap: 10 },
  responseLine: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  responseTitle: { color: colors.emerald, fontFamily: fonts.semibold, fontSize: 13 },
  responseText: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12, lineHeight: 19 },
  errorText: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, lineHeight: 18 },
});
