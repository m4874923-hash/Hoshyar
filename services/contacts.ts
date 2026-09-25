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
