# Supergoal RESEARCH execution protocol

Read by the executing agent at the start of the single `/goal` session for a
**research** run, and followed throughout. The research analog of `PROTOCOL.md`
(the build protocol). All paths are rooted at this run's artifact directory
(`{{RUN_ROOT}}`) — the concrete path is baked in at Stage 7.

The deliverable of a research run is **findings / data / an answer / a report**,
never code. The shape mirrors build (phases, per-phase VERIFY/DONE, a final
audit, the same `/goal` end-state markers) so dispatch + evaluator are
identical — but the verify gates are about **sources and evidence**, not
build/typecheck/lint.

## Research phase types (adaptive count — not all always present)

1. **Source Discovery** — bounded multi-modal sweep; deliverable is a LOCKED
   ranked source plan (`references/source-discovery.md`). Nothing downstream is
   valid until this is locked.
2. **Extraction** — pull data from the locked sources top-down; record raw value
   + citation (URL + quote + access date) per datum.
3. **Cross-Verification** — adversarial: each key number confirmed by >=2
   independent primary sources, else flagged. Runs the three gates below.
4. **Synthesis** — the answer / report / comparison; every claim carries a citation.
5. **Adversarial audit** (always last) — try to break each finding; the research
   analog of Polish & Harden.

## The loop

Repeat until `SUPERGOAL_RUN_COMPLETE`:

1. Read `{{RUN_ROOT}}/STATE.md`. Find `Current phase: N`; confirm `Mode: research`.
2. Read `{{RUN_ROOT}}/phases/phase-N.md` — full work spec.
3. Print `SUPERGOAL_PHASE_START` with the spec's metadata.
4. Do the work. Fetch the locked sources. Surface evidence into the transcript:
   for every datum a **quoted excerpt + URL + access date**, and its tier.
5. Print `SUPERGOAL_PHASE_VERIFY`: each acceptance criterion `pass|fail` with
   evidence, plus the **research cleanliness checks** — no uncited number; no
   fabricated/filled data; `~`/"about" not masking missing verification; modality
   preserved. A failed gate triggers the same 3-strike treatment as a failed
   criterion.
6. **Memory writeback check** — learned anything non-obvious (a primary source's
   real URL/shape, a dead aggregator, a domain quirk)? Write a memory file; print
   `MEMORY_SAVED: <name>` or `MEMORY_SAVED: none`.
7. Print `SUPERGOAL_PHASE_DONE`; update `STATE.md`.
8. **User-interrupt check** — address any new user message before continuing.
9. **Checkpoint check** (research-only — see Checkpoints below).
10. If N < total: continue. If N == total: run the **Adversarial audit**; only
    after `AUDIT_COMPLETE`, print `SUPERGOAL_RUN_COMPLETE`.

## Source Discovery — lock before anything downstream

The Source Discovery phase ends by printing `SOURCE_PLAN_LOCKED` and writing
`{{RUN_ROOT}}/source-plan.md` (format + bound rules in
`references/source-discovery.md`). No Extraction and no negative-result claim is
valid before the lock. Then **checkpoint** (below).

## Cross-Verification — the three gates (run every key datum through them)

- **Source-conflict adjudication.** Contradictory primaries → prefer the
  higher-tier / closer-to-truth source, state confidence, and if unresolved emit
  an explicit `conflicting, unresolved: X vs Y` outcome. Never silently pick one.
- **Recency / staleness.** Every claim carries publication + access date. Data
  past the freshness threshold for THIS question fails or is flagged stale.
- **Provenance independence.** "Independent" requires sources not downstream of
  the same feed (five sites reprinting one Opta number = one source). Mark raw vs
  derived/transformed.

Surface each gate's outcome in the phase VERIFY block.

## Negative-result gate — "unavailable" is a valid PASS, but only through this

"Data unavailable" is a legitimate terminal answer — NOT a failure to retry
forever, and NOT a premature surrender. It holds only when ALL of:

1. Source Discovery **locked a ranked source plan** first.
2. For **each required source/tier in that plan**, there is evidence of the
   actual failed query/fetch (the URL/query + the empty or failed result).
3. The plan included the **strongest available primary/domain sources before any
   fallback tier** (no "checked three weak sources → unavailable" gaming).
4. The **Adversarial-audit phase re-verified** the non-availability claim —
   re-attempted at least the single strongest source — before it holds.

Then `RESEARCH_CHECKPOINT` (negative terminal) for user confirmation, and only on
approval print `SUPERGOAL_RUN_COMPLETE` with the negative result + the per-source
evidence as the answer.

## Checkpoints (research-only — build never stops mid-`/goal` except on failure)

Research is iterative — findings change scope — so it checkpoints to the user at
exactly two boundaries, plus rescope:

- **After Source Discovery** — print `RESEARCH_CHECKPOINT` with the locked source
  plan + scope; set `STATE.md` Status `CHECKPOINT`; **stop**. The user approves
  (or edits) the plan, then says continue / re-dispatches the same `/goal`.
- **Before a negative terminal** — print `RESEARCH_CHECKPOINT` with the
  unavailable finding + per-source evidence; stop for confirmation.
- **RESCOPE** — if a finding invalidates the question or the source strategy
  mid-run, print `RESCOPE` with what changed, set Status `CHECKPOINT`, and route
  back to Source Discovery rather than forcing stale decomposition forward.

Everything between these boundaries runs autonomously — no babysitting. A
checkpoint does NOT satisfy the `/goal` condition (no `SUPERGOAL_RUN_COMPLETE`);
the host evaluator keeps evaluating while the agent waits for the user, exactly
like a `FAILURE_HANDOFF`.

## Adversarial audit (after the last phase, before completion)

The research analog of the build final audit. Re-validate against the original
`{{RUN_ROOT}}/ROADMAP.md`, not the run's self-reports. Up to 3 rounds; on the
3rd round's failure, `AUDIT_HANDOFF`.

1. Print `AUDIT_START` (round, phase count, criteria count, sources to re-touch).
2. Re-read `ROADMAP.md`; pull every phase's acceptance criteria fresh.
3. **Phase completeness** — one `SUPERGOAL_PHASE_DONE` per phase.
4. **Citation check** — every number in Synthesis maps to a cited source with an
   access date. Any uncited number → `AUDIT_GAP`.
5. **Re-verify behind "unavailable"** — for every claim marked unavailable,
   re-attempt at least the strongest locked source. If it now returns data, the
   negative result was wrong → `AUDIT_GAP`.
6. **Independence + recency spot-check** — confirm no two "independent" sources
   are the same feed; confirm dated data is within threshold.
7. Print `AUDIT_VERIFY` (per-phase status; per-criterion pass/fail/trust-prior +
   evidence; citation coverage; unavailable-claims re-checked).
8. **If gaps:** print `AUDIT_GAPS`; write `{{RUN_ROOT}}/phases/audit-fix-<round>.md`
   (targets only the failing findings, scope creep forbidden); execute inline;
   loop (round + 1). On 3rd-round failure: `AUDIT_HANDOFF`, Status `BLOCKED`, stop.
9. **If clean:** print `AUDIT_COMPLETE` (rounds, phases re-verified, citation
   coverage %, unavailable-claims re-confirmed). Then the negative-terminal or
   final-answer checkpoint as applicable, then `SUPERGOAL_RUN_COMPLETE` with a
   5-line summary: the answer (or the honest "unavailable"), top sources,
   confidence.

## Failure recovery (3-strike) — same shape as build

A "failure" here is a failed verification gate (uncited number, unmet
cross-verification, a fabricated datum caught), not a build error.

- **First:** `FAILURE_PROBE` (what failed, what was tried, hypothesis); log it;
  auto-retry the phase once with the probe injected.
- **Second:** `FAILURE_ESCALATE`; write `{{RUN_ROOT}}/phases/phase-N.fix.md`
  (targets only the failing gate); execute inline; re-run VERIFY.
- **Third:** `FAILURE_HANDOFF` (failing gate, probe history, suggested next move);
  Status `BLOCKED`; stop. Do not print `SUPERGOAL_RUN_COMPLETE`.

Distinction from the negative-result gate: a *failure* is "we couldn't verify
what we found"; a *negative result* is "we verified it isn't public." The first
escalates; the second is a valid PASS through its gate.

## Memory writeback rules

Same as build (`memory_writeback_rules` in SKILL.md). Research specifics worth
saving: a primary source's real access URL/shape, an aggregator that is
reliably empty for a class of fact, a domain's freshness behaviour. Final phase
always writes a `research_<slug>.md` memory (question, answer/verdict, top
sources, date). Never save secrets or transient state.

## Required transcript blocks

Shared with build (`references/goal-format.md`): `SUPERGOAL_PHASE_START` /
`SUPERGOAL_PHASE_VERIFY` / `MEMORY_SAVED` / `SUPERGOAL_PHASE_DONE` /
`AUDIT_START` / `AUDIT_VERIFY` / `AUDIT_GAPS` / `AUDIT_COMPLETE` /
`AUDIT_HANDOFF` / `SUPERGOAL_RUN_COMPLETE` / `FAILURE_PROBE` /
`FAILURE_ESCALATE` / `FAILURE_HANDOFF`.

Research-only: `SOURCE_PLAN_LOCKED`, `RESEARCH_CHECKPOINT`, `RESCOPE`.

The `/goal` end-state is unchanged: `SUPERGOAL_RUN_COMPLETE` preceded by
`AUDIT_COMPLETE` and one `SUPERGOAL_PHASE_DONE` per phase, with no
`FAILURE_HANDOFF` or `AUDIT_HANDOFF` outstanding.
