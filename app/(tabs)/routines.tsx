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
