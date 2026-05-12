# Superplan

A goal-compiler skill for Claude Code and Codex.

`/superplan <task>` turns a vague build request into a strict, testable project spec, renders it as a reviewable HTML plan, lets you iterate conversationally, and then emits a measurable `/goal` command that drives an autonomous build to a verifiable end state.

## What makes it different

Most "autonomous build" loops (Ralph, etc.) are persistence wrappers — they keep the model running until it claims it's done. Superplan adds four things on top:

1. **A plan compiler.** Vague intent → strict spec → measurable `/goal` condition. Done is defined before the build starts, not after.
2. **A hash-pinned contract.** `LOCK.json` records sha256s of PLAN/ACCEPTANCE/VERIFY/POLISH so the agent can't silently weaken the contract mid-run.
3. **Transcript-visible evidence.** The `/goal` evaluator only sees the conversation, so the compiled goal forces the agent to *paste* its `SUPERPLAN_MANIFEST` (contract surfaces), `SUPERPLAN_STATE` (per-turn ledger), `FAILURE_PROBE` (adversarial check), and `SELF_REVIEW` (final claim) blocks. References to files alone aren't enough.
4. **Verification matrix, not flat list.** Mandatory commands always run; conditional commands run when their trigger applies; non-terminating commands (dev servers, `docker compose up`) are allowlisted so the stuck-watcher doesn't kill them mid-run.

"Perfect" is not a stopping condition. "Build passes, tests pass, lint passes, polish phases complete, FAILURE_PROBE found no blocking issues, SELF_REVIEW confirms it" is.

## Workflow

```text
/superplan <your request>
  │
  ├─ 1. Intake        classify the task, ask only blocking questions
  ├─ 2. Recon         brownfield → detect-stack.sh + summarize-repo.sh
  │                   greenfield → environment recon (runtimes + folder)
  ├─ 3. Draft         write .superplan/*.md, render plan.html, open in browser
  ├─ 4. Iterate       feedback in chat → skill edits files → re-renders HTML
  └─ 5. Lock          write LOCK.json (sha256s) + GOAL.txt + paste/run instructions

Then:
  Paste:  /goal <contents of .superplan/GOAL.txt minus leading "/goal ">
  Or run: ./skills/superplan/scripts/superplan-go
```

## Host support

| Capability | Claude Code | Codex |
|---|---|---|
| Skill format | production | format-compatible (best effort) |
| `/goal` command | production | experimental, requires `features.goals = true` |
| `claude -p "/goal ..."` headless | yes | runner flag may differ; see `docs/codex-setup.md` |
| Plugin manifest | `.claude-plugin/plugin.json` | `.codex-plugin/plugin.json` |
| Skill location | `~/.claude/skills/<name>/` or project `.claude/skills/` | `~/.agents/skills/<name>/` or project `.agents/skills/` |

Codex parity isn't independently verified — please open an issue if you hit a deviation.

## Install

### Claude Code (project skill)

```bash
git clone https://github.com/robzilla1738/superplan.git
ln -s "$PWD/superplan/skills/superplan" .claude/skills/superplan
```

### Claude Code (personal skill)

```bash
git clone https://github.com/robzilla1738/superplan.git ~/Code/superplan
ln -s ~/Code/superplan/skills/superplan ~/.claude/skills/superplan
```

### Codex (experimental — please report issues)

```bash
git clone https://github.com/robzilla1738/superplan.git ~/Code/superplan
ln -s ~/Code/superplan/skills/superplan ~/.agents/skills/superplan
```

See [docs/install.md](docs/install.md) for plugin install, troubleshooting, and the runner setup.

## Repo layout

```
superplan/
├── skills/superplan/             single source of truth
│   ├── SKILL.md
│   ├── references/               rubrics, formats, flow docs
│   ├── templates/                .md + plan.html templates
│   └── scripts/                  detect, summarize, render, open, runner, watcher
├── .claude-plugin/plugin.json    Claude Code plugin manifest
├── .codex-plugin/plugin.json     Codex plugin manifest (experimental)
├── examples/                     frozen runs from real builds
└── docs/                         install + setup guides
```

## Status

V1 (MVP). Tested against Claude Code; Codex side is best-effort. Open an issue if you hit a frontmatter or `$ARGUMENTS` mismatch.

## License

MIT. See [LICENSE](LICENSE).
