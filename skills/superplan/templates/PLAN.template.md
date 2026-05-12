# Plan — {{TASK_TITLE}}

> Fill every section. Sections that don't apply: write **N/A** and a one-line reason. Empty sections are not acceptable.

## Product intent

One paragraph. What is being built, for whom, and why now. No implementation details here.

## Assumptions

Bullet list of decisions made without asking the user. Each item: "Assumed X because Y."

## Non-goals

Bullet list of things explicitly out of scope. This is how you prevent scope creep.

## Architecture

- Stack: {{STACK}}
- Package manager: {{PACKAGE_MANAGER}}
- Key dependencies (new or existing): list with rationale
- Major modules / services / packages touched: list
- New files to create: list with paths
- Files to modify: list with paths

## Data model changes

Schema changes, migrations, new tables/columns, new types. **N/A** if none.

## API / contracts

New endpoints, RPC methods, event payloads, public function signatures. Include shapes. **N/A** if none.

## UI / UX states

Required states for every new or changed view:
- Empty
- Loading
- Success
- Error (with message taxonomy)
- Permission-denied / unauthorized
- Offline (if app supports it)

**N/A** if no UI changes.

## Error handling

How errors are surfaced (toast / banner / inline / log-only). Retry policy. Fallbacks.

## Security / privacy

Authn/authz changes, secret handling, PII exposure, data-retention impact. **N/A** if none.

## Test strategy

- Unit tests: where, what coverage target
- Integration tests: where, against what
- End-to-end tests: where, what flows
- Manual smoke checks: what to click after a fresh build

## Migration strategy

Data migrations, feature flags, gradual rollout. **N/A** if none.

## Observability / logging

New log lines, metrics, traces. Dashboards or alerts to update. **N/A** if none.

## Rollback / cleanup

What gets reverted if this ships and breaks. Cleanup commits or feature-flag removals if applicable.

## Phase-by-phase implementation

Numbered phases. Each phase: name, files touched, acceptance signal (which check or test proves it works).

1. {{PHASE_1_NAME}} — {{PHASE_1_FILES}} — proves: {{PHASE_1_SIGNAL}}
2. ...

## Polish requirements

What "polish" means for this specific task. Cross-link to `POLISH.md` for the full pass list.

## Definition of Done

A single sentence: "This is done when ___." The blank must be measurable, not subjective.

See `ACCEPTANCE.md` for the binding criteria; this sentence is the human-readable summary.
