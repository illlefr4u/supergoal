#!/usr/bin/env node
// render-plan.mjs — read SUPERPLAN_ROOT/*.md (default .superplan), fill
// plan.html.template, write SUPERPLAN_ROOT/plan.html. Tries `marked` if
// available; otherwise falls back to a minimal markdown renderer good enough
// for planning artifacts.
//
// Env: SUPERPLAN_ROOT — base dir for artifacts. Default `.superplan`.
//      Used so dispatchers like Superboard can run multiple tasks without
//      colliding on a shared `.superplan/` directory.
//
// Usage:  node render-plan.mjs   (run from the project root, not the skill dir)

import { readFile, writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const SCRIPT_DIR = dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = dirname(SCRIPT_DIR);
const TEMPLATE_PATH = join(SKILL_DIR, 'templates', 'plan.html.template');
const SP = process.env.SUPERPLAN_ROOT || '.superplan';

let renderMarkdown;
try {
  const { marked } = await import('marked');
  marked.setOptions({ gfm: true, breaks: false });
  renderMarkdown = (md) => marked.parse(md);
} catch {
  renderMarkdown = minimalMarkdown;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function inlineFmt(s) {
  s = escapeHtml(s);
  s = s.replace(/`([^`]+)`/g, '<code>$1</code>');
  s = s.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  s = s.replace(/(^|\s)\*([^*\s][^*]*)\*/g, '$1<em>$2</em>');
  s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
  return s;
}

function minimalMarkdown(md) {
  const lines = md.split('\n');
  const out = [];
  let inCode = false;
  let codeBuf = [];
  let listType = null;        // 'ul' | 'ol' | null
  let listIsChecklist = false;
  let inTable = false;
  let tableHeaderEmitted = false;

  const closeList = () => {
    if (listType) { out.push(`</${listType}>`); listType = null; listIsChecklist = false; }
  };
  const closeTable = () => {
    if (inTable) { out.push('</tbody></table>'); inTable = false; tableHeaderEmitted = false; }
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (line.startsWith('```')) {
      closeList(); closeTable();
      if (inCode) {
        out.push(`<pre><code>${escapeHtml(codeBuf.join('\n'))}</code></pre>`);
        codeBuf = []; inCode = false;
      } else {
        inCode = true;
      }
      continue;
    }
    if (inCode) { codeBuf.push(line); continue; }

    // Tables (basic GFM)
    if (/^\|.*\|\s*$/.test(line)) {
      closeList();
      const cells = line.trim().slice(1, -1).split('|').map(c => c.trim());
      const isSep = cells.every(c => /^:?-+:?$/.test(c));
      if (!inTable) { out.push('<table><thead>'); inTable = true; }
      if (isSep && !tableHeaderEmitted) {
        // The previous row was the header
        out.push('</thead><tbody>');
        tableHeaderEmitted = true;
        continue;
      }
      const tag = tableHeaderEmitted ? 'td' : 'th';
      out.push(`<tr>${cells.map(c => `<${tag}>${inlineFmt(c)}</${tag}>`).join('')}</tr>`);
      continue;
    } else if (inTable) {
      closeTable();
    }

    let m;
    if ((m = line.match(/^(#{1,6})\s+(.*)$/))) {
      closeList();
      const lvl = m[1].length;
      out.push(`<h${lvl}>${inlineFmt(m[2])}</h${lvl}>`);
      continue;
    }
    if ((m = line.match(/^>\s?(.*)$/))) {
      closeList();
      out.push(`<blockquote>${inlineFmt(m[1])}</blockquote>`);
      continue;
    }
    if (/^---+\s*$/.test(line)) {
      closeList();
      out.push('<hr>');
      continue;
    }
    if ((m = line.match(/^\s*[-*+]\s+(?:(\[[xX ]\])\s+)?(.*)$/))) {
      const checkbox = m[1];
      const text = m[2];
      if (listType !== 'ul') {
        closeList();
        out.push(`<ul class="${checkbox ? 'checklist' : ''}">`);
        listType = 'ul';
        listIsChecklist = !!checkbox;
      }
      const doneCls = checkbox && /x/i.test(checkbox) ? ' class="done"' : '';
      out.push(`<li${doneCls}>${inlineFmt(text)}</li>`);
      continue;
    }
    if ((m = line.match(/^\s*\d+\.\s+(.*)$/))) {
      if (listType !== 'ol') {
        closeList();
        out.push('<ol>');
        listType = 'ol';
      }
      out.push(`<li>${inlineFmt(m[1])}</li>`);
      continue;
    }
    if (line.trim() === '') {
      closeList();
      continue;
    }

    // Paragraph
    closeList();
    out.push(`<p>${inlineFmt(line)}</p>`);
  }

  closeList(); closeTable();
  return out.join('\n');
}

async function tryRead(path) {
  try { return await readFile(path, 'utf-8'); }
  catch { return ''; }
}

function parseLock(raw) {
  if (!raw) return null;
  try { return JSON.parse(raw); }
  catch { return { _parseError: true }; }
}

function renderLockHtml(lock) {
  if (!lock) {
    return '<p style="color:var(--muted);">No <code>LOCK.json</code> yet. The skill writes one in Stage 5 when you say "lock it in".</p>';
  }
  if (lock._parseError) {
    return '<p style="color:var(--err);"><code>LOCK.json</code> exists but does not parse as JSON.</p>';
  }
  const phases = (lock.required_phases || []).map(p => `<li>${escapeHtml(p)}</li>`).join('');
  const cmds   = (lock.mandatory_commands || []).map(c => `<li><code>${escapeHtml(c)}</code></li>`).join('');
  const triggers = (lock.conditional_triggers || [])
    .map(t => `<li><strong>${escapeHtml(t.trigger || '?')}</strong> → <code>${escapeHtml(t.command || '?')}</code></li>`)
    .join('');
  const stops = (lock.stop_conditions || []).map(s => `<li>${escapeHtml(s)}</li>`).join('');
  return `
    <div class="meta" style="margin-bottom:14px;">
      <div class="kv"><div class="k">Task</div><div class="v">${escapeHtml(lock.task || '—')}</div></div>
      <div class="kv"><div class="k">Max turns</div><div class="v">${escapeHtml(String(lock.max_turns ?? '—'))}</div></div>
      <div class="kv"><div class="k">Locked at</div><div class="v">${escapeHtml(lock.created_at || '—')}</div></div>
    </div>
    <h3>File hashes (sha256, first 12 chars)</h3>
    <pre><code>PLAN.md       ${escapeHtml((lock.plan_sha256       || '—').slice(0, 12))}…
ACCEPTANCE.md ${escapeHtml((lock.acceptance_sha256 || '—').slice(0, 12))}…
VERIFY.md     ${escapeHtml((lock.verify_sha256     || '—').slice(0, 12))}…
POLISH.md     ${escapeHtml((lock.polish_sha256     || '—').slice(0, 12))}…</code></pre>
    <h3>Required phases</h3>
    <ol>${phases || '<li><em>none</em></li>'}</ol>
    <h3>Mandatory commands</h3>
    <ul>${cmds || '<li><em>none</em></li>'}</ul>
    <h3>Conditional triggers</h3>
    <ul>${triggers || '<li><em>none</em></li>'}</ul>
    <h3>Stop conditions</h3>
    <ul>${stops || '<li><em>none</em></li>'}</ul>
  `;
}

function extractTitle(plan) {
  const m = plan.match(/^#\s+(.*)$/m);
  if (!m) return 'Untitled plan';
  return m[1].replace(/^Plan\s*[—-]\s*/i, '').trim();
}

function extractKV(text, key) {
  const m = text.match(new RegExp('^' + key + '\\s*:\\s*(.+)$', 'm'));
  return m ? m[1].trim() : '';
}

async function main() {
  let tpl;
  try {
    tpl = await readFile(TEMPLATE_PATH, 'utf-8');
  } catch (e) {
    console.error(`render-plan: template not found at ${TEMPLATE_PATH}`);
    console.error('Is the skill installed correctly?');
    process.exit(2);
  }

  const plan       = await tryRead(join(SP, 'PLAN.md'));
  const acceptance = await tryRead(join(SP, 'ACCEPTANCE.md'));
  const verify     = await tryRead(join(SP, 'VERIFY.md'));
  const risks      = await tryRead(join(SP, 'RISKS.md'));
  const polish     = await tryRead(join(SP, 'POLISH.md'));
  const state      = await tryRead(join(SP, 'STATE.md'));
  const goalRaw    = await tryRead(join(SP, 'GOAL.txt'));
  const lockRaw    = await tryRead(join(SP, 'LOCK.json'));

  const lock = parseLock(lockRaw);
  const lockHtml = renderLockHtml(lock);
  const lockStatus = lock?.locked ? 'LOCKED' : 'UNLOCKED';
  const lockBadgeStyle = lock?.locked
    ? 'background:rgba(102,224,163,0.15);border-color:#66e0a3;color:#66e0a3;'
    : 'background:rgba(240,194,100,0.15);border-color:#f0c264;color:#f0c264;';

  const title       = extractTitle(plan);
  const stack       = extractKV(plan + '\n' + state, 'Stack') || '—';
  const taskType    = extractKV(state, 'Type') || (extractKV(plan, 'Type')) || 'brownfield';
  const maxTurns    = extractKV(state, 'Max turns') || extractKV(state, 'Max-turns') || '—';
  const phaseCount  = (plan.match(/^\d+\.\s+/gm) || []).length || '—';
  const goalText    = goalRaw.trim() || '(not yet compiled — run Stage 5 of /superplan)';
  const goalChars   = goalText.length;
  const renderedAt  = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

  const subs = {
    TASK_TITLE: escapeHtml(title),
    TASK_SUBTITLE: 'Plan compiled by /superplan. Refresh after every edit.',
    STACK: escapeHtml(stack),
    TASK_TYPE: escapeHtml(taskType),
    PHASE_COUNT: String(phaseCount),
    MAX_TURNS: escapeHtml(String(maxTurns)),
    RENDERED_AT: renderedAt,
    PLAN_HTML: renderMarkdown(plan || '_PLAN.md is empty — run /superplan to populate._'),
    ACCEPTANCE_HTML: renderMarkdown(acceptance || '_ACCEPTANCE.md is empty._'),
    VERIFY_HTML: renderMarkdown(verify || '_VERIFY.md is empty._'),
    RISKS_HTML: renderMarkdown(risks || '_RISKS.md is empty._'),
    POLISH_HTML: renderMarkdown(polish || '_POLISH.md is empty._'),
    STATE_HTML: renderMarkdown(state || '_STATE.md is empty._'),
    GOAL_TEXT: escapeHtml(goalText),
    GOAL_CHAR_COUNT: String(goalChars),
    LOCK_HTML: lockHtml,
    LOCK_STATUS: lockStatus,
    LOCK_BADGE_STYLE: lockBadgeStyle,
  };

  let html = tpl;
  for (const [k, v] of Object.entries(subs)) {
    html = html.replace(new RegExp(`{{${k}}}`, 'g'), v);
  }

  const outPath = join(SP, 'plan.html');
  await writeFile(outPath, html, 'utf-8');
  console.log(`Wrote ${outPath} (${html.length} bytes; /goal is ${goalChars}/4000 chars)`);
  if (goalChars > 3800) {
    console.warn(`WARNING: /goal is ${goalChars} chars — over the 3800 safe budget.`);
  }
}

main().catch(e => { console.error(e); process.exit(1); });
