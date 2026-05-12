# Handoff — {{TASK_TITLE}}

> Written by the agent when it stops without success: stuck-loop trigger, missing permission, unavailable dependency, or unresolvable ambiguity. Honest handoff > false success.

## Stopped at

```
Turn: {{TURN_NUMBER}}
Phase reached: {{CURRENT_PHASE}}
Stop reason: {{STUCK|BLOCKED|TURN_CAP|MANUAL_INTERVENTION_NEEDED}}
Stopped at: {{ISO_TIMESTAMP}}
```

## What was completed

Bullet list of phases and verifications that did succeed (with evidence pointers — `.superplan/logs/turn-NNN.md`).

## What blocked progress

Concrete description. Examples (delete and replace):

- "Stripe webhook endpoint isn't reachable from dev — need ngrok or live URL configured."
- "Test command `pnpm test` requires `DATABASE_URL` env var; no test database exists."
- "Migration `0042_team_invites` failed: `column already exists` — likely partial prior run; needs manual cleanup."
- "Plan assumed Resend for email; account not provisioned. Need credentials or a fallback provider."

## What was tried

For each attempted fix, one line:
- Attempt 1: {{WHAT}} → {{RESULT}}
- Attempt 2: ...

## What the next runner needs

Concrete, executable steps for a human or follow-up `/superplan` run:

1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

## Locked-file integrity

```
PLAN.md       hash: {{HASH_PLAN}}        matches LOCK.json: {{MATCH_PLAN}}
ACCEPTANCE.md hash: {{HASH_ACCEPTANCE}}  matches LOCK.json: {{MATCH_ACCEPTANCE}}
VERIFY.md     hash: {{HASH_VERIFY}}      matches LOCK.json: {{MATCH_VERIFY}}
POLISH.md     hash: {{HASH_POLISH}}      matches LOCK.json: {{MATCH_POLISH}}
```

If any mismatch is `yes`, document why and whether the change was intentional and authorised.

## Pointers

- Full state: `.superplan/STATE.md`
- Per-turn logs: `.superplan/logs/`
- Plan + acceptance: `.superplan/PLAN.md`, `.superplan/ACCEPTANCE.md`
- Lock manifest: `.superplan/LOCK.json`
- Last run output: `.superplan/run.log`
