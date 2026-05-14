# CLAUDE.md

Project-level instructions for Claude Code sessions opened in this repo. Read `AGENTS.md` first for the authoritative project doc; this file adds Claude-Code-specific tips on top.

## Quick orientation

This repo is the source of truth for the `supergoal` skill — a Claude Code plugin that turns vague build requests into deeply-planned, autonomously-executed `/goal` runs with a final audit pass.

Full project doc: see [AGENTS.md](AGENTS.md).

## Working in this repo from Claude Code

### File map you actually edit

- `skills/supergoal/SKILL.md` — the skill content. Edit here for behavioral changes.
- `skills/supergoal/references/*.md` — progressive-disclosure docs the agent reads when needed.
- `skills/supergoal/templates/PROTOCOL.md` — execution loop + failure recovery + audit. Edit here when changing the per-`/goal`-session protocol.
- `.claude-plugin/plugin.json` — bump `version` on every shipped change so the marketplace cache refreshes.
- `CHANGELOG.md` — add a top entry per release.
- `README.md` — public-facing only. Edit for docs / Mermaid diagram tweaks. No version bump needed.

### Before shipping a change

```bash
claude plugin validate .claude-plugin/plugin.json
claude plugin validate .claude-plugin/marketplace.json
bash skills/supergoal/scripts/validate-phase.sh skills/supergoal/templates/phase-goal.txt
```

All three should return `✔ Validation passed`.

### Local install testing

After committing + pushing + bumping version:

```bash
claude plugin marketplace update supergoal
claude plugin update supergoal@supergoal
# then in a Claude Code session:
/reload-plugins
/supergoal <some test task>
```

If `claude plugin update` reports "already at latest" but you know you pushed changes, you forgot to bump `version` in `plugin.json`.

### Codex sync

Claude Code auto-updates via the marketplace. Codex doesn't have a marketplace — it's a manual file copy. After any shipped change:

```bash
rm -rf ~/.codex/skills/supergoal
cp -R /Users/robert/Code/supergoal/skills/supergoal ~/.codex/skills/supergoal
```

## Conventions that matter here

### Commit attribution

**Do not add `Co-Authored-By` trailers to any commit message.** All commits are authored solely by the repo owner (`robzilla1738 <robertcourson1738@gmail.com>`). This rule has been load-bearing during cleanup of prior co-author attribution; preserve it going forward.

### Naming

Everything in lowercase `supergoal`. The plugin name, marketplace name, skill frontmatter `name:`, slash command (`/supergoal`), artifact dir (`.supergoal/`), and transcript markers (`SUPERGOAL_*`) all match. If you find a stray `superplan` outside the CHANGELOG, it's a bug — the CHANGELOG keeps historical names intentionally.

### Version bumping

Source of truth is `.claude-plugin/plugin.json`'s `version`. Must match README's "Current: v..." line and the latest `CHANGELOG.md` entry. Tag the same number: `git tag -a v0.5.x -m "..." && git push origin v0.5.x`.

### Slash command mechanics

`/goal` on both Claude Code and Codex is a **user-initiated** command. Agent text containing `/goal "..."` does **not** fire the command. Stage 7's design is an honest one-paste handoff — the planner prints a fenced code block with the `/goal` line, instructs the user to paste it, and stops. Never reframe this as automatic dispatch.

`/goal` itself is built-in on Claude Code (no plugin dependency) per the official docs.

### Transcript markers

The agent inside the `/goal` session must print these named blocks:

- `SUPERGOAL_PHASE_START` / `_VERIFY` / `_DONE`
- `MEMORY_SAVED`
- `AUDIT_START` / `AUDIT_VERIFY` / `AUDIT_GAPS` / `AUDIT_COMPLETE` / `AUDIT_HANDOFF`
- `SUPERGOAL_RUN_COMPLETE`
- `FAILURE_PROBE` / `FAILURE_ESCALATE` / `FAILURE_HANDOFF`

These are how the `/goal` evaluator decides the run is done. Don't rename without thinking through the protocol + the end-state condition string.

The `/goal` end-state requires `SUPERGOAL_RUN_COMPLETE` preceded by `AUDIT_COMPLETE` and one `SUPERGOAL_PHASE_DONE` per phase, with no `FAILURE_HANDOFF` or `AUDIT_HANDOFF`.

## Common pitfalls (field-tested)

- **Forgot to bump `version` after a content change** → marketplace cache stays stale. Symptom: `claude plugin update` says "already at latest". Fix: bump and re-push.
- **Mass find/replace missed `.gitignore`** → it has no extension so most find filters skip it. Always check it separately after global renames.
- **GitHub Contributors sidebar shows stale data after a history rewrite** → it's a stats-endpoint caching lag, clears on its own (minutes to hours). The actual `/contributors` API is what to trust.
- **`/plugin marketplace add owner/repo` shorthand defaults to SSH** → fails for users without GitHub SSH keys. README leads with the HTTPS URL form for this reason.
- **Codex install is a one-way copy** → users have to re-clone on update. Mention in any breaking-change CHANGELOG.
- **The skill description is the trigger** → tweak it carefully. Lead with `/supergoal` and natural-language phrases users actually type. Keep it pushy.

## When in doubt

Read `AGENTS.md`. It's the authoritative project doc. This file is a Claude-Code-flavored skim on top.
