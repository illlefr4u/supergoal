# AGENTS.md

Authoritative project doc. Any agent (Claude, Codex, or other) opening this repo should be able to read this file alone and understand the project, where to make changes, and what conventions to follow.

## What this repo is

**Supergoal** is a Claude Code / Codex skill that turns a vague build request into a deeply-planned, autonomously-executed `/goal` run with built-in retry, fix-spec recovery, per-phase memory writeback, and a final audit pass that re-validates the work against the original plan.

- Slash command: `/supergoal <task>`
- Central mechanism: produces one ready-to-paste `/goal` command. The user pastes it once; the rest is autonomous.
- Works on: Claude Code (via plugin marketplace) and Codex CLI (via manual skill copy).
- Public install: see `README.md`.

## Repo layout

```
supergoal/
├── .claude-plugin/
│   ├── marketplace.json        Catalog Claude Code reads when added as a marketplace
│   └── plugin.json             Plugin manifest (name, version, description, skills path)
├── .gitignore                  Editor/OS junk + .supergoal/ artifact dirs
├── AGENTS.md                   This file. Authoritative project doc.
├── CLAUDE.md                   Claude Code-specific tips. Points at this file.
├── CHANGELOG.md                Per-version release notes. Keep-a-Changelog format, SemVer.
├── LICENSE                     MIT.
├── README.md                   Public-facing: what it is, install, use, Mermaid flow charts.
└── skills/supergoal/
    ├── SKILL.md                The skill itself. ~430 lines, under the 500-line perf budget.
    ├── references/             Progressive-disclosure docs the agent reads when needed.
    │   ├── planning-depth.md   What makes a plan deserve "super".
    │   ├── phase-design.md     How to slice phases (adaptive count, no cap).
    │   └── goal-format.md      /goal mechanics on both hosts; required transcript blocks.
    ├── scripts/                Bash scripts the planner executes during stages.
    │   ├── detect-env.sh       Greenfield env recon.
    │   ├── detect-stack.sh     Brownfield stack/framework detection.
    │   ├── summarize-repo.sh   Compressed repo map.
    │   └── validate-phase.sh   Sanity-checks a phase spec has required markers.
    └── templates/              Files the planner copies into a user's `.supergoal/` dir.
        ├── ROADMAP.md          Phase plan with dependencies.
        ├── STATE.md            Live progress file.
        ├── phase-goal.txt      Phase spec skeleton (work, criteria, evidence, commands).
        └── PROTOCOL.md         Execution loop + failure recovery + final audit protocol.
```

## What ships vs what doesn't

- **Ships to consumers** (via marketplace install or manual clone): everything under `skills/supergoal/`. The plugin manifest at `.claude-plugin/plugin.json` declares `skills: "./skills/"`.
- **Repo-only** (not part of the plugin payload): `README.md`, `CHANGELOG.md`, `LICENSE`, `AGENTS.md`, `CLAUDE.md`, `.gitignore`. Docs / hygiene.
- **Marketplace entry** at `.claude-plugin/marketplace.json` is read by Claude Code when a user runs `/plugin marketplace add ...` against this repo. Points at the plugin at `./`.

## How the skill works (one paragraph)

When invoked, the skill runs Stages 0–6 (preload memory, detect tools, intake clarifying questions, recon, deep think, decompose into N phases, write per-phase specs to `.supergoal/`, plan review with revision menu). At Stage 7 it prints a ready-to-paste `/goal` command. The user pastes it. Inside the `/goal` session, the agent loops through each phase (read spec → do work → SUPERGOAL_PHASE_VERIFY → memory writeback → SUPERGOAL_PHASE_DONE), self-healing failures with a 3-strike retry/fix-spec/handoff protocol. After the last phase, the **final audit** re-reads the original `ROADMAP.md`, re-runs the deduplicated mandatory commands, spot-checks every acceptance criterion, and writes `audit-fix-<round>.md` for any gaps (up to 3 audit rounds). Only after `AUDIT_COMPLETE` does it print `SUPERGOAL_RUN_COMPLETE`.

## Making changes

### Editing the skill content

Edit `skills/supergoal/SKILL.md` or the files under `references/`, `scripts/`, `templates/`. The user-visible behavior is driven by what's in `SKILL.md` plus what the planner reads from `references/` and writes from `templates/`.

After editing:

1. **Validate any manifests you touched** — `claude plugin validate .claude-plugin/plugin.json` and `claude plugin validate .claude-plugin/marketplace.json`.
2. **Validate any phase spec template** — `bash skills/supergoal/scripts/validate-phase.sh skills/supergoal/templates/phase-goal.txt`.
3. **Bump the version** in `.claude-plugin/plugin.json` (`0.5.x → 0.5.x+1` for backwards-compatible patches, `0.x → 0.x+1` for new features, `x.0` for breaking changes). The marketplace cache only refreshes when this field changes.
4. **Add a CHANGELOG entry** at the top of `CHANGELOG.md`, Keep-a-Changelog format.
5. **Commit, push, tag** with the new version: `git tag -a v0.5.x -m "..."`, `git push origin v0.5.x`.

### Editing READMEs / docs only

No version bump needed. Just commit + push. Docs don't affect what install consumers get.

### Conventions

- **Slash command and skill name**: always `supergoal` (lowercase). Plugin name, marketplace name, skill frontmatter `name:`, slash command, artifact dir (`.supergoal/`), and transcript markers (`SUPERGOAL_*`) all match.
- **Versioning**: SemVer. Plugin manifest `version` field is the source of truth. README and CHANGELOG must match.
- **CHANGELOG**: every version gets an entry. Mention what changed, what's new, what's removed. Migration steps if breaking.
- **Co-Authored-By trailers**: do NOT add Claude or any AI attribution to commit messages. All commits are authored only by the repo owner.
- **No `.DS_Store`**: gitignored. If one slips in, remove it.

## Install flows (verified working)

### For a new user (Claude Code)

```text
/plugin marketplace add https://github.com/robzilla1738/supergoal.git
/plugin install supergoal@supergoal
/reload-plugins
```

The `owner/repo` shorthand (`/plugin marketplace add robzilla1738/supergoal`) also works, but only if the user has GitHub SSH keys configured — the CLI defaults to SSH cloning for that shorthand.

### For a new user (Codex CLI)

```bash
mkdir -p ~/.codex/skills
git clone https://github.com/robzilla1738/supergoal /tmp/supergoal-clone
cp -R /tmp/supergoal-clone/skills/supergoal ~/.codex/skills/
rm -rf /tmp/supergoal-clone
```

Codex doesn't have a plugin marketplace; this is the manual path.

### For local development on this repo

Source-of-truth is the repo (`/Users/robert/Code/supergoal/`). To test changes:

```bash
# After committing + pushing + version-bumping:
claude plugin marketplace update supergoal
claude plugin update supergoal@supergoal
# Then /reload-plugins in a Claude Code session
```

For Codex, after committing:

```bash
rm -rf ~/.codex/skills/supergoal
cp -R /Users/robert/Code/supergoal/skills/supergoal ~/.codex/skills/supergoal
```

## Transcript markers (load-bearing)

These are the named blocks the executing agent must print into the transcript. The host's `/goal` evaluator + the user both read them.

- `SUPERGOAL_PHASE_START` — once per phase, at the start. Metadata only.
- `SUPERGOAL_PHASE_VERIFY` — once per phase, before DONE. Each criterion pass/fail with evidence.
- `MEMORY_SAVED` — once per phase, between VERIFY and DONE. `<name>` or `none`.
- `SUPERGOAL_PHASE_DONE` — once per phase, final block.
- `FAILURE_PROBE` / `FAILURE_ESCALATE` / `FAILURE_HANDOFF` — 3-strike phase-criterion recovery.
- `AUDIT_START` / `AUDIT_VERIFY` / `AUDIT_GAPS` / `AUDIT_COMPLETE` / `AUDIT_HANDOFF` — final audit pass.
- `SUPERGOAL_RUN_COMPLETE` — only after `AUDIT_COMPLETE`. Run is done.

The `/goal` end-state requires `SUPERGOAL_RUN_COMPLETE` preceded by `AUDIT_COMPLETE` and one `SUPERGOAL_PHASE_DONE` per phase, with no `FAILURE_HANDOFF` or `AUDIT_HANDOFF`.

Full format spec: `skills/supergoal/references/goal-format.md`.

## Gotchas

- **Slash commands fire only from user input.** Agent text containing `/goal "..."` is *not* parsed as a command. Stage 7 is a one-paste handoff — the planner prints the line, the user pastes it. Never frame this as "automatic dispatch."
- **Plugin cache only refreshes on version-field change.** If you push a code change without bumping `plugin.json` version, `claude plugin update` reports "already at latest" and the cache stays stale. Always bump on shipped changes.
- **`.gitignore` extension filter**: the file has no extension, so `find -name "*.md"` etc. skip it. When doing mass renames, include the gitignore separately.
- **Codex install is a one-way copy**. There's no auto-update path. To update Codex users: `rm -rf ~/.codex/skills/supergoal && cp -R …` again. Document this in any breaking-change CHANGELOG entry.
- **Memory writeback is per-phase, optional**. The agent emits `MEMORY_SAVED: <name>` or `MEMORY_SAVED: none`. Future runs preload these for the user — load-bearing for the "starts smarter" pitch.
- **Mermaid renders natively in GitHub README** but not always in every external markdown viewer. Stick to standard Mermaid syntax (flowchart TD / LR, subgraphs, classDef styling).

## Working state (as of v0.5.2 — 2026-05-14)

- All planning + execution surfaces (Stages 0–7 + Phase loop + Final audit) are implemented and live.
- End-to-end install verified on this machine: marketplace → install → plugin details show `supergoal 0.5.2`.
- All three SKILL.md locations (repo source, Claude Code plugin cache, Codex skill dir) confirmed byte-identical.
- GitHub repo description, README headline, CHANGELOG, plugin.json, tag, and the live install metadata all aligned at v0.5.2.
- One known lag: the GitHub "Contributors" sidebar/graph is still recomputing after a prior history rewrite. The actual `/contributors` API returns only `robzilla1738`. The sidebar will catch up on GitHub's schedule.

## Open work (none blocking)

- First production use of `/supergoal` on a non-trivial task is the actual shakedown. Until then, design correctness is established by code review and the `claude plugin validate` checks, not real-world.
- The Mermaid diagrams in `README.md` are a v0.5.2 addition; tweak as the visual story matures.
- Audit step is new in v0.5.2; observe how many real-world gaps it surfaces vs how often the per-phase VERIFY caught everything. If audits never find gaps, the value is mostly defensive; if they routinely catch regressions, prioritize making the audit's command-rerun set smarter (e.g., only re-run commands whose touched files were modified since the last successful run).

## Related

- Repo: https://github.com/robzilla1738/supergoal
- License: MIT
- Author: Robert Courson
