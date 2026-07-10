#!/usr/bin/env node
/**
 * Build the E2E coverage dashboard.
 *
 *   node tools/build-dashboard.mjs
 *
 * - Parses every e2e/features/*.feature into Feature → Scenario → Steps.
 * - Overlays the latest Playwright run (test-results/full-run.json): each
 *   executed test is routed to the feature it exercises and rendered as an
 *   "automated" scenario with real pass/fail + the screenshots captured during
 *   the run (copied into dashboard/screenshots/). Failures are highlighted and
 *   show their screenshot at the failing step.
 * - Emits a self-contained interactive dashboard at dashboard/index.html.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const FEATURES_DIR = path.join(ROOT, 'features');
const RESULTS_JSON = path.join(ROOT, 'test-results', 'full-run.json');
const OUT_DIR = path.join(ROOT, 'dashboard');
const SHOT_DIR = path.join(OUT_DIR, 'screenshots');

const TAGS = ['@smoke', '@positive', '@negative', '@edge', '@permission', '@security', '@a11y', '@data'];

// ---- 1. Parse feature files -------------------------------------------------
function parseFeature(src, file) {
  const lines = src.split(/\r?\n/);
  const feat = { file, name: file.replace('.feature', ''), title: '', description: [], background: [], scenarios: [] };
  let pendingTags = [];
  let cur = null; // current scenario
  let inExamples = false;
  const stepRe = /^(Given|When|Then|And|But|\*)\s+(.*)$/;
  for (let raw of lines) {
    const line = raw.trim();
    if (!line) { inExamples = false; continue; }
    if (line.startsWith('#')) continue;
    if (line.startsWith('@')) { pendingTags.push(...line.split(/\s+/).filter((t) => TAGS.includes(t))); continue; }
    if (line.startsWith('Feature:')) { feat.title = line.slice(8).trim(); cur = null; continue; }
    if (line.startsWith('Background:')) { cur = { name: '__background__', steps: feat.background }; inExamples = false; continue; }
    const scen = line.match(/^Scenario(?: Outline)?:\s*(.*)$/);
    if (scen) {
      cur = { name: scen[1].trim(), outline: line.startsWith('Scenario Outline'), tags: pendingTags.slice(), steps: [], examples: [] };
      feat.scenarios.push(cur);
      pendingTags = [];
      inExamples = false;
      continue;
    }
    if (/^Examples:/.test(line)) { inExamples = true; continue; }
    const m = line.match(stepRe);
    if (m && cur && !inExamples) { (cur.steps).push({ kw: m[1], text: m[2] }); continue; }
    if (line.startsWith('|')) {
      if (cur && inExamples) cur.examples.push(line);
      else if (cur && cur.steps.length) (cur.steps[cur.steps.length - 1].table ||= []).push(line);
      continue;
    }
    if (!feat.scenarios.length && !line.startsWith('Scenario')) feat.description.push(line);
  }
  return feat;
}

const features = fs.readdirSync(FEATURES_DIR)
  .filter((f) => f.endsWith('.feature'))
  .sort()
  .map((f) => parseFeature(fs.readFileSync(path.join(FEATURES_DIR, f), 'utf8'), f));

// ---- 2. Load Playwright results + copy screenshots --------------------------
fs.rmSync(SHOT_DIR, { recursive: true, force: true });
fs.mkdirSync(SHOT_DIR, { recursive: true });

function routeTestToFeature(specFile, title) {
  const t = title.toLowerCase();
  if (/login|sign in|auth token|refresh/.test(specFile + ' ' + t)) return 'authentication';
  if (specFile.includes('schedule')) return 'scheduling';
  if (specFile.includes('sessions')) {
    if (/note|approve|amend/.test(t)) return 'session-notes';
    if (/collect|behaviour|behavior|handwashing|goal/.test(t)) return 'session-data-collection';
    return 'sessions';
  }
  if (specFile.includes('patient-intake')) {
    if (/insurance|card/.test(t)) return 'patient-insurance';
    if (/co-?pay/.test(t)) return 'copay';
    if (/authoriz/.test(t)) return 'authorization';
    if (/intake forms|fill "/.test(t)) return 'intake-forms';
    if (/patients list|navigate to patients|appears in the patients/.test(t)) return 'patients-list';
    return 'patient-basic-info';
  }
  return null;
}

const executedByFeature = {}; // featureName -> [ {title,status,duration,shots:[{name,rel}],error} ]
const bddResults = {}; // "featureTitle :: scenarioName" -> {status,shots,error,duration}
let runMeta = { present: false, total: 0, passed: 0, failed: 0, when: '' };
let bddMeta = { passed: 0, failed: 0, pending: 0 };
const norm = (s) => String(s).replace(/\s+/g, ' ').trim().toLowerCase();

let shotCounter = 0;
function copyShot(absPath) {
  try {
    if (!absPath || !fs.existsSync(absPath)) return null;
    const rel = `screenshots/shot-${++shotCounter}.png`;
    fs.copyFileSync(absPath, path.join(OUT_DIR, rel));
    return rel;
  } catch { return null; }
}

function shotsOf(res) {
  return (res.attachments || [])
    .filter((a) => a.contentType === 'image/png')
    .map((a) => ({ name: a.name || 'screenshot', rel: copyShot(a.path) }))
    .filter((x) => x.rel);
}
function errOf(res) {
  return (res.errors || []).map((e) => (e.message || '').replace(/\x1b\[[0-9;]*m/g, '')).join('\n').slice(0, 1400);
}

// One combined run (bespoke specs + BDD) → route per spec file.
//   bespoke specs (login/intake/schedule/sessions) → executedByFeature
//   bdd.spec.ts (Feature: … suites)               → per-scenario overlay
for (const src of [RESULTS_JSON, path.join(ROOT, 'test-results', 'bdd-run.json')]) {
  if (!fs.existsSync(src)) continue;
  const j = JSON.parse(fs.readFileSync(src, 'utf8'));
  runMeta.present = true;
  if (!runMeta.when && j.stats?.startTime) runMeta.when = new Date(j.stats.startTime).toISOString().slice(0, 10);
  const walk = (ss, featureTitle) => {
    for (const s of ss || []) {
      const ft = (s.title || '').startsWith('Feature:') ? s.title.replace(/^Feature:\s*/, '') : featureTitle;
      for (const sp of s.specs || []) {
        const res = sp.tests?.[0]?.results?.[0];
        if (!res) continue;
        const specFile = (sp.file || s.title || '').split('/').pop();
        if (specFile === 'bdd.spec.ts') {
          const st = res.status === 'skipped' ? 'pending' : (sp.ok ? 'passed' : 'failed');
          if (st === 'pending') bddMeta.pending++; else if (st === 'passed') bddMeta.passed++; else bddMeta.failed++;
          bddResults[norm(ft) + ' :: ' + norm(sp.title)] = {
            status: st, duration: Math.round(res.duration || 0),
            shots: st === 'failed' ? shotsOf(res) : [], error: st === 'failed' ? errOf(res) : '',
          };
        } else {
          runMeta.total++; sp.ok ? runMeta.passed++ : runMeta.failed++;
          (executedByFeature[routeTestToFeature(specFile, sp.title)] ||= []).push({
            title: sp.title, status: sp.ok ? 'passed' : 'failed',
            duration: Math.round(res.duration || 0), shots: shotsOf(res), error: sp.ok ? '' : errOf(res), spec: specFile,
          });
        }
      }
      walk(s.suites, ft);
    }
  };
  walk(j.suites, '');
}

// ---- 3. Render HTML ---------------------------------------------------------
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const kwClass = (kw) => ({ Given: 'kw-given', When: 'kw-when', Then: 'kw-then', And: 'kw-and', But: 'kw-and', '*': 'kw-and' }[kw] || 'kw-and');

let totalScenarios = 0, totalDrafted = 0;
const tagCounts = Object.fromEntries(TAGS.map((t) => [t, 0]));

function renderSteps(steps) {
  return steps.map((st) => {
    let h = `<div class="step"><span class="kw ${kwClass(st.kw)}">${st.kw}</span> ${esc(st.text)}</div>`;
    if (st.table) h += `<div class="table">${st.table.map((r) => esc(r)).join('<br>')}</div>`;
    return h;
  }).join('');
}

function renderShots(shots) {
  if (!shots.length) return '';
  return `<div class="shots">` + shots.map((s) =>
    `<figure><a href="${s.rel}" target="_blank"><img loading="lazy" src="${s.rel}" alt="${esc(s.name)}"></a><figcaption>${esc(s.name)}</figcaption></figure>`
  ).join('') + `</div>`;
}

function featureBlocks() {
  return features.map((f) => {
    const execs = executedByFeature[f.name] || [];
    const execPass = execs.filter((e) => e.status === 'passed').length;
    const execFail = execs.filter((e) => e.status === 'failed').length;
    totalScenarios += f.scenarios.length + execs.length;
    totalDrafted += f.scenarios.length;
    for (const sc of f.scenarios) for (const tg of sc.tags) if (tagCounts[tg] != null) tagCounts[tg]++;

    // automated scenarios (from the run)
    const execHtml = execs.map((e) => {
      const cls = e.status === 'passed' ? 'passed' : 'failed';
      const icon = e.status === 'passed' ? '✅' : '❌';
      const stepsFromShots = e.shots.length
        ? `<div class="autoshot-steps">` + e.shots.map((s, i) =>
            `<div class="astep"><span class="kw kw-then">Step ${i + 1}</span> ${esc(s.name)}` +
            `<div class="shots"><figure><a href="${s.rel}" target="_blank"><img loading="lazy" src="${s.rel}"></a></figure></div></div>`
          ).join('') + `</div>`
        : `<div class="muted">No screenshots captured for this step.</div>`;
      const err = e.error ? `<div class="error">${esc(e.error)}</div>` : '';
      return `<details class="scenario ${cls}" data-status="${e.status}" data-tags="@automated ${e.status === 'failed' ? '@failure' : ''}">
        <summary><span class="stat">${icon}</span> ${esc(e.title)} <span class="chip auto">automated · ${e.duration}ms</span></summary>
        <div class="body">${err}${stepsFromShots}</div></details>`;
    }).join('');

    // drafted scenarios (from .feature), overlaid with real BDD run status.
    let bddPass = 0, bddFail = 0, bddPend = 0;
    const draftHtml = f.scenarios.map((sc) => {
      const tagsAttr = sc.tags.join(' ');
      const tagChips = sc.tags.map((t) => `<span class="tag ${t.slice(1)}">${t}</span>`).join('');
      const examples = sc.examples.length ? `<div class="examples"><div class="ex-h">Examples</div><div class="table">${sc.examples.map((r) => esc(r)).join('<br>')}</div></div>` : '';
      const r = bddResults[norm(f.title || f.name) + ' :: ' + norm(sc.name)];
      let status = 'drafted', icon = '📝', extra = '', chip = '';
      if (r) {
        status = r.status;
        if (status === 'passed') { icon = '✅'; bddPass++; chip = `<span class="chip auto">bdd · ${r.duration}ms</span>`; }
        else if (status === 'failed') { icon = '❌'; bddFail++; chip = `<span class="chip fail">bdd failed</span>`;
          extra = (r.error ? `<div class="error">${esc(r.error)}</div>` : '') + renderShots(r.shots); }
        else { icon = '⏳'; bddPend++; chip = `<span class="chip">pending</span>`; }
      }
      return `<details class="scenario ${status}" data-status="${status}" data-tags="${tagsAttr}${status === 'failed' ? ' @failure' : ''}">
        <summary><span class="stat">${icon}</span> ${esc(sc.name)}${sc.outline ? ' <span class="chip">outline</span>' : ''} ${chip}<span class="tags">${tagChips}</span></summary>
        <div class="body">${renderSteps(sc.steps)}${examples}${extra}</div></details>`;
    }).join('');

    const totalPass = execPass + bddPass, totalRun = execs.length + bddPass + bddFail;
    const statusBadge = (execFail + bddFail)
      ? `<span class="badge fail">${totalPass}/${totalRun + bddPend} · ${execFail + bddFail} failing</span>`
      : (totalRun ? `<span class="badge pass">${totalPass} passing${bddPend ? ` · ${bddPend} pending` : ''} ✅</span>`
                  : `<span class="badge draft">drafted</span>`);

    return `<details class="feature" data-name="${esc(f.name)}">
      <summary>
        <span class="fname">${esc(f.title || f.name)}</span>
        ${statusBadge}
        <span class="counts">${f.scenarios.length + execs.length} scenarios</span>
      </summary>
      <div class="fdesc">${esc(f.description.join(' '))}</div>
      <div class="scenarios">${execHtml}${draftHtml}</div>
    </details>`;
  }).join('\n');
}

const blocks = featureBlocks();
const tagBar = TAGS.map((t) => `<button class="tagbtn" data-tag="${t}">${t} <b>${tagCounts[t]}</b></button>`).join('');

const html = `<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Wabi E2E Coverage Dashboard</title>
<style>
:root{--bg:#0f1420;--card:#161d2e;--card2:#1c2740;--txt:#e6ebf5;--mut:#8ea0c0;--line:#26324d;--grn:#2fbf71;--red:#ff5c7a;--amb:#f2b544;--acc:#7c9cff}
@media (prefers-color-scheme:light){:root{--bg:#f4f6fb;--card:#fff;--card2:#f0f3fa;--txt:#12203a;--mut:#5b6b88;--line:#dde4f0;--grn:#178f52;--red:#d33a5a;--amb:#b5820c;--acc:#3a5bd0}}
*{box-sizing:border-box}body{margin:0;font:14px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;background:var(--bg);color:var(--txt)}
.wrap{max-width:1100px;margin:0 auto;padding:24px 16px 80px}
h1{font-size:22px;margin:0 0 4px}.sub{color:var(--mut);margin:0 0 18px}
.summary{display:flex;flex-wrap:wrap;gap:10px;margin-bottom:16px}
.kpi{background:var(--card);border:1px solid var(--line);border-radius:12px;padding:12px 16px;min-width:120px}
.kpi b{display:block;font-size:22px}.kpi span{color:var(--mut);font-size:12px}
.kpi.pass b{color:var(--grn)}.kpi.fail b{color:var(--red)}
.toolbar{position:sticky;top:0;z-index:5;background:var(--bg);padding:10px 0;display:flex;flex-wrap:wrap;gap:8px;align-items:center;border-bottom:1px solid var(--line);margin-bottom:14px}
input#q{flex:1;min-width:200px;background:var(--card);border:1px solid var(--line);color:var(--txt);border-radius:8px;padding:8px 12px}
.btn{background:var(--card);border:1px solid var(--line);color:var(--txt);border-radius:8px;padding:7px 11px;cursor:pointer;font-size:13px}
.btn:hover{border-color:var(--acc)}
.tagbtn{background:var(--card);border:1px solid var(--line);color:var(--mut);border-radius:999px;padding:5px 10px;cursor:pointer;font-size:12px}
.tagbtn.on{background:var(--acc);color:#fff;border-color:var(--acc)}
.tagbtn b{color:var(--txt)}.tagbtn.on b{color:#fff}
details.feature{background:var(--card);border:1px solid var(--line);border-radius:12px;margin:10px 0;overflow:hidden}
details.feature>summary{list-style:none;cursor:pointer;padding:14px 16px;display:flex;align-items:center;gap:12px;font-weight:600}
details.feature>summary::-webkit-details-marker{display:none}
details.feature[open]>summary{border-bottom:1px solid var(--line)}
.fname{font-size:15px}.counts{color:var(--mut);font-weight:400;font-size:12px;margin-left:auto}
.badge{font-size:11px;padding:3px 9px;border-radius:999px;font-weight:600}
.badge.pass{background:rgba(47,191,113,.15);color:var(--grn)}.badge.fail{background:rgba(255,92,122,.15);color:var(--red)}
.badge.draft{background:var(--card2);color:var(--mut)}
.fdesc{color:var(--mut);padding:10px 16px 0;font-size:13px}
.scenarios{padding:8px 12px 12px}
details.scenario{border:1px solid var(--line);border-radius:9px;margin:7px 0;background:var(--card2)}
details.scenario>summary{list-style:none;cursor:pointer;padding:9px 12px;display:flex;align-items:center;gap:8px;flex-wrap:wrap}
details.scenario>summary::-webkit-details-marker{display:none}
details.scenario.failed{border-color:var(--red)}
details.scenario.passed .stat{filter:none}
.stat{font-size:13px}
.tags{margin-left:auto;display:flex;gap:4px;flex-wrap:wrap}
.tag{font-size:10px;padding:2px 7px;border-radius:999px;background:var(--card);color:var(--mut);border:1px solid var(--line)}
.tag.negative{color:var(--red)}.tag.security{color:#ff9d4d}.tag.edge{color:var(--amb)}.tag.positive,.tag.smoke{color:var(--grn)}.tag.permission{color:var(--acc)}
.chip{font-size:10px;padding:2px 7px;border-radius:6px;background:var(--card);color:var(--mut);border:1px solid var(--line)}
.chip.auto{color:var(--acc)}.chip.fail{color:var(--red);border-color:var(--red)}
details.scenario.pending{opacity:.72}details.scenario.passed>summary .stat{color:var(--grn)}
.body{padding:6px 14px 12px;border-top:1px solid var(--line)}
.step{padding:2px 0}.kw{display:inline-block;min-width:44px;font-weight:700;font-size:12px}
.kw-given{color:var(--acc)}.kw-when{color:var(--amb)}.kw-then{color:var(--grn)}.kw-and{color:var(--mut)}
.table{font-family:ui-monospace,Menlo,monospace;font-size:12px;color:var(--mut);background:var(--card);border:1px solid var(--line);border-radius:6px;padding:6px 8px;margin:4px 0;overflow-x:auto;white-space:nowrap}
.examples .ex-h{color:var(--mut);font-size:11px;text-transform:uppercase;margin-top:6px}
.error{white-space:pre-wrap;font-family:ui-monospace,monospace;font-size:12px;color:var(--red);background:rgba(255,92,122,.08);border:1px solid var(--red);border-radius:6px;padding:8px;margin:6px 0}
.astep{margin:6px 0}.shots{display:flex;flex-wrap:wrap;gap:8px;margin:4px 0}
.shots figure{margin:0;width:180px}.shots img{width:180px;height:auto;border:1px solid var(--line);border-radius:6px;display:block}
.shots figcaption{font-size:11px;color:var(--mut);margin-top:2px}
.muted{color:var(--mut);font-size:12px}
.hide{display:none!important}
.legend{color:var(--mut);font-size:12px;margin:2px 0 14px}
</style></head><body><div class="wrap">
<h1>Wabi Clinic — E2E Coverage Dashboard</h1>
<p class="sub">Feature → Scenario → Gherkin steps. Automated scenarios show the real last-run result with screenshots; drafted scenarios are specifications awaiting automation.${runMeta.when ? ' Last run: ' + runMeta.when + '.' : ''}</p>
<div class="summary">
  <div class="kpi"><b>${features.length}</b><span>Features</span></div>
  <div class="kpi"><b>${totalDrafted}</b><span>Total scenarios</span></div>
  <div class="kpi pass"><b>${runMeta.passed + bddMeta.passed}</b><span>Passing</span></div>
  <div class="kpi ${runMeta.failed + bddMeta.failed ? 'fail' : ''}"><b>${runMeta.failed + bddMeta.failed}</b><span>Failing</span></div>
  <div class="kpi"><b>${bddMeta.pending}</b><span>Pending (not yet implemented)</span></div>
</div>
<p class="legend">✅ passed · ❌ failed (error + screenshot shown) · ⏳ pending (step definitions not yet implemented) · 📝 drafted (runner has no result). The BDD runner (<code>npm run test:bdd</code>) executes the feature files; unimplemented steps mark a scenario pending so the suite stays green while coverage grows.</p>
<div class="toolbar">
  <input id="q" placeholder="Search features, scenarios, steps…">
  <button class="btn" id="expand">Expand all</button>
  <button class="btn" id="collapse">Collapse all</button>
  <button class="btn" id="failOnly">Failures only</button>
</div>
<div class="tags" style="margin-bottom:12px">${tagBar}</div>
<div id="list">${blocks}</div>
</div>
<script>
const q=document.getElementById('q'),list=document.getElementById('list');
let activeTags=new Set(),failOnly=false;
function apply(){
  const term=q.value.trim().toLowerCase();
  document.querySelectorAll('details.feature').forEach(f=>{
    let anyF=false;
    f.querySelectorAll('details.scenario').forEach(s=>{
      const txt=s.textContent.toLowerCase();
      const tags=(s.getAttribute('data-tags')||'');
      const okTerm=!term||txt.includes(term);
      const okTag=activeTags.size===0||[...activeTags].every(t=>tags.includes(t));
      const okFail=!failOnly||s.getAttribute('data-status')==='failed';
      const show=okTerm&&okTag&&okFail;
      s.classList.toggle('hide',!show); if(show)anyF=true;
    });
    f.classList.toggle('hide',!anyF);
    if(term&&anyF)f.open=true;
  });
}
q.addEventListener('input',apply);
document.getElementById('expand').onclick=()=>document.querySelectorAll('details').forEach(d=>d.open=true);
document.getElementById('collapse').onclick=()=>document.querySelectorAll('details').forEach(d=>d.open=false);
document.getElementById('failOnly').onclick=e=>{failOnly=!failOnly;e.target.classList.toggle('on',failOnly);e.target.style.borderColor=failOnly?'var(--red)':'';apply();};
document.querySelectorAll('.tagbtn').forEach(b=>b.onclick=()=>{const t=b.dataset.tag;if(activeTags.has(t)){activeTags.delete(t);b.classList.remove('on');}else{activeTags.add(t);b.classList.add('on');}apply();});
</script></body></html>`;

fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(path.join(OUT_DIR, 'index.html'), html);
console.log(`Dashboard written: dashboard/index.html`);
console.log(`Features: ${features.length} | Drafted scenarios: ${totalDrafted} | Automated: ${runMeta.passed} passed, ${runMeta.failed} failed | Screenshots: ${shotCounter}`);
