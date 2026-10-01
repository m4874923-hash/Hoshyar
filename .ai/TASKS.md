# Tasks — Hoshyar

## CURRENT TASK
Setup AI Loop for Multi-Model Collaboration (ChatGPT + DeepSeek + Grok)

## STATUS
IN PROGRESS

## OWNER
ARCHITECT / ORCHESTRATOR (ChatGPT)

## ALLOWED FILES
- .ai/AGENTS.md (update)
- .ai/AI_LOOP.md (create)
- .ai/TASKS.md (update)
- .ai/DECISIONS.md (update)

## OBJECTIVE
Define roles, boundaries, flow, and stop conditions for the multi-model AI Loop.

## SUCCESS CRITERIA
- [ ] AGENTS.md updated with 4 model roles
- [ ] AI_LOOP.md created with full flow
- [ ] TASKS.md current task updated
- [ ] DECISIONS.md has entry for loop setup
- [ ] No app code touched
- [ ] No build.yml touched
- [ ] No token touched

## TEST PLAN
- Verify all .ai/ files exist
- git diff --stat shows only .ai/

## BLOCKERS
None

## NEXT ACTION
- Hand off to Grok for review

---

## BACKLOG

### Phase 3: STT Proof of Concept
- Test STT in Gspace (Huawei device)
- If pass -> v2 with Google STT
- If fail -> Vosk

### Phase 4: Hoshyar v2
- New project structure
- Conversation UI (ChatGPT-like)
- Real STT + Parser + Executor
- No fake data

### Phase 5: Remove @fastshot/ai

### Phase 6: Fix TypeScript errors

### Phase 7: Accessibility Service real implementation

### Phase 8: Wake Word

### Phase 9: LLM integration
