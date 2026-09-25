#!/data/data/com.termux/files/usr/bin/bash
cd ~/Hoshyar

echo "📦 مرحله ۴: speech, accessibility, executor, store..."

cat > services/speech.ts << 'EOF'
import * as Speech from 'expo-speech';
import { transcribeAudio } from '@fastshot/ai';
import type { CommandLanguage } from './command-parser';

export interface SpeechRecognitionResult {
  transcript: string;
  isFinal: boolean;
}

interface BrowserRecognitionEvent extends Event {
  results: {
    [index: number]: {
      [index: number]: { transcript: string; confidence: number };
      isFinal: boolean;
    };
    length: number;
  };
}

interface BrowserRecognition extends EventTarget {
  lang: string;
  continuous: boolean;
  interimResults: boolean;
  onresult: ((event: BrowserRecognitionEvent) => void) | null;
  onerror: ((event: Event) => void) | null;
  onend: (() => void) | null;
  start: () => void;
  stop: () => void;
}

interface BrowserRecognitionWindow extends Window {
  SpeechRecognition?: new () => BrowserRecognition;
  webkitSpeechRecognition?: new () => BrowserRecognition;
}

const languageCode = (language: CommandLanguage): string => (language === 'fa' ? 'fa-IR' : 'en-US');

export async function speakText(text: string, language: CommandLanguage, rate = 1, pitch = 1): Promise<void> {
  try {
    await Speech.stop();
    const voices = await Speech.getAvailableVoicesAsync();
    const voice = voices.find((item) => item.language.toLowerCase().startsWith(language === 'fa' ? 'fa' : 'en'));
    Speech.speak(text, { language: languageCode(language), rate, pitch, voice: voice?.identifier });
  } catch (cause: unknown) {
    console.error('Text-to-speech failed', cause);
    throw new Error(cause instanceof Error ? cause.message : 'Speech output is unavailable.');
  }
}

export async function stopSpeaking(): Promise<void> {
  try {
    await Speech.stop();
  } catch (cause: unknown) {
    console.error('Stopping text-to-speech failed', cause);
    throw new Error(cause instanceof Error ? cause.message : 'Speech output could not stop.');
  }
}

export function startBrowserRecognition(
  language: CommandLanguage,
  onResult: (result: SpeechRecognitionResult) => void,
  onError: (message: string) => void,
  onEnd: () => void,
): (() => void) | null {
  if (typeof window === 'undefined') return null;
  const recognitionWindow = window as BrowserRecognitionWindow;
  const Recognition = recognitionWindow.SpeechRecognition ?? recognitionWindow.webkitSpeechRecognition;
  if (!Recognition) return null;
  const recognition = new Recognition();
  recognition.lang = languageCode(language);
  recognition.continuous = false;
  recognition.interimResults = true;
  recognition.onresult = (event) => {
    const result = event.results[event.results.length - 1];
    const transcript = result?.[0]?.transcript?.trim();
    if (transcript) onResult({ transcript, isFinal: result.isFinal });
  };
  recognition.onerror = () => onError('Browser speech recognition could not capture audio.');
  recognition.onend = onEnd;
  try {
    recognition.start();
  } catch (cause: unknown) {
    console.error('Browser speech recognition failed to start', cause);
    onError(cause instanceof Error ? cause.message : 'Browser speech recognition could not start.');
    return null;
  }
  return () => {
    try {
      recognition.stop();
    } catch (cause: unknown) {
      console.error('Browser speech recognition failed to stop', cause);
    }
  };
}

export async function transcribeRecordedAudio(audioUri: string, language: CommandLanguage): Promise<string> {
  try {
    const result = await transcribeAudio({ audioUri, language: language === 'fa' ? 'fa' : 'en' });
    if (!result.trim()) throw new Error('The audio transcription was empty.');
    return result.trim();
  } catch (cause: unknown) {
    console.error('AI audio transcription failed', cause);
    throw new Error(cause instanceof Error ? cause.message : 'Audio transcription failed.');
  }
}
EOF
echo "✅ services/speech.ts"

cat > services/accessibility.ts << 'EOF'
import { Platform } from 'react-native';
import { openSystemTarget } from './device-actions';

export type AccessibilityServiceState = 'native-build-ready' | 'expo-go-limited' | 'web-unavailable';

export function getAccessibilityServiceState(): AccessibilityServiceState {
  if (Platform.OS === 'android') return 'native-build-ready';
  if (Platform.OS === 'web') return 'web-unavailable';
  return 'expo-go-limited';
}

export async function openAccessibilitySettings(): Promise<void> {
  try {
    await openSystemTarget('accessibility');
  } catch (cause: unknown) {
    console.error('Accessibility settings could not open', cause);
    throw new Error(cause instanceof Error ? cause.message : 'Accessibility settings are unavailable.');
  }
}
EOF
echo "✅ services/accessibility.ts"

cat > services/command-executor.ts << 'EOF'
import type { ParsedCommand } from './command-parser';
import { findContactsByName } from './contacts';
import { openApp, openMessenger, openPhoneDialer, openSmsComposer, openSystemTarget } from './device-actions';
import { runTask, type TaskContext, type TaskRun, type TaskStep } from './task-engine';
import { saveNote } from './notes';

export interface CommandExecutionResult {
  summary: string;
  task?: TaskRun;
}

type ActionResult = Partial<TaskContext['values']>;
type ActionHandler = (command: ParsedCommand, context: TaskContext) => Promise<ActionResult>;

function chainedValue(context: TaskContext, key: string): string | undefined {
  const value = context.values[key];
  return typeof value === 'string' ? value : undefined;
}

function resolvedRecipient(command: ParsedCommand, context: TaskContext): string | undefined {
  return command.recipient ?? chainedValue(context, 'matchedContact');
}

function resolvedPhoneNumber(command: ParsedCommand, context: TaskContext): string | undefined {
  return command.phoneNumber ?? chainedValue(context, 'phoneNumber');
}

function sendMessageAction(command: ParsedCommand, context: TaskContext): Promise<ActionResult> {
  const recipient = resolvedRecipient(command, context);
  if (!recipient || !command.messenger) throw new Error('Choose a recipient and messenger before sending.');
  return openMessenger(command.messenger, recipient, command.message, resolvedPhoneNumber(command, context)).then(() => ({ dispatched: true, recipient }));
}

function callContactAction(command: ParsedCommand, context: TaskContext): Promise<ActionResult> {
  const recipient = resolvedRecipient(command, context);
  if (!recipient) throw new Error('Choose a contact before calling.');
  return openPhoneDialer(recipient, resolvedPhoneNumber(command, context)).then(() => ({ dispatched: true, recipient }));
}

function sendSmsAction(command: ParsedCommand, context: TaskContext): Promise<ActionResult> {
  const recipient = resolvedRecipient(command, context);
  if (!recipient) throw new Error('Choose a phone number or contact before sending SMS.');
  return openSmsComposer(recipient, command.message, resolvedPhoneNumber(command, context)).then(() => ({ dispatched: true, recipient }));
}

function openAppAction(command: ParsedCommand): Promise<ActionResult> {
  if (!command.appName) throw new Error('Choose an application to open.');
  return openApp(command.appName).then(() => ({ dispatched: true, app: command.appName }));
}

function openSystemAction(command: ParsedCommand): Promise<ActionResult> {
  if (!command.systemTarget) throw new Error('Choose a system destination to open.');
  return openSystemTarget(command.systemTarget).then(() => ({ dispatched: true, target: command.systemTarget }));
}

function findContactAction(command: ParsedCommand): Promise<ActionResult> {
  if (!command.recipient) throw new Error('Enter a contact name to search.');
  return findContactsByName(command.recipient).then((matches) => {
    if (matches.length === 0) throw new Error(`No contacts matched ${command.recipient}.`);
    return { matchedContact: matches[0].name, phoneNumber: matches[0].phoneNumber ?? '' };
  });
}

function createNoteAction(command: ParsedCommand): Promise<ActionResult> {
  if (!command.noteText?.trim()) throw new Error('Add text to the note before saving it.');
  return saveNote(command.noteText).then((note) => ({ noteId: note.id, noteText: note.text }));
}

function unsupportedRoutineAction(command: ParsedCommand): Promise<ActionResult> {
  return Promise.reject(new Error(`Routine execution needs concrete adapters for ${command.routineName ?? 'this routine'}; no step was faked.`));
}

function unsupportedCommandAction(): Promise<ActionResult> {
  return Promise.reject(new Error('This command has no executable action.'));
}

const actionHandlers: Record<ParsedCommand['action'], ActionHandler> = {
  ['send_message']: sendMessageAction,
  ['call_contact']: callContactAction,
  ['send_sms']: sendSmsAction,
  ['open_app']: (command) => openAppAction(command),
  ['open_system']: (command) => openSystemAction(command),
  ['run_routine']: unsupportedRoutineAction,
  ['create_note']: (command) => createNoteAction(command),
  ['find_contact']: (command) => findContactAction(command),
  ['multi_step']: unsupportedCommandAction,
  ['unknown']: unsupportedCommandAction,
};

function actionStep(command: ParsedCommand): TaskStep {
  return {
    id: `${command.action}-${Date.now()}`,
    label: command.title,
    run: (context) => actionHandlers[command.action](command, context),
  };
}

export function executeCommand(command: ParsedCommand, onProgress?: (step: number, total: number, label: string) => void): CommandExecutionResult {
  const commands = command.action === 'multi_step' ? command.steps ?? [] : [command];
  const steps = commands.map(actionStep);
  const task = runTask(steps, {}, (progress) => onProgress?.(progress.stepIndex, progress.total, progress.step.label));
  return { summary: command.detail, task };
}
EOF
echo "✅ services/command-executor.ts"

echo ""
echo "🎉 مرحله ۴ تمام شد! ۳ فایل مهم ساخته شد."
echo ""
echo "➡️ مرحله بعد: store/useAppStore.ts (جدا می‌سازیم چون بزرگه)"
