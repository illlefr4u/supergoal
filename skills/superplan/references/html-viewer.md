# HTML viewer reference

`.superplan/plan.html` is a single self-contained file: one `<html>` element, embedded CSS, no external JS or fonts. It must open via `file://` with no network dependency.

## What it shows

Six sections from the plan files:

1. **Plan** — full `PLAN.md`
2. **Acceptance** — `ACCEPTANCE.md` with checklist styling
3. **Verify** — `VERIFY.md` (commands in code blocks)
4. **Risks** — `RISKS.md` (rendered as a table)
5. **Polish** — `POLISH.md` (six-pass checklist)
6. **State** — `STATE.md` (initial ledger; live during execution)

Plus a final block:

7. **/goal** — the compiled goal text with a copy button and char-count indicator

## Header metadata

Above the sections, a 4-cell metadata strip:
- Stack (from PLAN.md or context.md)
- Type (greenfield / brownfield / bugfix / refactor / ui)
- Phases (count of `^\d+\. ` lines in PLAN.md)
- Max turns

If any value isn't extractable, the renderer fills `—` rather than erroring.

## Refresh model

The user opens the HTML once in their browser. The skill regenerates it on every `node render-plan.mjs` call (Stage 4 iteration). The user refreshes the tab manually.

This is cheap and reliable. No live-reload server required.

## Design constraints

- Dark mode by default (matches Claude Code default and saves eye strain on long iterations).
- Inline SVG / CSS only — no `<img>` tags pointing to external URLs.
- Print-friendly is **not** a requirement. Optimise for screen.
- Width capped at 920px for readability.
- Monospace fallback chain: `ui-monospace, "JetBrains Mono", Menlo, Consolas, monospace`.

## Failure modes

- **Template missing.** Renderer aborts with exit 2 and a "template not found" error pointing at `templates/plan.html.template`. Indicates broken install.
- **A `.superplan/*.md` file is missing.** Renderer fills its section with `_FILE.md is empty._` placeholder. Not fatal.
- **Markdown parser missing.** Renderer falls back to its internal minimal parser. Output may have rougher edges (less GFM table support) but is readable.
- **Goal over budget.** Renderer still writes the HTML but emits a `WARNING` line on stderr. The HTML's char-count badge turns red beyond 3800.

## Extension points (future)

- Phase progress bar from STATE.md.
- Live update via a tiny WebSocket loop (V2 only; keep V1 static).
- Embedded screenshot gallery from `.superplan/screenshots/` for UI tasks.
- Side-by-side diff between two plan revisions (`plan-old.html` vs `plan.html`).

None of these are MVP. The point of V1 is to prove the loop, not the chrome.
