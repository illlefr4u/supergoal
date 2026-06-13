# Research Depth — the bar to clear

A research plan deserves the "Super" prefix when, reading it cold, a competent
analyst could:

1. **Name every source that will be queried** — at the right granularity, each
   tagged with its taxonomy tier and access method (not "search the web" but
   "FIFA match-centre STATS tab via browser; Opta feed if that MCP is present").
2. **Name the top 3 research risks** and the mitigation for each.
3. **Verify each phase independently** — Extraction's output is checkable against
   its citations without reading Synthesis.
4. **State what "done" looks like** in falsifiable terms — including what "data
   unavailable" would have to show to count as a valid PASS.

If any of those four are weak, sweep and think more before locking the plan.

## The top-3 research risks (almost always these)

1. **The data may not exist publicly.** Predefine the **negative-result gate**
   (see `PROTOCOL-research.md`): a locked source plan + per-source failed-fetch
   evidence + an audit re-attempt. "Unavailable" is a valid terminal PASS only
   through that gate — never a hand-wave, never a premature surrender.
2. **Source reliability / conflict.** Two sources will disagree. Decide the
   adjudication rule up front: higher tier wins; state confidence; if unresolved,
   emit "conflicting, unresolved: X vs Y" — never silently pick one.
3. **Fabrication temptation.** A coherent narrative wants a number to fill the
   gap. Every number carries a citation (URL + quote + access date) or it is
   marked unverified. `~` / "about" / "roughly" must not mask missing
   verification.

## Falsifiable research criteria — examples

- ❌ "Find how far the players ran." (not falsifiable)
- ✅ "USA first-half per-player running distance sourced from ≥1 FIFA primary
  source (match centre / Training Centre), OR explicitly marked unavailable after
  the locked source plan fails with per-source evidence."
- ✅ "Each reported number confirmed by ≥2 independent primary/provider sources,
  or flagged single-source."
- ✅ "Every datum carries a publication + access date; anything past <freshness
  threshold> for this question is flagged stale."

## Provenance & recency (bake into every criterion)

- **Independence:** sources not downstream of the same feed. Five sites
  reprinting one Opta number = one source. Mark raw vs derived/transformed.
- **Recency:** a number true last season / last quarter / last block is not
  necessarily true now. Date everything; fail or flag stale data.

## What this is NOT

- Not a literature review. THINKING.md still fits on ~2 pages.
- Not where you write the answer. Plan + lock sources only.
- Not "trust the first confident search summary." Hit the primary source.
