# Failures — Hoshyar

## Format
ID / COMPONENT / ATTEMPT / ERROR / ROOT CAUSE / FIX / STATUS / REPEATABLE?

---

## FAIL-001 - Build fails at yarn step (GitHub Actions)

**ID:** FAIL-001
**COMPONENT:** GitHub Actions + EAS Build
**ATTEMPT:** npm install via GitHub Actions.
**ERROR:** The process /usr/local/bin/yarn failed with exit code 1
**ROOT CAUSE:** Expo SDK 57 requires Node 22.13+; workflow used Node 20.
**FIX:** Change workflow to node-version: 24 + npm ci + sync package-lock.json.
**STATUS:** FIXED (Build #7 passed)
**REPEATABLE?:** No

---

## FAIL-002 - Microphone permission missing in APK

**ID:** FAIL-002
**COMPONENT:** Android APK / app.json
**ATTEMPT:** Tap microphone button in installed APK.
**ERROR:** No Microphone permission in Settings; mic button did nothing.
**ROOT CAUSE:** app.json had no permissions array and no expo-audio plugin.
**FIX:** Add permissions: [RECORD_AUDIO] and expo-audio plugin (commit 5248f65).
**STATUS:** FIXED
**REPEATABLE?:** No

---

## FAIL-003 - @fastshot/ai requires EXPO_PUBLIC_NEWELL_API_URL

**ID:** FAIL-003
**COMPONENT:** services/speech.ts / services/ai-intent.ts
**ATTEMPT:** Record audio and call transcribeRecordedAudio().
**ERROR:** [@fastshot/ai] EXPO_PUBLIC_NEWELL_API_URL is not configured.
**ROOT CAUSE:** @fastshot/ai requires a Fastshot server. Not available in standalone APK.
**FIX:** Replace with expo-speech-recognition (streaming). Stub transcribeRecordedAudio.
**STATUS:** PARTIAL (speech.ts fixed, ai-intent.ts still uses @fastshot/ai)
**REPEATABLE?:** No

---

## FAIL-004 - Native crash on second mic tap

**ID:** FAIL-004
**COMPONENT:** app/voice.tsx + services/speech.ts
**ATTEMPT:** Tap mic twice.
**ERROR:** App crashes.
**ROOT CAUSE:** UNKNOWN. Hypothesis: getSupportedLocales() or stop() on invalid session.
**FIX:** Pending - removed getSupportedLocales(), added getStateAsync() check before stop.
**STATUS:** IN PROGRESS (needs Build + logcat to confirm)
**REPEATABLE?:** Unknown
