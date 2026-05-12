# Verify — {{TASK_TITLE}}

> Verification matrix. Three categories: **mandatory final**, **conditional**, **non-terminating/manual**. The agent runs all mandatory commands and any conditional command whose trigger applies. Non-terminating commands run only when needed and must be cleaned up.

## Mandatory final verification

Every command in this table must pass (or have its pre-existing failure proven unrelated) before final completion.

| Command | Required | Passing condition | Notes |
|---|:---:|---|---|
| `{{TYPECHECK_CMD}}` | yes | exit 0 | Required for all type-system changes |
| `{{LINT_CMD}}` | yes | exit 0 OR pre-existing failures documented in STATE.md | Required |
| `{{TEST_CMD}}` | yes | exit 0 OR targeted-subset pass with reason full suite is unavailable | Required |
| `{{BUILD_CMD}}` | yes | exit 0 | Required before final success |

## Conditional verification

Run when the listed trigger applies to changes in this task.

| Trigger | Command | Passing condition |
|---|---|---|
| Schema/migration changed | `{{MIGRATION_VALIDATE_CMD}}` | exit 0; migration applies cleanly on a fresh DB |
| UI files changed | `{{UI_VERIFY_CMD}}` (see `references/ui-verification.md`) | screenshots embedded in `POLISH.md` per state |
| Auth flow changed | targeted auth test command | pass |
| Payment / webhook code changed | webhook signature + idempotency tests | pass |
| Public API surface changed | API contract tests / OpenAPI diff | pass |
| Performance-sensitive path changed | benchmark or load test (if exists) | within tolerance documented in PLAN.md |

If a trigger doesn't apply, write `N/A — trigger not present` in `STATE.md` for that row; do not silently skip.

## Non-terminating / manual checks

These commands do not exit on their own. Use only when their trigger applies. Capture evidence, then stop the process cleanly.

| Command | When to use | Evidence captured |
|---|---|---|
| `{{DEV_CMD}}` | UI verification, manual smoke | dev URL + screenshot paths in POLISH.md; process stopped after |
| `docker compose up` | integration smoke against a service stack | log excerpt + curl probe; `docker compose down` after |
| `stripe listen` | webhook verification against real events | event IDs received + response status; process stopped after |

The runner watches `.superplan/run.log` for activity; allowlist long-running commands via `SUPERPLAN_ALLOW_LONG_COMMANDS` so the stuck-watcher doesn't kill them mid-run.

## Evidence rules

For every command run during execution:

- **Mandatory**: paste command line, exit code, and last 20 lines of output (or full output if ≤20 lines).
- **Conditional**: same, plus state which trigger applied.
- **Non-terminating**: paste the start command + log URL/path + the cleanup command, and confirm the process was stopped.

Long outputs (>20 lines) save to `.superplan/logs/verification-<turn>.txt` and reference the path in the transcript.

## What NOT to include

- "Run all tests" — name the command.
- Commands the project doesn't actually have — write `N/A — no <X> configured` and don't invent one.
- Optional commands that aren't conditional on anything — if it's truly optional, drop it.
- Non-terminating commands as "mandatory" — they don't exit, they can't pass.
