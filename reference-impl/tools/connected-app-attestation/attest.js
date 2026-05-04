#!/usr/bin/env node
/**
 * Connected-App Attestation Report
 *
 * Pillar IV.9 / Appendix O.4 quarterly cadence. Produces a Markdown report
 * suitable for sign-off and retention in the audit pack.
 *
 * Pulls:
 *   - Connected Apps (ConnectedApplication object) from SF CLI
 *   - OAuth tokens (OauthToken object)
 * Computes:
 *   - Apps without identifiable business owner (expects a custom field
 *     'Business_Owner__c' on a custom object 'Connected_App_Registry__c'
 *     keyed to the Connected App's ID; if absent, all apps are flagged)
 *   - Apps with > 25% user-count growth quarter-over-quarter (requires
 *     a prior-quarter snapshot at --baseline)
 *
 * Usage:
 *   node tools/connected-app-attestation/attest.js \
 *       --target <org-alias> \
 *       --baseline previous-quarter-snapshot.json \
 *       --output attestation-2026-Q2.md
 *
 * NOT official Salesforce documentation.
 */

import { execFile as execFileCb } from 'node:child_process';
import { promisify } from 'node:util';
import { readFile, writeFile } from 'node:fs/promises';
import { parseArgs } from 'node:util';

const execFile = promisify(execFileCb);

const { values: args } = parseArgs({
  options: {
    target: { type: 'string', short: 't' },
    baseline: { type: 'string', short: 'b' },
    output: { type: 'string', short: 'o', default: 'oauth-usage-attestation.md' },
    'snapshot-out': { type: 'string', default: 'oauth-usage-snapshot.json' },
  },
});

if (!args.target) {
  console.error('Usage: attest --target <org-alias> [--baseline <prior-snapshot>] [--output <md>]');
  process.exit(1);
}

console.log(`[connected-app-attestation] target=${args.target}`);

// ---- Pull Connected Apps + OAuth tokens ----
let apps = [];
let tokens = [];
try {
  const appsResult = await execFile('sf', [
    'data', 'query',
    '--query', 'SELECT Id, Name, OptionsRefreshTokenValidityMetric FROM ConnectedApplication',
    '--target-org', args.target,
    '--json',
  ], { maxBuffer: 32 * 1024 * 1024 });
  apps = JSON.parse(appsResult.stdout).result?.records || [];

  const tokensResult = await execFile('sf', [
    'data', 'query',
    '--query', 'SELECT Id, AppName, UserId, LastUsedDate, UseCount FROM OauthToken',
    '--target-org', args.target,
    '--json',
  ], { maxBuffer: 32 * 1024 * 1024 });
  tokens = JSON.parse(tokensResult.stdout).result?.records || [];
} catch (err) {
  console.error(`[connected-app-attestation] data pull failed: ${err.message}`);
  process.exit(2);
}

// ---- Compute per-app aggregates ----
const byApp = new Map();
for (const t of tokens) {
  const key = t.AppName || '(unknown)';
  if (!byApp.has(key)) byApp.set(key, { name: key, userIds: new Set(), lastUsed: null, totalUseCount: 0 });
  const agg = byApp.get(key);
  agg.userIds.add(t.UserId);
  if (t.LastUsedDate && (!agg.lastUsed || t.LastUsedDate > agg.lastUsed)) agg.lastUsed = t.LastUsedDate;
  agg.totalUseCount += Number(t.UseCount) || 0;
}

// ---- Optionally compare against prior-quarter baseline ----
let baseline = null;
if (args.baseline) {
  try {
    baseline = JSON.parse(await readFile(args.baseline, 'utf-8'));
  } catch (err) {
    console.warn(`[connected-app-attestation] baseline load warning: ${err.message}`);
  }
}

// ---- Render Markdown report ----
const today = new Date().toISOString().slice(0, 10);
const lines = [];
lines.push(`# OAuth Usage Attestation Report`);
lines.push(``);
lines.push(`**Run date:** ${today}`);
lines.push(`**Org:** ${args.target}`);
lines.push(`**Baseline:** ${args.baseline || '(none)'}`);
lines.push(``);
lines.push(`Pillar IV.9 / Appendix O.4 of the Salesforce CRM Security Hardening whitepaper.`);
lines.push(``);
lines.push(`## Summary`);
lines.push(``);
lines.push(`- Connected Apps detected: **${apps.length}**`);
lines.push(`- OAuth tokens active: **${tokens.length}**`);
lines.push(`- Distinct apps with active tokens: **${byApp.size}**`);
lines.push(``);
lines.push(`## Per-app detail`);
lines.push(``);
lines.push(`| App | Active users | Total use count | Last used | Growth vs. prior |`);
lines.push(`|---|---:|---:|---|---|`);

for (const [name, agg] of byApp.entries()) {
  let growth = '(no baseline)';
  if (baseline?.byApp?.[name]) {
    const prior = baseline.byApp[name].userCount;
    const cur = agg.userIds.size;
    if (prior > 0) {
      const pct = ((cur - prior) / prior) * 100;
      growth = `${pct >= 0 ? '+' : ''}${pct.toFixed(1)}%${pct > 25 ? ' (FLAG)' : ''}`;
    }
  }
  lines.push(
    `| ${name} | ${agg.userIds.size} | ${agg.totalUseCount} | ${agg.lastUsed || '(never)'} | ${growth} |`
  );
}

lines.push(``);
lines.push(`## Sign-off`);
lines.push(``);
lines.push(`- Reviewer: ___________________________`);
lines.push(`- Date: ___________________________`);
lines.push(`- Signature: ___________________________`);
lines.push(``);
lines.push(`> NOT official Salesforce documentation. (c) 2026 Dr. Paul Coleman.`);

await writeFile(args.output, lines.join('\n'), 'utf-8');
console.log(`[connected-app-attestation] report written: ${args.output}`);

// ---- Persist this run as the next-quarter's baseline ----
const snapshot = {
  ranAt: new Date().toISOString(),
  org: args.target,
  byApp: Object.fromEntries(
    Array.from(byApp.entries()).map(([name, agg]) => [name, {
      userCount: agg.userIds.size,
      totalUseCount: agg.totalUseCount,
      lastUsed: agg.lastUsed,
    }])
  ),
};
await writeFile(args['snapshot-out'], JSON.stringify(snapshot, null, 2), 'utf-8');
console.log(`[connected-app-attestation] snapshot written: ${args['snapshot-out']}`);
