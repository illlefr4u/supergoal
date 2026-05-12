---
name: superplan
description: Deeply plan a software task, render the plan as an HTML preview, iterate with the user, lock the plan into a hash-pinned contract, and compile a measurable /goal condition that drives autonomous execution to a verifiable end state. Use when the user invokes /superplan or asks to set up an autonomous build with a measurable end state.
argument-hint: <describe what you want built>
---

# Superplan

You are running the Superplan workflow for this request:

$ARGUMENTS

Your job is to compile this request into:
1. Durable planning artifacts under `$SUPERPLAN_ROOT/` (default `.superplan/` in the current working directory)
2. A single self-contained `$SUPERPLAN_ROOT/plan.html` for browser review
3. A locked contract: `$SUPERPLAN_ROOT/LOCK.json` (hash-pinned, plus required phases and mandatory commands)
4. A measurable `$SUPERPLAN_ROOT/GOAL.txt` containing a Claude Code `/goal` command

You do **not** execute the build. You prepare it. The user (or `superplan-go`) submits the `/goal` — unless auto-kick is enabled (default), in which case Stage 5 fires `superplan-go` in the background as soon as the lock completes.

## Operating principles

- "Perfect" is not a stopping condition. Translate it into measurable acceptance criteria.
- Don't ask clarifying questions unless missing information would block planning. Record assumptions in `PLAN.md`.
- After every artifact write/edit, re-render the HTML so the user's open browser tab shows the latest plan on refresh.
- The compiled `/goal` references `$SUPERPLAN_ROOT/*.md` files, not their contents. The 4000-char limit forces compression.
- **The evaluator only sees the transcript.** The compiled goal must force the agent to surface its contract — phases, mandatory commands, acceptance summary — into the conversation, not just point at files.

## Locating the skill and its artifact root

Discover both `SUPERPLAN_DIR` (where the skill lives) and `SUPERPLAN_ROOT` (where artifacts go) at the start. **Export both** so they're inherited by every script invocation.

```bash
SUPERPLAN_DIR=$(dirname "$(ls -1 \
  "$HOME/.claude/skills/superplan/SKILL.md" \
  "$HOME/.agents/skills/superplan/SKILL.md" \
  "$PWD/.claude/skills/superplan/SKILL.md" \
  "$PWD/.agents/skills/superplan/SKILL.md" \
  2>/dev/null | head -n1)")
export SUPERPLAN_DIR

# Dispatchers like Superboard set SUPERPLAN_ROOT to a per-task directory
# (e.g. .superboard/tasks/<id>/superplan). Standalone use defaults to .superplan.
export SUPERPLAN_ROOT="${SUPERPLAN_ROOT:-.superplan}"

echo "SUPERPLAN_DIR=$SUPERPLAN_DIR"
echo "SUPERPLAN_ROOT=$SUPERPLAN_ROOT"
```

All subsequent script and file references use `$SUPERPLAN_DIR` (for skill assets) and `$SUPERPLAN_ROOT` (for artifact files).

## Stage 1 — Intake

Echo the task back in one sentence. Classify:

- **greenfield** — request implies new project; cwd has no `.git/` or empty tree
- **brownfield** — change in existing repo
- **bugfix** — request mentions "bug", "broken", "fails", "regression"
- **refactor** — request mentions "refactor", "clean up", "restructure"
- **ui** — request mentions "design", "polish", "UI", "UX", "responsive", "redesign"

Tags combine (e.g. brownfield + ui).

Ask **only** blocking questions. Record non-blocking decisions as assumptions in PLAN.md.

## Stage 2 — Recon

### Codebase recon (brownfield only)

```bash
mkdir -p "$SUPERPLAN_ROOT"
bash "$SUPERPLAN_DIR/scripts/detect-stack.sh"   > "$SUPERPLAN_ROOT/context.md"
bash "$SUPERPLAN_DIR/scripts/summarize-repo.sh" > "$SUPERPLAN_ROOT/repo-map.md"
```

Read both files. Print a 5-line summary: stack, package manager, build/test/lint/typecheck commands, notable modules, risky areas.

### Environment recon (greenfield)

Even for greenfield, gather environment context — never start blind. Run inline:

```bash
mkdir -p "$SUPERPLAN_ROOT"
{
  echo "# Context (greenfield environment recon)"
  echo
  echo "Working dir: $(pwd)"
  echo "Git initialised: $([ -d .git ] && echo yes || echo no)"
  echo
  echo "## Runtimes available"
  for c in node npm pnpm yarn bun python3 ruby go rustc swift docker; do
    if command -v "$c" >/dev/null 2>&1; then
      echo "- \`$c\`: $("$c" --version 2>&1 | head -1)"
    fi
  done
  echo
  echo "## Folder state"
  ls -la | head -20
  echo
  echo "## Files present (depth 1)"
  find . -maxdepth 1 -not -name '.' | sort | head -30
} > "$SUPERPLAN_ROOT/context.md"
```

Then ask only the blocking product/stack questions the request didn't answer (which framework, which language, which provider for X).

## Stage 3 — Draft

Read templates from `$SUPERPLAN_DIR/templates/`:
- `PLAN.template.md`
- `ACCEPTANCE.template.md`
- `VERIFY.template.md` (verification **matrix** — mandatory / conditional / non-terminating)
- `RISKS.template.md`
- `POLISH.template.md`
- `STATE.template.md`
- `LOCK.template.json` (filled later in Stage 5)
- `HANDOFF.template.md` (referenced only by stuck/failure flow)

Fill each with task-specific content. Write to `$SUPERPLAN_ROOT/PLAN.md`, `$SUPERPLAN_ROOT/ACCEPTANCE.md`, etc.

While filling:
- Follow `references/planning-rubric.md` for content quality.
- Follow `references/verification-rubric.md` for matrix structure.
- For `ui` tasks, fold `references/ui-verification.md` into VERIFY.md (conditional row) and POLISH.md (visual pass).
- For `greenfield`, set `Recon: environment-only` in STATE.md and PLAN.md.

After all files exist, render the preview and open it:

```bash
node "$SUPERPLAN_DIR/scripts/render-plan.mjs"
bash "$SUPERPLAN_DIR/scripts/open-plan.sh"
```

(Both scripts read `SUPERPLAN_ROOT` from the environment, so no path argument is needed.)

Then tell the user exactly:

> Plan rendered at `$SUPERPLAN_ROOT/plan.html`. Review and reply with edits, or say "lock it in" to compile the `/goal` and auto-kick the build.

## Stage 4 — Iterate

Use **Edit** (not Write) on `$SUPERPLAN_ROOT/*.md` to preserve user-touched sections. Re-render after each batch:

```bash
node "$SUPERPLAN_DIR/scripts/render-plan.mjs"
```

Don't re-open the browser. Continue iterating until the user signals lock-in ("lock it in", "looks good", "ship it"). If iterations cross 5 rounds without convergence, prompt once: "We've iterated 5 times — lock now and adjust during execution?"

## Stage 5 — Lock

### Step 1: Compute file hashes and write LOCK.json

```bash
# Portable sha256 (macOS / Linux)
sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

H_PLAN=$(sha256 "$SUPERPLAN_ROOT/PLAN.md")
H_ACC=$(sha256 "$SUPERPLAN_ROOT/ACCEPTANCE.md")
H_VER=$(sha256 "$SUPERPLAN_ROOT/VERIFY.md")
H_POL=$(sha256 "$SUPERPLAN_ROOT/POLISH.md")
echo "Hashes computed"
```

Read `$SUPERPLAN_DIR/templates/LOCK.template.json`, fill it with:
- `locked: true`
- `task`: title from PLAN.md
- `created_at`: ISO 8601 UTC now
- `max_turns`: 80 default (greenfield 120, bugfix 30)
- The four hashes
- `required_phases`: list from PLAN.md phase headings
- `mandatory_commands`: from VERIFY.md mandatory rows
- `conditional_triggers`: from VERIFY.md conditional rows
- `stop_conditions`: as in the template

Write `$SUPERPLAN_ROOT/LOCK.json`.

### Step 2: Compile GOAL.txt

Use this exact template. Substitute `{MAX_TURNS}` AND substitute every `$SUPERPLAN_ROOT` literal with the actual root path so the agent reads real paths at run time (e.g. `.superplan` for standalone, `.superboard/tasks/abc-123/superplan` for board-managed):

```
/goal Complete the build locked in $SUPERPLAN_ROOT/PLAN.md, $SUPERPLAN_ROOT/ACCEPTANCE.md, $SUPERPLAN_ROOT/VERIFY.md, $SUPERPLAN_ROOT/POLISH.md, and $SUPERPLAN_ROOT/LOCK.json. First, read those files and print a compact SUPERPLAN_MANIFEST block listing phases, required acceptance criteria, mandatory verification commands, conditional verification triggers, polish passes, turn cap, and stop conditions so the evaluator can judge from transcript-visible evidence. Do not weaken locked plan/acceptance/verify/polish files during execution; update only STATE.md and proof logs unless stopping for an honest handoff. Each turn must print a SUPERPLAN_STATE block with turn, phase, files changed, evidence added, blockers, next action, and can_stop yes/no with reason. A phase may be marked complete only after transcript-visible evidence: passing command output, targeted test output, relevant diff summary, screenshot/artifact path, migration validation, or explicit review evidence. Runtime-behavior phases require command/test evidence unless marked documentation-only or review-only. Run all mandatory final verification commands and any conditional verification whose trigger applies. Report command, exit code, and relevant output; save long logs under $SUPERPLAN_ROOT/logs. Final completion requires all phases complete, all acceptance criteria met, mandatory verification passing or unrelated pre-existing failures proven, polish passes complete, FAILURE_PROBE completed, and SELF_REVIEW stating no blocking issues found with rationale. If stuck — same failure twice, no STATE/diff/log progress for the configured stuck window, missing permissions, unavailable dependency, or unresolvable ambiguity — write the blocker to $SUPERPLAN_ROOT/HANDOFF.md and stop with an honest handoff. Stop only on success-with-evidence, explicit handoff, or turn cap = {MAX_TURNS}.
```

Validate length: must be ≤3800 chars (200-char headroom under the 4000 limit). With a 3-digit MAX_TURNS and a typical SUPERPLAN_ROOT (`.superplan` ≈ 10 chars, `.superboard/tasks/<id>/superplan` ≈ 40 chars), the result stays well under the budget.

### Step 3: Update STATE.md

Mark `Locked: true`, `Ready-to-execute: true`, `LOCK.json present: true`, `Locked-at: <ISO>`.

### Step 4: Auto-kick the headless run (default behaviour)

Lock implies start. After GOAL.txt and LOCK.json are written, fire `superplan-go` in the background unless the caller opted out via `SUPERPLAN_NO_AUTOKICK=1` (Superboard sets this because it manages launch itself).

```bash
if [ "${SUPERPLAN_NO_AUTOKICK:-0}" != "1" ]; then
  nohup "$SUPERPLAN_DIR/scripts/superplan-go" \
    >> "$SUPERPLAN_ROOT/run.log" 2>&1 &
  KICK_PID=$!
  echo "Auto-kicked headless run. PID: $KICK_PID"
  echo "Tail: tail -f $SUPERPLAN_ROOT/run.log"
fi
```

### Step 5: Print the summary

```
$SUPERPLAN_ROOT/GOAL.txt is ready (NN chars).
$SUPERPLAN_ROOT/LOCK.json hashed and locked.

# If auto-kicked:
Headless run started. PID: <kick-pid>
Tail: tail -f $SUPERPLAN_ROOT/run.log

# If SUPERPLAN_NO_AUTOKICK=1 was set:
Auto-kick suppressed. To start manually, choose one:
  A. Paste into this Claude Code session:
       /goal <contents of $SUPERPLAN_ROOT/GOAL.txt without the leading "/goal ">
  B. Run headless in a separate terminal:
       $SUPERPLAN_DIR/scripts/superplan-go
```

Stop. Your job ends here. Do **not** attach to the headless run yourself — it streams to `$SUPERPLAN_ROOT/run.log` and the user (or Superboard) tails it.

## Execution-phase contract (for reference; the /goal enforces this)

When `/goal` starts, the agent must:

1. **Read** PLAN, ACCEPTANCE, VERIFY, POLISH, LOCK.json (from the substituted `$SUPERPLAN_ROOT` path baked into GOAL.txt).
2. **Print SUPERPLAN_MANIFEST** with: phases, acceptance summary, mandatory commands, conditional triggers, polish passes, turn cap, stop conditions. Evaluator-visible. See `references/goal-format.md` for the exact shape.
3. **Per turn**: implement a phase, gather evidence (command output, test output, diff summary, screenshot path, etc.), append a `logs/turn-NNN.md`, update STATE.md, then **paste SUPERPLAN_STATE** block into the transcript.
4. **Per phase**: flip to `complete` only with transcript-visible evidence of the matching type.
5. **Before final success**: run mandatory + applicable-conditional verification commands and paste evidence; complete all polish passes; paste **FAILURE_PROBE** (3 most likely break vectors, how each was checked); paste **SELF_REVIEW** ("no blocking issues found" + rationale).
6. **On stuck/blocked**: write `$SUPERPLAN_ROOT/HANDOFF.md` from template and stop. Do not weaken acceptance to force success.

## Reference docs (read when you need detail)

- `references/goal-format.md` — `/goal` syntax, 4000-char limit, SUPERPLAN_MANIFEST/STATE/FAILURE_PROBE shapes
- `references/planning-rubric.md` — quality bar for PLAN.md sections
- `references/verification-rubric.md` — matrix structure per stack
- `references/interactive-flow.md` — choreography detail and edge cases
- `references/ui-verification.md` — browser-harness integration for UI tasks
- `references/html-viewer.md` — plan.html structure
