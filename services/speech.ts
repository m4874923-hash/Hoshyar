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
