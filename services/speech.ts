import * as Speech from 'expo-speech';
import { ExpoSpeechRecognitionModule } from 'expo-speech-recognition';
import type { CommandLanguage } from './command-parser';

export interface SpeechRecognitionResult {
  transcript: string;
  isFinal: boolean;
}

// ─────────────────────────────────────────────────────────────
// Browser SpeechRecognition (فقط برای web preview)
// ─────────────────────────────────────────────────────────────

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

const languageCode = (language: CommandLanguage): string =>
  language === 'fa' ? 'fa-IR' : 'en-US';

// ─────────────────────────────────────────────────────────────
// Text-to-Speech (TTS)
// ─────────────────────────────────────────────────────────────

export async function speakText(
  text: string,
  language: CommandLanguage,
  rate = 1,
  pitch = 1,
): Promise<void> {
  try {
    await Speech.stop();
    const voices = await Speech.getAvailableVoicesAsync();
    const voice = voices.find((item) =>
      item.language.toLowerCase().startsWith(language === 'fa' ? 'fa' : 'en'),
    );
    Speech.speak(text, {
      language: languageCode(language),
      rate,
      pitch,
      voice: voice?.identifier,
    });
  } catch (cause: unknown) {
    console.error('Text-to-speech failed', cause);
    throw new Error(
      cause instanceof Error ? cause.message : 'Speech output is unavailable.',
    );
  }
}

export async function stopSpeaking(): Promise<void> {
  try {
    await Speech.stop();
  } catch (cause: unknown) {
    console.error('Stopping text-to-speech failed', cause);
    throw new Error(
      cause instanceof Error ? cause.message : 'Speech output could not stop.',
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Browser Speech Recognition (web only)
// ─────────────────────────────────────────────────────────────

export function startBrowserRecognition(
  language: CommandLanguage,
  onResult: (result: SpeechRecognitionResult) => void,
  onError: (message: string) => void,
  onEnd: () => void,
): (() => void) | null {
  if (typeof window === 'undefined') return null;
  const recognitionWindow = window as BrowserRecognitionWindow;
  const Recognition =
    recognitionWindow.SpeechRecognition ??
    recognitionWindow.webkitSpeechRecognition;
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
  recognition.onerror = () =>
    onError('Browser speech recognition could not capture audio.');
  recognition.onend = onEnd;
  try {
    recognition.start();
  } catch (cause: unknown) {
    console.error('Browser speech recognition failed to start', cause);
    onError(
      cause instanceof Error
        ? cause.message
        : 'Browser speech recognition could not start.',
    );
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

// ─────────────────────────────────────────────────────────────
// Native Speech Recognition (Android/iOS)
// ─────────────────────────────────────────────────────────────

export async function startNativeRecognition(
  language: CommandLanguage,
): Promise<void> {
  try {
    console.log('[HOSHYAR STT] PERMISSION: requesting...');
    const permission =
      await ExpoSpeechRecognitionModule.requestPermissionsAsync();
    console.log('[HOSHYAR STT] PERMISSION:', permission);

    if (!permission.granted) {
      throw new Error('دسترسی میکروفون داده نشده است.');
    }

    const lang = languageCode(language);
    const stateBefore = await ExpoSpeechRecognitionModule.getStateAsync();
    console.log('[HOSHYAR STT] STATE BEFORE START:', stateBefore);
    console.log('[HOSHYAR STT] START with lang:', lang);

    ExpoSpeechRecognitionModule.start({
      lang,
      interimResults: true,
      continuous: false,
      maxAlternatives: 1,
    });
  } catch (cause: unknown) {
    console.error('[HOSHYAR STT] START ERROR:', cause);
    throw new Error(
      cause instanceof Error
        ? cause.message
        : 'شروع تشخیص گفتار ناموفق بود.',
    );
  }
}

export async function stopNativeRecognition(): Promise<void> {
  try {
    const state = await ExpoSpeechRecognitionModule.getStateAsync();
    console.log('[HOSHYAR STT] STATE BEFORE STOP:', state);

    if (state === 'recognizing' || state === 'starting') {
      console.log('[HOSHYAR STT] STOP');
      ExpoSpeechRecognitionModule.stop();
    } else {
      console.log('[HOSHYAR STT] SKIP STOP (state:', state, ')');
    }
  } catch (cause: unknown) {
    console.error('[HOSHYAR STT] STOP ERROR:', cause);
  }
}

// ─────────────────────────────────────────────────────────────
// transcribeRecordedAudio — stub
// ─────────────────────────────────────────────────────────────

export async function transcribeRecordedAudio(
  _audioUri: string,
  _language: CommandLanguage,
): Promise<string> {
  throw new Error(
    'transcribeRecordedAudio موقتاً غیرفعال ئه. لطفاً از voice overlay با streaming استفاده کن.',
  );
}
