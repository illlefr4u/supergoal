# Example — Greenfield SaaS

The kind of request Superplan was designed for.

## Original task

```
/superplan Build a polished Stripe-powered subscription dashboard with team invites and admin analytics. Next.js 15, Postgres, Clerk for auth. Include billing portal, member roles (owner/admin/member), invite-by-email flow, and an admin overview page with MRR / active subscriptions / churn.
```

## What Superplan does with it

1. **Intake** — classifies as `greenfield` + `ui`; assumes Next.js 15 + Postgres + Clerk because the user named them.
2. **Recon** — skipped (greenfield, no existing repo to scan).
3. **Draft** — writes `.superplan/PLAN.md` with sections for:
   - Auth (Clerk integration)
   - Billing (Stripe portal + webhook handlers)
   - Team model (orgs, members, roles)
   - Invite flow (email + token)
   - Admin overview (MRR / active / churn queries)
   - UI states for each view (empty / loading / error / permission-denied)
4. **Iterate** — the user opens `.superplan/plan.html`, suggests "use Resend for invite emails, not Postmark"; skill edits PLAN.md and re-renders.
5. **Lock** — compiles GOAL.txt; user pastes `/goal` or runs `superplan-go`.

## What "done" looks like (compiled)

```
/goal Complete the build in .superplan/PLAN.md. Do not stop until every criterion in .superplan/ACCEPTANCE.md is met AND every command in .superplan/VERIFY.md has been run with output pasted into the transcript AND every phase in .superplan/STATE.md is marked complete with evidence. Each turn must (a) update .superplan/STATE.md with completed work, files changed, verification run, results, next step, blockers, can-stop assessment; (b) print the STATE.md tail to the transcript. A phase flips to complete ONLY after a pasted command-output proof block. Final completion requires polish passes (UX/copy, edge cases, tests, security, maintainability, diff review) AND a self-review block stating "no blocking issues found" with rationale. If stuck (same failure twice, no progress in 3 turns, unresolvable blocker), write the blocker to .superplan/STATE.md and stop with an honest handoff. Stop on: success-with-evidence, explicit handoff, or turn cap = 120.
```

(120 turn cap because greenfield SaaS is multi-feature; ~80 is typical for smaller scopes.)

## What polish looks like

Because the plan includes UI states, the polish phase runs through:
- Stripe checkout flow (success + decline + 3DS)
- Invite link expiration handling
- Admin page empty state when zero subscriptions
- Mobile breakpoints for the dashboard cards
- Keyboard navigation through the member list

Each is screenshot-verified via browser-harness; screenshots embed into `POLISH.md`.

## What a failure mode looks like

If Stripe webhooks aren't reachable in dev, the agent can't verify the billing phase. `STATE.md` records `Blocked: Stripe webhook URL unreachable in dev`, and the runner exits with an honest handoff rather than claiming success.
