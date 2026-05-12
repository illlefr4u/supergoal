# Acceptance — {{TASK_TITLE}}

> The agent cannot claim "done" until every box below has a pasted command-output proof block in the transcript or a documented N/A.

## Functional acceptance

- [ ] All user flows from `PLAN.md` work end-to-end.
- [ ] Every UI state listed in `PLAN.md` (empty / loading / success / error / permission / offline) is implemented where the section is not N/A.
- [ ] Existing behavior remains compatible unless `PLAN.md` explicitly changes it.
- [ ] All assumptions in `PLAN.md` either hold or have been re-evaluated in `STATE.md`.

## Engineering acceptance

- [ ] **Build** exits 0. Command: `{{BUILD_CMD}}`. Proof: paste last 20 lines of output.
- [ ] **Typecheck** exits 0. Command: `{{TYPECHECK_CMD}}`. Proof: paste output.
- [ ] **Lint** exits 0, or pre-existing lint issues are listed in `STATE.md` with file:line and reason. Command: `{{LINT_CMD}}`. Proof: paste output.
- [ ] **Relevant tests** pass. Command: `{{TEST_CMD}}`. Proof: paste output. New tests cover the new behavior.
- [ ] No `TODO`, `FIXME`, `XXX`, placeholder copy, or hardcoded fake data remains in changed files — or each is documented in `STATE.md` with a follow-up plan.
- [ ] No accidentally-committed debug code (`console.log`, `print`, `dbg!`, etc.) in changed files.

## Polish acceptance

- [ ] Every pass in `POLISH.md` is checked off with its evidence link.
- [ ] For UI changes: spacing, responsive behavior, copy, and accessibility reviewed (see `POLISH.md` UI pass).
- [ ] Error messages are actionable — they tell the user what to do next.
- [ ] Documentation or README updated where behavior changed.
- [ ] Final `git diff` reviewed for accidental changes; any noise removed.

## Evidence acceptance

- [ ] Every `VERIFY.md` command has been run and its output pasted into the transcript.
- [ ] `STATE.md` reflects the actual final state, including any known limitations.
- [ ] A final self-review block states "no blocking issues found" and lists the rationale (what was checked, what was deferred).

## Visual acceptance (UI tasks only — delete this section if N/A)

- [ ] Screenshots captured for every changed view at each required state.
- [ ] Screenshots embedded or referenced in `POLISH.md`.
- [ ] No visible regressions in adjacent views (see UI verification rubric).
