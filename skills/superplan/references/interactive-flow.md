# Interactive flow — choreography detail

The 5-stage flow in `SKILL.md` is the contract. This doc covers edge cases.

## Stage 1 — Intake edge cases

**The user gives a one-word request ("auth").**
Echo back, then ask one blocking question: "Auth for what stack, and is this new from scratch or replacing an existing system?"

**The user pastes a giant spec.**
Don't ask clarifying questions. Treat the spec as ground truth, classify the task, move on.

**The user invokes `/superplan` with no arguments.**
Ask: "What do you want me to plan?" Then wait. Don't classify a non-existent task.

**The classification is ambiguous (could be bugfix or refactor).**
Use both tags. Don't force a single bucket.

## Stage 2 — Recon edge cases

**`detect-stack.sh` finds nothing (brownfield).**
Either you misclassified as brownfield, or unknown stack. Ask: "I don't recognise this stack — what should I treat it as?" Record in `.superplan/context.md`.

**Greenfield: environment recon, not skip.**
Even for greenfield, run the inline environment recon block (see SKILL.md Stage 2). Capture available runtimes, package managers, git state, folder contents. This prevents starting blind.

**Recon finds conflicting markers (e.g. both `package.json` and `Cargo.toml`).**
Polyglot project. Treat each as its own subproject. Generate separate matrix sections in VERIFY.md (one mandatory block per stack).

**The repo is huge and `tree` output is overwhelming.**
The script caps at 120 lines. Don't summarise more — the agent only needs a structural sketch.

## Stage 3 — Draft edge cases

**The user's task is a typo fix or one-liner.**
Superplan is overkill. Tell the user: "This is a one-line change — recommend skipping `/superplan` and just editing the file. Continue anyway?" If yes, write a minimal PLAN with one phase.

**Template variables can't be filled (no info to fill them with).**
Write `N/A` with a one-line reason. Do not leave `{{PLACEHOLDER}}` strings in the rendered files.

**The plan's GOAL.txt naturally exceeds 4000 chars.**
This shouldn't happen — the template is sized for the budget. If it does, trim inline narrative; never trim file references. See `goal-format.md`.

## Stage 4 — Iterate edge cases

**The user asks to change something not in the plan files.**
Two cases:
- Scope expansion (new requirement) → add to PLAN.md and ACCEPTANCE.md.
- Scope cut (remove a phase) → strike from PLAN.md, ACCEPTANCE.md, POLISH.md, and STATE.md phase list.

After any structural edit, re-render the HTML.

**The user contradicts an earlier assumption.**
Update the assumption in PLAN.md. Add a one-line "Assumption updated: ..." note in STATE.md.

**The user wants to iterate forever.**
After 5 iterations, prompt once: "We've iterated 5 times. Want to lock and adjust during execution?" Then continue if they say keep going. Don't nag.

**The user says "looks good, but also add X."**
Don't lock yet. Treat as one more iteration. Lock only after a no-additions confirmation.

## Stage 5 — Lock edge cases

**The compiled goal is over budget.**
Trim inline narrative, keep file references. If still over, prompt the user to remove a polish pass or a conditional verification trigger. Never strip MANIFEST/STATE/FAILURE_PROBE requirements — those are load-bearing.

**`sha256sum`/`shasum` both missing.**
Rare. Fall back to `openssl dgst -sha256`. Document the platform in HANDOFF.md template hints. The LOCK.json can use any deterministic hash — the contract is that the hashes match what the agent recomputes at startup.

**The user wants to start execution in the same session.**
Print the goal text. Tell them to paste it. Do not invoke `/goal` yourself — the skill can't.

**The user wants headless execution.**
Print the `superplan-go` command with the absolute path to the script.

**The user changes their mind after lock.**
Unlock by editing STATE.md (`Locked: false`) and LOCK.json (`"locked": false`). Then back to Stage 4. After re-locking, hashes will differ — that's intentional.

**LOCK.json hashes don't match recomputed hashes during execution.**
Either the user edited a locked file (legitimate change request) or the agent did (contract violation). The agent must call this out in SUPERPLAN_STATE and either: (a) stop with a HANDOFF if it was a violation, or (b) re-lock by acknowledging the change in STATE.md.

## Universal "don't do this"

- Don't open the browser more than once. Subsequent renders happen silently.
- Don't write to `.superplan/*.md` with the Write tool after Stage 3 — use Edit so the user's hand-edits survive.
- Don't run any verification commands during planning. Verification belongs to execution.
- Don't modify the user's source code during planning. Planning touches only `.superplan/`.
- Don't summarise the plan in chat after rendering — the user has the HTML.

## Hand-off contract

When Stage 5 prints the start instructions, the skill's job is **done**. The next message from the user (or the runner) takes over. Do not append "should I start now?" or similar — that re-opens the loop.
