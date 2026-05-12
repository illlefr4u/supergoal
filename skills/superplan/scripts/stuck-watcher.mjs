#!/usr/bin/env node
// stuck-watcher.mjs — multi-signal stuck detector. Replaces the old bash
// watcher. Checks four signals; declares stuck only when all are stale.
//
// Signals:
//   1. SUPERPLAN_ROOT/STATE.md mtime
//   2. git diff hash
//   3. SUPERPLAN_ROOT/run.log size
//   4. allowlisted long-running command is NOT active
//
// Only when all four indicate stalled does the watcher declare stuck and
// kill the parent process group.
//
// Args:   --minutes=N  --parent-pid=N
// Env:    SUPERPLAN_ROOT                  default `.superplan`
//         SUPERPLAN_STUCK_MINUTES         default 15
//         SUPERPLAN_ALLOW_LONG_COMMANDS   comma-separated allowlist

import { statSync, appendFileSync, existsSync, mkdirSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { createHash } from 'node:crypto';

const args = parseArgs(process.argv.slice(2));
const minutes = parseInt(
  args.minutes || process.env.SUPERPLAN_STUCK_MINUTES || '15',
  10,
);
const parentPid = parseInt(args['parent-pid'] || '0', 10);
const intervalMs = 60_000;
const thresholdMs = minutes * 60_000;

const SP = process.env.SUPERPLAN_ROOT || '.superplan';
const STATE_PATH = `${SP}/STATE.md`;
const LOG_PATH = `${SP}/run.log`;

const DEFAULT_ALLOWLIST = [
  'pnpm install', 'npm install', 'yarn install', 'bun install',
  'pnpm test', 'npm test', 'yarn test', 'bun test',
  'pnpm run build', 'npm run build', 'yarn run build', 'bun run build',
  'cargo build', 'cargo test', 'go build', 'go test',
  'docker compose up', 'docker build', 'docker-compose up',
  'playwright test', 'pytest', 'vitest run',
  'xcodebuild', 'swift build', 'swift test',
];

const allowlist = (process.env.SUPERPLAN_ALLOW_LONG_COMMANDS
  ? process.env.SUPERPLAN_ALLOW_LONG_COMMANDS.split(',').map(s => s.trim()).filter(Boolean)
  : DEFAULT_ALLOWLIST);

function parseArgs(argv) {
  const o = {};
  for (const a of argv) {
    const m = a.match(/^--([^=]+)=(.*)$/);
    if (m) o[m[1]] = m[2];
  }
  return o;
}

function safeMtime(path) {
  try { return statSync(path).mtimeMs; } catch { return 0; }
}
function safeSize(path) {
  try { return statSync(path).size; } catch { return 0; }
}
function gitDiffHash() {
  try {
    const out = execSync('git diff --stat 2>/dev/null', { encoding: 'utf-8' });
    return createHash('sha1').update(out).digest('hex');
  } catch { return ''; }
}
function longCmdActive() {
  try {
    const out = execSync('ps -eo args 2>/dev/null', { encoding: 'utf-8' });
    return allowlist.some(cmd => out.includes(cmd));
  } catch { return false; }
}
function parentAlive() {
  if (!parentPid) return true;
  try { process.kill(parentPid, 0); return true; } catch { return false; }
}
function log(msg) {
  const line = `stuck-watcher: ${msg}`;
  process.stderr.write(line + '\n');
  try {
    if (!existsSync(SP)) mkdirSync(SP, { recursive: true });
    appendFileSync(LOG_PATH, line + '\n');
  } catch {}
}

let prev = { stateMtime: 0, diffHash: '', logSize: 0 };
let unchangedMs = 0;

log(`started, threshold ${minutes}m, watching parent pid ${parentPid}`);
log(`allowlist (${allowlist.length} entries): ${allowlist.slice(0, 5).join(', ')}${allowlist.length > 5 ? ', …' : ''}`);

const tick = () => {
  if (!parentAlive()) {
    log('parent gone, exiting cleanly');
    process.exit(0);
  }
  const cur = {
    stateMtime: safeMtime(STATE_PATH),
    diffHash: gitDiffHash(),
    logSize: safeSize(LOG_PATH),
  };
  const longActive = longCmdActive();
  const stale =
    cur.stateMtime === prev.stateMtime &&
    cur.diffHash === prev.diffHash &&
    cur.logSize === prev.logSize &&
    !longActive;

  if (stale) unchangedMs += intervalMs;
  else unchangedMs = 0;

  prev = cur;

  if (unchangedMs >= thresholdMs) {
    log(
      `no progress in ${minutes}m ` +
      `(STATE.md mtime + git diff hash + run.log size unchanged; ` +
      `no allowlisted long command active). ` +
      `Killing parent group ${parentPid}.`,
    );
    try { process.kill(-parentPid, 'SIGTERM'); } catch {}
    try { process.kill(parentPid, 'SIGTERM'); } catch {}
    setTimeout(() => {
      try { process.kill(parentPid, 'SIGKILL'); } catch {}
      process.exit(1);
    }, 5_000).unref();
  }
};

// First tick after one interval so we have a delta to compare.
setInterval(tick, intervalMs);

// Don't keep node alive if everything else exits.
process.on('SIGTERM', () => process.exit(0));
process.on('SIGINT',  () => process.exit(0));
