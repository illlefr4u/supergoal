#!/usr/bin/env bash
# sg-run-kernel.test.sh - fixture tests for the Supergoal v1 run kernel.

set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SG="$REPO_ROOT/skills/supergoal/scripts/sg.py"

if [ ! -f "$SG" ]; then
  echo "FATAL: sg.py not found at $SG" >&2
  exit 1
fi

# The kernel is deliberately bash-free: it does its own git reads in Python and
# never copies or invokes repo-state.sh. These fixtures therefore never place a
# repo-state.sh in the run root, so the whole suite exercises the pure-Python
# git path and would fail if a bash dependency crept back in.

pass=0
fail=0
ok() { pass=$((pass + 1)); printf '  [PASS] %s\n' "$1"; }
no() { fail=$((fail + 1)); printf '  [FAIL] %s\n      %s\n' "$1" "$2"; }

run() {
  OUT="$("$@" 2>&1)"
  RC=$?
}

assert_rc() {
  if [ "$2" = "$RC" ]; then ok "$1"; else no "$1" "expected exit $2 got $RC; output: $OUT"; fi
}
assert_contains() {
  case "$3" in *"$2"*) ok "$1";; *) no "$1" "missing substring [$2] in [$3]";; esac
}
assert_file() {
  if [ -f "$2" ]; then ok "$1"; else no "$1" "missing file $2"; fi
}

setup_fixture() {
  WORKDIR="$(mktemp -d)"
  cd "$WORKDIR" || exit 1
  git init -q
  git config user.email test@example.com
  git config user.name "Supergoal Test"
  mkdir -p src
  printf '.supergoal/\n' > .gitignore
  printf 'baseline\n' > src/existing.txt
  git add .gitignore src/existing.txt
  git commit -qm baseline
  BASE="$(git rev-parse HEAD)"

  RUN_ROOT="$WORKDIR/.supergoal/test-run"
  mkdir -p "$RUN_ROOT/phases" "$RUN_ROOT/evidence/phase-1/commands" "$RUN_ROOT/evidence/phase-1/diffs" "$RUN_ROOT/evidence/phase-2/commands"
  cp "$SG" "$RUN_ROOT/sg.py"

  cat > "$RUN_ROOT/ROADMAP.md" <<'EOF'
# Roadmap: Test Run

## Phase 1 - Build Feature

**Deliverables:**
- src/new.txt

## Phase 2 - Polish & Harden
EOF
  cat > "$RUN_ROOT/STATE.md" <<EOF
# State: Test Run

**Status:** PLANNING
**Current phase:** 1
**Run root:** $RUN_ROOT
**Baseline ref:** $BASE
EOF
  cat > "$RUN_ROOT/phases/phase-1.md" <<EOF
SUPERGOAL_PHASE_START
Phase: 1 of 2 - Build Feature
Task: add file
Mandatory command ids: test
Acceptance criteria: 2
Evidence required: commands/test.log,diffs/summary.txt
Depends on phases: none

## Acceptance criteria
- [mechanical] src/new.txt exists
- [trust-prior] manual review recorded
EOF
  cat > "$RUN_ROOT/phases/phase-2.md" <<EOF
SUPERGOAL_PHASE_START
Phase: 2 of 2 - Polish & Harden
Task: final checks
Mandatory command ids: none
Acceptance criteria: 1
Evidence required: none
Depends on phases: 1

## Acceptance criteria
- [mechanical] final audit passes
EOF
  printf 'new\n' > src/new.txt
  printf 'command: npm test\nlast line: ok\nexit 0\n' > "$RUN_ROOT/evidence/phase-1/commands/test.log"
  printf 'src/new.txt changed\n' > "$RUN_ROOT/evidence/phase-1/diffs/summary.txt"

  RUN_ROOT="$RUN_ROOT" BASE="$BASE" python - <<'PY'
import json
import os
from pathlib import Path

run_root = Path(os.environ["RUN_ROOT"])
base = os.environ["BASE"]
manifest = {
    "schema_version": "1.0",
    "run": {
        "id": "test-run",
        "title": "Test Run",
        "task": "Exercise the run kernel",
        "status": "PLANNING",
        "current_phase": 1,
        "run_root": str(run_root),
        "baseline_ref": base,
        "host": "test",
        "legacy": False,
        "created_at": "2026-06-07T00:00:00+00:00",
        "last_update": "2026-06-07T00:00:00+00:00"
    },
    "commands": [
        {"id": "test", "class": "test", "command": "npm test", "required": True}
    ],
    "phases": [
        {
            "id": 1,
            "name": "Build Feature",
            "status": "pending",
            "allowed_paths": ["src/"],
            "depends_on": [],
            "criteria": [
                {"id": "p1-c1", "text": "src/new.txt exists", "verification": "mechanical", "evidence": ["diffs/summary.txt"]},
                {"id": "p1-c2", "text": "manual review recorded", "verification": "trust-prior", "evidence": ["diffs/summary.txt"]}
            ],
            "commands": ["test"],
            "deliverables": ["src/new.txt"],
            "required_evidence": ["commands/test.log", "diffs/summary.txt"]
        },
        {
            "id": 2,
            "name": "Polish & Harden",
            "status": "pending",
            "allowed_paths": ["*"],
            "depends_on": [1],
            "criteria": [
                {"id": "p2-c1", "text": "final audit passes", "verification": "mechanical", "evidence": []}
            ],
            "commands": [],
            "deliverables": [],
            "required_evidence": []
        }
    ]
}
(run_root / "run.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY
}

cleanup_fixture() {
  cd "$REPO_ROOT" || exit 1
  rm -rf "$WORKDIR"
}

set_phase_statuses_complete() {
  RUN_ROOT="$RUN_ROOT" python - <<'PY'
import json
import os
from pathlib import Path

path = Path(os.environ["RUN_ROOT"]) / "run.json"
data = json.loads(path.read_text(encoding="utf-8"))
data["run"]["status"] = "AUDIT_PENDING"
for phase in data["phases"]:
    phase["status"] = "complete"
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

echo "sg-run-kernel.test.sh - fixtures for $SG"
echo

echo "[1] valid run.json passes validation"
setup_fixture
run python "$SG" validate-run "$RUN_ROOT"
assert_rc "validate-run exits 0" 0
assert_contains "validation prints kernel-ready marker" "SUPERGOAL_RUN_KERNEL_READY" "$OUT"
cleanup_fixture

echo
echo "[2] missing phase evidence fails gate"
setup_fixture
rm -f "$RUN_ROOT/evidence/phase-1/diffs/summary.txt"
run python "$SG" gate-phase "$RUN_ROOT" 1
assert_rc "gate fails with missing evidence" 1
assert_contains "gate reports missing evidence" "missing evidence" "$OUT"
cleanup_fixture

echo
echo "[3] failed mandatory command fails gate"
setup_fixture
printf 'command: npm test\nexit 1\n' > "$RUN_ROOT/evidence/phase-1/commands/test.log"
run python "$SG" gate-phase "$RUN_ROOT" 1
assert_rc "gate fails with failed command" 1
assert_contains "gate reports mandatory command" "mandatory command failed/missing" "$OUT"
cleanup_fixture

echo
echo "[4] out-of-scope changed file triggers SCOPE_DRIFT"
setup_fixture
printf 'outside\n' > README.md
run python "$SG" gate-phase "$RUN_ROOT" 1
assert_rc "gate fails with scope drift" 1
assert_contains "gate prints SCOPE_DRIFT" "SCOPE_DRIFT" "$OUT"
assert_contains "gate names the drifted file" "README.md" "$OUT"
cleanup_fixture

echo
echo "[5] trust-prior percentage is computed"
setup_fixture
run python "$SG" gate-phase "$RUN_ROOT" 1
assert_rc "gate passes clean fixture" 0
assert_contains "gate prints 50 percent trust debt" "TRUST_DEBT phase 1: 1/2 trust-prior (50%)" "$OUT"
cleanup_fixture

echo
echo "[6] resume identifies next pending phase"
setup_fixture
run python "$SG" resume "$RUN_ROOT"
assert_rc "resume exits 0" 0
assert_contains "resume reports phase 1" "Next action: resume phase 1" "$OUT"
cleanup_fixture

echo
echo "[7] blocked run reports failure history"
setup_fixture
RUN_ROOT="$RUN_ROOT" python - <<'PY'
import json
import os
from pathlib import Path

path = Path(os.environ["RUN_ROOT"]) / "run.json"
data = json.loads(path.read_text(encoding="utf-8"))
data["run"]["status"] = "BLOCKED"
data["phases"][0]["status"] = "blocked"
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
python "$SG" record-event "$RUN_ROOT" --type failure.probe --phase 1 --status fail --message "fixture failure" >/dev/null
run python "$SG" resume "$RUN_ROOT"
assert_rc "blocked resume exits 0" 0
assert_contains "resume reports blocked history" "Blocked/failure history" "$OUT"
assert_contains "resume includes failure message" "fixture failure" "$OUT"
cleanup_fixture

echo
echo "[8] audit detects missing deliverable via pure-Python git"
setup_fixture
rm -f src/new.txt
set_phase_statuses_complete
run python "$SG" audit "$RUN_ROOT"
assert_rc "audit fails when deliverable is missing" 1
assert_contains "audit prints AUDIT_GAPS" "AUDIT_GAPS" "$OUT"
assert_contains "audit names missing deliverable" "src/new.txt" "$OUT"
cleanup_fixture

echo
echo "[9] report generation creates report.html"
setup_fixture
run python "$SG" report "$RUN_ROOT"
assert_rc "report exits 0" 0
assert_contains "report prints RUN_REPORT_WRITTEN" "RUN_REPORT_WRITTEN" "$OUT"
assert_file "report.html exists" "$RUN_ROOT/report.html"
cleanup_fixture

echo
echo "[10] gate without a git baseline announces the scope skip (no silent pass)"
setup_fixture
# Drop the baseline so the scope firewall has nothing to diff against.
RUN_ROOT="$RUN_ROOT" python - <<'PY'
import json, os
from pathlib import Path
p = Path(os.environ["RUN_ROOT"]) / "run.json"
d = json.loads(p.read_text(encoding="utf-8"))
d["run"]["baseline_ref"] = "no-git"
p.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")
PY
# An edit that WOULD be out-of-scope drift if a baseline existed.
printf 'outside\n' > README.md
run python "$SG" gate-phase "$RUN_ROOT" 1
assert_rc "gate still completes without a baseline" 0
assert_contains "gate announces scope skip" "SCOPE_CHECK skipped (no git baseline)" "$OUT"
case "$OUT" in
  *SCOPE_DRIFT*) no "no false SCOPE_DRIFT without baseline" "unexpected SCOPE_DRIFT in [$OUT]";;
  *) ok "no false SCOPE_DRIFT without baseline";;
esac
cleanup_fixture

echo
echo "[11] scope skip is recorded as an event for the report"
setup_fixture
RUN_ROOT="$RUN_ROOT" python - <<'PY'
import json, os
from pathlib import Path
p = Path(os.environ["RUN_ROOT"]) / "run.json"
d = json.loads(p.read_text(encoding="utf-8"))
d["run"]["baseline_ref"] = "no-git"
p.write_text(json.dumps(d, indent=2) + "\n", encoding="utf-8")
PY
python "$SG" gate-phase "$RUN_ROOT" 1 >/dev/null
run grep -q "phase.scope.skipped" "$RUN_ROOT/events.jsonl"
assert_rc "scope skip recorded in events.jsonl" 0
cleanup_fixture

echo
echo "[12] compile turns ROADMAP.md into a valid run.json (lockfile)"
COMPILE_ROOT="$(mktemp -d)/.supergoal/compiled"
mkdir -p "$COMPILE_ROOT/phases"
cat > "$COMPILE_ROOT/ROADMAP.md" <<'EOF'
# Roadmap: Compile Demo

**Task:** Build a demo widget

## Phase 1 — Build Feature

**Deliverables:**
- src/widget.js

**Acceptance criteria:**
- [mechanical] src/widget.js exists
- [ ] [trust-prior] manual review recorded
- looks good

**Mandatory commands:**
- `npm test`
- `npm run lint`

**Evidence required:**
- commands/c1.log

**Allowed paths:**
- src/

**Dependencies:** none

## Phase 2 — Polish & Harden

**Acceptance criteria:**
- [mechanical] final audit passes

**Mandatory commands:**
- `npm test`

**Dependencies:** 1
EOF
printf '# State\n**Baseline ref:** no-git\n' > "$COMPILE_ROOT/STATE.md"
run python "$SG" compile "$COMPILE_ROOT"
assert_rc "compile exits 0" 0
assert_contains "compile prints RUN_COMPILED" "RUN_COMPILED 2 phase(s), 2 command(s)" "$OUT"
assert_contains "compile warns on unscoped phase" "COMPILE_WARN phase 2" "$OUT"
run python "$SG" validate-run "$COMPILE_ROOT"
assert_rc "compiled run.json validates" 0
COMPILE_ROOT="$COMPILE_ROOT" python - <<'PY'
import json, os, sys
from pathlib import Path
d = json.loads((Path(os.environ["COMPILE_ROOT"]) / "run.json").read_text())
assert len(d["commands"]) == 2, d["commands"]                       # npm test deduped across phases
p1 = d["phases"][0]
assert p1["commands"] == ["c1", "c2"], p1["commands"]
assert p1["allowed_paths"] == ["src/"], p1["allowed_paths"]
classes = [c["verification"] for c in p1["criteria"]]
assert classes == ["mechanical", "trust-prior", "trust-prior"], classes
assert d["phases"][1]["depends_on"] == [1], d["phases"][1]["depends_on"]
print("structure-ok")
PY
assert_rc "compiled run.json has expected structure" 0
rm -rf "$(dirname "$(dirname "$COMPILE_ROOT")")"

echo
echo "[13] malformed ROADMAP fails compile loudly"
BAD_ROOT="$(mktemp -d)/.supergoal/bad"
mkdir -p "$BAD_ROOT/phases"
printf '# Roadmap: Bad\n\n## Phase 1 — Build\n\n**Deliverables:**\n- x\n' > "$BAD_ROOT/ROADMAP.md"
printf '# State\n**Baseline ref:** no-git\n' > "$BAD_ROOT/STATE.md"
run python "$SG" compile "$BAD_ROOT"
assert_rc "compile fails without criteria" 1
assert_contains "compile reports the defect" "COMPILE_ERROR" "$OUT"
rm -rf "$(dirname "$(dirname "$BAD_ROOT")")"

echo
echo "[14] compile refuses to clobber an in-flight run without --force"
LIVE_ROOT="$(mktemp -d)/.supergoal/live"
mkdir -p "$LIVE_ROOT/phases"
printf '# Roadmap: Live\n\n## Phase 1 — Build\n\n**Acceptance criteria:**\n- [mechanical] ok\n' > "$LIVE_ROOT/ROADMAP.md"
printf '# State\n**Baseline ref:** no-git\n' > "$LIVE_ROOT/STATE.md"
printf '{"schema_version":"1.0","run":{"id":"live","status":"IN_PROGRESS"},"commands":[],"phases":[]}\n' > "$LIVE_ROOT/run.json"
run python "$SG" compile "$LIVE_ROOT"
assert_rc "compile refuses in-flight run" 1
assert_contains "compile explains the refusal" "in-flight run" "$OUT"
rm -rf "$(dirname "$(dirname "$LIVE_ROOT")")"

echo
printf 'sg-run-kernel.test.sh: %s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
