# Risks — {{TASK_TITLE}}

> Each risk: severity (LOW / MED / HIGH), mitigation, fallback if mitigation fails.

## Implementation risks

| # | Risk | Severity | Mitigation | Fallback |
|---|------|----------|------------|----------|
| 1 | {{RISK_1}} | {{SEV_1}} | {{MIT_1}} | {{FALL_1}} |

## Integration risks

External APIs, third-party libraries, services that can fail or change. **N/A** if none.

## Data risks

Migrations, irreversible writes, schema lock-in. **N/A** if none.

## Security risks

Auth changes, secret exposure, injection surfaces, privilege escalation. **N/A** if none.

## Time / scope risks

Where this build could balloon. Where to cut if running long.

## Rollback plan

If this ships and breaks, what's the exact revert path? Single commit, feature flag, or migration-down?
