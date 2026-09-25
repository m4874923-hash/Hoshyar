export type SkillId =
  | 'messages'
  | 'calendar'
  | 'reminders'
  | 'smarthome'
  | 'notes'
  | 'system'
  | 'web'
  | 'routine';

export type TriggerType = 'manual' | 'schedule' | 'voice';
export type LogStatus = 'success' | 'pending' | 'failed' | 'warning';
export type StepStatus = 'pending' | 'executing' | 'completed' | 'failed';

export type ParameterValue =
  | string
  | number
  | boolean
  | null
  | ParameterValue[]
  | { [key: string]: ParameterValue };

export interface Preferences {
  hapticsEnabled?: boolean;
  voiceLanguage?: 'fa-IR' | 'en-US';
  speechRate?: number;
  speechPitch?: number;
}

export interface ActionStep {
  id: string;
  skill: SkillId;
  action: string;
  description: string;
  params: Record<string, string | number | boolean>;
}

export interface Routine {
  id: string;
  title: string;
  icon: string;
  color: string;
  triggerType: TriggerType;
  triggerValue: string;
  isEnabled: boolean;
  steps: ActionStep[];
  runningStep?: number;
}

export interface CommandLog {
  id: string;
  userInput: string;
  intent: string;
  skill: SkillId;
  parameters: Record<string, ParameterValue>;
  status: LogStatus;
  timestamp: number;
  executionTimeMs: number;
  summary: string;
}

export interface SkillAdapterConfig {
  id: SkillId;
  name: string;
  icon: string;
  description: string;
  accent: string;
  isAuthorized: boolean;
  sampleCommands: string[];
  capabilities: string[];
}
