# AI Loop — Multi-Agent Protocol

## Models
- ChatGPT (Architect)
- DeepSeek (Coder)
- Grok (Reviewer)
- User (Tester)

## Loop
1. ChatGPT -> Task defined
2. DeepSeek -> Implement
3. DeepSeek -> Self-Review
4. Grok -> Review
5. DeepSeek -> Fix (if needed, max 3)
6. ChatGPT -> PASS/FAIL/BLOCKED
7. User -> Real device test

## Limits
- Max 3 fix cycles
- After 3: BLOCKED
- DeepSeek stops and requests ChatGPT decision

## PASS/FAIL/BLOCKED
- PASS: Test passed, all good
- FAIL: Error, need fix
- BLOCKED: Need ChatGPT decision

## Stop Conditions for DeepSeek
1. Files outside ALLOWED FILES needed
2. New dependency needed
3. Architecture change needed
4. 3 fix cycles without PASS
5. Test environment broken
6. Ambiguous requirements
7. Grok REJECTED >3 times
8. Unclear command output

## Handoff Formats

### ChatGPT to DeepSeek
CURRENT TASK: <name>
STATUS: IN PROGRESS
ALLOWED FILES: <list>
OBJECTIVE: <what to do>
SUCCESS CRITERIA: <checklist>
TEST PLAN: <commands>
BLOCKERS: <if any>

### DeepSeek to Grok
CHANGED FILES: <list>
git diff --stat: <output>
TEST OUTPUT: <output>
SELF-REVIEW: <notes>
COMMANDS RUN: <list>

### Grok to ChatGPT
RESULT: APPROVED / REJECTED
IF REJECTED:
  - File: <path>
  - Line: <number>
  - Issue: <description>
  - Fix needed: <description>
SEVERITY: LOW / MEDIUM / HIGH

## Emergency Stop
Any model detects data loss / security issue -> STOP + escalate
