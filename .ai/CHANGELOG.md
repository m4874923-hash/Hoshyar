# Changelog — Hoshyar

All notable changes to this project are documented here.
Format: [Date] [Commit] Description

---

## 2026-09-27

### [bde7d92] Phase 1-2: Migrate STT from @fastshot/ai to expo-speech-recognition
- Replaced transcribeAudio with expo-speech-recognition
- Rewrote services/speech.ts
- Rewrote app/voice.tsx for streaming
- Added startNativeRecognition / stopNativeRecognition

### [5248f65] Step 1: Add RECORD_AUDIO permission, expo-audio plugin, expo-asset
- Added permissions: [RECORD_AUDIO]
- Added expo-audio plugin
- Added expo-asset peer dependency

### [381f853] Enable new Hoshyar icon and microphone permissions
- Added new app icon (PNG)
- Added adaptive-icon, splash-icon, favicon
- Updated app.json with icon paths

### [ca703f6] Sync package lock with package.json
- Synced package-lock.json

### [bf8927f] Use Node 24 and npm ci for Expo SDK 57
- Changed workflow to Node 24
- Changed npm install to npm ci

---

## Uncommitted (pending)

### [UNCOMMITTED] Add MicOrb component
- Added MicOrb to components/nexus-ui.tsx
- Uses assets/icon.png
- Pulse animation when listening

### [UNCOMMITTED] Introduce .ai/ multi-agent control system
- Created .ai/PROJECT.md
- Created .ai/ARCHITECTURE.md
- Created .ai/AGENTS.md
- Created .ai/TASKS.md
- Created .ai/DECISIONS.md
- Created .ai/EXPERIMENTS.md
- Created .ai/FAILURES.md
- Created .ai/CHANGELOG.md
