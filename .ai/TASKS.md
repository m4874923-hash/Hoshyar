# Tasks — Hoshyar

## CURRENT TASK
**Establish Multi-Agent Project Control System**

## STATUS
IN PROGRESS

## OWNER
ARCHITECT / ORCHESTRATOR

## ALLOWED FILES
- `.ai/PROJECT.md`
- `.ai/ARCHITECTURE.md`
- `.ai/AGENTS.md`
- `.ai/TASKS.md`
- `.ai/DECISIONS.md`
- `.ai/EXPERIMENTS.md`
- `.ai/FAILURES.md`
- `.ai/CHANGELOG.md`

## OBJECTIVE
Create the `.ai/` directory with 8 machine-readable control files to manage multi-agent development of Hoshyar.

## SUCCESS CRITERIA
- [ ] All 8 files exist under `.ai/`
- [ ] Each file has a clear, machine-readable structure
- [ ] No file outside `.ai/` is modified
- [ ] `git diff --stat` shows only `.ai/` additions
- [ ] `git status` is clean except for `.ai/`

## TEST PLAN
## BLOCKERS
None

## NEXT ACTION
Create all 8 files, then report to ARCHITECT.

---

## BACKLOG (not yet scheduled)

### Phase 3: UI Redesign (app/(tabs)/index.tsx)
- ChatGPT-like UI
- Compact header with logo + status
- Remove NEXT UP card
- MicOrb in bottom bar
- Preserve all logic

### Phase 4: Remove @fastshot/ai
- Remove from `services/ai-intent.ts`
- Remove from `package.json`
- Replace AI fallback with online LLM or local model

### Phase 5: Fix TypeScript errors
- `app/(tabs)/index.tsx:155-156`
- TaskRun possibly undefined

### Phase 6: Accessibility Service real implementation
- canRetrieveWindowContent
- clickText, findText, typeText

### Phase 7: Wake Word
- Porcupine or alternative
- Background operation

### Phase 8: LLM integration
- Free conversation
- Online or local
