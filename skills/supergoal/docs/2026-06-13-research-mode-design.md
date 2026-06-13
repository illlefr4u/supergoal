# Supergoal v0.8 — dual-mode (build | research) design

**Date:** 2026-06-13
**Status:** design, codex arch-review round 1 resolved (this rev), pending re-review + user spec approval
**Decision locked:** one skill, auto-detect mode (build vs research), **dispatched via a thin router**. Engineering path stays a verbatim untouched module; research is a separate additive module.

## Problem

Supergoal (v0.7) is an autonomous, phased, memory-backed, one-paste `/goal` workflow tuned exclusively for **software builds** (recon codebase → build phases → build/typecheck/lint/test → code deliverables → audit vs ROADMAP). Running it on a **research/data** task is a category error: there is no code deliverable, the recon/verify machinery (detect-stack, build commands, git-diff deliverables) does not apply, and the 3-strike retry loop would thrash trying to "produce" data that may not exist. We want supergoal to also drive research to completion with the same shape (planning depth + phase decomposition + autonomous `/goal` + memory + final audit).

## Decision — router architecture (codex P1.1)

Single user entry (`/supergoal`), but internally a **router**, not stage-by-stage branching inside one flow:

- **Stage 0 router** detects mode, then dispatches to ONE of two self-contained flows.
- **`build` flow = v0.7 verbatim.** No edits inside build stages, no build-state schema change, build keeps its own `PROTOCOL.md`. The router is the only new code on the build path (a single dispatch at the top). This is what makes the "byte-for-byte unchanged" claim actually true — branching every stage (the rejected approach) could not guarantee it.
- **`research` flow = new module** with its own stages, its own `PROTOCOL-research.md`, its own phase template. Shares only the generic plumbing that is provably mode-agnostic (run-namespace claim, memory preload, `/goal` dispatch shell, STATE.md schema with an added `Mode:` field).

## Design

### 1. Mode detection (Stage 0 router) — deliverable-first (codex P2)
- Classify by **terminal deliverable first, verb second.**
  - **build** = the deliverable is code/files/a running system. Includes verb-confusing cases: "build a tool that researches X", "write a scraper/API client", "investigate the failing build and patch it", "analyze the repo and refactor" → all **build** (deliverable is code).
  - **research** = the deliverable is findings/data/an answer/a report, no code artifact.
- Ambiguous → one `AskUserQuestion` (build vs research). Clear → announce detected mode, proceed.
- Persist `Mode:` in STATE.md.

### 2. Recon (Stage 2, research) 
- Replace detect-stack/repo-map with **data-source-tool inventory**: which research tools exist this session (WebSearch, WebFetch, Chrome/browser MCP, domain MCPs: blockscout/defillama/github/…), plus a first-pass **source taxonomy**: official/primary → data providers → aggregators → broadcast → social → derived.
- New script `scripts/detect-research-tools.sh` → writes `context.md`.

### 3. Deep-think (Stage 3, research) — delegate, don't reimplement (codex P2)
- An existing `deep-research` skill already does fan-out search → fetch → adversarial-verify → cited report. Research-supergoal does NOT reimplement it. Its defensible differentiation: it is the **stateful, resumable, multi-phase orchestrator** (planning depth, phase decomposition, memory writeback, autonomous `/goal`, final audit) that **delegates** per-phase discovery/verification to deep-research methodology. If a phase is "just fan-out and verify," it invokes deep-research rather than duplicating it.
- Top-3 risks reframed: (a) data may not exist publicly → predefine the negative-result gate; (b) source reliability/conflict; (c) fabrication temptation.

### 4. Decompose (Stage 4, research) — phase types (adaptive count)
- **Source Discovery** — **bounded** multi-modal sweep; **its deliverable is a LOCKED ranked source plan** (specific sources + tier per source to query). Bounded = a stop budget (max source-families / wall-time) **plus** a minimum-tier checklist; discovery ends when the checklist is covered or the budget is hit, then locks the plan. The bound stops discovery itself from thrashing *before* the negative-result gate ever runs (codex round-2 P2). This lock is what makes the negative-result gate enforceable (see §6).
- **Extraction** — pull data from the locked sources top-down; record raw value + citation (URL + quote + access date).
- **Cross-Verification** — adversarial: each key number confirmed by ≥2 **independent primary** sources, else flagged single-source/unverified. Includes three first-class gates (codex P2):
  - **Source-conflict adjudication:** contradictory primaries trigger an adjudication rule (prefer higher-tier/closer-to-truth source, state confidence, and if unresolved emit an explicit "conflicting, unresolved: X vs Y" outcome — never silently pick one).
  - **Recency/staleness:** every claim carries publication/access date; data past a freshness threshold for the question fails or is flagged stale.
  - **Provenance independence:** "independent" requires sources not be downstream of the same feed (e.g. five sites all reprinting Opta = one source); mark raw vs derived/transformed.
- **Synthesis** — the answer/report/comparison; every claim carries a citation.
- Final phase = **Adversarial audit** (analog of Polish & Harden): try to break each finding; verify no uncited number, modality preserved, negative results honest, and **re-attempt ≥1 source behind any "unavailable" claim** to confirm it.
- **Re-scope transition (codex P3):** if a finding invalidates the question/source strategy mid-run, a phase may emit `RESCOPE` instead of forcing stale decomposition forward — routes back to Source Discovery with a user checkpoint.

### 5. Phase-spec adaptations (research)
- **Deliverables** → findings/data points, each with a required citation count + access date.
- **Acceptance criteria** → falsifiable research criteria ("USA first-half total distance sourced from ≥1 FIFA primary source, OR explicitly marked unavailable after the locked source plan fails with per-source evidence").
- **Mandatory commands** → verification gates (which locked sources fetched, cross-check + conflict/recency/provenance gates run); some are real shell (curl an API).
- **Evidence required** → quoted source excerpts + URLs + dates surfaced into the transcript.
- **Cleanliness checks** → no uncited numbers, no fabricated data, `~`/"about" must not mask missing verification, modality preserved.

### 6. Negative-result gate — concrete (codex P1.2)
"Data unavailable" is a **valid terminal PASS**, but only through a hard gate (not a hand-wave):
1. Source Discovery must have **locked a ranked source plan** first.
2. PASS-unavailable requires, **per required source/tier in that plan**, evidence of the actual failed query/fetch (the URL/query + the empty/again-failed result).
3. The Adversarial-audit phase must **re-verify the non-availability claim** (re-attempt at least one strongest source) before it holds.
4. The locked plan must include the **strongest available primary/domain sources** before any fallback tier — prevents lazy "checked three weak sources → declared unavailable" gaming (codex P3).

This is the structural fix for why blindly running v0.7 on the USA-Paraguay distance question would have been theater: the 3-strike loop cannot thrash on missing data, AND it cannot surrender prematurely.

### 7. Autonomy — checkpointed for research (codex P2)
Build keeps the fully-unsupervised one-paste `/goal` loop. Research is iterative (findings change scope), so research mode runs autonomously **inside** an approved phase but **checkpoints to the user** at two boundaries: (a) after Source Discovery (approve the locked source plan + scope), and (b) before accepting a negative terminal outcome. A `RESCOPE` also checkpoints. Everything else runs without babysitting.

### 8. Files
- `SKILL.md` — add the Stage 0 **router**; build flow text stays verbatim; research flow is a new section/file.
- New `scripts/detect-research-tools.sh`.
- New `templates/phase-research.txt`.
- New `references/source-discovery.md` (taxonomy + sweep + locked-plan format).
- New `references/research-depth.md` (research planning-depth bar).
- New `templates/PROTOCOL-research.md` (research VERIFY/AUDIT/negative-result/conflict/recency/provenance + checkpoints). Build's `PROTOCOL.md` untouched.
- STATE.md template: add `Mode:` field only (back-compat: build reads it as `build`).
- Version → 0.8.0; CHANGELOG entry.

## Dogfood case (live result, 2026-06-13)
USA–Paraguay WC 2026, first-half per-player running distance.
- Aggregators (FotMob, Opta Analyst, SofaScore): **no distance data at all.**
- FIFA match centre STATS tab: **distance IS published** — full-match leader Antonee Robinson 11.96 km; widget shows category leaders, full per-player table needs deeper navigation; **no first-half split** (that is FIFA Training Centre / EFI territory).
- This validates the design: source-discovery (don't trust search summaries, hit the primary source directly), provenance (aggregators were downstream-empty), and negative-result honesty (first-half split = unavailable on public sources, would need the locked-plan gate to confirm at Training Centre).

## Codex arch-review round 1 — resolutions
- **P1.1 (build isolation unsafe)** → router architecture; build verbatim behind dispatch; separate research protocol file; no build-state schema change. (§Decision, §8)
- **P1.2 (negative-result gate under-specified)** → locked ranked source plan + per-source failure evidence + audit re-verification. (§6)
- **P2s folded:** deliverable-first detection (§1), deep-research delegation not reimplementation (§3), source-conflict/recency/provenance gates (§4), research checkpoints (§7).
- **P3s:** lazy-surrender mitigation folded into §6.4; re-scope transition folded into §4.

## Backlog / risk table (not blocking)
- Mode-detection edge cases will need a small labeled test set before trusting auto-detect (monitor false-positive rate).
- deep-research delegation contract (how exactly a phase invokes it) to be specified at implementation.
