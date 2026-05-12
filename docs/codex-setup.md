# Codex setup (experimental)

> **Status: best-effort.** The Agent Skill format is broadly portable, but specific deltas (frontmatter keys, `$ARGUMENTS` substitution, `/goal` availability) aren't independently verified across Codex versions. Please file an issue if you hit one.

## Enable `/goal` in Codex

Codex treats `/goal` as experimental. Before invoking, enable it one of two ways:

**Option A — via slash command:**
```
/experimental
# toggle features.goals = true
```

**Option B — via config file:**

Edit `~/.codex/config.toml` (path may vary by Codex version):

```toml
[features]
goals = true
```

If `/goal <condition>` returns "command not found" or similar, you have not enabled the feature.

## Skill location

```bash
mkdir -p ~/.agents/skills
ln -s ~/Code/superplan/skills/superplan ~/.agents/skills/superplan
```

For project-level install, use `<project>/.agents/skills/superplan` instead.

## Headless runner

`superplan-go` shells out to `claude -p "/goal ..."`. For Codex:

```bash
CLAUDE_BIN=codex ./skills/superplan/scripts/superplan-go
```

If Codex's headless flag differs from `-p`, the runner won't work as-is. Fallback: paste the `/goal` into an interactive Codex session manually.

The Node-based `stuck-watcher.mjs` is host-independent and works regardless of which CLI you're driving.

## Known unknowns

| Concern | Status |
|---|---|
| `$ARGUMENTS` substitution syntax | unverified — Claude Code uses `$ARGUMENTS`; Codex may differ |
| Frontmatter field names (`name`, `description`, `argument-hint`) | unverified — may need an adapter |
| Skill discovery precedence (project vs personal vs plugin) | undocumented |
| `claude -p` equivalent in Codex | check `codex --help` for the headless flag |
| Long-running command behaviour in Codex | the watcher's allowlist should handle it, untested |

## When you find a delta

Open an issue with:
- Codex version (`codex --version`)
- The Superplan stage that broke
- The exact error message or unexpected behaviour
- Workaround (if any)

A small adapter shim should fix most cases — the structural design is identical.

## What works the same

- The 5-stage choreography in SKILL.md
- HTML rendering via `render-plan.mjs`
- LOCK.json hash pinning
- The compiled `/goal` text (once `features.goals` is enabled)
- `superplan-go` runner (with `CLAUDE_BIN=codex` and verified `-p` equivalent)
- All planning artifacts in `.superplan/`
