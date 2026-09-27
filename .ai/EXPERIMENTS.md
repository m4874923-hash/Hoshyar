# Experiments — Hoshyar

## Format
ID / DATE / GOAL / HYPOTHESIS / METHOD / RESULT / EVIDENCE / STATUS / DO NOT REPEAT

---

## EXP-001 - Use expo-speech-recognition for STT

**ID:** EXP-001
**DATE:** 2026-09-27
**GOAL:** Replace @fastshot/ai transcribe with a working STT.
**HYPOTHESIS:** expo-speech-recognition@57.1.0 works with Expo SDK 57.
**METHOD:**
- npx expo install expo-speech-recognition
- Rewrite services/speech.ts
- Rewrite app/voice.tsx
- npx tsc --noEmit
**RESULT:** Pending build + runtime test.
**EVIDENCE:**
- npm ls -> expo-speech-recognition@57.1.0
- tsc --noEmit -> only 2 pre-existing errors
**STATUS:** IN PROGRESS
**DO NOT REPEAT:** No

---

## EXP-002 - Use @react-native-voice/voice for STT

**ID:** EXP-002
**DATE:** 2026-09-27
**GOAL:** Alternative STT package.
**HYPOTHESIS:** @react-native-voice/voice could work.
**METHOD:** Research only.
**RESULT:** REJECTED - package is deprecated and archived.
**EVIDENCE:** Repository shows "package deprecated and archived".
**STATUS:** REJECTED
**DO NOT REPEAT:** YES - do not install @react-native-voice/voice.

---

## EXP-003 - Remove getSupportedLocales() from start path

**ID:** EXP-003
**DATE:** 2026-09-27
**GOAL:** Fix native crash on mic button.
**HYPOTHESIS:** getSupportedLocales() causes crash on Android 12 and below.
**METHOD:**
- Remove getSupportedLocales() from startNativeRecognition.
- Add maxAlternatives: 1.
- Add getStateAsync() before start/stop.
**RESULT:** Pending build + runtime test.
**EVIDENCE:** tsc passes with no new errors.
**STATUS:** IN PROGRESS
**DO NOT REPEAT:** No
