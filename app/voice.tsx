import { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, Platform, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { useRouter } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { RecordingPresets, requestRecordingPermissionsAsync, useAudioRecorder } from 'expo-audio';
import { colors, fonts } from '@/constants/Theme';
import { ErrorState, LoadingState } from '@/components/screen-state';
import { Icon, PrimaryButton, VoiceOrb, uiStyles } from '@/components/nexus-ui';
import { useAppReady } from '@/hooks/use-app-ready';
import { useAppStore } from '@/store/useAppStore';
import type { CommandLanguage } from '@/services/command-parser';
import { speakText, startBrowserRecognition, transcribeRecordedAudio } from '@/services/speech';

const bars = [18, 31, 47, 27, 60, 35, 72, 43, 24, 54, 34, 67, 28, 50, 21];

export default function VoiceScreen() {
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { ready, error, retry } = useAppReady();
  const setDraftCommand = useAppStore((state) => state.setDraftCommand);
  const preferences = useAppStore((state) => state.preferences);
  const setVoiceLanguage = useAppStore((state) => state.setVoiceLanguage);
  const setSpeechSettings = useAppStore((state) => state.setSpeechSettings);
  const recorder = useAudioRecorder(RecordingPresets.LOW_QUALITY);
  const [listening, setListening] = useState(false);
  const [transcript, setTranscript] = useState('Press the orb to capture a command');
  const [language, setLanguage] = useState<CommandLanguage>(preferences.voiceLanguage?.startsWith('fa') ? 'fa' : 'en');
  const [isTranscribing, setIsTranscribing] = useState(false);
  const [speechRate, setSpeechRate] = useState(preferences.speechRate ?? 1);
  const [speechPitch, setSpeechPitch] = useState(preferences.speechPitch ?? 1);
  const [screenError, setScreenError] = useState<string | null>(null);
  const [browserStop, setBrowserStop] = useState<(() => void) | null>(null);

  useEffect(() => {
    return () => {
      browserStop?.();
    };
  }, [browserStop]);

  const close = useCallback(() => router.back(), [router]);

  const startCapture = useCallback(async () => {
    setScreenError(null);
    try {
      if (Platform.OS === 'web') {
        const stop = startBrowserRecognition(language, (result) => {
          setTranscript(result.transcript);
          if (result.isFinal) setListening(false);
        }, setScreenError, () => setListening(false));
        if (!stop) throw new Error('This browser does not provide SpeechRecognition. Use the text field or a native Android build.');
        setBrowserStop(() => stop);
        setListening(true);
        setTranscript(language === 'fa' ? 'در حال شنیدن...' : 'Listening...');
        return;
      }
      const permission = await requestRecordingPermissionsAsync();
      if (!permission.granted) throw new Error('Microphone permission is required for voice commands.');
      await recorder.prepareToRecordAsync();
      recorder.record();
      setListening(true);
      setTranscript(language === 'fa' ? 'در حال شنیدن...' : 'Listening...');
    } catch (cause: unknown) {
      console.error('Voice capture failed to start', cause);
      setScreenError(cause instanceof Error ? cause.message : 'Voice capture could not start.');
      setListening(false);
    }
  }, [language, recorder]);

  const stopCapture = useCallback(async () => {
    try {
      if (Platform.OS === 'web') {
        browserStop?.();
        setBrowserStop(null);
        setListening(false);
        return;
      }
      await recorder.stop();
      setListening(false);
      if (!recorder.uri) throw new Error('The recording did not produce an audio file.');
      setIsTranscribing(true);
      const result = await transcribeRecordedAudio(recorder.uri, language);
      setTranscript(result);
    } catch (cause: unknown) {
      console.error('Voice capture failed to stop or transcribe', cause);
      setScreenError(cause instanceof Error ? cause.message : 'The voice recording could not be transcribed.');
    } finally {
      setIsTranscribing(false);
    }
  }, [browserStop, language, recorder]);

  const toggleCapture = useCallback(() => {
    if (listening) {
      void stopCapture();
      return;
    }
    void startCapture();
  }, [listening, startCapture, stopCapture]);

  const useTranscript = useCallback(() => {
    try {
      if (!transcript.trim() || transcript.endsWith('...') || transcript.includes('Press the orb')) {
        setScreenError(language === 'fa' ? 'هنوز دستوری دریافت نشده است.' : 'No command has been captured yet.');
        return;
      }
      setDraftCommand(transcript);
      router.back();
    } catch (cause: unknown) {
      console.error('Voice command handoff failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'The command could not be sent to Assistant.');
    }
  }, [language, router, setDraftCommand, transcript]);

  const speakTranscript = useCallback(() => {
    void speakText(transcript, language, speechRate, speechPitch).catch((cause: unknown) => {
      console.error('Voice response failed', cause);
      setScreenError(cause instanceof Error ? cause.message : 'Text-to-speech is unavailable.');
    });
  }, [language, speechPitch, speechRate, transcript]);

  const toggleLanguage = useCallback(() => {
    const nextLanguage = language === 'fa' ? 'en' : 'fa';
    setLanguage(nextLanguage);
    setVoiceLanguage(nextLanguage === 'fa' ? 'fa-IR' : 'en-US');
  }, [language, setVoiceLanguage]);

  const cycleRate = useCallback(() => {
    setSpeechRate((current) => {
      const nextRate = current >= 1.25 ? 0.75 : current + 0.25;
      setSpeechSettings({ speechRate: nextRate });
      return nextRate;
    });
  }, [setSpeechSettings]);

  const cyclePitch = useCallback(() => {
    setSpeechPitch((current) => {
      const nextPitch = current >= 1.25 ? 0.75 : current + 0.25;
      setSpeechSettings({ speechPitch: nextPitch });
      return nextPitch;
    });
  }, [setSpeechSettings]);

  if (!ready && !error) return <LoadingState />;
  if (error) return <ErrorState message={error} onRetry={retry} />;

  return (
    <View style={[uiStyles.screen, styles.screenPadding, { paddingTop: insets.top + 12, paddingBottom: insets.bottom + 20 }]}>
      <View style={styles.header}>
        <Pressable accessibilityRole="button" accessibilityLabel="Close voice overlay" onPress={close} style={styles.close}>
          <Icon name="close" size={20} color={colors.text} />
        </Pressable>
        <View style={styles.headerTitle}>
          <Text style={styles.kicker}>VOICE OVERLAY</Text>
          <Text style={styles.title}>Talk to Hoshyar</Text>
        </View>
        <Pressable accessibilityRole="button" accessibilityLabel="Toggle Persian and English" onPress={toggleLanguage} style={styles.languageButton}>
          <Text style={styles.languageText}>{language === 'fa' ? 'FA' : 'EN'}</Text>
        </Pressable>
        <View style={styles.liveDot} />
      </View>
      <View style={styles.center}>
        <Text style={styles.listeningLabel}>{listening ? 'HOSHYAR IS LISTENING' : 'VOICE PAUSED'}</Text>
        <VoiceOrb size={92} onPress={toggleCapture} />
        <View style={styles.waveform}>
          {bars.map((height, index) => <View key={`${height}-${index}`} style={[styles.bar, { height: listening ? height : 8, opacity: listening ? 0.55 + (index % 3) * 0.15 : 0.25 }]} />)}
        </View>
        {isTranscribing ? <ActivityIndicator color={colors.cyan} /> : <Text style={styles.transcript}>{transcript}</Text>}
        <Text style={styles.hint}>Tap the orb to {listening ? 'stop and transcribe' : 'start capture'}</Text>
      </View>
      <View style={styles.bottom}>
        <Text style={styles.fieldLabel}>Or refine the command</Text>
        <View style={styles.inputShell}>
          <Icon name="sparkles-outline" size={17} color={colors.violetSoft} />
          <TextInput value={transcript.includes('...') || transcript.includes('Press the orb') ? '' : transcript} onChangeText={setTranscript} placeholder="Type a command instead" placeholderTextColor={colors.textDim} style={styles.input} accessibilityLabel="Voice command transcript" />
        </View>
        <View style={styles.voiceControls}>
          <Pressable accessibilityRole="button" onPress={speakTranscript} style={styles.controlButton}>
            <Icon name="volume-high-outline" size={15} color={colors.cyan} />
            <Text style={styles.controlText}>Read aloud</Text>
          </Pressable>
          <Pressable accessibilityRole="button" onPress={cycleRate} style={styles.controlButton}>
            <Text style={styles.controlText}>Rate {speechRate.toFixed(2)}x</Text>
          </Pressable>
          <Pressable accessibilityRole="button" onPress={cyclePitch} style={styles.controlButton}>
            <Text style={styles.controlText}>Pitch {speechPitch.toFixed(2)}</Text>
          </Pressable>
        </View>
        {screenError ? <Text selectable style={styles.errorText}>{screenError}</Text> : null}
        <PrimaryButton label="Use this command" icon="arrow-forward" onPress={useTranscript} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  screenPadding: { paddingHorizontal: 20 },
  header: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  close: { width: 42, height: 42, borderRadius: 13, alignItems: 'center', justifyContent: 'center', backgroundColor: colors.card, borderWidth: 1, borderColor: colors.border },
  headerTitle: { flex: 1, gap: 3 },
  languageButton: { minWidth: 40, minHeight: 34, alignItems: 'center', justifyContent: 'center', borderRadius: 11, borderWidth: 1, borderColor: colors.borderBright, backgroundColor: colors.card },
  languageText: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 11 },
  kicker: { color: colors.cyan, fontFamily: fonts.semibold, fontSize: 10, letterSpacing: 1.2 },
  title: { color: colors.text, fontFamily: fonts.bold, fontSize: 20 },
  liveDot: { width: 9, height: 9, borderRadius: 5, backgroundColor: colors.cyan },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 19 },
  listeningLabel: { color: colors.textMuted, fontFamily: fonts.semibold, fontSize: 11, letterSpacing: 1.5 },
  waveform: { height: 76, flexDirection: 'row', alignItems: 'center', gap: 4 },
  bar: { width: 4, borderRadius: 3, backgroundColor: colors.cyan },
  transcript: { color: colors.text, fontFamily: fonts.semibold, fontSize: 19, textAlign: 'center', lineHeight: 27, maxWidth: 310 },
  hint: { color: colors.textDim, fontFamily: fonts.regular, fontSize: 12 },
  bottom: { gap: 10 },
  fieldLabel: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 11 },
  inputShell: { minHeight: 50, flexDirection: 'row', alignItems: 'center', gap: 9, paddingHorizontal: 13, borderRadius: 14, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.card },
  input: { flex: 1, color: colors.text, fontFamily: fonts.regular, fontSize: 13, minHeight: 48 },
  voiceControls: { flexDirection: 'row', flexWrap: 'wrap', gap: 7 },
  controlButton: { minHeight: 34, flexDirection: 'row', alignItems: 'center', gap: 5, paddingHorizontal: 9, borderRadius: 10, borderWidth: 1, borderColor: colors.border, backgroundColor: colors.card },
  controlText: { color: colors.textMuted, fontFamily: fonts.medium, fontSize: 10 },
  errorText: { color: colors.red, fontFamily: fonts.medium, fontSize: 12, lineHeight: 17 },
});
