# Roadmap: {{TASK_TITLE}}

**Task:** {{ONE_LINE_TASK}}
**Type:** {{TAGS}}
**Created:** {{DATE}}
**Total phases:** {{N}}

## Context summary

- **Stack:** {{STACK}}
- **Package manager:** {{PM}}
- **Build / test / lint commands:** {{COMMANDS}}
- **Risky areas:** {{RISKS_ONE_LINE}}

## Assumptions

Non-blocking decisions recorded here so we can proceed without round-trips. If any are wrong, stop the run and tell us:

- {{ASSUMPTION_1}}
- {{ASSUMPTION_2}}
- ...

## Risk top 3

1. **{{RISK_1}}** — likelihood: {{L}}, mitigation: {{M}}
2. **{{RISK_2}}** — likelihood: {{L}}, mitigation: {{M}}
3. **{{RISK_3}}** — likelihood: {{L}}, mitigation: {{M}}

## Phase map

| # | Phase | Depends on | Deliverable |
|---|-------|------------|-------------|
| 1 | {{P1_NAME}} | — | {{P1_DELIVERABLE}} |
| 2 | {{P2_NAME}} | 1 | {{P2_DELIVERABLE}} |
| 3 | {{P3_NAME}} | 1, 2 | {{P3_DELIVERABLE}} |
| ... | ... | ... | ... |
| N | Polish & Harden | 1..N-1 | Every aspect is verified |

---

## Phase 1 — {{P1_NAME}}

**Why:** {{P1_WHY}}

**Deliverables:**
- {{P1_FILE_OR_FEATURE_1}}
- {{P1_FILE_OR_FEATURE_2}}

**Acceptance criteria:**
<!-- Tag each criterion [mechanical] (a command/file proves it), [human] (a person
     must confirm), or [trust-prior] (asserted, unverifiable). Untagged = trust-prior. -->
- [mechanical] {{CRIT_1}}
- [human] {{CRIT_2}}
- [trust-prior] {{CRIT_3}}

**Mandatory commands:**
- `{{CMD_1}}`
- `{{CMD_2}}`

**Allowed paths:**
<!-- Files/dirs this phase may change. The scope firewall flags edits outside them.
     A bare `*` (or omitting this section) disables the firewall for the phase. -->
- {{PATH_OR_DIR_1}}
- {{PATH_OR_DIR_2}}

**Evidence required:**
<!-- Paths under evidence/phase-N/ that must exist for the gate to pass,
     e.g. commands/test.log, diffs/summary.txt, screenshots/home.png. -->
- {{EVIDENCE_1}}
- {{EVIDENCE_2}}

**Dependencies:** none

---

## Phase 2 — {{P2_NAME}}

(same structure)

---

## ... (additional phases)

---

## Phase N — Polish & Harden

**Why:** Catch what earlier phases missed because they were focused on shipping behavior. This is how "every aspect is perfect" gets enforced.

**Sub-passes (each must produce evidence):**

- [ ] **UX & copy** — every visible string reads well, no debug placeholders
- [ ] **States** — empty, loading, error, unauthorized verified for every new surface
- [ ] **Edges** — empty inputs, long inputs, special chars, slow network
- [ ] **Security** — input validation, auth checks, no secrets in client bundle
- [ ] **A11y** (if UI) — keyboard nav, focus, screen reader, contrast ≥ AA
- [ ] **Perf** — no obvious N+1, no megabyte bundles, no blocking renders
- [ ] **Diff review** — `git diff` reviewed for stray debug logs, TODOs from this run
- [ ] **Regression sweep** — full test suite + manual check of one adjacent feature

**Mandatory commands:**
- All build/test/lint commands from earlier phases
- Whatever stack-specific perf/security checks apply

**Evidence required:**
- One paragraph per sub-pass with what was checked and what was found/fixed
- Final `git diff --stat` summary
- Final test summary
- (UI) Final screenshot(s) of key surfaces in light + dark + mobile widths
