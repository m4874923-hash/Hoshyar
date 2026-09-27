# Hoshyar Project

## Identity
- **Name:** Hoshyar (هوشیار)
- **Type:** Persian Android Voice Assistant
- **Package:** com.hoshyar.app
- **Version:** 1.0.0

## Tech Stack (verified from repository)
- React Native: 0.86.3
- Expo SDK: ~57.0.20
- React: 19.2.3
- TypeScript: ~6.0.3
- State: Zustand ^5.0.10
- Routing: expo-router ~57.0.19

## Repository
- **GitHub:** https://github.com/m4874923-hash/Hoshyar
- **Branch:** main
- **Last Commit:** bde7d92 "Phase 1-2: Migrate STT from @fastshot/ai to expo-speech-recognition"

## Project Structure (verified)

## Core Capabilities (verified from code)
- Persian/English STT via `expo-speech-recognition` (streaming)
- Persian/English TTS via `expo-speech`
- Persian rule-based command parser (`command-parser.ts`)
- AI fallback via `@fastshot/ai` — STILL PRESENT in `ai-intent.ts`
- Messenger adapters via deep links (WhatsApp, Telegram, Bale, Eitaa)
- Contacts lookup (`expo-contacts`)
- Phone dialer + SMS composer
- Android system settings deep links
- Confirmation flow for sensitive actions
- Task pause/resume/cancel (`task-engine.ts`)
- Accessibility Service config plugin (observe-only stub)
- Persian RTL UI with cyber-slate theme

## Known Issues (verified from code)
1. TypeScript errors in `app/(tabs)/index.tsx:155-156` (TaskRun possibly undefined)
2. `@fastshot/ai` still in:
   - `services/ai-intent.ts:1`
   - `package.json:14`
3. Uncommitted changes:
   - `app/voice.tsx` (modified)
   - `components/nexus-ui.tsx` (modified)
   - `services/speech.ts` (modified)
   - `app/(tabs)/index.tsx.backup` (untracked)
4. Accessibility Service is observe-only
5. Some tests are placeholders

## UNKNOWN
- Exact runtime behavior of MicOrb on Android
- Whether expo-speech-recognition fa-IR works on all Android devices
- Whether STT streaming actually returns transcript on target device
- Accessibility Service runtime behavior
- Background/Wake-Word implementation status (NOT implemented)

## Goal (Long-term)
Transform Hoshyar into a real Persian voice-first assistant:
- Understands natural Persian commands
- Executes real Android actions
- Supports free conversation (LLM)
- Uses Accessibility Service for UI automation
- Has wake-word and background operation

## Current Phase
Phase 2: Multi-Agent Project Control System (IN PROGRESS)
