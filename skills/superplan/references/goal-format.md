# `/goal` format reference

## What `/goal` is

`/goal <condition>` is a host command (Claude Code; experimental in Codex) that sets a measurable end state for the session. The host continues working — running tools, editing files, asking minimal questions — until either (a) the evaluator decides the condition is met based on the transcript, or (b) you abort, or (c) it hits an internal cap.

**The evaluator only judges what's visible in the conversation.** It does not independently run tools or read files. The compiled goal therefore must force the agent to *surface* its contract into the transcript — phases, mandatory commands, verifications, evidence — not merely reference files.

## Hard constraints

- Max length: **4000 characters**
- Available in Claude Code (production) and Codex (experimental — may require `features.goals = true`)

## Superplan's safe budget

≤ **3800 characters**. Leaves 200-char headroom for whitespace, BOMs, or CLI quoting.

If a draft exceeds this:
1. Remove inline narrative that duplicates `.superplan/PLAN.md`.
2. Replace command listings with file references (`see .superplan/VERIFY.md`).
3. Tighten verbose phrasing.
4. **Never** trim the references themselves. They are the anchor.

## Required transcript blocks

The compiled goal forces the agent to print three named blocks during execution. These are the contract surfaces the evaluator actually sees.

### SUPERPLAN_MANIFEST (printed once, at execution start)

```
SUPERPLAN_MANIFEST
Task: <one-line description from PLAN.md>
Type: <greenfield | brownfield | bugfix | refactor | ui>
Max turns: <N>
Phases:
  1. <phase 1 name>
  2. <phase 2 name>
  ...
Acceptance summary:
  - Functional: <N criteria>
  - Engineering: build/typecheck/lint/test
  - Polish: <N passes>
  - Evidence: STATE.md, transcript proof per phase
Mandatory commands:
  - <command 1>
  - <command 2>
  ...
Conditional triggers:
  - <trigger>: <command>
Polish passes:
  - UX/copy, edge cases, tests, security, maintainability, diff review, [visual if UI]
Stop conditions:
  - all phases complete with evidence
  - mandatory verifications pass or pre-existing failures proven unrelated
  - FAILURE_PROBE complete; SELF_REVIEW reports no blocking issues
Locked files:
  - PLAN.md sha256: <first 12 chars>
  - ACCEPTANCE.md sha256: <first 12 chars>
  - VERIFY.md sha256: <first 12 chars>
  - POLISH.md sha256: <first 12 chars>
```

This block makes the contract evaluator-visible. Without it, the evaluator only sees file references and has to trust the agent's summary.

### SUPERPLAN_STATE (printed every turn)

```
SUPERPLAN_STATE
turn: 7
phase: 3 — Stripe webhook handler
files_changed: app/api/webhooks/stripe/route.ts, lib/stripe/verify.ts
evidence_added: command (pnpm test tests/webhooks.test.ts → 4 passed)
blockers: none
next_action: hook webhook into subscription update flow
can_stop: no (phase 3 incomplete; needs subscription update + flip)
```

Compact, scannable, evaluator-friendly. Full per-turn detail goes to `.superplan/logs/turn-007.md`.

### FAILURE_PROBE (printed once, immediately before SELF_REVIEW)

```
FAILURE_PROBE
Three most likely break vectors for this implementation:
  1. <vector 1> — <how it was tested/inspected/fixed/deferred>
  2. <vector 2> — <how it was tested/inspected/fixed/deferred>
  3. <vector 3> — <how it was tested/inspected/fixed/deferred>
Remaining blocking: <yes-with-list | no>
```

Adversarial. Forces the agent to argue against itself before claiming success.

### SELF_REVIEW (printed once, after FAILURE_PROBE)

```
SELF_REVIEW
status: no blocking issues found
checked: UX/copy, edge cases, tests, security, maintainability, diff review[, visual]
deferred: <list or "none">
ready_for: review | merge | deploy
```

## Phase-flip evidence types

A phase may flip to `complete` only when transcript-visible evidence of a matching type is present:

| Type | Looks like |
|---|---|
| `command` | command line + exit code + last 20 lines of output |
| `test` | targeted test output with pass/fail counts |
| `diff` | `git diff --stat` summary tied to changed files |
| `screenshot` | path under `.superplan/screenshots/<phase>-<state>.png` |
| `artifact` | path under `.superplan/artifacts/` (generated files) |
| `migration` | migration validation output |
| `review` | explicit code-review note for `documentation-only` or `review-only` phases |

Runtime-behavior phases require `command` or `test` evidence. Phases marked `documentation-only` or `review-only` in PLAN.md can use `review` evidence.

## Lock integrity rule

The goal must include:

> Do not weaken locked plan/acceptance/verify/polish files during execution; update only STATE.md and proof logs unless stopping for an honest handoff.

`.superplan/LOCK.json` pins sha256 hashes of the four locked files. SUPERPLAN_MANIFEST surfaces the first 12 chars of each. If the agent silently edits a locked file to make success easier, future turns' hashes diverge — and the agent is required to call this out and stop with a handoff.

## Anti-patterns

- **"Be perfect."** Not measurable.
- **"Until done."** Done by whose definition?
- **"Tests pass."** Which tests? Run with which command?
- **"All criteria met."** Criteria are in a file the evaluator can't see. Surface them in MANIFEST.
- **Non-terminating commands marked mandatory.** They don't exit, so they can't pass.

## Validation checklist (apply before writing `.superplan/GOAL.txt`)

- [ ] References PLAN, ACCEPTANCE, VERIFY, POLISH, LOCK.json
- [ ] Requires SUPERPLAN_MANIFEST at execution start
- [ ] Requires SUPERPLAN_STATE every turn
- [ ] Requires FAILURE_PROBE before SELF_REVIEW
- [ ] Defines evidence types for phase completion
- [ ] Distinguishes mandatory vs conditional verification
- [ ] Forbids weakening locked files
- [ ] Defines stuck/handoff conditions and writes `.superplan/HANDOFF.md`
- [ ] Contains explicit turn cap
- [ ] Length ≤ 3800 chars
