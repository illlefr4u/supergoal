# Verification rubric

VERIFY.md is a **matrix**, not a flat list. Three sections — mandatory, conditional, non-terminating — keep the agent from getting stuck on the wrong kind of command.

## Section: Mandatory final verification

Every command in this section must run successfully (or have a pre-existing failure proven unrelated) before final completion.

Per stack:

### Node.js / TypeScript

```bash
{pnpm|yarn|npm|bun} run build       # exit 0
{pnpm|yarn|npm|bun} run typecheck   # exit 0 (or tsc --noEmit fallback)
{pnpm|yarn|npm|bun} run lint        # exit 0
{pnpm|yarn|npm|bun} test            # exit 0
```

### Rust

```bash
cargo build --all-targets                                 # exit 0
cargo test --all-features                                 # exit 0
cargo clippy --all-targets --all-features -- -D warnings  # exit 0
cargo fmt --check                                         # exit 0
```

### Python

```bash
pytest                  # exit 0
ruff check              # exit 0
ruff format --check     # exit 0
mypy .                  # exit 0
```

### Go

```bash
go build ./...      # exit 0
go test ./...       # exit 0
golangci-lint run   # exit 0 (or go vet ./...)
```

### Swift (SPM)

```bash
swift build   # exit 0
swift test    # exit 0
```

Prefer the project's actual `package.json`/`Cargo.toml`/`pyproject.toml` scripts over the fallbacks. If the project genuinely has no lint script, mark `N/A — no lint configured` and do not invent one.

## Section: Conditional verification

Run when the trigger applies to changes in this task.

| Trigger | Command | Passing condition |
|---|---|---|
| Schema/migration changed | `<prisma validate \| sqlx migrate run --dry-run \| alembic check>` | exit 0; applies cleanly on a fresh DB |
| UI files changed | browser-harness screenshot recipe | screenshots embedded per state |
| Auth flow changed | targeted auth-test command | pass |
| Payment/webhook code changed | signature + idempotency tests | pass |
| Public API surface changed | API contract tests / OpenAPI diff | pass |
| Performance-sensitive path changed | benchmark / load test (if exists) | within tolerance documented in PLAN.md |
| New dependency added | `pnpm audit` / `cargo audit` / `pip-audit` | no high/critical issues unresolved |

Triggers are evaluated against the changed file set in each turn's git diff.

## Section: Non-terminating / manual

Commands that do not exit on their own. Use only when their trigger applies. Capture evidence, then stop the process.

| Command | When to use | Evidence + cleanup |
|---|---|---|
| `{pnpm|npm|yarn|bun} run dev` | UI verification | log URL, screenshot paths, then SIGTERM the dev server |
| `docker compose up` | integration smoke | log excerpt + curl probe + `docker compose down` |
| `stripe listen` | webhook verification | event IDs + response status + SIGTERM |
| `playwright test --ui` | manual e2e debugging | only if interactive; otherwise use `playwright test` |

The runner's stuck-watcher allowlists these via `SUPERPLAN_ALLOW_LONG_COMMANDS` so it doesn't kill them during legitimate use. Default allowlist is in `scripts/stuck-watcher.mjs`.

## Evidence rules

- **Mandatory**: paste command + exit code + last 20 lines.
- **Conditional**: same, plus state which trigger applied (e.g. "trigger: schema_changed").
- **Non-terminating**: paste start command + log URL/path + cleanup command + confirmation process stopped.
- Outputs longer than 20 lines: save to `.superplan/logs/verification-<turn>.txt` and reference the path.

## What NOT to put in VERIFY.md

- "Run all tests" — name the command.
- Commands the project doesn't have — write `N/A — no <X> configured`.
- Optional commands not conditional on anything — drop them.
- Non-terminating commands marked "mandatory" — they can't pass.
- Commands that require external services without documenting how to mock or skip.
