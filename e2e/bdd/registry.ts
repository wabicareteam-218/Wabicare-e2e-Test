/**
 * Step-definition registry. Steps are registered with a pattern (RegExp or a
 * cucumber-lite string supporting {string}/{int}/{word}) and an async handler
 * receiving (world, ...captures). Keyword (Given/When/Then) is informational —
 * matching is by text only, like Cucumber.
 */
import type { World } from './world';

export type StepFn = (world: World, ...args: string[]) => Promise<void> | void;
interface StepDef { re: RegExp; fn: StepFn; }

const defs: StepDef[] = [];

function toRegExp(pattern: RegExp | string): RegExp {
  if (pattern instanceof RegExp) return pattern;
  // cucumber-lite: escape regex, then expand {string}/{int}/{word}
  let src = pattern.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  src = src
    .replace(/\\\{string\\\}/g, '"([^"]*)"')
    .replace(/\\\{int\\\}/g, '(-?\\d+)')
    .replace(/\\\{word\\\}/g, '(\\S+)')
    .replace(/\\\{\\\}/g, '(.+)');
  return new RegExp('^' + src + '$');
}

export function defineStep(pattern: RegExp | string, fn: StepFn): void {
  defs.push({ re: toRegExp(pattern), fn });
}
export const Given = defineStep;
export const When = defineStep;
export const Then = defineStep;

export function matchStep(text: string): { fn: StepFn; args: string[] } | null {
  for (const d of defs) {
    const m = text.match(d.re);
    if (m) return { fn: d.fn, args: m.slice(1) };
  }
  return null;
}

export function stepCount(): number { return defs.length; }
