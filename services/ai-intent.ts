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
