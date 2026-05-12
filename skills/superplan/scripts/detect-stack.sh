#!/usr/bin/env bash
# detect-stack.sh — scan current working directory for stack markers,
# emit a markdown summary on stdout. Intended to be redirected into
# .superplan/context.md by the superplan skill.
#
# Compatible with bash 3.2+ (no associative arrays).

set -u

echo "# Context"
echo
echo "Generated at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Working dir: $(pwd)"
echo

# --- Stack markers ---------------------------------------------------------

check_marker() {
  local marker="$1"
  local label="$2"
  if compgen -G "$marker" > /dev/null 2>&1; then
    echo "- \`$marker\` — $label"
    return 0
  fi
  return 1
}

echo "## Stack markers"
echo

FOUND=0
check_marker "package.json"       "Node.js / JavaScript / TypeScript" && FOUND=1
check_marker "pnpm-lock.yaml"     "Node.js (pnpm)"                    && FOUND=1
check_marker "yarn.lock"          "Node.js (yarn)"                    && FOUND=1
check_marker "bun.lockb"          "Bun"                               && FOUND=1
check_marker "Cargo.toml"         "Rust"                              && FOUND=1
check_marker "pyproject.toml"     "Python (pyproject)"                && FOUND=1
check_marker "requirements.txt"   "Python (requirements.txt)"         && FOUND=1
check_marker "Pipfile"            "Python (pipenv)"                   && FOUND=1
check_marker "go.mod"             "Go"                                && FOUND=1
check_marker "Gemfile"            "Ruby"                              && FOUND=1
check_marker "composer.json"      "PHP (composer)"                    && FOUND=1
check_marker "pom.xml"            "Java (Maven)"                      && FOUND=1
check_marker "build.gradle"       "Java/Kotlin (Gradle)"              && FOUND=1
check_marker "build.gradle.kts"   "Kotlin (Gradle)"                   && FOUND=1
check_marker "Package.swift"      "Swift (SPM)"                       && FOUND=1
check_marker "*.xcodeproj"        "Xcode project"                     && FOUND=1
check_marker "mix.exs"            "Elixir (mix)"                      && FOUND=1
check_marker "deno.json"          "Deno"                              && FOUND=1
check_marker "deno.jsonc"         "Deno"                              && FOUND=1
check_marker "flake.nix"          "Nix flake"                         && FOUND=1
check_marker "Dockerfile"         "Containerised (Dockerfile present)" && FOUND=1

[ $FOUND -eq 0 ] && echo "_No common stack markers found in the working directory._"
echo

# --- Node project hints ----------------------------------------------------

if [ -f package.json ]; then
  echo "## Node project hints"
  echo
  if command -v jq >/dev/null 2>&1; then
    NAME=$(jq -r '.name // "(unnamed)"' package.json)
    echo "- Package: \`$NAME\`"
    echo "- Scripts:"
    jq -r '.scripts // {} | to_entries[] | "  - `\(.key)` → `\(.value)`"' package.json
    echo "- Notable deps:"
    jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' package.json \
      | grep -iE 'next|react|vue|svelte|astro|nuxt|remix|express|fastify|nest|vite|webpack|jest|vitest|playwright|cypress|prisma|drizzle|trpc|tailwind|zod' \
      | head -20 | sed 's/^/  - `/' | sed 's/$/`/'
  else
    echo "_jq not installed; install for richer package.json parsing._"
    grep -E '"name"|"scripts"' package.json | head -5 | sed 's/^/    /'
  fi
  echo
fi

# --- Suggested verification commands --------------------------------------

echo "## Suggested verification commands"
echo
if [ -f package.json ]; then
  if   [ -f pnpm-lock.yaml ]; then PM=pnpm
  elif [ -f yarn.lock      ]; then PM=yarn
  elif [ -f bun.lockb      ]; then PM=bun
  else PM=npm
  fi
  echo "- Package manager: \`$PM\`"
  echo "- Build:     \`$PM run build\`"
  echo "- Typecheck: \`$PM run typecheck\` (or \`tsc --noEmit\`)"
  echo "- Lint:      \`$PM run lint\`"
  echo "- Test:      \`$PM test\`"
  echo "- Dev:       \`$PM run dev\`"
elif [ -f Cargo.toml ]; then
  echo "- Build: \`cargo build\`"
  echo "- Test:  \`cargo test\`"
  echo "- Lint:  \`cargo clippy --all-targets --all-features -- -D warnings\`"
  echo "- Fmt:   \`cargo fmt --check\`"
elif [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  echo "- Test:      \`pytest\` (if installed)"
  echo "- Lint:      \`ruff check\` (or \`flake8\`)"
  echo "- Typecheck: \`mypy .\` (or \`pyright\`)"
elif [ -f go.mod ]; then
  echo "- Build: \`go build ./...\`"
  echo "- Test:  \`go test ./...\`"
  echo "- Lint:  \`golangci-lint run\` (or \`go vet ./...\`)"
elif [ -f Package.swift ]; then
  echo "- Build: \`swift build\`"
  echo "- Test:  \`swift test\`"
else
  echo "_Unknown stack — fill verification commands manually in VERIFY.md._"
fi
echo

# --- Risky surfaces (heuristic) -------------------------------------------

echo "## Risky surfaces (heuristic)"
echo

HITS=0

if [ -d auth ] || [ -d src/auth ] || [ -d lib/auth ]; then
  echo "- Auth code present (directory \`auth/\`, \`src/auth/\`, or \`lib/auth/\`)"
  HITS=$((HITS+1))
fi

# grep -q exits non-zero on no match. Use plain conditional.
if grep -rqEli -m1 'stripe|payment|subscription' \
     --include='*.ts' --include='*.tsx' \
     --include='*.js' --include='*.jsx' \
     --include='*.py' --include='*.go'  --include='*.rs' \
     . 2>/dev/null; then
  echo "- Payment / billing code present"
  HITS=$((HITS+1))
fi

if [ -d migrations ] || [ -d db/migrations ] || [ -d prisma/migrations ] || [ -d supabase/migrations ]; then
  echo "- Database migrations directory present"
  HITS=$((HITS+1))
fi

if [ -f .env ] || [ -f .env.local ] || [ -f .env.production ]; then
  echo "- Local env file present (do not commit secrets)"
  HITS=$((HITS+1))
fi

if [ -f Dockerfile ] || [ -f docker-compose.yml ] || [ -f vercel.json ] || [ -f netlify.toml ] || [ -d .github/workflows ]; then
  echo "- Deploy / CI config present"
  HITS=$((HITS+1))
fi

[ $HITS -eq 0 ] && echo "_None obvious._"
echo
