


# Architecture — Hoshyar

## Implemented (verified from repository)

### Stack
- React Native 0.86.3
- Expo SDK ~57.0.20
- TypeScript ~6.0.3
- Zustand ^5.0.10 (state)
- expo-router ~57.0.19 (routing)

### STT / Command Flow (implemented)
- Microphone
- expo-audio (recording)
- expo-speech-recognition (streaming STT)
- transcript
- services/speech.ts (startNativeRecognition / stopNativeRecognition)
- app/voice.tsx (useSpeechRecognitionEvent)
- setDraftCommand(transcript)
- app/(tabs)/index.tsx
- parseCommand (services/command-parser.ts)
- ParsedCommand
- executeCommand (services/command-executor.ts)
- services/device-actions.ts (Linking / IntentLauncher)
- Android

### TTS Flow (implemented)
- app/voice.tsx (speakTranscript)
- speakText (services/speech.ts)
- expo-speech
- Android TTS

### Layer Map
| Layer | Location | Responsibility |
|-------|----------|----------------|
| UI | app/, components/ | Screens, tabs, overlays |
| State | store/useAppStore.ts | Preferences, routines, logs, skills, draftCommand |
| NLU | services/command-parser.ts | Persian regex parser |
| AI fallback | services/ai-intent.ts | [DEPRECATED] uses @fastshot/ai |
| Execution | services/command-executor.ts | Action dispatch |
| Task | services/task-engine.ts | Multi-step, pause/resume/cancel |
| Speech | services/speech.ts | STT + TTS |
| Device | services/device-actions.ts | Deep links, intents |
| Contacts | services/contacts.ts | expo-contacts |
| Notes | services/notes.ts | AsyncStorage |
| Accessibility | services/accessibility.ts | Observe-only stub |
| Config | app.json, eas.json | Expo + EAS config |

### Accessibility Plugin
- File: plugins/with-accessibility-service.js
- Adds service: com.hoshyar.app.HoshyarAccessibilityService
- Permission: android.permission.BIND_ACCESSIBILITY_SERVICE
- Config: canRetrieveWindowContent=false (observe-only)
- Implementation: STUB (empty onAccessibilityEvent)

---

## Target Architecture (NOT implemented)

### Voice-First Loop (target)
- Wake Word "هوشیار"
- Background Service (Android native)
- STT (on-device or online)
- NLU (rule-based + LLM)
- Action Execution
- TTS Response
- return to listening

### Components Needed
| Component | Status | Notes |
|-----------|--------|-------|
| Wake Word | NOT implemented | Needs native (Porcupine or similar) |
| Background Service | NOT implemented | Needs Android Foreground Service |
| Accessibility UI automation | STUB only | Needs clickText, findText, typeText |
| LLM free conversation | NOT implemented | Needs online API or local model |
| Context memory | NOT implemented | Needs conversation history |
| Full offline mode | PARTIAL | STT depends on device engine; LLM is online |

### Migration Boundaries
- Expo to Expo (kept)
- Expo to Native modules (allowed via Development Build)
- No full rewrite to Kotlin planned for current phase
# Architecture — Hoshyar

## Implemented (verified from repository)

### Stack
- React Native 0.86.3
- Expo SDK ~57.0.20
- TypeScript ~6.0.3
- Zustand ^5.0.10 (state)
- expo-router ~57.0.19 (routing)

### STT / Command Flow (implemented)
- Microphone
- expo-audio (recording)
- expo-speech-recognition (streaming STT)
- transcript
- services/speech.ts (startNativeRecognition / stopNativeRecognition)
- app/voice.tsx (useSpeechRecognitionEvent)
- setDraftCommand(transcript)
- app/(tabs)/index.tsx
- parseCommand (services/command-parser.ts)
- ParsedCommand
- executeCommand (services/command-executor.ts)
- services/device-actions.ts (Linking / IntentLauncher)
- Android

### TTS Flow (implemented)
- app/voice.tsx (speakTranscript)
- speakText (services/speech.ts)
- expo-speech
- Android TTS

### Layer Map
| Layer | Location | Responsibility |
|-------|----------|----------------|
| UI | app/, components/ | Screens, tabs, overlays |
| State | store/useAppStore.ts | Preferences, routines, logs, skills, draftCommand |
| NLU | services/command-parser.ts | Persian regex parser |
| AI fallback | services/ai-intent.ts | [DEPRECATED] uses @fastshot/ai |
| Execution | services/command-executor.ts | Action dispatch |
| Task | services/task-engine.ts | Multi-step, pause/resume/cancel |
| Speech | services/speech.ts | STT + TTS |
| Device | services/device-actions.ts | Deep links, intents |
| Contacts | services/contacts.ts | expo-contacts |
| Notes | services/notes.ts | AsyncStorage |
| Accessibility | services/accessibility.ts | Observe-only stub |
| Config | app.json, eas.json | Expo + EAS config |

### Accessibility Plugin
- File: plugins/with-accessibility-service.js
- Adds service: com.hoshyar.app.HoshyarAccessibilityService
- Permission: android.permission.BIND_ACCESSIBILITY_SERVICE
- Config: canRetrieveWindowContent=false (observe-only)
- Implementation: STUB (empty onAccessibilityEvent)


---

## Target Architecture (NOT implemented)

### Voice-First Loop (target)
- Wake Word "هوشیار"
- Background Service (Android native)
- STT (on-device or online)
- NLU (rule-based + LLM)
- Action Execution
- TTS Response
- return to listening

### Components Needed
| Component | Status | Notes |
|-----------|--------|-------|
بزنمkkkkkkmk
بزنمkkkkkkmkk
| Wake Word | NOT implemented | Needs native (Porcupine or similar) |
| Background Service | NOT implemented | Needs Android Foreground Service |
| Accessibility UI automation | STUB only | Needs clickText, findText, typeText |
| LLM free conversation | NOT implemented | Needs online API or local model |
| Context memory | NOT implemented | Needs conversation history |
| Full offline mode | PARTIAL | STT depends on device engine; LLM is online |

### Migration Boundaries
- Expo to Expo (kept)
- Expo to Native modules (allowed via Development Build)
- No full rewrite to Kotlin planned for current phaseبزنمk
بزنمkk










# Architecture — Hoshyar

## Implemented (verified from repository)

### Stack
- React Native 0.86.3
- Expo SDK ~57.0.20
- TypeScript ~6.0.3
- Zustand ^5.0.10 (state)
- expo-router ~57.0.19 (routing)

### STT / Command Flow (implemented)
- Microphone
- expo-audio (recording)
- expo-speech-recognition (streaming STT)
- transcript
- services/speech.ts (startNativeRecognition / stopNativeRecognition)
- app/voice.tsx (useSpeechRecognitionEvent)
- setDraftCommand(transcript)
- app/(tabs)/index.tsx
- parseCommand (services/command-parser.ts)
- ParsedCommand
- executeCommand (services/command-executor.ts)
- services/device-actions.ts (Linking / IntentLauncher)
- Android

### TTS Flow (implemented)
- app/voice.tsx (speakTranscript)
- speakText (services/speech.ts)
- expo-speech
- Android TTS

### Layer Map
| Layer | Location | Responsibility |
|-------|----------|----------------|
| UI | app/, components/ | Screens, tabs, overlays |
| State | store/useAppStore.ts | Preferences, routines, logs, skills, draftCommand |
| NLU | services/command-parser.ts | Persian regex parser |
| AI fallback | services/ai-intent.ts | [DEPRECATED] uses @fastshot/ai |
| Execution | services/command-executor.ts | Action dispatch |
| Task | services/task-engine.ts | Multi-step, pause/resume/cancel |
| Speech | services/speech.ts | STT + TTS |
| Device | services/device-actions.ts | Deep links, intents |
| Contacts | services/contacts.ts | expo-contacts |
| Notes | services/notes.ts | AsyncStorage |
| Accessibility | services/accessibility.ts | Observe-only stub |
| Config | app.json, eas.json | Expo + EAS config |

### Accessibility Plugin
- File: plugins/with-accessibility-service.js
- Adds service: com.hoshyar.app.HoshyarAccessibilityService
- Permission: android.permission.BIND_ACCESSIBILITY_SERVICE
- Config: canRetrieveWindowContent=false (observe-only)
- Implementation: STUB (empty onAccessibilityEvent)

---

## Target Architecture (NOT implemented)

### Voice-First Loop (target)
- Wake Word "هوشیار"
- Background Service (Android native)
- STT (on-device or online)
- NLU (rule-based + LLM)
- Action Execution
- TTS Response
- return to listening

### Components Needed
| Component | Status | Notes |
|-----------|--------|-------|
| Wake Word | NOT implemented | Needs native (Porcupine or similar) |
| Background Service | NOT implemented | Needs Android Foreground Service |
| Accessibility UI automation | STUB only | Needs clickText, findText, typeText |
| LLM free conversation | NOT implemented | Needs online API or local model |
| Context memory | NOT implemented | Needs conversation history |
| Full offline mode | PARTIAL | STT depends on device engine; LLM is online |

### Migration Boundaries
- Expo to Expo (kept)
- Expo to Native modules (allowed via Development Build)
- No full rewrite to Kotlin planned for current phase





c
cx


## Implemented (verified from repository)

### Stack
- React Native 0.86.3
- Expo SDK ~57.0.20
- TypeScript ~6.0.3
- Zustand ^5.0.10 (state)
- expo-router ~57.0.19 (routing)
