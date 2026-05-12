# Polish — {{TASK_TITLE}}

> Six passes. Each pass must be checked off with an evidence link (commit hash, file:line, screenshot path, or pasted command output) before final "done" is allowed.

## Pass 1 — UX and copy

- [ ] Every user-facing string reviewed for tone, voice, and clarity.
- [ ] Error messages tell the user what to do next, not just what failed.
- [ ] Empty states have helpful copy + a next action.
- [ ] Loading states aren't blank — spinner or skeleton with context.
- [ ] Buttons say what they do, not "Submit" / "OK" / "Click here".

Evidence: {{EVIDENCE_1}}

## Pass 2 — Edge cases and errors

- [ ] Network failure paths tested or stubbed.
- [ ] Auth failure paths handled (expired token, missing permission).
- [ ] Invalid input rejected with helpful messages, not stack traces.
- [ ] Large input / pagination edge cases handled.
- [ ] Concurrent / race conditions identified — at least documented if not fixed.

Evidence: {{EVIDENCE_2}}

## Pass 3 — Tests and coverage

- [ ] New behavior has tests.
- [ ] At least one test for the unhappy path of each new flow.
- [ ] No tests skipped or `.only`-ed by accident.
- [ ] Test command exits 0 (paste output).

Evidence: {{EVIDENCE_3}}

## Pass 4 — Security and privacy

- [ ] No secrets committed (check `git diff` for keys, tokens, passwords).
- [ ] User input validated at trust boundaries.
- [ ] No new PII surfaces in logs.
- [ ] Auth checks present on every new endpoint or sensitive UI route.

Evidence: {{EVIDENCE_4}}

## Pass 5 — Maintainability

- [ ] No dead code left behind.
- [ ] No comments explaining what well-named code already says.
- [ ] No `// TODO` without an owner + condition.
- [ ] Imports tidy, exports minimal.
- [ ] File and function names match what they do.

Evidence: {{EVIDENCE_5}}

## Pass 6 — Final diff review

- [ ] `git diff` reviewed line-by-line.
- [ ] No accidental changes (formatter churn, debug code, unrelated edits).
- [ ] Changes match `PLAN.md` scope; if not, scope delta noted in `STATE.md`.
- [ ] Diff size proportional to the task — large diffs justified.

Evidence: {{EVIDENCE_6}}

## Visual polish (UI tasks only — delete if N/A)

- [ ] Screenshots captured for each changed view × state.
- [ ] Spacing, alignment, typographic hierarchy reviewed.
- [ ] Hover, focus, active, disabled states present where applicable.
- [ ] Responsive behavior verified at small / medium / large breakpoints.
- [ ] Accessibility: keyboard navigation works, focus visible, color contrast passes WCAG AA.

Evidence: {{EVIDENCE_VISUAL}}

## Final self-review block

After all passes are checked, paste a self-review block of the form:

```
Self-review: no blocking issues found.
Checked: {{LIST_OF_PASSES}}
Deferred: {{LIST_OF_KNOWN_LIMITATIONS_OR_NONE}}
Ready for: review / merge / deploy
```
