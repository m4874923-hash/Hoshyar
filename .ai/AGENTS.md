# Agent Roles — Hoshyar AI Loop

## Active Models (Current Phase)

### 1. ChatGPT — ARCHITECT / ORCHESTRATOR
**Model:** ChatGPT
**Responsibility:**
- Define architecture and solution path
- Split work into tasks
- Decide PASS/FAIL/BLOCKED
- Approve next phase
- Only model that can authorize new dependencies

**Constraints:**
- No code changes
- Must update .ai/TASKS.md before each task
- Must provide SUCCESS CRITERIA

**Output Format:**
- TASKS.md update
- Decision entry in DECISIONS.md

---

### 2. DeepSeek — LEAD CODER / IMPLEMENTER
**Model:** DeepSeek
**Responsibility:**
- Implement the assigned task
- Run commands (build, test, diagnostics)
- Self-Review after implementation
- Only model that modifies code

**Constraints:**
- Only touch files listed in ALLOWED FILES
- Cannot install new dependencies without ChatGPT approval
- Cannot change architecture
- Must run Self-Review before handoff

**Output Format:**
- Changed files list
- git diff --stat
- Test results
- Self-Review report

---

### 3. Grok — INDEPENDENT REVIEWER
**Model:** Grok
**Responsibility:**
- Independent code review
- Find bugs DeepSeek missed
- Check regressions
- Verify SUCCESS CRITERIA

**Constraints:**
- No code changes
- Only approve or reject with reason
- Must provide exact file + line for bugs

**Output Format:**
- APPROVED / REJECTED
- If REJECTED: exact reason + file + line
- Required fixes

---

### 4. User — FINAL TESTER
**Responsibility:**
- Install APK on real device
- Run runtime tests
- Report exact results
- Final approval

---

## AI Loop Flow

1. ChatGPT defines task (TASKS.md updated)
2. DeepSeek implements (only ALLOWED FILES)
3. DeepSeek Self-Review
4. Grok reviews (APPROVED or REJECTED)
5. If REJECTED: DeepSeek fixes (max 3 cycles)
6. ChatGPT decides PASS/FAIL/BLOCKED
7. User tests on real device

## Decision Boundaries

| Decision | Owner | Cannot be overridden by |
|----------|-------|-------------------------|
| Architecture change | ChatGPT | DeepSeek, Grok |
| New dependency | ChatGPT | DeepSeek, Grok |
| Task definition | ChatGPT | DeepSeek, Grok |
| Code implementation | DeepSeek | ChatGPT (review only), Grok (review only) |
| Code approval | Grok | DeepSeek |
| Final PASS/FAIL/BLOCKED | ChatGPT | DeepSeek, Grok |
| Real-device test | User | All models |

## Fix Loop Limits

- Max 3 fix cycles per task
- After 3 cycles: DeepSeek must STOP and request ChatGPT decision
- BLOCKED conditions:
  - 3 fix cycles without PASS
  - New dependency needed
  - Architecture change needed
  - Test environment broken
  - Conflicting requirements

## Stop Conditions for DeepSeek

DeepSeek MUST stop and request ChatGPT decision when:
1. Task needs files outside ALLOWED FILES
2. Task needs new dependency
3. Task needs architecture change
4. 3 fix cycles completed without PASS
5. Test environment is broken
6. Requirements are ambiguous
7. Grok REJECTED more than 3 times
8. Command output is unclear

## Handoff Protocol

### ChatGPT to DeepSeek
Provide: CURRENT TASK, STATUS, ALLOWED FILES, OBJECTIVE, SUCCESS CRITERIA, TEST PLAN, BLOCKERS

### DeepSeek to Grok
Provide: Changed files, git diff --stat, Test output, Self-Review report, Commands run

### Grok to ChatGPT
Provide: APPROVED / REJECTED, If REJECTED: exact fixes, Files affected, Severity level

### ChatGPT to User
Provide: Build status, APK location, Test instructions, Expected result

## Emergency Stop

If any model detects: Data loss risk, Security issue, Irreversible operation
-> STOP immediately and escalate to ChatGPT

## Conflict Resolution

If two models disagree:
1. Both stop
2. ChatGPT decides
3. Only one proceeds
