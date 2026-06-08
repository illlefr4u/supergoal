# Run kernel — working context (branch `run-kernel-extract`)

> Status doc for the in-progress "run kernel" effort. Read this first when
> resuming work on this branch. It explains **what we're building, why, the
> decisions we've locked, what's done, and what's left.** When the work ships,
> fold the relevant parts into `AGENTS.md` and delete this file.

## TL;DR

We're adding an **optional mechanical-verification layer** to Supergoal: a
single stdlib-Python script (`skills/supergoal/scripts/sg.py`) that compiles a
run's plan into a machine contract (`run.json`), enforces phase completion with
real checks (commands actually ran, evidence exists, edits stayed in scope),
records telemetry, and writes an inspectable report.

The hard constraint is **universality**: Supergoal works for *anybody* today
because it's pure markdown with zero runtime deps. The kernel must not break
that. So it's a **progressive enhancement**, not a replacement.

## Origin & verdict

This started from **PR #4** (`muhammadyusuf7008/supergoal`, "Ship Supergoal v1
run kernel and Pages site"). Review conclusion: **mine, don't merge.** Reasons:

- The engineering in `sg.py` is genuinely good (clean, stdlib-only, tested).
- But the PR was **over-bundled** (kernel + a full website rebuild in one),
  shipped under **spoofed commit authorship** (commits stamped as the repo
  owner though they came from an external fork), and made the kernel a
  **breaking, mandatory v1.0.0** that demoted markdown to a "legacy fallback" —
  which destroys the universality that makes Supergoal good.

So we extracted just the engine onto this branch with honest authorship and are
redesigning the *adoption model* around universality.

## Locked decisions

1. **Adoption model: progressive enhancement.** Markdown stays the universal
   default. The kernel auto-activates **only** when `python3` (+ `git`) is
   present, and is otherwise invisible. No breaking change, no v1.0 reset. The
   switch is a single file-existence check: **if `sg.py` is present in the run
   root, the executor gates each phase through it; otherwise it verifies by the
   prose checklist.** One protocol document, one conditional — not a forked
   "v1 vs legacy" path.

2. **Source of truth: lockfile model.** `ROADMAP.md` is the human-authored plan
   (the one artifact a reviewer edits at the Stage 6 confirmation). `sg.py
   compile` parses it into `run.json`, the machine contract that drives
   gates/telemetry/audit/report. **Humans never hand-edit `run.json`** — it's
   compiled, like `package-lock.json`. `STATE.md` and `report.html` are
   *rendered outputs*. One source, one direction of flow:
   `ROADMAP.md → run.json → STATE.md / report.html`.

## Universality matrix (this is tested, not hoped)

| Capability        | Mode      | Phase gates              | Scope firewall                       | Report / telemetry |
|-------------------|-----------|--------------------------|--------------------------------------|--------------------|
| python3 **+** git | Full      | mechanical               | enforced                             | yes                |
| python3, no git   | Partial   | mechanical (cmds+evidence) | `SCOPE_CHECK skipped` — **announced** | yes                |
| no python3        | Baseline  | prose (exactly as today) | n/a                                  | STATE.md only      |

Everyone gets a working run. **An unverifiable check never reads as a passed
one** — that honesty rule is the heart of the design.

## "No tech debt" rules we're holding

- **One source of truth, one direction.** No dual-authority between markdown and
  JSON. `run.json` is compiled, never hand-edited.
- **No second-class "legacy" path.** Markdown *is* the baseline, not a fallback.
- **Honest degradation, never silent.** Missing capability is announced and
  recorded as an event, never a green check.
- **python3 + git only** for the kernel — no bash (dropped for Windows).
- **Loud failures at compile/preflight**, not silent best-effort.
- **One file** (`sg.py`), stdlib-only — keeps the Codex manual-sync cheap.

## Branch status — what's built

Branch: **`run-kernel-extract`** (off `origin/main`). Commits, oldest first:

1. `Extract run-kernel engine from PR #4 for evaluation` — `sg.py` + its test +
   fixtures, isolated from the website and the breaking wiring.
2. `kernel: drop bash dependency, do git reads in pure Python` — kernel does its
   own read-only `git` calls via `subprocess`; capability floor is now
   python3 + git (no bash). `repo-state.sh` stays for the *markdown* cleanliness
   check; the kernel no longer touches it.
3. `kernel: announce scope-firewall skip when no git baseline` — no usable
   baseline → `SCOPE_CHECK skipped (no git baseline)` + a `phase.scope.skipped`
   event, instead of silently passing. Capability limit, not a gate failure.
4. `kernel: add ROADMAP.md -> run.json compiler (lockfile model)` — the
   `compile` command + the ROADMAP template's `Allowed paths` section and
   criterion/evidence hints.

All authored as `robzilla1738 <robertcourson1738@gmail.com>`, no
`Co-Authored-By` (repo convention).

### `sg.py` commands

`init-run`, **`compile`** (new), `record-event`, `gate-phase`, `audit`,
`resume`, `report`, `validate-run`.

### The ROADMAP format the compiler parses

```
## Phase N — Name
**Deliverables:**            - bullets (paths or features)
**Acceptance criteria:**     - bullets, optionally tagged [mechanical]/[human]/[trust-prior]
                               (untagged => trust-prior, so unverified work shows as trust debt)
**Mandatory commands:**      - `cmd` bullets (deduped into a command registry, referenced by id)
**Allowed paths:**           - files/dirs the phase may change (scope firewall; omit/`*` => disabled, with a warn)
**Evidence required:**       - paths under evidence/phase-N/ the gate checks exist
**Dependencies:** none | 1, 2
```

`compile` errors loudly (`COMPILE_ERROR`) on a malformed plan (no phases, a
phase with no criteria, validation failures) and refuses to clobber an in-flight
run (`IN_PROGRESS`/`AUDIT_PENDING`/`COMPLETE`) without `--force`.

## What's left

**Engine-complete (branch-only, safe to do without ceremony):**

- `render` command: regenerate `STATE.md` *from* `run.json`, closing the
  one-directional loop (`report.html` already renders from `run.json`).

**Make it live (changes the shipped skill — confirm before doing):**

- Wire the single conditional into `templates/PROTOCOL.md` + `SKILL.md`
  ("if `sg.py` present, gate through it; else prose").
- Add a `python3` probe to `scripts/detect-env.sh`; Stage 7 copies `sg.py` into
  the run namespace and runs `compile` when python3 is present.
- Reframe the kernel's `legacy_resume` / `LEGACY_RUN_FALLBACK` wording from
  "legacy" to "baseline" (per the progressive-enhancement decision).
- **Minor** version bump (target **0.8.0**, *not* PR #4's breaking 1.0.0):
  `plugin.json`, README "Current:" line, AGENTS "Working state", CHANGELOG entry.
- Codex sync (`rm -rf ~/.codex/skills/supergoal && cp -R skills/supergoal
  ~/.codex/skills/supergoal`) and marketplace verification.
- New transcript markers to document where they're introduced: `RUN_COMPILED`,
  `COMPILE_WARN`/`COMPILE_ERROR`, `SCOPE_CHECK`, `phase.scope.skipped`,
  plus PR #4's `PHASE_GATE_VERIFY`, `SCOPE_DRIFT`, `TRUST_DEBT`,
  `RUN_REPORT_WRITTEN`, `SUPERGOAL_RUN_KERNEL_READY`.

## Verify locally

```bash
python3 -m py_compile skills/supergoal/scripts/sg.py
bash tests/sg-run-kernel.test.sh   # expect: 35 passed, 0 failed
bash tests/repo-state.test.sh      # expect: 47 passed, 0 failed
bash tests/claim-run.test.sh       # expect: 23 passed, 0 failed
bash skills/supergoal/scripts/validate-phase.sh skills/supergoal/templates/phase-goal.txt
claude plugin validate .claude-plugin/plugin.json
```

> **CI/sandbox note:** `tests/sg-run-kernel.test.sh` does real `git init` +
> `git commit` in a temp dir. If the environment force-enables commit signing,
> those commits fail and ~3 scope cases error out. That's environmental, not a
> code bug — run with a config that disables signing
> (`GIT_CONFIG_GLOBAL` pointing at a file with `commit.gpgsign=false`) or on a
> normal local machine, where it's a clean 35/35.

## Files that matter for this effort

- `skills/supergoal/scripts/sg.py` — the run kernel (the whole engine).
- `tests/sg-run-kernel.test.sh` + `tests/fixtures/runs/**` — kernel tests.
- `skills/supergoal/templates/ROADMAP.md` — the human plan the compiler reads.
- `skills/supergoal/scripts/repo-state.sh` — **markdown-path** cleanliness check
  (unchanged; the kernel no longer calls it).
- Not yet touched on this branch: `templates/PROTOCOL.md`, `SKILL.md`,
  `scripts/detect-env.sh`, `plugin.json`, `CHANGELOG.md` — these are the
  "make it live" surface.
