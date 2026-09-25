import { useCallback, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useRouter } from 'expo-router';
import { colors, fonts, radii } from '@/constants/Theme';
import { ErrorState, LoadingState } from '@/components/screen-state';
import { GlassCard, Icon, type IconName, SectionLabel, StatusBadge, uiStyles } from '@/components/nexus-ui';
import { useAppReady } from '@/hooks/use-app-ready';
import { useAppStore } from '@/store/useAppStore';
import type { CommandLog, LogStatus, SkillId } from '@/store/types';

type FilterKey = 'all' | LogStatus;

const filters: { key: FilterKey; label: string }[] = [
  { key: 'all', label: 'All' },
  { key: 'success', label: 'Success' },
  { key: 'warning', label: 'Warning' },
  { key: 'failed', label: 'Failed' },
];

const skillIcons: Record<SkillId, IconName> = {
  messages: 'chatbubble-outline',
  calendar: 'calendar-outline',
  reminders: 'checkbox-outline',
  smarthome: 'home-outline',
  notes: 'document-text-outline',
  system: 'options-outline',
  web: 'globe-outline',
  routine: 'sparkles-outline',
};

const skillColors: Record<SkillId, string> = {
  messages: colors.cyan,
  calendar: colors.violet,
  reminders: colors.amber,
  smarthome: colors.emerald,
  notes: colors.cyanSoft,
  system: colors.violetSoft,
  web: '#5E9CFF',
  routine: colors.cyan,
};

export default function ActivityScreen() {
  const router = useRouter();
  const { ready, error, retry } = useAppReady();
  const logs = useAppStore((state) => state.logs);
  const clearLogs = useAppStore((state) => state.clearLogs);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<FilterKey>('all');
  const [screenError, setScreenError] = useState<string | null>(null);

  const filteredLogs = useMemo(() => {
    const query = search.trim().toLowerCase();
    return logs.filter((log) => {
      const matchesFilter = filter === 'all' || log.status === filter;
      const matchesSearch = !query || `${log.userInput} ${log.intent} ${log.summary}`.toLowerCase().includes(query);
      return matchesFilter && matchesSearch;
    });
  }, [filter, logs, search]);

  const openDetail = useCallback((logId: string) => {
    router.push(`/command-detail?logId=${logId}`);
  }, [router]);

  const rerunLog = useCallback((log: CommandLog) => {
    try {
      router.push(`/command-detail?logId=${log.id}`);
    } catch (cause: unknown) {
      console.error('Activity re-run navigation failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'This entry could not be opened.');
    }
  }, [router]);

  const clearAll = useCallback(() => {
    try {
      clearLogs();
      setScreenError(null);
    } catch (cause: unknown) {
      console.error('Clearing logs failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'Activity history could not be cleared.');
    }
  }, [clearLogs]);

  if (!ready && !error) return <LoadingState />;
  if (error) return <ErrorState message={error} onRetry={retry} />;

  return (
    <View style={uiStyles.screen}>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
        <View style={uiStyles.header}>
          <View>
            <Text style={uiStyles.headerTitle}>Activity</Text>
            <Text style={uiStyles.headerSubtitle}>Every command, adapter, and outcome.</Text>
          </View>
          <View style={styles.headerActions}>
            {logs.length > 0 ? (
              <Pressable accessibilityRole="button" accessibilityLabel="Clear activity history" onPress={clearAll} style={uiStyles.iconButton}>
                <Icon name="trash-outline" size={18} color={colors.textMuted} />
              </Pressable>
            ) : null}
          </View>
        </View>

        <View style={styles.searchBox}>
          <Icon name="search-outline" size={18} color={colors.textMuted} />
          <TextInput value={search} onChangeText={setSearch} placeholder="Search commands or intents" placeholderTextColor={colors.textDim} style={styles.searchInput} accessibilityLabel="Search activity" />
          {search ? (
            <Pressable accessibilityRole="button" onPress={() => setSearch('')}>
              <Icon name="close-circle" size={17} color={colors.textDim} />
            </Pressable>
          ) : null}
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.filterScroll} contentContainerStyle={styles.filterContent}>
          {filters.map((item) => {
            const active = filter === item.key;
            return (
              <Pressable key={item.key} accessibilityRole="button" accessibilityState={{ selected: active }} onPress={() => setFilter(item.key)} style={[styles.filterChip, active && styles.filterChipActive]}>
                <Text style={[styles.filterText, active && styles.filterTextActive]}>{item.label}</Text>
              </Pressable>
            );
          })}
        </ScrollView>

        <View style={styles.listSection}>
          <SectionLabel action={logs.length > 0 ? 'Clear' : undefined} onAction={logs.length > 0 ? clearAll : undefined}>
            {filteredLogs.length} {filteredLogs.length === 1 ? 'entry' : 'entries'}
          </SectionLabel>

          {filteredLogs.length === 0 ? (
            <GlassCard style={styles.emptyCard}>
              <Icon name="time-outline" size={24} color={colors.textDim} />
              <Text style={styles.emptyTitle}>No activity yet</Text>
              <Text style={styles.emptyText}>Commands you run will appear here for audit and re-run.</Text>
            </GlassCard>
          ) : (
            filteredLogs.map((log) => <LogCard key={log.id} log={log} onOpen={openDetail} onRerun={rerunLog} />)
          )}
        </View>

        {screenError ? <Text selectable style={styles.errorText}>{screenError}</Text> : null}
      </ScrollView>
    </View>
  );
}

function LogCard({ log, onOpen, onRerun }: { log: CommandLog; onOpen: (id: string) => void; onRerun: (log: CommandLog) => void }) {
  const accent = skillColors[log.skill] ?? colors.cyan;
  const icon = skillIcons[log.skill] ?? 'pulse-outline';
  const relative = formatRelativeTime(log.timestamp);
  return (
    <GlassCard style={styles.logCard} onPress={() => onOpen(log.id)} accessibilityLabel={`Open ${log.intent}`}>
      <View style={styles.logTop}>
        <View style={[styles.logIcon, { backgroundColor: `${accent}1A` }]}>
          <Icon name={icon} size={17} color={accent} />
        </View>
        <View style={styles.logIdentity}>
          <Text numberOfLines={1} style={styles.logIntent}>{log.intent}</Text>
          <Text numberOfLines={1} style={styles.logSummary}>{log.summary}</Text>
        </View>
        <Text style={styles.logTime}>{relative}</Text>
      </View>
      <View style={styles.logBottom}>
        <StatusBadge status={log.status} />
        <View style={styles.latency}>
          <Icon name="flash-outline" size={11} color={colors.textDim} />
          <Text style={styles.latencyText}>{log.executionTimeMs}ms</Text>
        </View>
        <Pressable accessibilityRole="button" accessibilityLabel={`Re-run ${log.intent}`} onPress={() => onRerun(log)} style={styles.rerun} hitSlop={10}>
          <Icon name="refresh-outline" size={13} color={colors.textMuted} />
          <Text style={styles.rerunText}>Re-run</Text>
        </Pressable>
      </View>
    </GlassCard>
  );
}

function formatRelativeTime(timestamp: number): string {
  const diff = Date.now() - timestamp;
  const minutes = Math.round(diff / 60000);
  if (minutes < 1) return 'now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.round(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.round(hours / 24);
  return `${days}d ago`;
}

const styles = StyleSheet.create({
  content: { paddingBottom: 122, gap: 17 },
  headerActions: { flexDirection: 'row', gap: 8 },
  searchBox: { marginHorizontal: 18, minHeight: 45, flexDirection: 'row', alignItems: 'center', gap: 8, paddingHorizontal: 12, borderRadius: 13, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.card },
  searchInput: { flex: 1, color: colors.text, fontFamily: fonts.regular, fontSize: 12, minHeight: 43 },
  filterScroll: { flexGrow: 0 },
  filterContent: { gap: 8, paddingHorizontal: 18 },
  filterChip: { minHeight: 35, justifyContent: 'center', paddingHorizontal: 14, borderRadius: radii.pill, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.card },
  filterChipActive: { borderColor: colors.cyan, backgroundColor: '#18D7E820' },
  filterText: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 12 },
  filterTextActive: { color: colors.cyan },
  listSection: { gap: 11, paddingHorizontal: 18 },
  logCard: { padding: 13, gap: 12 },
  logTop: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  logIcon: { width: 35, height: 35, borderRadius: 11, alignItems: 'center', justifyContent: 'center' },
  logIdentity: { flex: 1, gap: 4 },
  logIntent: { color: colors.text, fontFamily: fonts.semibold, fontSize: 13 },
  logSummary: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12 },
  logTime: { color: colors.textDim, fontFamily: fonts.medium, fontSize: 11, alignSelf: 'flex-start' },
  logBottom: { flexDirection: 'row', alignItems: 'center', gap: 9, paddingLeft: 45 },
  latency: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  latencyText: { color: colors.textDim, fontFamily: 'monospace', fontSize: 10 },
  rerun: { flexDirection: 'row', alignItems: 'center', gap: 4, marginLeft: 'auto', paddingVertical: 4 },
  rerunText: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 10 },
  emptyCard: { alignItems: 'center', gap: 7, paddingVertical: 30 },
  emptyTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 15 },
  emptyText: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12, textAlign: 'center' },
  errorText: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, marginHorizontal: 18 },
});
