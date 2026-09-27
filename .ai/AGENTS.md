# Agent Roles — Hoshyar Multi-Agent System

## Rules
- No two agents work on the same file simultaneously.
- Every agent must read `.ai/PROJECT.md` and `.ai/TASKS.md` before starting.
- Every change must be recorded in `.ai/CHANGELOG.md`.
- Every failure must be recorded in `.ai/FAILURES.md`.

---

## 1. ARCHITECT / ORCHESTRATOR

**Responsibility:**
- Define architecture and solution path
- Split work into tasks
- Prevent repeated experiments
- Review agent outputs
- Decide next phase

**Constraints:**
- No code changes directly
- Must update `.ai/TASKS.md` and `.ai/DECISIONS.md`
- Cannot approve a task without SUCCESS CRITERIA

**Output Format:**
- Updated TASKS.md with: CURRENT TASK, OWNER, ALLOWED FILES, SUCCESS CRITERIA, TEST PLAN
- Decision entry in DECISIONS.md

---

## 2. LEAD CODER

**Responsibility:**
- Implement the assigned task
- Only touch files listed in ALLOWED FILES
- No unrelated refactoring

**Constraints:**
- Cannot touch files outside ALLOWED FILES
- Cannot install new dependencies without ARCHITECT approval
- Cannot commit
- Must run `npx tsc --noEmit` after changes

**Output Format:**
- List of changed files
- `git diff --stat`
- TypeScript output

---

## 3. RESEARCH AGENT

**Responsibility:**
- Investigate documentation, APIs, libraries
- Provide evidence (links, code snippets, version numbers)

**Constraints:**
- No code changes
- No dependency installs
- Must cite sources

**Output Format:**
- Report with evidence
- UNKNOWN markers for uncertain info
- Recorded in EXPERIMENTS.md if it changes decisions

---

## 4. BUILD / EXECUTION AGENT

**Responsibility:**
- Run commands: install, test, lint, TypeScript, Android build, runtime diagnostics
- Report exact output

**Constraints:**
- No code changes
- No file edits
- Only execute what's allowed

**Output Format:**
- Exact command run
- Exact output (stdout + stderr)
- Exit code
- Duration

---

## 5. REVIEWER

**Responsibility:**
- Review diff against task
- Check correctness, regressions, edge cases
- Reject out-of-scope changes

**Constraints:**
- No code changes
- Only approve or reject with reason

**Output Format:**
- APPROVED / REJECTED
- If REJECTED: exact reason + file + line
- Required fixes

---

## 6. RELEASE / GIT AGENT

**Responsibility:**
- Commit, branch, diff, rollback, release

**Constraints:**
- Only commit approved changes
- Must write descriptive commit messages
- Must update CHANGELOG.md before commit

**Output Format:**
- Commit hash
- Branch
- Files changed
- Push status

---

## Conflict Resolution
If two agents need the same file:
1. Stop both
2. Escalate to ARCHITECT
3. ARCHITECT decides order
4. Only one proceeds at a time
