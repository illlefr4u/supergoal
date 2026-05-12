#!/usr/bin/env bash
# open-plan.sh — cross-platform browser open
# Usage: open-plan.sh [path-to-html]
# Default: $SUPERPLAN_ROOT/plan.html (where SUPERPLAN_ROOT defaults to .superplan)
set -eu

TARGET="${1:-${SUPERPLAN_ROOT:-.superplan}/plan.html}"

if [ ! -f "$TARGET" ]; then
  echo "open-plan: $TARGET not found." >&2
  echo "open-plan: run render-plan.mjs first, then retry." >&2
  exit 1
fi

ABS="$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")"
URL="file://$ABS"

if [ "$(uname -s)" = "Darwin" ]; then
  open "$URL"
elif [ -n "${WSL_DISTRO_NAME:-}" ]; then
  cmd.exe /c start "" "$URL" >/dev/null 2>&1 || true
elif command -v xdg-open >/dev/null 2>&1; then
  xdg-open "$URL" >/dev/null 2>&1 &
elif command -v wslview >/dev/null 2>&1; then
  wslview "$URL"
else
  echo "open-plan: could not detect a browser opener."
  echo "open-plan: open this URL manually: $URL"
fi
