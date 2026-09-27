# Decisions — Hoshyar

## Format
DATE: / DECISION: / REASON: / ALTERNATIVES: / CONSEQUENCE:

---

## 2026-09-27 - Use expo-speech-recognition for STT

**DATE:** 2026-09-27
**DECISION:** Replace @fastshot/ai transcribe with expo-speech-recognition (streaming).
**REASON:**
- @fastshot/ai requires EXPO_PUBLIC_NEWELL_API_URL (not configured in standalone APK).
- expo-speech-recognition@57.1.0 is SDK 57 compatible.
- @react-native-voice/voice is deprecated and archived.
**ALTERNATIVES:**
- @react-native-voice/voice (rejected - deprecated)
- Vosk (deferred - heavy)
- Whisper API (rejected - requires internet + API key)
**CONSEQUENCE:**
- services/speech.ts rewritten.
- app/voice.tsx migrated to streaming.
- @fastshot/ai still remains in services/ai-intent.ts and package.json (Phase 4).

---

## 2026-09-27 - Keep Expo SDK 57, do not migrate to native yet

**DATE:** 2026-09-27
**DECISION:** Keep Expo SDK 57. Do not rewrite in Kotlin/native yet.
**REASON:**
- Existing APK pipeline works (GitHub Actions -> EAS).
- Migration cost is high.
- STT, TTS, parser, executor already work in Expo.
**ALTERNATIVES:**
- Full native Kotlin rewrite (rejected - too costly)
- Development Build with custom native modules (deferred)
**CONSEQUENCE:**
- Wake Word and Background Service deferred.
- Accessibility Service stays observe-only.

---

## 2026-09-27 - Introduce .ai/ multi-agent control system

**DATE:** 2026-09-27
**DECISION:** Create .ai/ with 8 control files.
**REASON:**
- Development is chaotic.
- Repeated experiments waste time.
- Need machine-readable state for next agent.
**ALTERNATIVES:**
- Continue as-is (rejected)
- External tool (rejected - Termux-only)
**CONSEQUENCE:**
- All future changes go through .ai/ workflow.
