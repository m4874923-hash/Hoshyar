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
