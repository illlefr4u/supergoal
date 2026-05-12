# Planning rubric

What a strong `.superplan/PLAN.md` contains, and how Stage 5 turns the plan into a contract the evaluator can hold the agent to.

## How planning maps to enforcement

| What the plan says | How execution enforces it |
|---|---|
| Phase list in PLAN.md | `required_phases` in LOCK.json, surfaced in SUPERPLAN_MANIFEST |
| Acceptance criteria | Hash-pinned in LOCK.json; can't be silently weakened |
| Mandatory commands | `mandatory_commands` in LOCK.json, surfaced in SUPERPLAN_MANIFEST |
| Conditional verification | `conditional_triggers` in LOCK.json, applied per turn |
| Polish passes | Listed in SUPERPLAN_MANIFEST; required before SELF_REVIEW |
| Definition of Done | Encoded in `stop_conditions` in LOCK.json |

So plan quality is contract quality. A vague phase becomes a vague contract.

## Quality bar

A good plan reads like a senior engineer briefing a junior who just walked in. Specific. Constrained. No filler.

A bad plan reads like an LLM padding sections to look thorough. Bullet lists with one bullet. "Various", "appropriate", "best practices", "robust", "scalable", "modern" with nothing behind the words.

## Section quality checks

### Product intent

- ✅ One paragraph. Concrete user. Concrete pain. Concrete outcome.
- ❌ "Build a robust solution that delights users with a modern experience."

### Assumptions

- ✅ "Assumed Next.js 15 because `package.json` shows `next@15.0.3`."
- ❌ "Assumed modern stack."

### Non-goals

- ✅ "Not adding email notifications (out of scope; tracked separately)."
- ❌ Empty section, or "TBD".

### Architecture

- ✅ Names the modules, the entry points, the new files.
- ✅ Identifies which existing patterns to mirror (with file:line).
- ❌ "Standard MVC architecture."

### Data model changes

- ✅ Concrete table/column/type names. Migration steps.
- ✅ "N/A" with a reason if there are none.
- ❌ "May require database changes."

### API / contracts

- ✅ HTTP method, path, request/response shape, error codes.
- ✅ For internal APIs: function signature.
- ❌ "Expose endpoints as needed."

### UI / UX states

- ✅ Empty / loading / success / error / permission / offline named per view.
- ✅ Error taxonomy with exact copy.
- ❌ "Handle states appropriately."

### Error handling

- ✅ Where errors go (toast, banner, inline, log-only).
- ✅ Retry policy with concrete numbers.
- ❌ "Graceful error handling."

### Security / privacy

- ✅ "Auth check via `requireUser()` at `app/api/foo/route.ts:1`."
- ❌ "Apply standard security practices."

### Test strategy

- ✅ Names files, what they cover, what the assertion is.
- ❌ "Add tests."

### Migration strategy

- ✅ Migration name, direction, rollback path, feature-flag gate.
- ✅ N/A with reason if none.
- ❌ "Migrate as needed."

### Observability

- ✅ "Add `logger.info('checkout.completed', {amount, currency})` at `lib/checkout.ts:42`."
- ❌ "Add logging."

### Phase-by-phase implementation

- ✅ Phase 1: files touched, acceptance signal ("`npm run build` exits 0 with no new warnings"), proves: type contract works.
- ❌ Phase 1: "Set up the basics."

### Definition of Done

- ✅ One sentence. Measurable. Matches ACCEPTANCE.md.
- ❌ "When it's working and polished."

## Phase metadata

Each phase in PLAN.md may carry one optional tag affecting evidence requirements:

- `runtime` (default — needs `command` or `test` evidence)
- `documentation-only` — `review` evidence sufficient
- `review-only` — `review` evidence sufficient

Example phase heading:

```
3. Update CONTRIBUTING.md (documentation-only)
```

Documentation-only and review-only should be rare. Default to runtime unless the change touches no executable code.

## Anti-patterns to reject

- Sections with one vague bullet — either fill it or write N/A with reason.
- "TODO" placeholders left in the final draft.
- Restating what the codebase already does instead of what will change.
- Treating "polish" as a phase you'll figure out later — POLISH.md must be specific.
- Phase descriptions that don't name files or modules. The phase needs to be concrete enough that LOCK.json can list it as required.
