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
