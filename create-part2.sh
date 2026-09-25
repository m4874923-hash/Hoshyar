#!/data/data/com.termux/files/usr/bin/bash
cd ~/Hoshyar

echo "📦 مرحله ۲: services (بخش ۱)..."

cat > services/task-engine.ts << 'EOF'
export interface TaskContext {
  values: Record<string, string | number | boolean>;
}

export interface TaskStep {
  id: string;
  label: string;
  run: (context: TaskContext) => Promise<Partial<TaskContext['values']>>;
}

export interface TaskProgress {
  stepIndex: number;
  total: number;
  step: TaskStep;
}

export interface TaskRun {
  promise: Promise<TaskContext>;
  pause: () => void;
  resume: () => void;
  cancel: () => void;
}

export class TaskCancelledError extends Error {
  constructor() {
    super('Task execution was cancelled.');
    this.name = 'TaskCancelledError';
  }
}

export function runTask(
  steps: TaskStep[],
  initialValues: TaskContext['values'],
  onProgress?: (progress: TaskProgress) => void,
): TaskRun {
  let paused = false;
  let cancelled = false;
  let resumeWaiter: (() => void) | null = null;

  const waitUntilResumed = async (): Promise<void> => {
    if (!paused) return;
    await new Promise<void>((resolve) => {
      resumeWaiter = resolve;
    });
  };

  const promise = (async () => {
    const context: TaskContext = { values: { ...initialValues } };
    for (let index = 0; index < steps.length; index += 1) {
      if (cancelled) throw new TaskCancelledError();
      await waitUntilResumed();
      if (cancelled) throw new TaskCancelledError();
      const step = steps[index];
      onProgress?.({ stepIndex: index, total: steps.length, step });
      const result = await step.run(context);
      const definedValues = Object.entries(result).reduce<Record<string, string | number | boolean>>((values, [key, value]) => {
        if (value !== undefined) values[key] = value;
        return values;
      }, {});
      context.values = { ...context.values, ...definedValues };
    }
    return context;
  })();

  return {
    promise,
    pause: () => {
      paused = true;
    },
    resume: () => {
      paused = false;
      resumeWaiter?.();
      resumeWaiter = null;
    },
    cancel: () => {
      cancelled = true;
      resumeWaiter?.();
      resumeWaiter = null;
    },
  };
}
EOF
echo "✅ services/task-engine.ts"

cat > services/command-parser.ts << 'EOF'
import type { SkillId } from '@/store/types';

export type CommandLanguage = 'fa' | 'en';
export type MessengerId = 'whatsapp' | 'telegram' | 'bale' | 'eitaa';
export type SystemTarget = 'settings' | 'wifi' | 'bluetooth' | 'sound' | 'battery' | 'accessibility' | 'app-store';
export type CommandAction =
  | 'send_message'
  | 'call_contact'
  | 'send_sms'
  | 'open_app'
  | 'open_system'
  | 'run_routine'
  | 'create_note'
  | 'find_contact'
  | 'multi_step'
  | 'unknown';

export interface ParsedCommand {
  action: CommandAction;
  language: CommandLanguage;
  original: string;
  confidence: number;
  requiresConfirmation: boolean;
  title: string;
  detail: string;
  skill: SkillId;
  recipient?: string;
  phoneNumber?: string;
  messenger?: MessengerId;
  message?: string;
  appName?: string;
  systemTarget?: SystemTarget;
  routineName?: string;
  noteText?: string;
  steps?: ParsedCommand[];
}

const messengerAliases: Record<string, MessengerId> = {
  whatsapp: 'whatsapp',
  'واتساپ': 'whatsapp',
  'واتس': 'whatsapp',
  telegram: 'telegram',
  'تلگرام': 'telegram',
  bale: 'bale',
  'بله': 'bale',
  eitaa: 'eitaa',
  'ایتا': 'eitaa',
};

const appAliases: Record<string, string> = {
  whatsapp: 'WhatsApp',
  'واتساپ': 'WhatsApp',
  telegram: 'Telegram',
  'تلگرام': 'Telegram',
  bale: 'Bale',
  'بله': 'Bale',
  eitaa: 'Eitaa',
  'ایتا': 'Eitaa',
  settings: 'Settings',
  'تنظیمات': 'Settings',
};

const systemAliases: Array<{ target: SystemTarget; values: string[]; label: string }> = [
  { target: 'wifi', values: ['wifi', 'wi-fi', 'وای فای', 'وایفای', 'اینترنت'], label: 'Wi-Fi settings' },
  { target: 'bluetooth', values: ['bluetooth', 'بلوتوث'], label: 'Bluetooth settings' },
  { target: 'sound', values: ['sound', 'صدا', 'صدای گوشی'], label: 'Sound settings' },
  { target: 'battery', values: ['battery', 'باتری'], label: 'Battery settings' },
  { target: 'accessibility', values: ['accessibility', 'دسترسی پذیری', 'دسترسی پذیری'], label: 'Accessibility settings' },
  { target: 'app-store', values: ['play store', 'google play', 'کافه بازار', 'بازار', 'app store'], label: 'App store' },
  { target: 'settings', values: ['settings', 'تنظیمات'], label: 'System settings' },
];

export function normalizeDigits(value: string): string {
  return value.replace(/[۰-۹]/g, (digit) => String('۰۱۲۳۴۵۶۷۸۹'.indexOf(digit))).replace(/[٠-٩]/g, (digit) => String('٠١٢٣٤٥٦٧٨٩'.indexOf(digit)));
}

export function normalizeCommand(value: string): string {
  return normalizeDigits(value)
    .replace(/[يى]/g, 'ی')
    .replace(/ك/g, 'ک')
    .replace(/[\u200c\u200f]/g, ' ')
    .replace(/[َُِّْ]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}

export function detectCommandLanguage(value: string): CommandLanguage {
  return /[\u0600-\u06ff]/u.test(value) ? 'fa' : 'en';
}

function unknownCommand(input: string, language: CommandLanguage): ParsedCommand {
  return {
    action: 'unknown',
    language,
    original: input,
    confidence: 0.2,
    requiresConfirmation: false,
    title: language === 'fa' ? 'دستور ناشناخته' : 'Unknown command',
    detail: language === 'fa' ? 'برای این دستور هنوز اقدامی پیدا نشد.' : 'No action matched this command yet.',
    skill: 'web',
  };
}

function findMessenger(value: string): MessengerId | undefined {
  const alias = Object.keys(messengerAliases).find((item) => value.includes(item));
  return alias ? messengerAliases[alias] : undefined;
}

function findSystemTarget(value: string): { target: SystemTarget; label: string } | undefined {
  return systemAliases.find((item) => item.values.some((candidate) => value.includes(candidate)));
}

function splitSteps(input: string, language: CommandLanguage): string[] {
  const separator = language === 'fa' ? /\s+(?:و سپس|بعدش|بعد از آن|سپس)\s+/u : /\s+(?:and then|then|after that)\s+/i;
  return input.split(separator).map((item) => item.trim()).filter(Boolean);
}

interface ParseContext {
  input: string;
  normalized: string;
  language: CommandLanguage;
  messenger?: MessengerId;
  systemTarget?: { target: SystemTarget; label: string };
  phoneNumber?: string;
}

type SingleParser = (context: ParseContext) => ParsedCommand | undefined;

function createParseContext(input: string): ParseContext {
  const normalized = normalizeCommand(input);
  return {
    input,
    normalized,
    language: detectCommandLanguage(input),
    messenger: findMessenger(normalized),
    systemTarget: findSystemTarget(normalized),
    phoneNumber: normalized.match(/(?:\+|00)?\d[\d\s().-]{6,}\d/u)?.[0],
  };
}

function parseSystemCommand(context: ParseContext): ParsedCommand | undefined {
  const { input, normalized, language, systemTarget } = context;
  if (!systemTarget || !/(?:تنظیمات|settings|باز کن|باز کردن|open)/u.test(normalized)) return undefined;
  return {
    action: 'open_system', language, original: input, confidence: 0.97, requiresConfirmation: false,
    title: language === 'fa' ? `باز کردن ${systemTarget.label}` : `Open ${systemTarget.label}`,
    detail: systemTarget.label, skill: 'system', systemTarget: systemTarget.target,
  };
}

function parseSmsCommand(context: ParseContext): ParsedCommand | undefined {
  const { input, normalized, language, phoneNumber } = context;
  const smsMatch = language === 'fa'
    ? normalized.match(/(?:ارسال|فرستادن|فرست)\s*پیامک\s+(?:به|برای)\s+(.+?)(?:\s+(?:با متن|که|متن)\s+(.+))?$/u)
    : normalized.match(/(?:send|compose)\s+(?:an?\s+)?sms\s+(?:to|for)\s+(.+?)(?:\s+(?:saying|with|text)\s+(.+))?$/i);
  if (!smsMatch) return undefined;
  const recipient = smsMatch[1].trim();
  const message = smsMatch[2]?.trim();
  return {
    action: 'send_sms', language, original: input, confidence: 0.96, requiresConfirmation: true,
    title: language === 'fa' ? 'ارسال پیامک' : 'Send SMS',
    detail: message ? `${recipient} · ${message}` : recipient, skill: 'messages', recipient,
    phoneNumber, message,
  };
}

function parseCallCommand(context: ParseContext): ParsedCommand | undefined {
  const { input, normalized, language, phoneNumber } = context;
  const callMatch = language === 'fa'
    ? normalized.match(/(?:تماس|زنگ)\s+(?:با|به)\s+(.+?)(?:\s+(?:بگیر|بزن|بگیرم))?$/u)
    : normalized.match(/(?:call|phone|dial)\s+(.+)$/i);
  if (!callMatch) return undefined;
  const recipient = callMatch[1].trim();
  return {
    action: 'call_contact', language, original: input, confidence: 0.98, requiresConfirmation: true,
    title: language === 'fa' ? 'تماس تلفنی' : 'Phone call',
    detail: recipient, skill: 'messages', recipient, phoneNumber,
  };
}

function parseMessageCommand(context: ParseContext): ParsedCommand | undefined {
  const { input, normalized, language, messenger, phoneNumber } = context;
  const messageMatch = language === 'fa'
    ? normalized.match(/(?:یک\s+)?پیام(?:ی)?\s+(?:به|برای)\s+(.+?)(?:\s+(?:در|روی)\s+(واتساپ|تلگرام|بله|ایتا))?(?:\s+(?:که|با متن|متن)\s+(.+))?(?:\s+(?:بفرست|ارسال کن))?$/u)
    : normalized.match(/(?:send|message)\s+(?:a\s+)?message\s+(?:to|for)\s+(.+?)(?:\s+(?:on|via|in)\s+(whatsapp|telegram|bale|eitaa))?(?:\s+(?:saying|that says|with)\s+(.+))?$/i);
  if (!messageMatch) return undefined;
  const recipient = messageMatch[1].trim();
  const selectedMessenger = messageMatch[2] ? messengerAliases[messageMatch[2]] : messenger;
  const message = messageMatch[3]?.trim();
  const serviceLabel = selectedMessenger ?? (language === 'fa' ? 'پیام رسان' : 'messenger');
  return {
    action: 'send_message', language, original: input, confidence: 0.95, requiresConfirmation: true,
    title: language === 'fa' ? 'ارسال پیام' : 'Send message',
    detail: `${recipient}${message ? ` · ${message}` : ''} · ${serviceLabel}`, skill: 'messages', recipient,
    phoneNumber, messenger: selectedMessenger, message,
  };
}

function parseQuickMessageCommand(context: ParseContext): ParsedCommand | undefined {
  const { input, normalized, language } = context;
  const quickMessageMatch = normalized.match(/^(?:send|tell)\s+([a-z][a-z\s'-]{1,40}?)(?:\s+(?:a\s+)?(?:quick\s+)?(?:update|message))(?:\s+(?:that|saying|with)\s+(.+))?$/i);
  if (!quickMessageMatch) return undefined;
  const recipient = quickMessageMatch[1].trim();
  const message = quickMessageMatch[2]?.trim();
  return {
    action: 'send_message', language, original: input, confidence: 0.9, requiresConfirmation: true,
    title: 'Send message', detail: `${recipient}${message ? ` · ${message}` : ''} · whatsapp`, skill: 'messages', recipient,
    messenger: 'whatsapp', message,
  };
}

function parseOpenAppCommand(context: ParseContext): ParsedCommand | undefined {
  const { input, normalized, language, messenger } = context;
  const openMatch = language === 'fa'
    ? normalized.match(/^(?:باز کردن|باز کن|بازش کن)\s+(.+?)(?:\s+را)?$/u) ?? normalized.match(/^(.+?)\s+را\s+باز\s+کن$/u)
    : normalized.match(/^(?:open|launch)\s+(.+)$/i);
  if (!openMatch) return undefined;
  const appName = openMatch[1].trim();
  const canonicalName = appAliases[appName] ?? appName;
  if (!messenger && !appAliases[appName]) return undefined;
  return {
    action: 'open_app', language, original: input, confidence: 0.97, requiresConfirmation: false,
    title: language === 'fa' ? `باز کردن ${canonicalName}` : `Open ${canonicalName}`,
    detail: canonicalName, skill: 'system', appName: canonicalName,
  };
}

function parseRoutineCommand(context: ParseContext): ParsedCommand | undefined {
  const { input, normalized, language } = context;
  if (!/(?:روال|routine|workflow)/u.test(normalized)) return undefined;
  const routineName = normalized.replace(/^(?:اجرای|run|شروع|روال|routine|workflow)\s*/u, '').trim() || 'morning';
  return {
    action: 'run_routine', language, original: input, confidence: 0.9, requiresConfirmation: true,
    title: language === 'fa' ? 'اجرای روال' : 'Run routine', detail: routineName, skill: 'routine', routineName,
  };
}

function parseNoteCommand(context: ParseContext): ParsedCommand | undefined {
  const { input, normalized, language } = context;
  if (!/(?:یادداشت|note)/u.test(normalized)) return undefined;
  const noteText = normalized.replace(/^(?:یادداشت جدید|یادداشت|new note|create note)\s*/u, '').trim();
  return {
    action: 'create_note', language, original: input, confidence: 0.88, requiresConfirmation: false,
    title: language === 'fa' ? 'یادداشت جدید' : 'New note', detail: noteText || (language === 'fa' ? 'یادداشت خالی' : 'Empty note'), skill: 'reminders', noteText,
  };
}

function parseContactCommand(context: ParseContext): ParsedCommand | undefined {
  const { input, normalized, language } = context;
  if (!/(?:مخاطب|contact)/u.test(normalized)) return undefined;
  const recipient = normalized.replace(/^(?:جستجوی|پیدا کن|find|search)\s*(?:مخاطب|contact)?\s*/u, '').trim();
  return {
    action: 'find_contact', language, original: input, confidence: 0.86, requiresConfirmation: false,
    title: language === 'fa' ? 'جستجوی مخاطب' : 'Find contact', detail: recipient, skill: 'messages', recipient,
  };
}

const singleParsers: SingleParser[] = [
  parseSystemCommand,
  parseSmsCommand,
  parseCallCommand,
  parseMessageCommand,
  parseQuickMessageCommand,
  parseOpenAppCommand,
  parseRoutineCommand,
  parseNoteCommand,
  parseContactCommand,
];

function parseSingle(input: string): ParsedCommand {
  const context = createParseContext(input);
  for (const parser of singleParsers) {
    const command = parser(context);
    if (command) return command;
  }
  return unknownCommand(input, context.language);
}

export function parseCommand(input: string): ParsedCommand {
  const language = detectCommandLanguage(input);
  const parts = splitSteps(input, language);
  if (parts.length > 1) {
    const steps = parts.map(parseSingle);
    if (steps.every((step) => step.action !== 'unknown')) {
      return {
        action: 'multi_step', language, original: input, confidence: Math.min(...steps.map((step) => step.confidence)),
        requiresConfirmation: steps.some((step) => step.requiresConfirmation),
        title: language === 'fa' ? 'دستور چندمرحله ای' : 'Multi-step command',
        detail: steps.map((step) => step.detail).join(' → '), skill: 'routine', steps,
      };
    }
  }

  return parseSingle(input);
}
EOF
echo "✅ services/command-parser.ts"

echo ""
echo "🎉 مرحله ۲ تمام شد! ۲ فایل کلیدی ساخته شد."
