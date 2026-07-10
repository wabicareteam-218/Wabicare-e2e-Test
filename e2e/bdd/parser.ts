/**
 * Minimal Gherkin parser for the BDD runner. Parses a `.feature` file into
 * a Feature with Background + Scenarios (Scenario Outlines expanded over their
 * Examples). Enough of Gherkin for this project — no rules/data-tables beyond
 * step argument tables and Examples.
 */
import * as fs from 'fs';

export interface Step { keyword: string; text: string; }
export interface Scenario {
  name: string;
  tags: string[];
  steps: Step[];
  isOutline: boolean;
  exampleRow?: Record<string, string>;
}
export interface Feature {
  file: string;
  name: string;
  title: string;
  background: Step[];
  scenarios: Scenario[];
}

const STEP_RE = /^(Given|When|Then|And|But|\*)\s+(.*)$/;

export function parseFeatureFile(filePath: string): Feature {
  const src = fs.readFileSync(filePath, 'utf8');
  const lines = src.split(/\r?\n/);
  const file = filePath.split('/').pop() || filePath;
  const feature: Feature = { file, name: file.replace('.feature', ''), title: '', background: [], scenarios: [] };

  let pendingTags: string[] = [];
  let mode: 'none' | 'background' | 'scenario' | 'examples' = 'none';
  let cur: { name: string; tags: string[]; steps: Step[]; isOutline: boolean } | null = null;
  let exampleHeaders: string[] | null = null;
  const rawScenarios: Array<typeof cur & { examples: Record<string, string>[] }> = [] as any;
  let curExamples: Record<string, string>[] = [];

  const flush = () => {
    if (cur) rawScenarios.push({ ...(cur as any), examples: curExamples });
    cur = null; curExamples = []; exampleHeaders = null;
  };

  for (const raw of lines) {
    const line = raw.trim();
    if (!line || line.startsWith('#')) { if (mode === 'examples') { /* stay */ } continue; }
    if (line.startsWith('@')) { pendingTags.push(...line.split(/\s+/).filter((t) => t.startsWith('@'))); continue; }
    if (line.startsWith('Feature:')) { feature.title = line.slice(8).trim(); mode = 'none'; continue; }
    if (line.startsWith('Background:')) { flush(); mode = 'background'; continue; }
    const sc = line.match(/^Scenario(?: Outline)?:\s*(.*)$/);
    if (sc) {
      flush();
      cur = { name: sc[1].trim(), tags: pendingTags.slice(), steps: [], isOutline: line.startsWith('Scenario Outline') };
      pendingTags = [];
      mode = 'scenario';
      continue;
    }
    if (/^Examples:/.test(line)) { mode = 'examples'; exampleHeaders = null; continue; }

    if (mode === 'examples' && line.startsWith('|')) {
      const cells = line.split('|').slice(1, -1).map((c) => c.trim());
      if (!exampleHeaders) exampleHeaders = cells;
      else { const row: Record<string, string> = {}; exampleHeaders.forEach((h, i) => (row[h] = cells[i] ?? '')); curExamples.push(row); }
      continue;
    }

    const m = line.match(STEP_RE);
    if (m) {
      const step: Step = { keyword: m[1], text: m[2] };
      if (mode === 'background') feature.background.push(step);
      else if (cur) cur.steps.push(step);
      continue;
    }
    // Non-step lines under a step (e.g. free text) are ignored.
  }
  flush();

  // Expand outlines over Examples; substitute <param> tokens.
  for (const rs of rawScenarios) {
    if (rs.isOutline && rs.examples.length) {
      for (const row of rs.examples) {
        feature.scenarios.push({
          name: rs.name + ' [' + Object.values(row).join(', ') + ']',
          tags: rs.tags, isOutline: true, exampleRow: row,
          steps: rs.steps.map((s) => ({ keyword: s.keyword, text: substitute(s.text, row) })),
        });
      }
    } else {
      feature.scenarios.push({ name: rs.name, tags: rs.tags, isOutline: false, steps: rs.steps });
    }
  }
  return feature;
}

function substitute(text: string, row: Record<string, string>): string {
  return text.replace(/<([^>]+)>/g, (_, k) => (k in row ? row[k] : `<${k}>`));
}

export function parseAllFeatures(dir: string): Feature[] {
  return fs.readdirSync(dir)
    .filter((f) => f.endsWith('.feature'))
    .sort()
    .map((f) => parseFeatureFile(`${dir}/${f}`));
}
