#!/data/data/com.termux/files/usr/bin/bash
cd ~/Hoshyar

echo "📦 مرحله ۷f: routines + skills + activity..."

cat > app/\(tabs\)/routines.tsx << 'EOF'
import { useCallback, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Switch, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { colors, fonts, radii } from '@/constants/Theme';
import { ErrorState, LoadingState } from '@/components/screen-state';
import { GlassCard, Icon, type IconName, PrimaryButton, SectionLabel, uiStyles } from '@/components/nexus-ui';
import { useAppReady } from '@/hooks/use-app-ready';
import { useAppStore } from '@/store/useAppStore';
import type { Routine } from '@/store/types';

const triggers = [
  { title: 'Morning Briefing', detail: 'Calendar - Weather - Priorities', icon: 'sunny-outline' as const, color: colors.cyan },
  { title: 'Focus Mode', detail: 'DND - Timer - Ambient lights', icon: 'moon-outline' as const, color: colors.violet },
  { title: 'Evening Wrap-up', detail: 'Tasks - Notes - Sleep mode', icon: 'sparkles-outline' as const, color: colors.amber },
];

const wait = (duration: number) => new Promise<void>((resolve) => setTimeout(resolve, duration));

export default function RoutinesScreen() {
  const router = useRouter();
  const { ready, error, retry } = useAppReady();
  const routines = useAppStore((state) => state.routines);
  const toggleRoutine = useAppStore((state) => state.toggleRoutine);
  const updateRoutine = useAppStore((state) => state.updateRoutine);
  const addLog = useAppStore((state) => state.addLog);
  const [runningId, setRunningId] = useState<string | null>(null);
  const [screenError, setScreenError] = useState<string | null>(null);
  const activeCount = useMemo(() => routines.filter((routine) => routine.isEnabled).length, [routines]);

  const runRoutine = useCallback(async (routine: Routine) => {
    if (runningId) return;
    setRunningId(routine.id);
    setScreenError(null);
    try {
      for (let index = 0; index < routine.steps.length; index += 1) {
        updateRoutine(routine.id, { runningStep: index });
        await wait(650);
        updateRoutine(routine.id, { runningStep: index + 1 });
      }
      addLog({ userInput: `Run ${routine.title}`, intent: `Routine.${routine.id.replace('routine-', '')}`, skill: 'routine', parameters: { stepsExecuted: routine.steps.length, trigger: 'manual' }, status: 'success', executionTimeMs: routine.steps.length * 650, summary: `${routine.steps.length}/${routine.steps.length} Steps executed` });
    } catch (cause: unknown) {
      console.error('Routine execution failed', cause);
      setScreenError(cause instanceof Error ? cause.message : `Unable to run ${routine.title}.`);
    } finally {
      updateRoutine(routine.id, { runningStep: undefined });
      setRunningId(null);
    }
  }, [addLog, runningId, updateRoutine]);

  const openBuilder = useCallback(() => {
    router.push('/routine-builder');
  }, [router]);

  const openRoutine = useCallback((id: string) => {
    router.push(`/routine-builder?routineId=${id}`);
  }, [router]);

  if (!ready && !error) return <LoadingState />;
  if (error) return <ErrorState message={error} onRetry={retry} />;

  return (
    <View style={uiStyles.screen}>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
        <View style={uiStyles.header}>
          <View><Text style={uiStyles.headerTitle}>Automations</Text><Text style={uiStyles.headerSubtitle}>Workflows that move before you do.</Text></View>
          <View style={styles.activeBadge}><View style={styles.activeDot} /><Text style={styles.activeText}>{activeCount} active</Text></View>
        </View>

        <View style={styles.triggerSection}>
          <View style={styles.sectionRow}><SectionLabel>Instant triggers</SectionLabel><Pressable accessibilityRole="button" onPress={openBuilder} style={styles.newRoutine}><Icon name="add" size={16} color={colors.background} /><Text style={styles.newRoutineText}>New routine</Text></Pressable></View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.triggerScroll} contentContainerStyle={styles.triggerContent}>
            {triggers.map((trigger) => <Pressable key={trigger.title} accessibilityRole="button" onPress={() => openBuilder()} style={[styles.triggerCard, { borderColor: `${trigger.color}55` }]}><View style={[styles.triggerIcon, { backgroundColor: `${trigger.color}1A` }]}><Icon name={trigger.icon} size={19} color={trigger.color} /></View><Text style={styles.triggerTitle}>{trigger.title}</Text><Text style={styles.triggerDetail}>{trigger.detail}</Text><View style={styles.triggerArrow}><Icon name="arrow-forward" size={14} color={trigger.color} /></View></Pressable>)}
          </ScrollView>
        </View>

        <View style={styles.listSection}><SectionLabel action={`${routines.length} recipes`} onAction={() => setScreenError(null)}>Your routines</SectionLabel>
          {routines.map((routine) => <RoutineCard key={routine.id} routine={routine} isRunning={routine.id === runningId} onToggle={toggleRoutine} onRun={runRoutine} onOpen={openRoutine} />)}
        </View>
        {screenError ? <GlassCard style={styles.errorCard}><Icon name="warning-outline" size={18} color={colors.red} /><Text selectable style={styles.errorText}>{screenError}</Text><Pressable accessibilityRole="button" onPress={() => setScreenError(null)}><Text style={styles.dismissText}>Dismiss</Text></Pressable></GlassCard> : null}
      </ScrollView>
    </View>
  );
}

function RoutineCard({ routine, isRunning, onToggle, onRun, onOpen }: { routine: Routine; isRunning: boolean; onToggle: (id: string) => void; onRun: (routine: Routine) => void; onOpen: (id: string) => void }) {
  const progress = routine.runningStep ?? 0;
  return (
    <GlassCard style={[styles.routineCard, isRunning && { borderColor: routine.color }]} onPress={() => onOpen(routine.id)} accessibilityLabel={`Edit ${routine.title} routine`}>
      <View style={styles.routineHeader}><View style={[styles.routineIcon, { backgroundColor: `${routine.color}1A` }]}><Icon name={routine.icon as IconName} size={21} color={routine.color} /></View><View style={styles.routineHeading}><Text style={styles.routineTitle}>{routine.title}</Text><View style={styles.triggerLine}><Icon name={routine.triggerType === 'schedule' ? 'time-outline' : routine.triggerType === 'voice' ? 'mic-outline' : 'hand-left-outline'} size={13} color={colors.textDim} /><Text style={styles.triggerText}>{routine.triggerType === 'schedule' ? `Scheduled - ${routine.triggerValue}` : routine.triggerValue}</Text></View></View><Switch value={routine.isEnabled} onValueChange={() => onToggle(routine.id)} trackColor={{ false: colors.cardMuted, true: '#18D7E870' }} thumbColor={routine.isEnabled ? colors.cyan : colors.textMuted} accessibilityLabel={`Toggle ${routine.title}`} /></View>
      {isRunning ? <View style={styles.progressShell}><View style={styles.progressLabels}><Text style={styles.progressTitle}>Executing Step {Math.min(progress + 1, routine.steps.length)} of {routine.steps.length}...</Text><Text style={styles.progressPercent}>{Math.round((progress / routine.steps.length) * 100)}%</Text></View><View style={styles.progressTrack}><View style={[styles.progressFill, { width: `${Math.max(8, (progress / routine.steps.length) * 100)}%`, backgroundColor: routine.color }]} /></View></View> : null}
      <View style={styles.steps}>{routine.steps.map((step, index) => { const complete = isRunning && index < progress; const executing = isRunning && index === progress; return <View key={step.id} style={[styles.stepRow, complete && styles.stepComplete, executing && { borderColor: `${routine.color}80`, backgroundColor: `${routine.color}12` }]}><View style={[styles.stepIndex, complete && { backgroundColor: colors.emerald }, executing && { backgroundColor: routine.color }]}>{complete ? <Icon name="checkmark" size={12} color={colors.background} /> : <Text style={[styles.stepIndexText, executing && { color: colors.background }]}>{index + 1}</Text>}</View><Text numberOfLines={1} style={[styles.stepText, complete && styles.stepTextComplete]}>{step.description}</Text>{executing ? <Icon name="ellipsis-horizontal" size={16} color={routine.color} /> : null}</View>; })}</View>
      <View style={styles.routineFooter}><Text style={styles.stepCount}>{routine.steps.length} action steps</Text><PrimaryButton label={isRunning ? 'Running...' : 'Run now'} icon={isRunning ? 'hourglass-outline' : 'play'} disabled={isRunning || !routine.isEnabled} onPress={() => onRun(routine)} /></View>
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  content: { paddingBottom: 122, gap: 22 },
  activeBadge: { flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: '#8C7CFF22', borderRadius: radii.pill, paddingHorizontal: 11, paddingVertical: 8 },
  activeDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: colors.violetSoft },
  activeText: { color: colors.violetSoft, fontFamily: fonts.semibold, fontSize: 12 },
  triggerSection: { gap: 11 },
  sectionRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 18 },
  newRoutine: { flexDirection: 'row', alignItems: 'center', gap: 5, backgroundColor: colors.cyan, borderRadius: 11, paddingHorizontal: 10, minHeight: 34 },
  newRoutineText: { color: colors.background, fontFamily: fonts.semibold, fontSize: 11 },
  triggerScroll: { flexGrow: 0 },
  triggerContent: { gap: 10, paddingHorizontal: 18 },
  triggerCard: { width: 178, minHeight: 134, padding: 13, borderRadius: radii.medium, borderWidth: 1, backgroundColor: colors.card },
  triggerIcon: { width: 34, height: 34, borderRadius: 11, alignItems: 'center', justifyContent: 'center', marginBottom: 12 },
  triggerTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 14 },
  triggerDetail: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 11, lineHeight: 16, marginTop: 4, maxWidth: 135 },
  triggerArrow: { position: 'absolute', right: 12, bottom: 12 },
  listSection: { gap: 11, paddingHorizontal: 18 },
  routineCard: { padding: 14, gap: 13 },
  routineHeader: { flexDirection: 'row', alignItems: 'center', gap: 11 },
  routineIcon: { width: 42, height: 42, borderRadius: 13, alignItems: 'center', justifyContent: 'center' },
  routineHeading: { flex: 1, gap: 5 },
  routineTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 17 },
  triggerLine: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  triggerText: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 11 },
  progressShell: { gap: 7, paddingTop: 2 },
  progressLabels: { flexDirection: 'row', justifyContent: 'space-between' },
  progressTitle: { color: colors.cyan, fontFamily: fonts.medium, fontSize: 12 },
  progressPercent: { color: colors.textMuted, fontFamily: 'monospace', fontSize: 11 },
  progressTrack: { height: 5, borderRadius: 4, backgroundColor: colors.cardMuted, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 4 },
  steps: { gap: 6 },
  stepRow: { minHeight: 37, flexDirection: 'row', alignItems: 'center', gap: 9, paddingHorizontal: 9, borderRadius: 10, borderWidth: 1, borderColor: 'transparent', backgroundColor: '#202A3D' },
  stepComplete: { backgroundColor: '#40D99B18', borderColor: '#40D99B55' },
  stepIndex: { width: 20, height: 20, borderRadius: 10, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.borderBright },
  stepIndexText: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 10 },
  stepText: { color: colors.text, fontFamily: fonts.regular, fontSize: 12, flex: 1 },
  stepTextComplete: { color: colors.emerald },
  routineFooter: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  stepCount: { color: colors.textDim, fontFamily: fonts.regular, fontSize: 11 },
  errorCard: { marginHorizontal: 18, flexDirection: 'row', alignItems: 'center', gap: 9, borderColor: colors.red },
  errorText: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, flex: 1 },
  dismissText: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 11 },
});
EOF
echo "✅ app/(tabs)/routines.tsx"

cat > app/\(tabs\)/skills.tsx << 'EOF'
import { useCallback, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Switch, Text, TextInput, View } from 'react-native';
import { useRouter } from 'expo-router';
import { colors, fonts } from '@/constants/Theme';
import { ErrorState, LoadingState } from '@/components/screen-state';
import { GlassCard, Icon, type IconName, PrimaryButton, SectionLabel, uiStyles } from '@/components/nexus-ui';
import { useAppReady } from '@/hooks/use-app-ready';
import { useAppStore } from '@/store/useAppStore';
import type { SkillAdapterConfig } from '@/store/types';

export default function SkillsScreen() {
  const router = useRouter();
  const { ready, error, retry } = useAppReady();
  const skills = useAppStore((state) => state.skills);
  const updateSkillAuthorization = useAppStore((state) => state.updateSkillAuthorization);
  const setDraftCommand = useAppStore((state) => state.setDraftCommand);
  const [search, setSearch] = useState('');
  const [screenError, setScreenError] = useState<string | null>(null);

  const filteredSkills = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return skills;
    return skills.filter((skill) => `${skill.name} ${skill.description} ${skill.capabilities.join(' ')}`.toLowerCase().includes(query));
  }, [search, skills]);

  const testPrompt = useCallback((skill: SkillAdapterConfig) => {
    try {
      setDraftCommand(skill.sampleCommands[0] ?? `Test ${skill.name}`);
      router.push('/(tabs)');
    } catch (cause: unknown) {
      console.error('Skill prompt navigation failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'The assistant could not be opened.');
    }
  }, [router, setDraftCommand]);

  const togglePermission = useCallback((id: SkillAdapterConfig['id']) => {
    try {
      updateSkillAuthorization(id);
    } catch (cause: unknown) {
      console.error('Skill permission update failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'Permission state could not be updated.');
    }
  }, [updateSkillAuthorization]);

  if (!ready && !error) return <LoadingState />;
  if (error) return <ErrorState message={error} onRetry={retry} />;

  return (
    <View style={uiStyles.screen}>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
        <View style={uiStyles.header}>
          <View>
            <Text style={uiStyles.headerTitle}>Skill Adapters</Text>
            <Text style={uiStyles.headerSubtitle}>Permissions, capabilities, and test payloads.</Text>
          </View>
          <View style={styles.headerActions}>
            <Pressable accessibilityRole="button" accessibilityLabel="Open contacts" onPress={() => router.push('/contacts')} style={uiStyles.iconButton}>
              <Icon name="people-outline" size={18} color={colors.textMuted} />
            </Pressable>
            <View style={styles.connectedBadge}>
              <Text style={styles.connectedNumber}>{skills.filter((skill) => skill.isAuthorized).length}</Text>
              <Text style={styles.connectedLabel}>connected</Text>
            </View>
          </View>
        </View>

        <View style={styles.searchBox}>
          <Icon name="search-outline" size={18} color={colors.textMuted} />
          <TextInput value={search} onChangeText={setSearch} placeholder="Search skills or capabilities" placeholderTextColor={colors.textDim} style={styles.searchInput} accessibilityLabel="Search skill adapters" />
          {search ? (
            <Pressable accessibilityRole="button" onPress={() => setSearch('')}>
              <Icon name="close-circle" size={17} color={colors.textDim} />
            </Pressable>
          ) : null}
        </View>

        <View style={styles.infoBanner}>
          <View style={styles.infoIcon}><Icon name="shield-checkmark-outline" size={17} color={colors.cyan} /></View>
          <View style={styles.infoCopy}>
            <Text style={styles.infoTitle}>Local-first permissions</Text>
            <Text style={styles.infoText}>Supported actions use the device OS and always wait for your confirmation before dispatch.</Text>
          </View>
        </View>

        <View style={styles.skillSection}>
          <SectionLabel>{filteredSkills.length} available adapters</SectionLabel>
          {filteredSkills.length === 0 ? (
            <GlassCard style={styles.emptyCard}>
              <Icon name="search-outline" size={23} color={colors.textDim} />
              <Text style={styles.emptyTitle}>No adapter matches</Text>
              <Text style={styles.emptyText}>Try a broader capability or service name.</Text>
            </GlassCard>
          ) : (
            filteredSkills.map((skill) => <SkillCard key={skill.id} skill={skill} onTest={testPrompt} onToggle={togglePermission} />)
          )}
        </View>

        {screenError ? (
          <GlassCard style={styles.errorCard}>
            <Icon name="warning-outline" size={18} color={colors.red} />
            <Text selectable style={styles.errorText}>{screenError}</Text>
            <Pressable accessibilityRole="button" onPress={() => setScreenError(null)}>
              <Text style={styles.dismissText}>Dismiss</Text>
            </Pressable>
          </GlassCard>
        ) : null}
      </ScrollView>
    </View>
  );
}

function SkillCard({ skill, onTest, onToggle }: { skill: SkillAdapterConfig; onTest: (skill: SkillAdapterConfig) => void; onToggle: (id: SkillAdapterConfig['id']) => void }) {
  return (
    <GlassCard style={styles.skillCard}>
      <View style={styles.skillHeader}>
        <View style={[styles.skillIcon, { backgroundColor: `${skill.accent}1A` }]}>
          <Icon name={skill.icon as IconName} size={22} color={skill.accent} />
        </View>
        <View style={styles.skillHeading}>
          <Text style={styles.skillName}>{skill.name}</Text>
          <View style={styles.connectionLine}>
            <View style={[styles.connectionDot, { backgroundColor: skill.isAuthorized ? colors.emerald : colors.textDim }]} />
            <Text style={[styles.connectionText, skill.isAuthorized && { color: colors.emerald }]}>{skill.isAuthorized ? 'Authorized' : 'Permission needed'}</Text>
          </View>
        </View>
        <Switch value={skill.isAuthorized} onValueChange={() => onToggle(skill.id)} trackColor={{ false: colors.cardMuted, true: `${skill.accent}90` }} thumbColor={skill.isAuthorized ? skill.accent : colors.textMuted} accessibilityLabel={`Toggle ${skill.name} permission`} />
      </View>
      <Text style={styles.skillDescription}>{skill.description}</Text>
      <View style={styles.capabilities}>
        {skill.capabilities.map((capability) => (
          <View key={capability} style={styles.capability}>
            <Icon name="checkmark" size={12} color={skill.accent} />
            <Text style={styles.capabilityText}>{capability}</Text>
          </View>
        ))}
      </View>
      <View style={styles.skillFooter}>
        <Text style={styles.sampleText}>Try: "{skill.sampleCommands[0]}"</Text>
        <PrimaryButton label="Test prompt" icon="arrow-forward" variant="secondary" onPress={() => onTest(skill)} />
      </View>
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  content: { paddingBottom: 122, gap: 17 },
  connectedBadge: { alignItems: 'flex-end', backgroundColor: '#40D99B18', borderWidth: 1, borderColor: '#40D99B45', borderRadius: 12, paddingHorizontal: 10, paddingVertical: 7 },
  headerActions: { alignItems: 'flex-end', gap: 7 },
  connectedNumber: { color: colors.emerald, fontFamily: fonts.bold, fontSize: 16 },
  connectedLabel: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 10 },
  searchBox: { marginHorizontal: 18, minHeight: 48, flexDirection: 'row', alignItems: 'center', gap: 9, paddingHorizontal: 13, borderWidth: 1, borderColor: colors.border, borderRadius: 14, backgroundColor: colors.card },
  searchInput: { flex: 1, color: colors.text, fontFamily: fonts.regular, fontSize: 13, minHeight: 46 },
  infoBanner: { flexDirection: 'row', gap: 10, marginHorizontal: 18, padding: 12, borderRadius: 14, borderWidth: 1, borderColor: '#18D7E840', backgroundColor: '#18D7E810' },
  infoIcon: { width: 31, height: 31, borderRadius: 10, alignItems: 'center', justifyContent: 'center', backgroundColor: '#18D7E820' },
  infoCopy: { flex: 1, gap: 3 },
  infoTitle: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 12 },
  infoText: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 11, lineHeight: 16 },
  skillSection: { gap: 11, paddingHorizontal: 18 },
  skillCard: { padding: 14, gap: 12 },
  skillHeader: { flexDirection: 'row', alignItems: 'center', gap: 11 },
  skillIcon: { width: 43, height: 43, borderRadius: 13, alignItems: 'center', justifyContent: 'center' },
  skillHeading: { flex: 1, gap: 5 },
  skillName: { color: colors.text, fontFamily: fonts.semibold, fontSize: 16 },
  connectionLine: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  connectionDot: { width: 6, height: 6, borderRadius: 3 },
  connectionText: { color: colors.textDim, fontFamily: fonts.medium, fontSize: 11 },
  skillDescription: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12, lineHeight: 18 },
  capabilities: { flexDirection: 'row', flexWrap: 'wrap', gap: 7 },
  capability: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingHorizontal: 8, paddingVertical: 6, borderRadius: 8, backgroundColor: colors.cardRaised },
  capabilityText: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 10 },
  skillFooter: { gap: 10, paddingTop: 2 },
  sampleText: { color: colors.textDim, fontFamily: fonts.regular, fontSize: 11, fontStyle: 'italic' },
  emptyCard: { alignItems: 'center', gap: 7, paddingVertical: 30 },
  emptyTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 15 },
  emptyText: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12, textAlign: 'center' },
  errorCard: { marginHorizontal: 18, flexDirection: 'row', alignItems: 'center', gap: 9, borderColor: colors.red },
  errorText: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, flex: 1 },
  dismissText: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 11 },
});
EOF
echo "✅ app/(tabs)/skills.tsx"

cat > app/\(tabs\)/activity.tsx << 'EOF'
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
  searchBox: { marginHorizontal: 18, minHeight: 45, flexDirection: 'row', alignItems: 'center', gap: 8, paddingHorizontal: 12, borderRadius: 13, borderWidth: 1,
cat > ~/Hoshyar/create-part7f.sh << 'ENDOFSCRIPT'
#!/data/data/com.termux/files/usr/bin/bash
cd ~/Hoshyar

echo "📦 مرحله ۷f: routines + skills + activity..."

cat > app/\(tabs\)/routines.tsx << 'EOF'
import { useCallback, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Switch, Text, View } from 'react-native';
import { useRouter } from 'expo-router';
import { colors, fonts, radii } from '@/constants/Theme';
import { ErrorState, LoadingState } from '@/components/screen-state';
import { GlassCard, Icon, type IconName, PrimaryButton, SectionLabel, uiStyles } from '@/components/nexus-ui';
import { useAppReady } from '@/hooks/use-app-ready';
import { useAppStore } from '@/store/useAppStore';
import type { Routine } from '@/store/types';

const triggers = [
  { title: 'Morning Briefing', detail: 'Calendar - Weather - Priorities', icon: 'sunny-outline' as const, color: colors.cyan },
  { title: 'Focus Mode', detail: 'DND - Timer - Ambient lights', icon: 'moon-outline' as const, color: colors.violet },
  { title: 'Evening Wrap-up', detail: 'Tasks - Notes - Sleep mode', icon: 'sparkles-outline' as const, color: colors.amber },
];

const wait = (duration: number) => new Promise<void>((resolve) => setTimeout(resolve, duration));

export default function RoutinesScreen() {
  const router = useRouter();
  const { ready, error, retry } = useAppReady();
  const routines = useAppStore((state) => state.routines);
  const toggleRoutine = useAppStore((state) => state.toggleRoutine);
  const updateRoutine = useAppStore((state) => state.updateRoutine);
  const addLog = useAppStore((state) => state.addLog);
  const [runningId, setRunningId] = useState<string | null>(null);
  const [screenError, setScreenError] = useState<string | null>(null);
  const activeCount = useMemo(() => routines.filter((routine) => routine.isEnabled).length, [routines]);

  const runRoutine = useCallback(async (routine: Routine) => {
    if (runningId) return;
    setRunningId(routine.id);
    setScreenError(null);
    try {
      for (let index = 0; index < routine.steps.length; index += 1) {
        updateRoutine(routine.id, { runningStep: index });
        await wait(650);
        updateRoutine(routine.id, { runningStep: index + 1 });
      }
      addLog({ userInput: `Run ${routine.title}`, intent: `Routine.${routine.id.replace('routine-', '')}`, skill: 'routine', parameters: { stepsExecuted: routine.steps.length, trigger: 'manual' }, status: 'success', executionTimeMs: routine.steps.length * 650, summary: `${routine.steps.length}/${routine.steps.length} Steps executed` });
    } catch (cause: unknown) {
      console.error('Routine execution failed', cause);
      setScreenError(cause instanceof Error ? cause.message : `Unable to run ${routine.title}.`);
    } finally {
      updateRoutine(routine.id, { runningStep: undefined });
      setRunningId(null);
    }
  }, [addLog, runningId, updateRoutine]);

  const openBuilder = useCallback(() => {
    router.push('/routine-builder');
  }, [router]);

  const openRoutine = useCallback((id: string) => {
    router.push(`/routine-builder?routineId=${id}`);
  }, [router]);

  if (!ready && !error) return <LoadingState />;
  if (error) return <ErrorState message={error} onRetry={retry} />;

  return (
    <View style={uiStyles.screen}>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
        <View style={uiStyles.header}>
          <View><Text style={uiStyles.headerTitle}>Automations</Text><Text style={uiStyles.headerSubtitle}>Workflows that move before you do.</Text></View>
          <View style={styles.activeBadge}><View style={styles.activeDot} /><Text style={styles.activeText}>{activeCount} active</Text></View>
        </View>

        <View style={styles.triggerSection}>
          <View style={styles.sectionRow}><SectionLabel>Instant triggers</SectionLabel><Pressable accessibilityRole="button" onPress={openBuilder} style={styles.newRoutine}><Icon name="add" size={16} color={colors.background} /><Text style={styles.newRoutineText}>New routine</Text></Pressable></View>
          <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.triggerScroll} contentContainerStyle={styles.triggerContent}>
            {triggers.map((trigger) => <Pressable key={trigger.title} accessibilityRole="button" onPress={() => openBuilder()} style={[styles.triggerCard, { borderColor: `${trigger.color}55` }]}><View style={[styles.triggerIcon, { backgroundColor: `${trigger.color}1A` }]}><Icon name={trigger.icon} size={19} color={trigger.color} /></View><Text style={styles.triggerTitle}>{trigger.title}</Text><Text style={styles.triggerDetail}>{trigger.detail}</Text><View style={styles.triggerArrow}><Icon name="arrow-forward" size={14} color={trigger.color} /></View></Pressable>)}
          </ScrollView>
        </View>

        <View style={styles.listSection}><SectionLabel action={`${routines.length} recipes`} onAction={() => setScreenError(null)}>Your routines</SectionLabel>
          {routines.map((routine) => <RoutineCard key={routine.id} routine={routine} isRunning={routine.id === runningId} onToggle={toggleRoutine} onRun={runRoutine} onOpen={openRoutine} />)}
        </View>
        {screenError ? <GlassCard style={styles.errorCard}><Icon name="warning-outline" size={18} color={colors.red} /><Text selectable style={styles.errorText}>{screenError}</Text><Pressable accessibilityRole="button" onPress={() => setScreenError(null)}><Text style={styles.dismissText}>Dismiss</Text></Pressable></GlassCard> : null}
      </ScrollView>
    </View>
  );
}

function RoutineCard({ routine, isRunning, onToggle, onRun, onOpen }: { routine: Routine; isRunning: boolean; onToggle: (id: string) => void; onRun: (routine: Routine) => void; onOpen: (id: string) => void }) {
  const progress = routine.runningStep ?? 0;
  return (
    <GlassCard style={[styles.routineCard, isRunning && { borderColor: routine.color }]} onPress={() => onOpen(routine.id)} accessibilityLabel={`Edit ${routine.title} routine`}>
      <View style={styles.routineHeader}><View style={[styles.routineIcon, { backgroundColor: `${routine.color}1A` }]}><Icon name={routine.icon as IconName} size={21} color={routine.color} /></View><View style={styles.routineHeading}><Text style={styles.routineTitle}>{routine.title}</Text><View style={styles.triggerLine}><Icon name={routine.triggerType === 'schedule' ? 'time-outline' : routine.triggerType === 'voice' ? 'mic-outline' : 'hand-left-outline'} size={13} color={colors.textDim} /><Text style={styles.triggerText}>{routine.triggerType === 'schedule' ? `Scheduled - ${routine.triggerValue}` : routine.triggerValue}</Text></View></View><Switch value={routine.isEnabled} onValueChange={() => onToggle(routine.id)} trackColor={{ false: colors.cardMuted, true: '#18D7E870' }} thumbColor={routine.isEnabled ? colors.cyan : colors.textMuted} accessibilityLabel={`Toggle ${routine.title}`} /></View>
      {isRunning ? <View style={styles.progressShell}><View style={styles.progressLabels}><Text style={styles.progressTitle}>Executing Step {Math.min(progress + 1, routine.steps.length)} of {routine.steps.length}...</Text><Text style={styles.progressPercent}>{Math.round((progress / routine.steps.length) * 100)}%</Text></View><View style={styles.progressTrack}><View style={[styles.progressFill, { width: `${Math.max(8, (progress / routine.steps.length) * 100)}%`, backgroundColor: routine.color }]} /></View></View> : null}
      <View style={styles.steps}>{routine.steps.map((step, index) => { const complete = isRunning && index < progress; const executing = isRunning && index === progress; return <View key={step.id} style={[styles.stepRow, complete && styles.stepComplete, executing && { borderColor: `${routine.color}80`, backgroundColor: `${routine.color}12` }]}><View style={[styles.stepIndex, complete && { backgroundColor: colors.emerald }, executing && { backgroundColor: routine.color }]}>{complete ? <Icon name="checkmark" size={12} color={colors.background} /> : <Text style={[styles.stepIndexText, executing && { color: colors.background }]}>{index + 1}</Text>}</View><Text numberOfLines={1} style={[styles.stepText, complete && styles.stepTextComplete]}>{step.description}</Text>{executing ? <Icon name="ellipsis-horizontal" size={16} color={routine.color} /> : null}</View>; })}</View>
      <View style={styles.routineFooter}><Text style={styles.stepCount}>{routine.steps.length} action steps</Text><PrimaryButton label={isRunning ? 'Running...' : 'Run now'} icon={isRunning ? 'hourglass-outline' : 'play'} disabled={isRunning || !routine.isEnabled} onPress={() => onRun(routine)} /></View>
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  content: { paddingBottom: 122, gap: 22 },
  activeBadge: { flexDirection: 'row', alignItems: 'center', gap: 6, backgroundColor: '#8C7CFF22', borderRadius: radii.pill, paddingHorizontal: 11, paddingVertical: 8 },
  activeDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: colors.violetSoft },
  activeText: { color: colors.violetSoft, fontFamily: fonts.semibold, fontSize: 12 },
  triggerSection: { gap: 11 },
  sectionRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 18 },
  newRoutine: { flexDirection: 'row', alignItems: 'center', gap: 5, backgroundColor: colors.cyan, borderRadius: 11, paddingHorizontal: 10, minHeight: 34 },
  newRoutineText: { color: colors.background, fontFamily: fonts.semibold, fontSize: 11 },
  triggerScroll: { flexGrow: 0 },
  triggerContent: { gap: 10, paddingHorizontal: 18 },
  triggerCard: { width: 178, minHeight: 134, padding: 13, borderRadius: radii.medium, borderWidth: 1, backgroundColor: colors.card },
  triggerIcon: { width: 34, height: 34, borderRadius: 11, alignItems: 'center', justifyContent: 'center', marginBottom: 12 },
  triggerTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 14 },
  triggerDetail: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 11, lineHeight: 16, marginTop: 4, maxWidth: 135 },
  triggerArrow: { position: 'absolute', right: 12, bottom: 12 },
  listSection: { gap: 11, paddingHorizontal: 18 },
  routineCard: { padding: 14, gap: 13 },
  routineHeader: { flexDirection: 'row', alignItems: 'center', gap: 11 },
  routineIcon: { width: 42, height: 42, borderRadius: 13, alignItems: 'center', justifyContent: 'center' },
  routineHeading: { flex: 1, gap: 5 },
  routineTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 17 },
  triggerLine: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  triggerText: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 11 },
  progressShell: { gap: 7, paddingTop: 2 },
  progressLabels: { flexDirection: 'row', justifyContent: 'space-between' },
  progressTitle: { color: colors.cyan, fontFamily: fonts.medium, fontSize: 12 },
  progressPercent: { color: colors.textMuted, fontFamily: 'monospace', fontSize: 11 },
  progressTrack: { height: 5, borderRadius: 4, backgroundColor: colors.cardMuted, overflow: 'hidden' },
  progressFill: { height: '100%', borderRadius: 4 },
  steps: { gap: 6 },
  stepRow: { minHeight: 37, flexDirection: 'row', alignItems: 'center', gap: 9, paddingHorizontal: 9, borderRadius: 10, borderWidth: 1, borderColor: 'transparent', backgroundColor: '#202A3D' },
  stepComplete: { backgroundColor: '#40D99B18', borderColor: '#40D99B55' },
  stepIndex: { width: 20, height: 20, borderRadius: 10, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.borderBright },
  stepIndexText: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 10 },
  stepText: { color: colors.text, fontFamily: fonts.regular, fontSize: 12, flex: 1 },
  stepTextComplete: { color: colors.emerald },
  routineFooter: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  stepCount: { color: colors.textDim, fontFamily: fonts.regular, fontSize: 11 },
  errorCard: { marginHorizontal: 18, flexDirection: 'row', alignItems: 'center', gap: 9, borderColor: colors.red },
  errorText: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, flex: 1 },
  dismissText: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 11 },
});
EOF
echo "✅ app/(tabs)/routines.tsx"

cat > app/\(tabs\)/skills.tsx << 'EOF'
import { useCallback, useMemo, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Switch, Text, TextInput, View } from 'react-native';
import { useRouter } from 'expo-router';
import { colors, fonts } from '@/constants/Theme';
import { ErrorState, LoadingState } from '@/components/screen-state';
import { GlassCard, Icon, type IconName, PrimaryButton, SectionLabel, uiStyles } from '@/components/nexus-ui';
import { useAppReady } from '@/hooks/use-app-ready';
import { useAppStore } from '@/store/useAppStore';
import type { SkillAdapterConfig } from '@/store/types';

export default function SkillsScreen() {
  const router = useRouter();
  const { ready, error, retry } = useAppReady();
  const skills = useAppStore((state) => state.skills);
  const updateSkillAuthorization = useAppStore((state) => state.updateSkillAuthorization);
  const setDraftCommand = useAppStore((state) => state.setDraftCommand);
  const [search, setSearch] = useState('');
  const [screenError, setScreenError] = useState<string | null>(null);

  const filteredSkills = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return skills;
    return skills.filter((skill) => `${skill.name} ${skill.description} ${skill.capabilities.join(' ')}`.toLowerCase().includes(query));
  }, [search, skills]);

  const testPrompt = useCallback((skill: SkillAdapterConfig) => {
    try {
      setDraftCommand(skill.sampleCommands[0] ?? `Test ${skill.name}`);
      router.push('/(tabs)');
    } catch (cause: unknown) {
      console.error('Skill prompt navigation failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'The assistant could not be opened.');
    }
  }, [router, setDraftCommand]);

  const togglePermission = useCallback((id: SkillAdapterConfig['id']) => {
    try {
      updateSkillAuthorization(id);
    } catch (cause: unknown) {
      console.error('Skill permission update failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'Permission state could not be updated.');
    }
  }, [updateSkillAuthorization]);

  if (!ready && !error) return <LoadingState />;
  if (error) return <ErrorState message={error} onRetry={retry} />;

  return (
    <View style={uiStyles.screen}>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
        <View style={uiStyles.header}>
          <View>
            <Text style={uiStyles.headerTitle}>Skill Adapters</Text>
            <Text style={uiStyles.headerSubtitle}>Permissions, capabilities, and test payloads.</Text>
          </View>
          <View style={styles.headerActions}>
            <Pressable accessibilityRole="button" accessibilityLabel="Open contacts" onPress={() => router.push('/contacts')} style={uiStyles.iconButton}>
              <Icon name="people-outline" size={18} color={colors.textMuted} />
            </Pressable>
            <View style={styles.connectedBadge}>
              <Text style={styles.connectedNumber}>{skills.filter((skill) => skill.isAuthorized).length}</Text>
              <Text style={styles.connectedLabel}>connected</Text>
            </View>
          </View>
        </View>

        <View style={styles.searchBox}>
          <Icon name="search-outline" size={18} color={colors.textMuted} />
          <TextInput value={search} onChangeText={setSearch} placeholder="Search skills or capabilities" placeholderTextColor={colors.textDim} style={styles.searchInput} accessibilityLabel="Search skill adapters" />
          {search ? (
            <Pressable accessibilityRole="button" onPress={() => setSearch('')}>
              <Icon name="close-circle" size={17} color={colors.textDim} />
            </Pressable>
          ) : null}
        </View>

        <View style={styles.infoBanner}>
          <View style={styles.infoIcon}><Icon name="shield-checkmark-outline" size={17} color={colors.cyan} /></View>
          <View style={styles.infoCopy}>
            <Text style={styles.infoTitle}>Local-first permissions</Text>
            <Text style={styles.infoText}>Supported actions use the device OS and always wait for your confirmation before dispatch.</Text>
          </View>
        </View>

        <View style={styles.skillSection}>
          <SectionLabel>{filteredSkills.length} available adapters</SectionLabel>
          {filteredSkills.length === 0 ? (
            <GlassCard style={styles.emptyCard}>
              <Icon name="search-outline" size={23} color={colors.textDim} />
              <Text style={styles.emptyTitle}>No adapter matches</Text>
              <Text style={styles.emptyText}>Try a broader capability or service name.</Text>
            </GlassCard>
          ) : (
            filteredSkills.map((skill) => <SkillCard key={skill.id} skill={skill} onTest={testPrompt} onToggle={togglePermission} />)
          )}
        </View>

        {screenError ? (
          <GlassCard style={styles.errorCard}>
            <Icon name="warning-outline" size={18} color={colors.red} />
            <Text selectable style={styles.errorText}>{screenError}</Text>
            <Pressable accessibilityRole="button" onPress={() => setScreenError(null)}>
              <Text style={styles.dismissText}>Dismiss</Text>
            </Pressable>
          </GlassCard>
        ) : null}
      </ScrollView>
    </View>
  );
}

function SkillCard({ skill, onTest, onToggle }: { skill: SkillAdapterConfig; onTest: (skill: SkillAdapterConfig) => void; onToggle: (id: SkillAdapterConfig['id']) => void }) {
  return (
    <GlassCard style={styles.skillCard}>
      <View style={styles.skillHeader}>
        <View style={[styles.skillIcon, { backgroundColor: `${skill.accent}1A` }]}>
          <Icon name={skill.icon as IconName} size={22} color={skill.accent} />
        </View>
        <View style={styles.skillHeading}>
          <Text style={styles.skillName}>{skill.name}</Text>
          <View style={styles.connectionLine}>
            <View style={[styles.connectionDot, { backgroundColor: skill.isAuthorized ? colors.emerald : colors.textDim }]} />
            <Text style={[styles.connectionText, skill.isAuthorized && { color: colors.emerald }]}>{skill.isAuthorized ? 'Authorized' : 'Permission needed'}</Text>
          </View>
        </View>
        <Switch value={skill.isAuthorized} onValueChange={() => onToggle(skill.id)} trackColor={{ false: colors.cardMuted, true: `${skill.accent}90` }} thumbColor={skill.isAuthorized ? skill.accent : colors.textMuted} accessibilityLabel={`Toggle ${skill.name} permission`} />
      </View>
      <Text style={styles.skillDescription}>{skill.description}</Text>
      <View style={styles.capabilities}>
        {skill.capabilities.map((capability) => (
          <View key={capability} style={styles.capability}>
            <Icon name="checkmark" size={12} color={skill.accent} />
            <Text style={styles.capabilityText}>{capability}</Text>
          </View>
        ))}
      </View>
      <View style={styles.skillFooter}>
        <Text style={styles.sampleText}>Try: "{skill.sampleCommands[0]}"</Text>
        <PrimaryButton label="Test prompt" icon="arrow-forward" variant="secondary" onPress={() => onTest(skill)} />
      </View>
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  content: { paddingBottom: 122, gap: 17 },
  connectedBadge: { alignItems: 'flex-end', backgroundColor: '#40D99B18', borderWidth: 1, borderColor: '#40D99B45', borderRadius: 12, paddingHorizontal: 10, paddingVertical: 7 },
  headerActions: { alignItems: 'flex-end', gap: 7 },
  connectedNumber: { color: colors.emerald, fontFamily: fonts.bold, fontSize: 16 },
  connectedLabel: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 10 },
  searchBox: { marginHorizontal: 18, minHeight: 48, flexDirection: 'row', alignItems: 'center', gap: 9, paddingHorizontal: 13, borderWidth: 1, borderColor: colors.border, borderRadius: 14, backgroundColor: colors.card },
  searchInput: { flex: 1, color: colors.text, fontFamily: fonts.regular, fontSize: 13, minHeight: 46 },
  infoBanner: { flexDirection: 'row', gap: 10, marginHorizontal: 18, padding: 12, borderRadius: 14, borderWidth: 1, borderColor: '#18D7E840', backgroundColor: '#18D7E810' },
  infoIcon: { width: 31, height: 31, borderRadius: 10, alignItems: 'center', justifyContent: 'center', backgroundColor: '#18D7E820' },
  infoCopy: { flex: 1, gap: 3 },
  infoTitle: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 12 },
  infoText: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 11, lineHeight: 16 },
  skillSection: { gap: 11, paddingHorizontal: 18 },
  skillCard: { padding: 14, gap: 12 },
  skillHeader: { flexDirection: 'row', alignItems: 'center', gap: 11 },
  skillIcon: { width: 43, height: 43, borderRadius: 13, alignItems: 'center', justifyContent: 'center' },
  skillHeading: { flex: 1, gap: 5 },
  skillName: { color: colors.text, fontFamily: fonts.semibold, fontSize: 16 },
  connectionLine: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  connectionDot: { width: 6, height: 6, borderRadius: 3 },
  connectionText: { color: colors.textDim, fontFamily: fonts.medium, fontSize: 11 },
  skillDescription: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12, lineHeight: 18 },
  capabilities: { flexDirection: 'row', flexWrap: 'wrap', gap: 7 },
  capability: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingHorizontal: 8, paddingVertical: 6, borderRadius: 8, backgroundColor: colors.cardRaised },
  capabilityText: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 10 },
  skillFooter: { gap: 10, paddingTop: 2 },
  sampleText: { color: colors.textDim, fontFamily: fonts.regular, fontSize: 11, fontStyle: 'italic' },
  emptyCard: { alignItems: 'center', gap: 7, paddingVertical: 30 },
  emptyTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 15 },
  emptyText: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12, textAlign: 'center' },
  errorCard: { marginHorizontal: 18, flexDirection: 'row', alignItems: 'center', gap: 9, borderColor: colors.red },
  errorText: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, flex: 1 },
  dismissText: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 11 },
});
EOF
echo "✅ app/(tabs)/skills.tsx"

cat > app/\(tabs\)/activity.tsx << 'EOF'
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
EOF
echo "✅ app/(tabs)/activity.tsx"

echo ""
echo "🎉🎉🎉 مرحله ۷f تمام شد! تمام صفحات ساخته شد!"
echo ""
echo "📊 چک نهایی:"
find . -type f -not -path './node_modules/*' | sort
