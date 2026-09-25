#!/data/data/com.termux/files/usr/bin/bash
cd ~/Hoshyar

echo "📦 مرحله ۳: بقیه services..."

cat > services/contacts.ts << 'EOF'
import * as Contacts from 'expo-contacts/legacy';
import type { ExistingContact } from 'expo-contacts/legacy';
import { normalizeDigits, normalizeCommand } from './command-parser';

export interface ContactMatch {
  id: string;
  name: string;
  phoneNumber?: string;
}

function getContactName(contact: ExistingContact): string {
  return [contact.firstName, contact.middleName, contact.lastName].filter(Boolean).join(' ') || contact.name || 'Unknown contact';
}

export async function findContactsByName(name: string): Promise<ContactMatch[]> {
  try {
    const permission = await Contacts.requestPermissionsAsync();
    if (!permission.granted) throw new Error('Contacts permission is required to find this person.');
    const response = await Contacts.getContactsAsync({ name: normalizeCommand(name), pageSize: 20 });
    return response.data.map((contact) => ({ id: contact.id, name: getContactName(contact), phoneNumber: contact.phoneNumbers?.[0]?.number }));
  } catch (cause: unknown) {
    console.error('Contact search failed', cause);
    throw new Error(cause instanceof Error ? cause.message : 'Contacts could not be loaded.');
  }
}

export async function resolvePhoneNumber(recipient: string, explicitPhone?: string): Promise<string> {
  const normalizedRecipient = normalizeDigits(recipient).trim();
  if (explicitPhone || /(?:^|\D)\+?\d[\d\s().-]{6,}\d(?:$|\D)/u.test(normalizedRecipient)) return explicitPhone ?? normalizedRecipient;
  const matches = await findContactsByName(recipient);
  const phoneNumber = matches[0]?.phoneNumber;
  if (!phoneNumber) throw new Error(`No phone number was found for ${recipient}.`);
  return phoneNumber;
}
EOF
echo "✅ services/contacts.ts"

cat > services/contacts.web.ts << 'EOF'
import { normalizeDigits } from './command-parser';

export interface ContactMatch {
  id: string;
  name: string;
  phoneNumber?: string;
}

export async function findContactsByName(_name: string): Promise<ContactMatch[]> {
  throw new Error('The local contact directory is available in a native Android or iOS build.');
}

export async function resolvePhoneNumber(recipient: string, explicitPhone?: string): Promise<string> {
  if (explicitPhone) return normalizeDigits(explicitPhone);
  if (/^\+?\d[\d\s().-]{6,}\d$/u.test(normalizeDigits(recipient))) return normalizeDigits(recipient);
  throw new Error('Contact lookup requires a native build. Enter a phone number in the preview.');
}
EOF
echo "✅ services/contacts.web.ts"

cat > services/device-actions.ts << 'EOF'
import { ActivityAction, openApplication, startActivityAsync } from 'expo-intent-launcher';
import { Linking, Platform } from 'react-native';
import { resolvePhoneNumber } from './contacts';
import type { MessengerId, SystemTarget } from './command-parser';

interface AppTarget {
  packageName: string;
  deepLink: string;
}

const appTargets: Record<MessengerId, AppTarget> = {
  whatsapp: { packageName: 'com.whatsapp', deepLink: 'whatsapp://send' },
  telegram: { packageName: 'org.telegram.messenger', deepLink: 'tg://resolve' },
  bale: { packageName: 'ir.ble.messenger', deepLink: 'bale://' },
  eitaa: { packageName: 'ir.eitaa.messenger', deepLink: 'eitaa://' },
};

const systemActions: Record<SystemTarget, ActivityAction | string> = {
  settings: ActivityAction.SETTINGS,
  wifi: ActivityAction.WIFI_SETTINGS,
  bluetooth: ActivityAction.BLUETOOTH_SETTINGS,
  sound: ActivityAction.SOUND_SETTINGS,
  battery: ActivityAction.BATTERY_SAVER_SETTINGS,
  accessibility: ActivityAction.ACCESSIBILITY_SETTINGS,
  'app-store': 'android.intent.action.VIEW',
};

function encode(value: string): string {
  return encodeURIComponent(value);
}

async function openUrl(url: string): Promise<void> {
  const supported = await Linking.canOpenURL(url);
  if (!supported) throw new Error(`No application can handle ${url.split(':')[0]}.`);
  await Linking.openURL(url);
}

function openAndroidApplication(packageName: string): void {
  if (Platform.OS !== 'android') throw new Error('Android application launching is only available on Android.');
  try {
    openApplication(packageName);
  } catch (cause: unknown) {
    console.error(`Could not open Android package ${packageName}`, cause);
    throw new Error(`The application ${packageName} is not installed.`);
  }
}

function resolveMessengerPhone(messenger: MessengerId, recipient: string, explicitPhone?: string): Promise<string | undefined> {
  if (explicitPhone !== undefined) return Promise.resolve(explicitPhone);
  if (!['whatsapp', 'bale', 'eitaa'].includes(messenger)) return Promise.resolve(undefined);
  return resolvePhoneNumber(recipient);
}

function buildMessengerUrl(messenger: MessengerId, target: AppTarget, recipient: string, message: string | undefined, phone: string | undefined): string {
  const encodedMessage = message ? `&text=${encode(message)}` : '';
  if (messenger === 'whatsapp') return `${target.deepLink}?phone=${encode(phone ?? recipient)}${message ? `&text=${encode(message)}` : ''}`;
  if (messenger === 'telegram') {
    return phone
      ? `tg://resolve?phone=${encode(phone)}${message ? `&text=${encode(message)}` : ''}`
      : `tg://resolve?domain=${encode(recipient.replace(/^@/u, ''))}${message ? `&text=${encode(message)}` : ''}`;
  }
  return `${target.deepLink}${phone ? `?phone=${encode(phone)}` : ''}${encodedMessage ? `${phone ? '&' : '?'}${encodedMessage.slice(1)}` : ''}`;
}

async function openMessengerUrl(messenger: MessengerId, url: string, packageName: string): Promise<void> {
  try {
    await openUrl(url);
  } catch (cause: unknown) {
    console.error(`Deep link failed for ${messenger}`, cause);
    await openAndroidApplication(packageName);
  }
}

export async function openMessenger(messenger: MessengerId, recipient: string, message?: string, explicitPhone?: string): Promise<void> {
  try {
    const target = appTargets[messenger];
    const phone = await resolveMessengerPhone(messenger, recipient, explicitPhone);
    await openMessengerUrl(messenger, buildMessengerUrl(messenger, target, recipient, message, phone), target.packageName);
  } catch (cause: unknown) {
    console.error(`Could not launch ${messenger}`, cause);
    throw new Error(cause instanceof Error ? cause.message : `Could not open ${messenger}.`);
  }
}

export async function openApp(appName: string): Promise<void> {
  const normalized = appName.toLowerCase();
  const target = (Object.keys(appTargets) as MessengerId[]).find((item) => normalized.includes(item));
  if (!target) throw new Error(`No launcher adapter is registered for ${appName}.`);
  await openAndroidApplication(appTargets[target].packageName);
}

export async function openSystemTarget(target: SystemTarget): Promise<void> {
  try {
    if (target === 'app-store') {
      const marketUrl = 'market://details?id=com.farsitel.bazaar';
      try {
        await openUrl(marketUrl);
      } catch (cause: unknown) {
        console.error('Cafe Bazaar market link failed', cause);
        await openUrl('https://cafebazaar.ir');
      }
      return;
    }
    if (Platform.OS === 'android') {
      try {
        await startActivityAsync(systemActions[target]);
      } catch (cause: unknown) {
        console.error(`Android intent failed for ${target}`, cause);
        await openUrl(`intent:#Intent;action=${String(systemActions[target])};end`);
      }
      return;
    }
    await openUrl('app-settings:');
  } catch (cause: unknown) {
    console.error(`Could not open system target ${target}`, cause);
    throw new Error(cause instanceof Error ? cause.message : `Could not open ${target} settings.`);
  }
}

export function formatPhoneNumber(value: string): string {
  const normalized = value.replace(/[۰-۹]/g, (digit) => String('۰۱۲۳۴۵۶۷۸۹'.indexOf(digit))).replace(/[٠-٩]/g, (digit) => String('٠١٢٣٤٥٦٧٨٩'.indexOf(digit))).replace(/[^\d+]/g, '');
  if (normalized.startsWith('0098')) return `+98${normalized.slice(4)}`;
  if (normalized.startsWith('09')) return `+98${normalized.slice(1)}`;
  if (normalized.startsWith('9') && normalized.length === 10) return `+98${normalized}`;
  if (normalized.startsWith('+')) return normalized;
  return normalized;
}

export async function openPhoneDialer(recipient: string, explicitPhone?: string): Promise<void> {
  try {
    const phone = formatPhoneNumber(await resolvePhoneNumber(recipient, explicitPhone));
    if (!/^\+[1-9]\d{6,14}$/u.test(phone)) throw new Error('The phone number is not valid.');
    await openUrl(`tel:${phone}`);
  } catch (cause: unknown) {
    console.error('Phone dialer launch failed', cause);
    throw new Error(cause instanceof Error ? cause.message : 'The phone dialer could not be opened.');
  }
}

export async function openSmsComposer(recipient: string, message: string | undefined, explicitPhone?: string): Promise<void> {
  try {
    const phone = formatPhoneNumber(await resolvePhoneNumber(recipient, explicitPhone));
    if (!/^\+[1-9]\d{6,14}$/u.test(phone)) throw new Error('The phone number is not valid.');
    const body = message ? `?body=${encode(message)}` : '';
    await openUrl(`sms:${phone}${body}`);
  } catch (cause: unknown) {
    console.error('SMS composer launch failed', cause);
    throw new Error(cause instanceof Error ? cause.message : 'The SMS composer could not be opened.');
  }
}
EOF
echo "✅ services/device-actions.ts"

cat > services/ai-intent.ts << 'EOF'
import { generateText } from '@fastshot/ai';
import type { SkillId } from '@/store/types';
import { detectCommandLanguage, type CommandLanguage, type CommandAction, type MessengerId, type ParsedCommand, type SystemTarget } from './command-parser';

interface AiIntentPayload {
  action?: CommandAction;
  language?: CommandLanguage;
  title?: string;
  detail?: string;
  skill?: SkillId;
  recipient?: string;
  phoneNumber?: string;
  messenger?: MessengerId;
  message?: string;
  appName?: string;
  systemTarget?: SystemTarget;
  routineName?: string;
  noteText?: string;
  requiresConfirmation?: boolean;
}

function parseJson(response: string): AiIntentPayload | null {
  const cleaned = response.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/u, '').trim();
  try {
    const parsed: unknown = JSON.parse(cleaned);
    if (!parsed || typeof parsed !== 'object') return null;
    return parsed as AiIntentPayload;
  } catch (cause: unknown) {
    console.error('AI command response was not valid JSON', cause);
    return null;
  }
}

export async function parseCommandWithAi(input: string): Promise<ParsedCommand | null> {
  const language = detectCommandLanguage(input);
  try {
    const response = await generateText({
      prompt: [
        'Parse the user command into exactly one JSON object. Do not add markdown.',
        'Allowed action values: send_message, call_contact, send_sms, open_app, open_system, run_routine, create_note, find_contact, unknown.',
        'Allowed systemTarget values: settings, wifi, bluetooth, sound, battery, accessibility, app-store.',
        'Allowed messenger values: whatsapp, telegram, bale, eitaa.',
        'The language is fa for Persian and en for English. Preserve recipient and message text exactly.',
        'Required JSON keys: action, language, title, detail, skill, requiresConfirmation.',
        `Command: ${input}`,
      ].join('\n'),
      temperature: 0,
      injectBranding: false,
    });
    const payload = parseJson(response);
    const validActions: CommandAction[] = ['send_message', 'call_contact', 'send_sms', 'open_app', 'open_system', 'run_routine', 'create_note', 'find_contact', 'unknown'];
    const validSkills: SkillId[] = ['messages', 'calendar', 'reminders', 'smarthome', 'notes', 'system', 'web', 'routine'];
    if (!payload?.action || !validActions.includes(payload.action) || !payload.title || !payload.detail) return null;
    return {
      action: payload.action,
      language: payload.language === 'fa' ? 'fa' : language,
      original: input,
      confidence: 0.8,
      requiresConfirmation: Boolean(payload.requiresConfirmation),
      title: payload.title,
      detail: payload.detail,
      skill: payload.skill && validSkills.includes(payload.skill) ? payload.skill : 'web',
      recipient: payload.recipient,
      phoneNumber: payload.phoneNumber,
      messenger: payload.messenger,
      message: payload.message,
      appName: payload.appName,
      systemTarget: payload.systemTarget,
      routineName: payload.routineName,
      noteText: payload.noteText,
    };
  } catch (cause: unknown) {
    console.error('AI command parsing failed', cause);
    return null;
  }
}
EOF
echo "✅ services/ai-intent.ts"

echo ""
echo "🎉 مرحله ۳ تمام شد! ۴ فایل ساخته شد."
