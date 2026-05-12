# Claude Code setup

Notes specific to Claude Code.

## Skill location

Claude Code looks for skills in this order:

1. `<project>/.claude/skills/<name>/SKILL.md`
2. `~/.claude/skills/<name>/SKILL.md`
3. Installed plugin skills (namespaced as `/plugin:skill`)

Pick one location and symlink in:

```bash
ln -s ~/Code/superplan/skills/superplan ~/.claude/skills/superplan
```

After install, restart Claude Code or use `/reload-plugins` to pick up the new skill.

## Invoking

```
/superplan Build a polished Stripe-powered subscription dashboard with team invites and admin analytics
```

`$ARGUMENTS` carries the request through to the skill.

## /goal in Claude Code

Once `.superplan/GOAL.txt` is compiled, run:

```
/goal <contents of .superplan/GOAL.txt without the leading "/goal ">
```

Claude Code stays in goal mode until the agent surfaces evidence the condition is met, you cancel, or the internal cap kicks in.

## Non-interactive (headless) mode

```bash
./skills/superplan/scripts/superplan-go
```

Internally runs `claude -p "/goal …"`. The runner:
- Tees output to `.superplan/run.log`.
- Spawns `stuck-watcher.sh` as a sidecar.
- Exits non-zero on failure, timeout, or stuck.

Tunables (env vars):
- `CLAUDE_BIN` — path to claude CLI (default `claude`).
- `SUPERPLAN_MAX_RUNTIME` — seconds; default 7200 (2h).
- `SUPERPLAN_STUCK_MINUTES` — default 15.

## Known Claude Code quirks

- `$ARGUMENTS` is substituted at skill-load time. Don't echo it back without escaping if it might contain shell metacharacters.
- The skill cannot programmatically run `/goal`. It only prepares the goal text. You (or the runner) submit it.
- Sub-agents inherit skills but may not all have `/goal` permissions configured — keep the goal-execution path in the main session unless you've verified.

## Verifying the install

In a Claude Code session:

```
/superplan
```

(no arguments) — should respond with "What do you want me to plan?"

If you get "Skill not found" or no response, the symlink isn't resolving. Check:

```bash
readlink ~/.claude/skills/superplan
ls -l ~/.claude/skills/superplan/SKILL.md
```
