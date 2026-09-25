import { useCallback, useMemo, useState } from 'react';
import { KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useLocalSearchParams, useRouter } from 'expo-router';
import { colors, fonts, radii } from '@/constants/Theme';
import { GlassCard, Icon, type IconName, PrimaryButton, uiStyles } from '@/components/nexus-ui';
import { useAppStore } from '@/store/useAppStore';
import type { ActionStep, Routine, SkillId } from '@/store/types';

const iconChoices: IconName[] = ['sunny-outline', 'moon-outline', 'sparkles-outline', 'navigate-outline', 'home-outline', 'time-outline'];

const colorChoices = ['#18D7E8', '#8C7CFF', '#B06CFF', '#F5A742', '#40D99B', '#E667F0'];

const skillChoices: { id: SkillId; label: string; icon: IconName }[] = [
  { id: 'messages', label: 'Messages', icon: 'chatbubble-outline' },
  { id: 'calendar', label: 'Calendar', icon: 'calendar-outline' },
  { id: 'reminders', label: 'Notes', icon: 'checkbox-outline' },
  { id: 'smarthome', label: 'Smart Home', icon: 'home-outline' },
  { id: 'system', label: 'System', icon: 'options-outline' },
  { id: 'web', label: 'Web', icon: 'globe-outline' },
];

const makeStepId = () => `step-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`;

export default function RoutineBuilderScreen() {
  const router = useRouter();
  const params = useLocalSearchParams<{ routineId?: string | string[] }>();
  const routineId = typeof params.routineId === 'string' ? params.routineId : params.routineId?.[0];
  const routines = useAppStore((state) => state.routines);
  const addRoutine = useAppStore((state) => state.addRoutine);
  const updateRoutine = useAppStore((state) => state.updateRoutine);

  const sourceRoutine = useMemo(() => routines.find((item) => item.id === routineId), [routineId, routines]);

  const [title, setTitle] = useState(sourceRoutine?.title ?? 'New routine');
  const [icon, setIcon] = useState<IconName>((sourceRoutine?.icon as IconName) ?? 'sparkles-outline');
  const [color, setColor] = useState(sourceRoutine?.color ?? colors.cyan);
  const [triggerType, setTriggerType] = useState<Routine['triggerType']>(sourceRoutine?.triggerType ?? 'manual');
  const [triggerValue, setTriggerValue] = useState(sourceRoutine?.triggerValue ?? 'Manual tap');
  const [steps, setSteps] = useState<ActionStep[]>(sourceRoutine?.steps ?? []);
  const [showSkillPicker, setShowSkillPicker] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const addStep = useCallback((skill: (typeof skillChoices)[number]) => {
    setSteps((current) => [...current, { id: makeStepId(), skill: skill.id, action: 'custom_action', description: `${skill.label} action`, params: {} }]);
    setShowSkillPicker(false);
  }, []);

  const removeStep = useCallback((id: string) => {
    setSteps((current) => current.filter((step) => step.id !== id));
  }, []);

  const moveStep = useCallback((index: number, direction: -1 | 1) => {
    setSteps((current) => {
      const next = [...current];
      const target = index + direction;
      if (target < 0 || target >= next.length) return current;
      [next[index], next[target]] = [next[target], next[index]];
      return next;
    });
  }, []);

  const saveRoutine = useCallback(() => {
    if (!title.trim()) {
      setFormError('Give the routine a name before saving.');
      return;
    }
    if (steps.length === 0) {
      setFormError('Add at least one action step.');
      return;
    }
    const payload: Routine = {
      id: sourceRoutine?.id ?? `routine-${Date.now()}`,
      title: title.trim(),
      icon,
      color,
      triggerType,
      triggerValue,
      isEnabled: sourceRoutine?.isEnabled ?? true,
      steps,
    };
    if (sourceRoutine) {
      updateRoutine(sourceRoutine.id, payload);
    } else {
      addRoutine(payload);
    }
    router.back();
  }, [addRoutine, color, icon, router, sourceRoutine, steps, title, triggerType, triggerValue, updateRoutine]);

  return (
    <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={uiStyles.screen}>
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
        <View style={styles.modalHeader}>
          <Pressable accessibilityRole="button" onPress={() => router.back()} style={styles.headerAction}>
            <Text style={styles.cancelText}>Cancel</Text>
          </Pressable>
          <View style={styles.headerTitleWrap}>
            <Text style={styles.headerKicker}>ROUTINE</Text>
            <Text style={styles.headerTitle}>{sourceRoutine ? 'Edit routine' : 'New routine'}</Text>
          </View>
          <Pressable accessibilityRole="button" onPress={saveRoutine} style={styles.saveButton}>
            <Text style={styles.saveText}>Save</Text>
          </Pressable>
        </View>

        <View style={styles.formSection}>
          <Text style={styles.sectionLabel}>Identity</Text>
          <GlassCard style={styles.identityCard}>
            <TextInput
              value={title}
              onChangeText={setTitle}
              placeholder="Routine name"
              placeholderTextColor={colors.textDim}
              style={styles.titleInput}
              accessibilityLabel="Routine title"
            />
            <View style={styles.divider} />
            <Text style={styles.fieldLabel}>Icon</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.iconScroll} contentContainerStyle={styles.iconContent}>
              {iconChoices.map((choice) => (
                <Pressable
                  key={choice}
                  accessibilityRole="button"
                  accessibilityState={{ selected: icon === choice }}
                  onPress={() => setIcon(choice)}
                  style={[styles.iconChoice, icon === choice && { borderColor: colors.cyan }]}
                >
                  <Icon name={choice} size={18} color={icon === choice ? colors.cyan : colors.textMuted} />
                </Pressable>
              ))}
            </ScrollView>
            <Text style={styles.fieldLabel}>Accent color</Text>
            <View style={styles.colorRow}>
              {colorChoices.map((choice) => (
                <Pressable
                  key={choice}
                  accessibilityRole="button"
                  accessibilityState={{ selected: color === choice }}
                  onPress={() => setColor(choice)}
                  style={[styles.colorChoice, { backgroundColor: choice }, color === choice && styles.colorChoiceSelected]}
                />
              ))}
            </View>
          </GlassCard>
        </View>

        <View style={styles.formSection}>
          <Text style={styles.sectionLabel}>Trigger type</Text>
          <GlassCard style={styles.triggerCard}>
            <View style={styles.segmented}>
              {([['manual', 'Manual tap', 'hand-left-outline'], ['schedule', 'Time schedule', 'time-outline'], ['voice', 'Voice keyword', 'mic-outline']] as const).map(([value, label, triggerIcon]) => (
                <Pressable
                  key={value}
                  accessibilityRole="button"
                  accessibilityState={{ selected: triggerType === value }}
                  onPress={() => {
                    setTriggerType(value);
                    setTriggerValue(value === 'manual' ? 'Manual tap' : value === 'schedule' ? '08:00 AM' : 'Run this routine');
                  }}
                  style={[styles.segment, triggerType === value && styles.segmentActive]}
                >
                  <Icon name={triggerIcon} size={15} color={triggerType === value ? colors.cyan : colors.textMuted} />
                  <Text style={[styles.segmentText, triggerType === value && styles.segmentTextActive]}>{label}</Text>
                </Pressable>
              ))}
            </View>
            <TextInput
              value={triggerValue}
              onChangeText={setTriggerValue}
              placeholder={triggerType === 'voice' ? 'Say a phrase...' : 'Time or trigger value'}
              placeholderTextColor={colors.textDim}
              style={styles.triggerInput}
              accessibilityLabel="Trigger value"
            />
          </GlassCard>
        </View>

        <View style={styles.formSection}>
          <View style={styles.pipelineHeader}>
            <Text style={styles.sectionLabel}>Action pipeline</Text>
            <Text style={styles.stepTotal}>{steps.length} {steps.length === 1 ? 'step' : 'steps'}</Text>
          </View>
          <View style={styles.pipeline}>
            {steps.map((step, index) => (
              <StepEditor key={step.id} step={step} index={index} total={steps.length} onRemove={removeStep} onMove={moveStep} />
            ))}
          </View>
          {showSkillPicker ? (
            <GlassCard style={styles.skillPicker}>
              <Text style={styles.pickerTitle}>Choose an adapter</Text>
              <View style={styles.pickerGrid}>
                {skillChoices.map((skill) => (
                  <Pressable key={skill.id} accessibilityRole="button" onPress={() => addStep(skill)} style={styles.pickerItem}>
                    <Icon name={skill.icon} size={18} color={colors.cyan} />
                    <Text style={styles.pickerLabel}>{skill.label}</Text>
                  </Pressable>
                ))}
              </View>
            </GlassCard>
          ) : (
            <Pressable accessibilityRole="button" onPress={() => setShowSkillPicker(true)} style={styles.addStep}>
              <Icon name="add-circle-outline" size={19} color={colors.cyan} />
              <Text style={styles.addStepText}>Add action step</Text>
            </Pressable>
          )}
        </View>

        {formError ? <Text selectable style={styles.formError}>{formError}</Text> : null}

        <PrimaryButton label={sourceRoutine ? 'Save changes' : 'Create routine'} icon="checkmark" onPress={saveRoutine} />
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

function StepEditor({ step, index, total, onRemove, onMove }: { step: ActionStep; index: number; total: number; onRemove: (id: string) => void; onMove: (index: number, direction: -1 | 1) => void }) {
  const icon = skillChoices.find((choice) => choice.id === step.skill)?.icon ?? 'flash-outline';
  return (
    <GlassCard style={styles.stepCard}>
      <View style={styles.stepCardTop}>
        <View style={styles.stepNumber}>
          <Text style={styles.stepNumberText}>{String(index + 1).padStart(2, '0')}</Text>
        </View>
        <View style={styles.stepCopy}>
          <Text style={styles.stepSkill}>{step.skill.toUpperCase()} - {step.action}</Text>
          <Text style={styles.stepDescription}>{step.description}</Text>
        </View>
        <Icon name={icon} size={18} color={colors.cyan} />
      </View>
      <View style={styles.stepControls}>
        <Pressable accessibilityRole="button" accessibilityLabel="Move step up" disabled={index === 0} onPress={() => onMove(index, -1)} style={styles.smallControl}>
          <Icon name="chevron-up" size={16} color={index === 0 ? colors.textDim : colors.textMuted} />
        </Pressable>
        <Pressable accessibilityRole="button" accessibilityLabel="Move step down" disabled={index === total - 1} onPress={() => onMove(index, 1)} style={styles.smallControl}>
          <Icon name="chevron-down" size={16} color={index === total - 1 ? colors.textDim : colors.textMuted} />
        </Pressable>
        <Pressable accessibilityRole="button" accessibilityLabel={`Remove ${step.description}`} onPress={() => onRemove(step.id)} style={styles.removeControl}>
          <Icon name="trash-outline" size={15} color={colors.red} />
        </Pressable>
      </View>
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 18, paddingBottom: 40, gap: 21 },
  modalHeader: { minHeight: 53, flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  headerAction: { minWidth: 70, minHeight: 42, justifyContent: 'center' },
  cancelText: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 13 },
  headerTitleWrap: { alignItems: 'center', gap: 3 },
  headerKicker: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 9, letterSpacing: 1.2 },
  headerTitle: { color: colors.text, fontFamily: fonts.bold, fontSize: 17 },
  saveButton: { minWidth: 70, minHeight: 38, alignItems: 'flex-end', justifyContent: 'center' },
  saveText: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 13 },
  formSection: { gap: 10 },
  sectionLabel: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 11, letterSpacing: 1.1, textTransform: 'uppercase' },
  identityCard: { gap: 13 },
  titleInput: { color: colors.text, fontFamily: fonts.semibold, fontSize: 18, minHeight: 38 },
  divider: { height: 1, backgroundColor: colors.border },
  fieldLabel: { color: colors.textDim, fontFamily: fonts.medium, fontSize: 11 },
  iconScroll: { flexGrow: 0 },
  iconContent: { gap: 8, paddingVertical: 2 },
  iconChoice: { width: 40, height: 40, borderRadius: 12, alignItems: 'center', justifyContent: 'center', borderWidth: 1, borderColor: colors.border, backgroundColor: colors.cardRaised },
  colorRow: { flexDirection: 'row', gap: 12 },
  colorChoice: { width: 27, height: 27, borderRadius: 14, alignItems: 'center', justifyContent: 'center' },
  colorChoiceSelected: { borderWidth: 3, borderColor: colors.text },
  triggerCard: { gap: 14 },
  segmented: { flexDirection: 'row', gap: 5 },
  segment: { flex: 1, minHeight: 46, alignItems: 'center', justifyContent: 'center', gap: 4, borderRadius: 10, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.cardRaised, paddingHorizontal: 4 },
  segmentActive: { borderColor: colors.cyan, backgroundColor: '#18D7E818' },
  segmentText: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 10, textAlign: 'center' },
  segmentTextActive: { color: colors.cyan },
  triggerInput: { minHeight: 45, color: colors.text, fontFamily: fonts.regular, fontSize: 13, paddingHorizontal: 12, borderRadius: 11, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.backgroundRaised },
  pipelineHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  stepTotal: { color: colors.textDim, fontFamily: fonts.medium, fontSize: 11 },
  pipeline: { gap: 9 },
  stepCard: { padding: 12, gap: 10 },
  stepCardTop: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  stepNumber: { width: 34, height: 34, borderRadius: 11, alignItems: 'center', justifyContent: 'center', backgroundColor: '#18D7E818', borderWidth: 1, borderColor: '#18D7E840' },
  stepNumberText: { color: colors.cyan, fontFamily: 'monospace', fontSize: 11 },
  stepCopy: { flex: 1, gap: 4 },
  stepSkill: { color: colors.violetSoft, fontFamily: 'monospace', fontSize: 9 },
  stepDescription: { color: colors.text, fontFamily: fonts.medium, fontSize: 13 },
  stepControls: { flexDirection: 'row', justifyContent: 'flex-end', gap: 7 },
  smallControl: { width: 30, height: 28, alignItems: 'center', justifyContent: 'center', borderRadius: 8, borderWidth: 1, borderColor: colors.border },
  removeControl: { width: 30, height: 28, alignItems: 'center', justifyContent: 'center', borderRadius: 8, borderWidth: 1, borderColor: '#FF687F40', backgroundColor: '#FF687F0D' },
  addStep: { minHeight: 49, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, borderRadius: 13, borderWidth: 1, borderStyle: 'dashed', borderColor: colors.cyan, backgroundColor: '#18D7E808' },
  addStepText: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 13 },
  skillPicker: { gap: 13, borderColor: colors.cyan },
  pickerTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 14 },
  pickerGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  pickerItem: { width: '31%', minHeight: 65, alignItems: 'center', justifyContent: 'center', gap: 5, borderRadius: 10, backgroundColor: colors.cardRaised },
  pickerLabel: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 10, textAlign: 'center' },
  formError: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, lineHeight: 18 },
});
