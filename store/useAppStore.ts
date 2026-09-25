import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';
import type { CommandLog, Preferences, Routine, SkillAdapterConfig, SkillId } from './types';

const makeId = (prefix: string) => `${prefix}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

const createInitialRoutines = (): Routine[] => [
  {
    id: 'routine-morning-kickoff',
    title: 'Morning Kickoff',
    icon: 'sunny-outline',
    color: '#18D7E8',
    triggerType: 'schedule',
    triggerValue: '08:00 AM',
    isEnabled: true,
    steps: [
      { id: 'morning-1', skill: 'calendar', action: 'list_events', description: "Fetch today's schedule", params: {} },
      { id: 'morning-2', skill: 'smarthome', action: 'set_thermostat', description: 'Set Thermostat to 72F', params: { temperature: 72 } },
      { id: 'morning-3', skill: 'notes', action: 'create_note', description: 'Create daily priority note', params: { title: 'Daily priorities' } },
    ],
  },
  {
    id: 'routine-commute',
    title: 'Meeting Commute Prep',
    icon: 'navigate-outline',
    color: '#8C7CFF',
    triggerType: 'manual',
    triggerValue: 'Manual tap',
    isEnabled: true,
    steps: [
      { id: 'commute-1', skill: 'web', action: 'traffic_check', description: 'Check traffic to Office', params: { destination: 'Office' } },
      { id: 'commute-2', skill: 'messages', action: 'send_message', description: 'Send ETA to Slack #team-sync', params: { channel: '#team-sync' } },
      { id: 'commute-3', skill: 'system', action: 'set_dnd', description: 'Set phone to DND', params: { enabled: true } },
    ],
  },
  {
    id: 'routine-evening',
    title: 'Evening Wind-down',
    icon: 'moon-outline',
    color: '#B06CFF',
    triggerType: 'schedule',
    triggerValue: '09:30 PM',
    isEnabled: true,
    steps: [
      { id: 'evening-1', skill: 'notes', action: 'summarize_tasks', description: 'Summarize unfinished tasks', params: {} },
      { id: 'evening-2', skill: 'smarthome', action: 'set_lights', description: 'Dim Living Room lights to 20%', params: { brightness: 20 } },
      { id: 'evening-3', skill: 'system', action: 'set_alarm', description: 'Enable Sleep Alarm', params: { time: '06:30 AM' } },
    ],
  },
  {
    id: 'routine-cleanup',
    title: 'Quick Clean-up',
    icon: 'sparkles-outline',
    color: '#F5A742',
    triggerType: 'voice',
    triggerValue: 'Clean up my day',
    isEnabled: false,
    steps: [
      { id: 'cleanup-1', skill: 'messages', action: 'draft_replies', description: 'Draft unread replies', params: {} },
      { id: 'cleanup-2', skill: 'calendar', action: 'resolve_conflicts', description: "Find tomorrow's conflicts", params: {} },
    ],
  },
];

const createInitialLogs = (): CommandLog[] => {
  const now = Date.now();
  return [
    {
      id: 'log-routine-morning',
      userInput: 'Run Morning Kickoff',
      intent: 'Routine.morning_kickoff',
      skill: 'routine',
      parameters: { stepsExecuted: 3, trigger: 'schedule' },
      status: 'success',
      timestamp: now - 45 * 60 * 1000,
      executionTimeMs: 184,
      summary: '3/3 Steps executed',
    },
    {
      id: 'log-calendar-sync',
      userInput: 'Schedule sync with the Product Team',
      intent: 'Calendar.create_event',
      skill: 'calendar',
      parameters: { title: 'Sync with Product Team', time: 'Today 11:20 AM', participants: ['Sarah', 'Alex'] },
      status: 'success',
      timestamp: now - 8 * 60 * 60 * 1000,
      executionTimeMs: 12,
      summary: '"Sync with Product Team"',
    },
    {
      id: 'log-message-maya',
      userInput: 'Tell Maya I am on my way',
      intent: 'Messages.send_sms',
      skill: 'messages',
      parameters: { recipient: 'Maya', message: 'On my way', etaMinutes: 15 },
      status: 'success',
      timestamp: now - 9 * 60 * 60 * 1000,
      executionTimeMs: 28,
      summary: 'To Maya: "On my way"',
    },
    {
      id: 'log-thermostat',
      userInput: 'Set the thermostat to 70 degrees',
      intent: 'SmartHome.set_thermostat',
      skill: 'smarthome',
      parameters: { target: '70F', room: 'Living Room' },
      status: 'warning',
      timestamp: now - 24 * 60 * 60 * 1000,
      executionTimeMs: 410,
      summary: 'Target: 70F',
    },
  ];
};

const initialSkills: SkillAdapterConfig[] = [
  { id: 'messages', name: 'Messages & Chat', icon: 'chatbubble-ellipses-outline', accent: '#18D7E8', description: 'A fast lane for keeping people in the loop.', capabilities: ['Send message', 'Fetch unread', 'Draft reply'], sampleCommands: ['Send Maya a quick update', 'Show unread messages'], isAuthorized: true },
  { id: 'calendar', name: 'Calendar & Schedule', icon: 'calendar-outline', accent: '#8C7CFF', description: 'Turn intent into time, without the back-and-forth.', capabilities: ['Add event', 'Check availability', 'Resolve conflicts'], sampleCommands: ['Find a 30 minute slot tomorrow', 'Move my 2 PM review'], isAuthorized: true },
  { id: 'reminders', name: 'Tasks & Notes', icon: 'checkbox-outline', accent: '#F5A742', description: 'Capture, organize, and close the loop.', capabilities: ['Create markdown note', 'Append bullet', 'Toggle reminder'], sampleCommands: ['Add milk to my errands note', 'Remind me after lunch'], isAuthorized: true },
  { id: 'smarthome', name: 'Smart Home IoT', icon: 'home-outline', accent: '#40D99B', description: 'Make your environment match the moment.', capabilities: ['Dim lights', 'Set thermostat', 'Check door lock'], sampleCommands: ['Dim study lights to 40%', 'Set the office to 72 degrees'], isAuthorized: false },
  { id: 'system', name: 'System Controls', icon: 'options-outline', accent: '#E667F0', description: 'Tune the device around your attention.', capabilities: ['Volume', 'Brightness', 'DND mode'], sampleCommands: ['Turn on Do Not Disturb', 'Set brightness to 60%'], isAuthorized: true },
  { id: 'web', name: 'Web & Knowledge AI', icon: 'globe-outline', accent: '#5E9CFF', description: 'A research layer for the questions between tasks.', capabilities: ['Live search simulation', 'Weather forecast', 'Summarize text'], sampleCommands: ['What is on my schedule?', 'Summarize this note'], isAuthorized: true },
];

interface AppStore {
  preferences: Preferences;
  routines: Routine[];
  logs: CommandLog[];
  skills: SkillAdapterConfig[];
  draftCommand: string | null;
  addRoutine: (routine: Routine) => void;
  updateRoutine: (id: string, patch: Partial<Routine>) => void;
  toggleRoutine: (id: string) => void;
  addLog: (log: Omit<CommandLog, 'id' | 'timestamp'>) => string;
  clearLogs: () => void;
  updateSkillAuthorization: (id: SkillId) => void;
  setDraftCommand: (command: string | null) => void;
  setVoiceLanguage: (language: Preferences['voiceLanguage']) => void;
  setSpeechSettings: (settings: Pick<Preferences, 'speechRate' | 'speechPitch'>) => void;
}

export const useAppStore = create<AppStore>()(
  persist(
    (set) => ({
      preferences: { hapticsEnabled: true, voiceLanguage: 'en-US', speechRate: 1, speechPitch: 1 },
      routines: createInitialRoutines(),
      logs: createInitialLogs(),
      skills: initialSkills,
      draftCommand: null,
      addRoutine: (routine) => set((state) => ({ routines: [routine, ...state.routines] })),
      updateRoutine: (id, patch) => set((state) => ({ routines: state.routines.map((routine) => (routine.id === id ? { ...routine, ...patch } : routine)) })),
      toggleRoutine: (id) => set((state) => ({ routines: state.routines.map((routine) => (routine.id === id ? { ...routine, isEnabled: !routine.isEnabled } : routine)) })),
      addLog: (log) => {
        const id = makeId('log');
        set((state) => ({ logs: [{ ...log, id, timestamp: Date.now() }, ...state.logs].slice(0, 50) }));
        return id;
      },
      clearLogs: () => set({ logs: [] }),
      updateSkillAuthorization: (id) => set((state) => ({ skills: state.skills.map((skill) => (skill.id === id ? { ...skill, isAuthorized: !skill.isAuthorized } : skill)) })),
      setDraftCommand: (command) => set({ draftCommand: command }),
      setVoiceLanguage: (language) => set((state) => ({ preferences: { ...state.preferences, voiceLanguage: language } })),
      setSpeechSettings: (settings) => set((state) => ({ preferences: { ...state.preferences, ...settings } })),
    }),
    {
      name: 'hoshyar-storage',
      storage: createJSONStorage(() => AsyncStorage),
      partialize: (state) => ({ preferences: state.preferences, routines: state.routines, logs: state.logs, skills: state.skills }),
    },
  ),
);
