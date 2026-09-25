#!/data/data/com.termux/files/usr/bin/bash
cd ~/Hoshyar

echo "📦 مرحله ۷b: assistant + voice..."

cat > app/\(tabs\)/index.tsx << 'EOF'
import { useCallback, useEffect, useMemo, useState } from 'react';
import { KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useRouter } from 'expo-router';
import { colors, fonts, radii } from '@/constants/Theme';
import { ErrorState, LoadingState } from '@/components/screen-state';
import { GlassCard, GlowDot, Icon, PrimaryButton, SectionLabel, uiStyles } from '@/components/nexus-ui';
import { useAppReady } from '@/hooks/use-app-ready';
import { useAppStore } from '@/store/useAppStore';
import type { ParameterValue, SkillId } from '@/store/types';
import { parseCommand, type ParsedCommand } from '@/services/command-parser';
import { parseCommandWithAi } from '@/services/ai-intent';
import { executeCommand } from '@/services/command-executor';
import { speakText } from '@/services/speech';
import type { TaskRun } from '@/services/task-engine';

interface ParsedIntent {
  intent: string;
  skill: SkillId;
  label: string;
  detail: string;
  parameters: Record<string, ParameterValue>;
  confidence: number;
  command?: ParsedCommand;
}

interface DialogueItem {
  id: string;
  role: 'user' | 'assistant';
  text: string;
}

const quickActions = [
  { label: 'Schedule event', icon: 'calendar-outline' as const, prompt: 'Schedule a team sync tomorrow at 10 AM' },
  { label: 'Send message', icon: 'chatbubble-outline' as const, prompt: 'Send Maya a quick update that I am 10 mins away' },
  { label: 'Summarize note', icon: 'document-text-outline' as const, prompt: 'Summarize my product launch note' },
  { label: 'Toggle DND', icon: 'moon-outline' as const, prompt: 'Turn on Do Not Disturb for one hour' },
  { label: 'Run morning', icon: 'sparkles-outline' as const, prompt: 'Run Morning Kickoff routine' },
];

const starterDialogue: DialogueItem[] = [
  { id: 'welcome', role: 'assistant', text: 'Good morning. What should I move forward for you?' },
  { id: 'example', role: 'user', text: 'Schedule team sync tomorrow at 10 AM and alert Maya on Slack' },
  { id: 'parsed', role: 'assistant', text: 'I split that into two safe-to-run steps and found all required details.' },
];

function intentFromCommand(command: ParsedCommand): ParsedIntent {
  return {
    intent: `Hoshyar.${command.action}`,
    skill: command.skill,
    label: command.title,
    detail: command.detail,
    parameters: {
      recipient: command.recipient ?? '',
      message: command.message ?? '',
      messenger: command.messenger ?? '',
      target: command.systemTarget ?? command.appName ?? '',
    },
    confidence: command.confidence,
    command,
  };
}

function resolveIntent(input: string): ParsedIntent {
  const command = parseCommand(input);
  if (command.action !== 'unknown') return intentFromCommand(command);
  const normalized = input.toLowerCase();
  if (normalized.includes('schedule') || normalized.includes('calendar') || normalized.includes('event')) {
    return { intent: 'Calendar.create_event', skill: 'calendar', label: 'Create calendar event', detail: 'Team Sync - Tomorrow, 10:00 AM', parameters: { title: 'Team Sync', time: 'Tomorrow 10:00 AM', participants: ['Sarah', 'Alex'] }, confidence: 0.96 };
  }
  if (normalized.includes('message') || normalized.includes('maya') || normalized.includes('slack') || normalized.includes('tell')) {
    return { intent: 'Messages.send_message', skill: 'messages', label: 'Send message', detail: 'Maya - "I am 10 mins away"', parameters: { recipient: 'Maya', channel: 'Slack', message: 'I am 10 mins away' }, confidence: 0.94 };
  }
  if (normalized.includes('dnd') || normalized.includes('disturb') || normalized.includes('silent')) {
    return { intent: 'System.set_dnd', skill: 'system', label: 'Do Not Disturb', detail: 'Android permission-controlled action', parameters: { enabled: true }, confidence: 0.4, command: parseCommand(input) };
  }
  if (normalized.includes('summarize') || normalized.includes('note')) {
    return { intent: 'Notes.summarize_note', skill: 'notes', label: 'Summarize note', detail: 'Product launch note - 4 key points', parameters: { note: 'Product launch', output: 'Key points' }, confidence: 0.89 };
  }
  return { intent: 'Web.knowledge_search', skill: 'web', label: 'Knowledge search', detail: 'Search and synthesize an answer', parameters: { query: input, source: 'Nexus web index' }, confidence: 0.73 };
}

async function parseSubmittedIntent(input: string): Promise<ParsedIntent> {
  try {
    let parsed = resolveIntent(input);
    if (!parsed.command && parseCommand(input).action === 'unknown') {
      const aiCommand = await parseCommandWithAi(input);
      if (aiCommand) parsed = intentFromCommand(aiCommand);
    }
    return parsed;
  } catch (cause: unknown) {
    console.error('Command parsing failed', cause);
    return resolveIntent(input);
  }
}

export default function AssistantScreen() {
  const router = useRouter();
  const { ready, error, retry } = useAppReady();
  const addLog = useAppStore((state) => state.addLog);
  const draftCommand = useAppStore((state) => state.draftCommand);
  const setDraftCommand = useAppStore((state) => state.setDraftCommand);
  const preferences = useAppStore((state) => state.preferences);

  const [input, setInput] = useState('');
  const [dialogue, setDialogue] = useState<DialogueItem[]>(starterDialogue);
  const [intent, setIntent] = useState<ParsedIntent | null>(null);
  const [isParsing, setIsParsing] = useState(false);
  const [activeTask, setActiveTask] = useState<TaskRun | null>(null);
  const [screenError, setScreenError] = useState<string | null>(null);

  const language = useMemo(() => (preferences.voiceLanguage?.startsWith('fa') ? 'fa' : 'en'), [preferences.voiceLanguage]);

  useEffect(() => {
    if (draftCommand) {
      setInput(draftCommand);
      setDraftCommand(null);
    }
  }, [draftCommand, setDraftCommand]);

  useEffect(() => {
    return () => {
      activeTask?.cancel();
    };
  }, [activeTask]);

  const appendDialogue = useCallback((item: Omit<DialogueItem, 'id'>) => {
    setDialogue((current) => [...current, { ...item, id: `${item.role}-${Date.now()}` }]);
  }, []);

  const submit = useCallback(async () => {
    const trimmed = input.trim();
    if (!trimmed) return;
    setScreenError(null);
    setIsParsing(true);
    appendDialogue({ role: 'user', text: trimmed });
    setInput('');
    try {
      const parsed = await parseSubmittedIntent(trimmed);
      setIntent(parsed);
      appendDialogue({ role: 'assistant', text: parsed.detail });
    } catch (cause: unknown) {
      console.error('Command submission failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'That command could not be processed.');
    } finally {
      setIsParsing(false);
    }
  }, [appendDialogue, input]);

  const confirmAndExecute = useCallback(() => {
    if (!intent?.command) return;
    try {
      const result = executeCommand(intent.command, (step, total, label) => {
        appendDialogue({ role: 'assistant', text: `Step ${step + 1}/${total}: ${label}` });
      });
      setActiveTask(result.task);
      result.task.promise
        .then(() => {
          addLog({ userInput: intent.command!.original, intent: intent.intent, skill: intent.skill, parameters: intent.parameters, status: 'success', executionTimeMs: 0, summary: result.summary });
          appendDialogue({ role: 'assistant', text: `Done. ${result.summary}` });
        })
        .catch((cause: unknown) => {
          const message = cause instanceof Error ? cause.message : 'The task could not be completed.';
          addLog({ userInput: intent.command!.original, intent: intent.intent, skill: intent.skill, parameters: intent.parameters, status: 'failed', executionTimeMs: 0, summary: message });
          setScreenError(message);
        })
        .finally(() => {
          setActiveTask(null);
          setIntent(null);
        });
    } catch (cause: unknown) {
      console.error('Command execution failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'The command could not be executed.');
    }
  }, [addLog, appendDialogue, intent]);

  const cancelIntent = useCallback(() => {
    setIntent(null);
    appendDialogue({ role: 'assistant', text: 'Cancelled. Nothing was executed.' });
  }, [appendDialogue]);

  const runQuickAction = useCallback((prompt: string) => {
    setInput(prompt);
  }, []);

  if (!ready && !error) return <LoadingState />;
  if (error) return <ErrorState message={error} onRetry={retry} />;

  return (
    <View style={uiStyles.screen}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={styles.flex}>
        <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
          <View style={uiStyles.header}>
            <View>
              <Text style={uiStyles.headerTitle}>Hoshyar</Text>
              <View style={styles.statusLine}><GlowDot /><Text style={styles.statusText}>Gateway ready</Text></View>
            </View>
            <View style={styles.headerActions}>
              <Pressable accessibilityRole="button" accessibilityLabel="Toggle Persian and English" onPress={() => setDraftCommand(null)} style={styles.languageButton}>
                <Text style={styles.languageText}>{language === 'fa' ? 'FA' : 'EN'}</Text>
              </Pressable>
              <Pressable accessibilityRole="button" accessibilityLabel="Clear conversation" onPress={() => setDialogue(starterDialogue)} style={styles.gatewayBadge}>
                <Icon name="sparkles" size={13} color={colors.cyan} />
                <Text style={styles.gatewayText}>AI Gateway Ready</Text>
              </Pressable>
            </View>
          </View>

          <GlassCard style={styles.nextCard}>
            <View style={styles.nextTop}>
              <View style={styles.nextIcon}><Icon name="time-outline" size={14} color={colors.cyan} /></View>
              <Text style={styles.eyebrow}>NEXT UP</Text>
              <Text style={styles.nextTime}>in 42 min</Text>
            </View>
            <Text style={styles.nextTitle}>Product Review at 2:00 PM</Text>
            <Pressable accessibilityRole="button" onPress={() => runQuickAction('Draft a Running late message for the Product Review')} style={styles.draftLink}>
              <Icon name="create-outline" size={14} color={colors.cyanSoft} />
              <Text style={styles.draftText}>Draft Running late message</Text>
            </Pressable>
          </GlassCard>

          <View style={styles.sectionBlock}>
            <SectionLabel>Quick intents</SectionLabel>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipScroll} contentContainerStyle={styles.chipContent}>
              {quickActions.map((action) => (
                <Pressable key={action.label} accessibilityRole="button" onPress={() => runQuickAction(action.prompt)} style={styles.intentChip}>
                  <Icon name={action.icon} size={15} color={colors.cyan} />
                  <Text style={styles.chipText}>{action.label}</Text>
                </Pressable>
              ))}
            </ScrollView>
          </View>

          <View style={styles.sectionBlock}>
            <View style={styles.dialogueHeader}>
              <SectionLabel>Active dialogue</SectionLabel>
              <View style={styles.liveBadge}><GlowDot size={6} /><Text style={styles.liveText}>Live</Text></View>
            </View>
            <View style={styles.dialogue}>
              {dialogue.map((item) => (
                <View key={item.id} style={[styles.messageRow, item.role === 'user' && styles.messageRowUser]}>
                  <View style={[styles.avatar, item.role === 'user' ? styles.avatarUser : styles.avatarAssistant]}>
                    <Icon name={item.role === 'user' ? 'person' : 'sparkles'} size={13} color={item.role === 'user' ? colors.violetSoft : colors.cyan} />
                  </View>
                  <View style={[styles.messageBubble, item.role === 'user' ? styles.userBubble : styles.assistantBubble]}>
                    <Text style={styles.messageText}>{item.text}</Text>
                  </View>
                </View>
              ))}
            </View>
          </View>

          {intent ? (
            <GlassCard style={styles.intentCard}>
              <View style={styles.intentCardTop}>
                <View style={styles.flex}>
                  <Text style={styles.intentKicker}>INTENT RESOLVED</Text>
                  <Text style={styles.intentTitle}>{intent.label}</Text>
                </View>
                <View style={styles.confidence}>
                  <Text style={styles.confidenceValue}>{Math.round(intent.confidence * 100)}%</Text>
                  <Text style={styles.confidenceLabel}>confidence</Text>
                </View>
              </View>
              <View style={styles.intentDivider} />
              <View style={styles.intentMeta}>
                <Icon name="flash" size={13} color={colors.violetSoft} />
                <Text style={styles.intentName}>{intent.intent}</Text>
              </View>
              <Text style={styles.intentDetail}>{intent.detail}</Text>
              <View style={styles.parameterRow}>
                {Object.entries(intent.parameters).map(([key, value]) => (
                  <View key={key} style={styles.parameter}>
                    <Text style={styles.parameterKey}>{key}</Text>
                    <Text numberOfLines={1} style={styles.parameterValue}>{Array.isArray(value) ? value.join(', ') : String(value ?? '')}</Text>
                  </View>
                ))}
              </View>
              <View style={styles.intentActions}>
                <PrimaryButton label="Edit" icon="create-outline" variant="secondary" onPress={() => setInput(intent.command?.original ?? '')} />
                <View style={styles.confirmWrap}>
                  <PrimaryButton label="Cancel" icon="close-outline" variant="quiet" onPress={cancelIntent} />
                </View>
                <View style={styles.confirmWrap}>
                  <PrimaryButton label={activeTask ? 'Executing...' : 'Confirm & Execute'} icon="checkmark" onPress={confirmAndExecute} disabled={Boolean(activeTask)} />
                </View>
              </View>
            </GlassCard>
          ) : null}

          {activeTask ? (
            <View style={styles.taskControls}>
              <PrimaryButton label="Pause" icon="pause" variant="secondary" onPress={activeTask.pause} />
              <PrimaryButton label="Resume" icon="play" variant="secondary" onPress={activeTask.resume} />
              <PrimaryButton label="Cancel task" icon="close-circle-outline" variant="quiet" onPress={activeTask.cancel} />
            </View>
          ) : null}

          {screenError ? <Text selectable style={styles.inlineError}>{screenError}</Text> : null}

          <View style={styles.composerShell}>
            <View style={styles.composerIcon}><Icon name="sparkles" size={16} color={colors.violetSoft} /></View>
            <TextInput
              value={input}
              onChangeText={setInput}
              onSubmitEditing={submit}
              placeholder="Type a command or tap the mic"
              placeholderTextColor={colors.textDim}
              style={styles.input}
              returnKeyType="send"
              editable={!isParsing}
              accessibilityLabel="Command input"
            />
            <Pressable accessibilityRole="button" accessibilityLabel="Open voice assistant" onPress={() => router.push('/voice')} style={styles.micButton}>
              <Icon name="mic" size={17} color={colors.cyan} />
            </Pressable>
            <Pressable accessibilityRole="button" accessibilityLabel="Send command" onPress={submit} disabled={isParsing || !input.trim()} style={styles.sendButton}>
              <Icon name="arrow-up" size={17} color={colors.background} />
            </Pressable>
          </View>

          <Text style={styles.helperText}>Safe execution is on. Hoshyar will always show the payload before dispatch.</Text>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  content: { paddingBottom: 122, gap: 17 },
  statusLine: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 4 },
  statusText: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 12 },
  headerActions: { alignItems: 'flex-end', gap: 10 },
  languageButton: { minWidth: 42, minHeight: 34, alignItems: 'center', justifyContent: 'center', borderRadius: 11, borderWidth: 1, borderColor: colors.borderBright, backgroundColor: colors.card },
  languageText: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 11 },
  gatewayBadge: { flexDirection: 'row', alignItems: 'center', gap: 5, paddingHorizontal: 10, paddingVertical: 8, borderRadius: radii.pill, borderWidth: 1, borderColor: colors.cyan, backgroundColor: '#18D7E812' },
  gatewayText: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 11 },
  nextCard: { marginHorizontal: 18, padding: 17, borderColor: '#3A4660', backgroundColor: '#192236' },
  nextTop: { flexDirection: 'row', alignItems: 'center', gap: 7, marginBottom: 10 },
  nextIcon: { width: 26, height: 26, borderRadius: 9, backgroundColor: '#18D7E81A', alignItems: 'center', justifyContent: 'center' },
  eyebrow: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 10, letterSpacing: 1.2 },
  nextTime: { marginLeft: 'auto', color: colors.textDim, fontFamily: fonts.medium, fontSize: 11 },
  nextTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 20, letterSpacing: -0.4 },
  draftLink: { flexDirection: 'row', alignItems: 'center', gap: 7, marginTop: 14, minHeight: 30 },
  draftText: { color: colors.cyanSoft, fontFamily: fonts.medium, fontSize: 13, flex: 1 },
  sectionBlock: { gap: 10 },
  dialogueHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 18 },
  liveBadge: { flexDirection: 'row', alignItems: 'center', gap: 5, paddingHorizontal: 9, paddingVertical: 5, borderRadius: radii.pill, backgroundColor: '#18D7E814' },
  liveText: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 10 },
  chipScroll: { flexGrow: 0 },
  chipContent: { gap: 8, paddingRight: 18, paddingLeft: 18 },
  intentChip: { flexDirection: 'row', alignItems: 'center', gap: 7, backgroundColor: colors.card, borderWidth: 1, borderColor: colors.border, borderRadius: radii.pill, paddingHorizontal: 12, minHeight: 38 },
  chipText: { color: colors.text, fontFamily: fonts.medium, fontSize: 12 },
  dialogue: { gap: 12 },
  messageRow: { flexDirection: 'row', alignItems: 'flex-end', gap: 8, paddingHorizontal: 18 },
  messageRowUser: { justifyContent: 'flex-end' },
  avatar: { width: 27, height: 27, borderRadius: 10, alignItems: 'center', justifyContent: 'center' },
  avatarAssistant: { backgroundColor: '#18D7E81A', borderWidth: 1, borderColor: '#18D7E860' },
  avatarUser: { backgroundColor: '#8C7CFF1A', borderWidth: 1, borderColor: '#8C7CFF55' },
  messageBubble: { maxWidth: '83%', paddingHorizontal: 14, paddingVertical: 11, borderRadius: 16 },
  assistantBubble: { backgroundColor: colors.card, borderTopLeftRadius: 5, borderWidth: 1, borderColor: colors.border },
  userBubble: { backgroundColor: '#303147', borderBottomRightRadius: 5 },
  messageText: { color: colors.text, fontFamily: fonts.regular, fontSize: 14, lineHeight: 20 },
  intentCard: { marginHorizontal: 18, borderColor: colors.violetSoft, borderWidth: 1, backgroundColor: '#1C2033' },
  intentCardTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  intentKicker: { color: colors.violetSoft, fontFamily: fonts.semibold, fontSize: 10, letterSpacing: 1.1, marginBottom: 5 },
  intentTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 18 },
  confidence: { alignItems: 'flex-end' },
  confidenceValue: { color: colors.cyan, fontFamily: fonts.bold, fontSize: 16 },
  confidenceLabel: { color: colors.textDim, fontFamily: fonts.regular, fontSize: 10 },
  intentDivider: { height: 1, backgroundColor: colors.border, marginVertical: 13 },
  intentMeta: { flexDirection: 'row', alignItems: 'center', gap: 7 },
  intentName: { color: colors.violetSoft, fontFamily: 'monospace', fontSize: 12 },
  intentDetail: { color: colors.text, fontFamily: fonts.medium, fontSize: 14, marginTop: 9 },
  parameterRow: { gap: 7, marginTop: 13 },
  parameter: { flexDirection: 'row', gap: 10, alignItems: 'center' },
  parameterKey: { width: 82, color: colors.textDim, fontFamily: 'monospace', fontSize: 11 },
  parameterValue: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12, flex: 1 },
  intentActions: { flexDirection: 'row', gap: 8, marginTop: 16 },
  confirmWrap: { flex: 1 },
  taskControls: { flexDirection: 'row', gap: 8, marginHorizontal: 18 },
  inlineError: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, marginTop: 10, lineHeight: 17, paddingHorizontal: 18 },
  composerShell: { flexDirection: 'row', alignItems: 'center', minHeight: 58, marginHorizontal: 18, paddingLeft: 10, paddingRight: 7, borderRadius: 18, borderWidth: 1, borderColor: colors.borderBright, backgroundColor: colors.card },
  composerIcon: { width: 32, height: 32, borderRadius: 10, alignItems: 'center', justifyContent: 'center', backgroundColor: '#8C7CFF18' },
  input: { flex: 1, color: colors.text, fontFamily: fonts.regular, fontSize: 13, paddingHorizontal: 10, minHeight: 48 },
  micButton: { width: 38, height: 38, borderRadius: 13, alignItems: 'center', justifyContent: 'center', backgroundColor: '#18D7E812' },
  sendButton: { width: 38, height: 38, borderRadius: 13, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.cyan },
  helperText: { color: colors.textDim, fontFamily: fonts.regular, fontSize: 11, textAlign: 'center', marginHorizontal: 24 },
});
EOF
echo "✅ app/(tabs)/index.tsx"

echo ""
echo "🎉 مرحله ۷b تمام شد! صفحه اصلی ساخته شد."
