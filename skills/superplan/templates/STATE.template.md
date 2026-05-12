# State — {{TASK_TITLE}}

> Live ledger. The agent updates this every turn and pastes a compact **SUPERPLAN_STATE** block into the transcript. Full per-turn detail goes to `.superplan/logs/turn-NNN.md`. Long verification outputs go to `.superplan/logs/verification-NNN.txt`.

## Header

```
Task: {{TASK_TITLE}}
Stack: {{STACK}}
Type: {{TASK_TYPE}}
Max turns: {{MAX_TURNS}}
Started: {{ISO_START}}
Locked: {{LOCKED}}
Ready-to-execute: {{READY}}
Locked-at: {{ISO_LOCKED}}
LOCK.json present: {{LOCK_PRESENT}}
```

## Phases

Mirror the `PLAN.md` phase list. A phase flips to `complete` only after transcript-visible evidence.

| # | Phase | Status | Evidence | Evidence type |
|---|-------|--------|----------|----------------|
| 1 | {{PHASE_1_NAME}} | pending | — | — |
| 2 | ... | pending | — | — |

Statuses: `pending` → `in-progress` → `complete`.

Evidence types (one of):
- `command` — passing command output pasted in transcript
- `test` — targeted test output
- `diff` — relevant git diff summary tied to changed files
- `screenshot` — path under `.superplan/screenshots/`
- `artifact` — path under `.superplan/artifacts/`
- `migration` — migration validation output
- `review` — explicit code-review note for documentation-only or review-only phases

Runtime-behavior phases require `command` or `test` evidence unless the plan marks them `documentation-only` or `review-only`.

## Polish passes

| # | Pass | Status | Evidence |
|---|------|--------|----------|
| 1 | UX and copy | pending | — |
| 2 | Edge cases and errors | pending | — |
| 3 | Tests and coverage | pending | — |
| 4 | Security and privacy | pending | — |
| 5 | Maintainability | pending | — |
| 6 | Final diff review | pending | — |
| 7 | Visual (UI tasks only) | pending | — |

## Locked-file integrity

Update each turn to confirm locked files weren't silently weakened.

```
PLAN.md       hash: {{HASH_PLAN}}        matches LOCK.json: {{MATCH_PLAN}}
ACCEPTANCE.md hash: {{HASH_ACCEPTANCE}}  matches LOCK.json: {{MATCH_ACCEPTANCE}}
VERIFY.md     hash: {{HASH_VERIFY}}      matches LOCK.json: {{MATCH_VERIFY}}
POLISH.md     hash: {{HASH_POLISH}}      matches LOCK.json: {{MATCH_POLISH}}
```

If any `matches` is `no`, halt and stop with a handoff — the contract has drifted.

## Current

Per-turn compact view (also pasted into transcript as `SUPERPLAN_STATE`):

```
SUPERPLAN_STATE
turn: {{TURN_NUMBER}}
phase: {{CURRENT_PHASE}}
files_changed: {{LIST}}
evidence_added: {{TYPE_AND_LOCATION}}
blockers: {{NONE_OR_LIST}}
next_action: {{NEXT}}
can_stop: {{YES_OR_NO}} ({{REASON}})
```

## Log index

Full per-turn detail in `.superplan/logs/`:

- `logs/turn-001.md` — first-turn snapshot
- `logs/turn-002.md` — …
- `logs/verification-NNN.txt` — long verification output excerpts

The log directory is created lazily on first append.
