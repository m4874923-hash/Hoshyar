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
