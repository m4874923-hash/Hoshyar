import AsyncStorage from '@react-native-async-storage/async-storage';

const NOTES_KEY = 'hoshyar-notes';

interface StoredNote {
  id: string;
  text: string;
  createdAt: number;
}

export async function saveNote(text: string): Promise<StoredNote> {
  try {
    const existingRaw = await AsyncStorage.getItem(NOTES_KEY);
    const decoded: unknown = existingRaw ? JSON.parse(existingRaw) : [];
    const existing: StoredNote[] = Array.isArray(decoded) ? decoded.filter((item): item is StoredNote => Boolean(item) && typeof item === 'object' && typeof (item as StoredNote).id === 'string' && typeof (item as StoredNote).text === 'string' && typeof (item as StoredNote).createdAt === 'number') : [];
    const note: StoredNote = { id: `note-${Date.now()}`, text, createdAt: Date.now() };
    await AsyncStorage.setItem(NOTES_KEY, JSON.stringify([note, ...existing].slice(0, 100)));
    return note;
  } catch (cause: unknown) {
    console.error('Note could not be saved', cause);
    throw new Error(cause instanceof Error ? cause.message : 'The note could not be saved.');
  }
}
