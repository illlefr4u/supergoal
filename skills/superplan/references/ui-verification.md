# UI verification

For tasks tagged `ui` (or any task that touches UI files), planning must add visual verification on top of the standard text checks.

## When to apply

Apply if `PLAN.md` modifies any of:
- `*.tsx`, `*.jsx`, `*.vue`, `*.svelte`, `*.astro`
- `*.css`, `*.scss`, `*.sass`, `tailwind.config.*`
- `pages/`, `app/` (Next.js / Remix routes)
- `components/`, `views/`, `templates/`
- Storybook stories
- SwiftUI views, `.swift` files containing `View` body

If the change is purely backend or build-config, skip this section.

## Required additions to VERIFY.md

Add a "Visual verification" section with:

```bash
# 1. Start dev server in the background
{DEV_CMD} &

# 2. Wait for it to be ready
until curl -sf http://localhost:{PORT}/ > /dev/null; do sleep 1; done

# 3. Drive browser-harness through every changed route × state
browser-harness <<'PY'
new_tab("http://localhost:{PORT}/{ROUTE}")
wait_for_load()
screenshot("/tmp/superplan-{ROUTE_SLUG}-success.png")
# repeat for each required state: empty, error, loading, permission-denied
PY
```

For each changed route, list the screenshots required:
- `{ROUTE}` success state
- `{ROUTE}` empty state (if applicable)
- `{ROUTE}` error state
- `{ROUTE}` mobile viewport
- `{ROUTE}` dark mode (if app supports themes)

## Required additions to POLISH.md

Append a "Visual polish" pass:

```
- [ ] Screenshots embedded or linked from this file for each route × state
- [ ] Spacing, alignment, typographic hierarchy reviewed (compare to existing pages)
- [ ] Hover / focus / active / disabled states present where applicable
- [ ] Responsive breakpoints verified (≤640px, 641–1024px, ≥1025px)
- [ ] Keyboard navigation works; focus indicator visible
- [ ] Color contrast meets WCAG AA (4.5:1 for body, 3:1 for large text)
- [ ] No layout shift on data load (CLS check)
```

## Required additions to ACCEPTANCE.md

Add a "Visual acceptance" block:

```
- [ ] Screenshots captured for every changed view × state, paths listed in POLISH.md
- [ ] No visible regressions in adjacent views (spot-check ≥2 nearby routes)
- [ ] Accessibility checks recorded (focus order, contrast, alt text)
```

## If browser-harness isn't installed

Fall back to a manual review prompt in POLISH.md:

```
- [ ] Open each changed route in the browser and visually review the states listed in PLAN.md
- [ ] Save screenshots manually to .superplan/screenshots/
- [ ] Note any issues in STATE.md
```

The skill should not silently drop the visual check just because browser-harness isn't available. Falling back to manual is a feature, not a bug.

## browser-harness integration tips

- First call is `new_tab(url)`, not `goto(url)` — see `~/Code/browser-harness/SKILL.md`.
- `wait_for_load()` before any screenshot.
- Save screenshots into `/tmp/superplan-*.png` (or `.superplan/screenshots/` if you want them committed).
- For state simulation (e.g. error state), often easiest to hit a route with a query param or seed the store.
- Use `screenshot("/path.png")` — coords aren't needed unless you're clicking through a flow.

## What NOT to do

- Don't run browser-harness during planning. It belongs to execution.
- Don't generate hundreds of screenshots; pick the ones that actually differ across states.
- Don't include pixel coordinates in plan files — they break on different viewports.
