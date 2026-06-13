# Source Discovery — sweep, rank, LOCK

Source Discovery is the research analog of recon. Its deliverable is **not** an
answer — it is a **locked, ranked source plan**: the specific sources to query,
each tagged with its taxonomy tier, in priority order. Everything downstream
(Extraction, Cross-Verification, and the negative-result gate) depends on this
lock.

## 1. Multi-modal sweep (bounded)

Find candidate sources four ways — each blind to the others, so one angle's gap
is covered by another:

- **By entity** — who owns the fact? (the issuer, the league, the protocol, the registry)
- **By container** — where does this *class* of fact live? (filings DB, match centre, block explorer, stats-provider API)
- **By content** — search the claim itself (keywords, the exact number, the player/ticker name)
- **By time** — is there a date-specific edition? (the match page, the quarter's report, a block range)

Do **not** treat a search summary as the source. A summary that says "no data"
means *fetch the primary source directly and look* — search engines routinely
miss what JS-rendered or auth-gated primary pages actually publish. (Live
example: aggregators returned "no distance data" for USA–Paraguay WC 2026, while
the FIFA match-centre STATS tab published it.)

## 2. Bound the sweep (so it cannot thrash)

Discovery ends when **either**:

- the **minimum-tier checklist** is covered — at least the strongest tier-1
  primary source for the question is located (even if not yet fetched), plus one
  independent tier-1/2 corroborator where one plausibly exists; **or**
- the **stop budget** is hit — a cap on source-families swept (default ~6) or a
  wall-time bound. Log what was dropped; never imply the sweep was exhaustive.

The bound stops discovery itself from looping forever — *before* the
negative-result gate ever runs. Hitting the budget without covering the
checklist is itself a finding: surface it.

## 3. LOCK the plan

Write the ranked plan to `$SUPERGOAL_ROOT/source-plan.md` and treat it as frozen
for the run (only a `RESCOPE` reopens it). Format:

```
# Locked source plan — <question>
Locked: <date>  ·  Sweep budget: <n families / time>  ·  Checklist: <covered | partial: …>

| # | Source | Tier | Access method | Expected datum | Status |
|---|--------|------|---------------|----------------|--------|
| 1 | FIFA match centre — STATS tab | 1 primary  | browser/WebFetch | per-player distance | to-fetch |
| 2 | Opta / StatsBomb feed         | 2 provider | (no tool this session) | distance | unavailable-tool |
| 3 | FotMob match page             | 3 aggregator | WebFetch | distance (corroborate) | to-fetch |
...
Strongest primary for this question: #1. Fallback tiers below the line: #3+.
```

Rules:

- **Strongest primary / domain sources rank above any fallback tier.** This is
  what stops lazy "checked three weak sources → declared unavailable" gaming.
- If a source needs a tool you don't have this session, mark it
  `unavailable-tool` — a real, citable reason, not a pass.
- The lock is the contract the **negative-result gate** enforces: "unavailable"
  is valid only after the *locked* sources fail with per-source evidence, and
  only after the adversarial-audit phase re-attempts the strongest one.

## Why the lock matters

Without a locked plan, "I couldn't find it" is unfalsifiable — the run could
have surrendered after three weak sources, or thrashed forever. The lock turns
both failure modes into a checkable contract: discovery is bounded, the
strongest sources are named up front, and a negative result must show the named
sources actually failed.
