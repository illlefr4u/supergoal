#!/usr/bin/env bash
# detect-research-tools.sh — research-mode recon (analog of detect-stack.sh).
# Emits a research-context scaffold: a tool-inventory checklist the AGENT fills
# from its actual tool list (a shell cannot see the agent's MCP tools), a source
# taxonomy to rank every source against, and the local fetch/compute
# capabilities a shell CAN verify. Writes markdown to stdout.

set -uo pipefail

echo "# Research context"
echo
echo "_Generated $(date '+%Y-%m-%d %H:%M:%S')_"
echo

# --- Tool inventory (the AGENT fills this from THIS session's tool list) ---
echo "## Tool inventory — fill from this session's tool list"
echo
echo "A shell cannot introspect the agent's MCP tools. Mark which are actually"
echo "available this session; a phase may only rely on a tool marked present."
echo
echo "- [ ] **WebSearch** — broad web lookup"
echo "- [ ] **WebFetch** — fetch + read a specific URL (primary-source retrieval)"
echo "- [ ] **Browser** (Chrome MCP / agent-browser / Playwright) — JS-rendered, auth-gated, or canvas-rendered pages"
echo "- [ ] **Domain MCPs** — list any present (blockscout, defillama, github, gmail, drive, 1inch, …)"
echo "- [ ] **deep-research skill** — fan-out → fetch → adversarial-verify → cited report (delegate per-phase discovery to it instead of reimplementing)"
echo "- [ ] **Bash / code execution** — parse downloaded data, call APIs, compute from raw records"
echo
echo "Rule: if the strongest primary source needs a tool you do NOT have this"
echo "session, record that in the locked source plan as \`unavailable-tool\` —"
echo "do not silently downgrade to a weaker tier and call it covered."
echo

# --- Source taxonomy (rank every source against this) ---
echo "## Source taxonomy — tier every source before trusting it"
echo
echo "| Tier | What | Examples |"
echo "|---|---|---|"
echo "| 1 Primary / official | The entity that owns the fact | issuer filing, FIFA match centre, on-chain contract read, govt registry, a protocol's own API |"
echo "| 2 Data providers | First-party measurement / market data | exchange API, Opta/StatsBomb, Chainlink, CoinGecko |"
echo "| 3 Aggregators | Reprint or blend tier-1/2 | FotMob, DexScreener, DefiLlama, news wires |"
echo "| 4 Broadcast / press | Reported, edited | reputable outlet quoting a source |"
echo "| 5 Social | Unvetted, fast | X / Telegram / forum posts |"
echo "| 6 Derived | Computed from the above | your own calc from raw records (cite the inputs) |"
echo
echo "Higher tier wins conflicts. 'Independent' means NOT downstream of the same"
echo "tier-1/2 feed — five sites reprinting one Opta number count as ONE source."
echo

# --- Local fetch/compute capabilities a shell CAN verify ---
echo "## Local fetch / compute capabilities"
for tool in curl wget jq python3 node; do
  if command -v "$tool" >/dev/null 2>&1; then
    echo "- ✅ \`$tool\` available"
  else
    echo "- ❌ \`$tool\` missing"
  fi
done
if command -v curl >/dev/null 2>&1; then
  if curl -fsS -m 5 -o /dev/null https://example.com 2>/dev/null; then
    echo "- ✅ outbound HTTPS reachable"
  else
    echo "- ⚠️ outbound HTTPS check failed (offline or egress blocked — note it in the plan)"
  fi
fi
echo

echo "_End research context._"
