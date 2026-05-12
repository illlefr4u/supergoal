#!/usr/bin/env bash
# summarize-repo.sh — emit a repo map (git state + tree + entry points)
# on stdout as markdown. Intended for redirect into .superplan/repo-map.md.

set -u

echo "# Repo map"
echo
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo

# --- Git ------------------------------------------------------------------

echo "## Git"
echo
if [ -d .git ]; then
  echo '```'
  echo "Branch:  $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '(detached)')"
  echo "HEAD:    $(git rev-parse --short HEAD 2>/dev/null || echo '(none yet)')"
  echo "Remote:  $(git config --get remote.origin.url 2>/dev/null || echo '(no origin)')"
  echo
  echo "Status (short):"
  git status --short 2>/dev/null | head -40 || echo '(error)'
  echo
  echo "Recent commits:"
  git log --oneline -10 2>/dev/null || echo '(no commits yet)'
  echo '```'
else
  echo "_Not a git repository._"
fi
echo

# --- Tree -----------------------------------------------------------------

echo "## Tree (depth 2)"
echo
echo '```'
if command -v tree >/dev/null 2>&1; then
  tree -L 2 -a \
    -I 'node_modules|target|dist|build|.next|.git|.venv|venv|__pycache__|.cache|.DS_Store|.pytest_cache|.mypy_cache|coverage' \
    2>/dev/null | head -120
else
  find . -maxdepth 2 \
    -not -path '*/node_modules*' \
    -not -path '*/.git*' \
    -not -path '*/target*' \
    -not -path '*/dist*' \
    -not -path '*/build*' \
    -not -path '*/.next*' \
    -not -path '*/.venv*' \
    -not -path '*/venv*' \
    -not -path '*/__pycache__*' \
    | sort | head -120
fi
echo '```'
echo

# --- Entry points ---------------------------------------------------------

echo "## Key entry points (heuristic)"
echo
for f in \
  README.md \
  CLAUDE.md \
  AGENTS.md \
  CONTRIBUTING.md \
  .cursorrules \
  package.json \
  pyproject.toml \
  Cargo.toml \
  go.mod \
  Package.swift \
  src/index.ts src/index.tsx src/index.js \
  src/main.rs src/main.py \
  cmd/main.go main.go \
  app/page.tsx app/layout.tsx \
  pages/index.tsx pages/_app.tsx \
  index.html \
  Dockerfile docker-compose.yml \
  ; do
  if [ -f "$f" ]; then
    echo "- \`$f\`"
  fi
done
echo

# --- Test config ----------------------------------------------------------

echo "## Test / lint config"
echo
HITS=0
for f in \
  vitest.config.ts vitest.config.js \
  jest.config.ts jest.config.js \
  playwright.config.ts \
  cypress.config.ts \
  pytest.ini setup.cfg pyproject.toml \
  .eslintrc .eslintrc.js .eslintrc.json eslint.config.js \
  .prettierrc \
  tsconfig.json \
  ; do
  if [ -f "$f" ]; then
    echo "- \`$f\`"
    HITS=1
  fi
done
[ $HITS -eq 0 ] && echo "_No common test/lint config files found._"
echo
