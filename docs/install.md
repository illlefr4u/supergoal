# Install

Three install paths, ranked from simplest to most shareable.

## 1. Personal skill (recommended for trying it out)

Clone once, symlink into your personal skills directory.

```bash
# Clone wherever you keep your tools
git clone https://github.com/robzilla1738/superplan.git ~/Code/superplan

# Claude Code
mkdir -p ~/.claude/skills
ln -s ~/Code/superplan/skills/superplan ~/.claude/skills/superplan

# Codex (experimental — see docs/codex-setup.md)
mkdir -p ~/.agents/skills
ln -s ~/Code/superplan/skills/superplan ~/.agents/skills/superplan
```

Now `/superplan <task>` works in any Claude Code or Codex session.

## 2. Project skill (per-repo, committed)

If you want a specific project's skill to live alongside the code (shared with collaborators):

```bash
cd ~/your-project
mkdir -p .claude/skills
git submodule add https://github.com/robzilla1738/superplan.git vendor/superplan
ln -s ../../vendor/superplan/skills/superplan .claude/skills/superplan
```

Or just `cp -R` the skill in if you don't want a submodule:

```bash
cp -R ~/Code/superplan/skills/superplan ~/your-project/.claude/skills/superplan
```

## 3. Plugin install (most shareable)

Both Claude Code and Codex support plugin manifests in this repo:

- `.claude-plugin/plugin.json`
- `.codex-plugin/plugin.json`

Plugin install commands vary by host version — see `claude-code-setup.md` and `codex-setup.md`.

## After install

Test that the skill loads:

```bash
# From any directory with a git repo
cd ~/some-project
echo "Hello" > /tmp/test.txt   # dummy command to confirm shell works
```

Then in a Claude Code session: `/superplan Build a Hello World CLI in Node`. You should see Stage 1 echo back the task.

If `/superplan` isn't recognised, the symlink didn't resolve. Verify:

```bash
ls -l ~/.claude/skills/superplan/SKILL.md
# Should print a symlink resolving to ~/Code/superplan/skills/superplan/SKILL.md
```

## Optional: `marked` for richer markdown rendering

The HTML renderer falls back to a minimal parser if `marked` isn't installed. For full GFM support:

```bash
cd ~/Code/superplan/skills/superplan
npm init -y >/dev/null
npm install marked >/dev/null
```

The renderer dynamic-imports `marked`; if it's not in `node_modules` of the skill dir or globally available, the fallback kicks in. No errors either way.

## Headless runner setup

`scripts/superplan-go` requires the Claude Code CLI on `PATH` (or set `CLAUDE_BIN`). Verify:

```bash
which claude
claude --version
```

If `claude` isn't installed, the runner errors with exit code 2 and a setup hint. The skill itself works fine without the runner — you can always paste the `/goal` manually.

## Uninstall

```bash
rm ~/.claude/skills/superplan
rm ~/.agents/skills/superplan
rm -rf ~/Code/superplan
```

Existing `.superplan/` directories inside your projects are untouched. Delete them if you want — they're plain markdown.

## Troubleshooting

**`/superplan` does nothing.** Skill discovery is host-specific. Try `/list-skills` (Claude Code) or check `~/.claude/skills/superplan/SKILL.md` is readable.

**HTML doesn't open in a browser.** Check `scripts/open-plan.sh` works standalone: `bash ~/.claude/skills/superplan/scripts/open-plan.sh ~/Code/superplan/README.md`. If your OS isn't macOS/Linux/WSL, you may need to add a case.

**`/goal` is too long.** The skill should self-trim, but if you hand-edited the artifacts and added a lot, the next render warns. Either trim the inline narrative in the goal template (in `SKILL.md` Stage 5) or compress the PLAN file references it links to.

**Stuck-watcher kills runs too fast.** Bump `SUPERPLAN_STUCK_MINUTES` (default 15). Long verification phases can legitimately take >15 minutes if the build is slow.

**Codex frontmatter rejected.** See `codex-setup.md` for current known deltas.
