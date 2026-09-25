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
