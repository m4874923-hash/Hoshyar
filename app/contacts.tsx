import { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, Alert, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { Stack, useRouter } from 'expo-router';
import { colors, fonts } from '@/constants/Theme';
import { GlassCard, Icon, PrimaryButton, uiStyles } from '@/components/nexus-ui';
import { findContactsByName, type ContactMatch } from '@/services/contacts';
import { openPhoneDialer } from '@/services/device-actions';

export default function ContactsScreen() {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [contacts, setContacts] = useState<ContactMatch[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadContacts = useCallback(async (name: string) => {
    setIsLoading(true);
    setError(null);
    try {
      setContacts(await findContactsByName(name));
    } catch (cause: unknown) {
      console.error('Contact directory failed to load', cause);
      setError(cause instanceof Error ? cause.message : 'The contact directory could not be loaded.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      void loadContacts('');
    }, 0);
    return () => clearTimeout(timer);
  }, [loadContacts]);

  const confirmCall = useCallback((contact: ContactMatch) => {
    Alert.alert('Confirm phone call', `Call ${contact.name}${contact.phoneNumber ? ` at ${contact.phoneNumber}` : ''}?`, [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Confirm & Execute',
        onPress: () => {
          void openPhoneDialer(contact.name, contact.phoneNumber).catch((cause: unknown) => {
            console.error('Confirmed contact call failed', cause);
            setError(cause instanceof Error ? cause.message : 'The phone dialer could not be opened.');
          });
        },
      },
    ]);
  }, []);

  return (
    <View style={uiStyles.screen}>
      <Stack.Screen options={{ title: 'Contacts', headerShown: false }} />
      <ScrollView contentInsetAdjustmentBehavior="automatic" contentContainerStyle={styles.content}>
        <View style={uiStyles.header}>
          <View><Text style={uiStyles.headerTitle}>Contacts</Text><Text style={uiStyles.headerSubtitle}>Search the device directory before an action.</Text></View>
          <Pressable accessibilityRole="button" accessibilityLabel="Close contacts" onPress={() => router.back()} style={uiStyles.iconButton}><Icon name="close" size={19} color={colors.textMuted} /></Pressable>
        </View>
        <View style={styles.searchShell}><Icon name="search-outline" size={18} color={colors.textMuted} /><TextInput value={query} onChangeText={setQuery} onSubmitEditing={() => { void loadContacts(query.trim()); }} placeholder="Search by name" placeholderTextColor={colors.textDim} style={styles.searchInput} returnKeyType="search" accessibilityLabel="Search contacts" /></View>
        {isLoading ? <View style={styles.state}><ActivityIndicator color={colors.cyan} size="large" /><Text style={styles.stateText}>Loading contacts...</Text></View> : null}
        {error ? <GlassCard style={styles.errorCard}><Icon name="warning-outline" size={19} color={colors.red} /><Text selectable style={styles.errorText}>{error}</Text><PrimaryButton label="Retry" icon="refresh-outline" variant="secondary" onPress={() => { void loadContacts(query.trim()); }} /></GlassCard> : null}
        {!isLoading && !error && contacts.length === 0 ? <GlassCard style={styles.emptyCard}><Icon name="people-outline" size={25} color={colors.textDim} /><Text style={styles.emptyTitle}>No contacts found</Text><Text style={styles.emptyText}>Grant contact access or try another name.</Text></GlassCard> : null}
        {!isLoading && !error ? contacts.map((contact) => <GlassCard key={contact.id} style={styles.contactCard}><View style={styles.contactIcon}><Icon name="person-outline" size={20} color={colors.cyan} /></View><View style={styles.contactCopy}><Text style={styles.contactName}>{contact.name}</Text><Text style={styles.contactNumber}>{contact.phoneNumber ?? 'No phone number'}</Text></View><Pressable accessibilityRole="button" accessibilityLabel={`Call ${contact.name}`} disabled={!contact.phoneNumber} onPress={() => confirmCall(contact)} style={[styles.callButton, !contact.phoneNumber && styles.callButtonDisabled]}><Icon name="call-outline" size={17} color={contact.phoneNumber ? colors.background : colors.textDim} /></Pressable></GlassCard>) : null}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  content: { paddingBottom: 32, gap: 14 },
  searchShell: { marginHorizontal: 18, minHeight: 48, flexDirection: 'row', alignItems: 'center', gap: 9, paddingHorizontal: 13, borderWidth: 1, borderColor: colors.border, borderRadius: 14, backgroundColor: colors.card },
  searchInput: { flex: 1, color: colors.text, fontFamily: fonts.regular, fontSize: 13, minHeight: 46 },
  state: { alignItems: 'center', gap: 10, paddingVertical: 40 },
  stateText: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 13 },
  errorCard: { marginHorizontal: 18, gap: 10, borderColor: colors.red },
  errorText: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, lineHeight: 17 },
  emptyCard: { marginHorizontal: 18, alignItems: 'center', gap: 7, paddingVertical: 30 },
  emptyTitle: { color: colors.text, fontFamily: fonts.semibold, fontSize: 15 },
  emptyText: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12, textAlign: 'center' },
  contactCard: { marginHorizontal: 18, flexDirection: 'row', alignItems: 'center', gap: 11, padding: 13 },
  contactIcon: { width: 40, height: 40, borderRadius: 13, alignItems: 'center', justifyContent: 'center', backgroundColor: '#18D7E81A' },
  contactCopy: { flex: 1, gap: 4 },
  contactName: { color: colors.text, fontFamily: fonts.semibold, fontSize: 15 },
  contactNumber: { color: colors.textMuted, fontFamily: fonts.regular, fontSize: 12 },
  callButton: { width: 42, height: 42, borderRadius: 13, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.cyan },
  callButtonDisabled: { backgroundColor: colors.cardMuted },
});
