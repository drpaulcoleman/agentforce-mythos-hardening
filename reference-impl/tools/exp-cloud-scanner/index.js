#!/usr/bin/env node
/**
 * Experience Cloud Guest-Profile Scanner -- entry point
 *
 * Pillar III.8 / Appendix F in the whitepaper. Two independent perspectives
 * on the guest-profile exposure of an Experience Cloud site, with cross-
 * validation. Divergence between perspectives is auto-classified critical.
 *
 *   Scanner Alpha (metadata)  -- pulls guest profile, sharing rules, class
 *                                access, etc. via Metadata API; diffs against
 *                                an approved baseline manifest in baselines/.
 *
 *   Scanner Beta (crawl)      -- walks the public site as an unauthenticated
 *                                user; probes Aura/LWC controllers, GraphQL
 *                                introspection, record-id-shaped URLs.
 *
 *   Cross-validator           -- agreement = high confidence; alpha-only or
 *                                beta-only = medium; divergence = CRITICAL.
 *
 * Usage:
 *   node tools/exp-cloud-scanner/index.js --target <sf-org-alias> --site <site-name>
 *
 * NOT official Salesforce documentation. (c) 2026 Dr. Paul Coleman.
 */

import { parseArgs } from 'node:util';
import { runMetadataScanner } from './scanner-alpha-metadata.js';
import { runCrawlScanner } from './scanner-beta-crawl.js';
import { crossValidate, persistResults } from './cross-validator.js';

const { values: args } = parseArgs({
  options: {
    target: { type: 'string', short: 't' },
    site: { type: 'string', short: 's' },
    baseline: { type: 'string', short: 'b', default: 'baselines/exp-cloud-baseline.json' },
    output: { type: 'string', short: 'o', default: 'scan-results.json' },
    'dry-run': { type: 'boolean', default: false },
  },
});

if (!args.target || !args.site) {
  console.error('Usage: scan --target <org-alias> --site <site-name>');
  console.error('  --target    Salesforce org alias (sf org login web --alias <alias>)');
  console.error('  --site      Experience Cloud site name to scan');
  console.error('  --baseline  Path to approved-baseline JSON (default: baselines/exp-cloud-baseline.json)');
  console.error('  --output    Path for scan-results JSON (default: scan-results.json)');
  console.error('  --dry-run   Run both scanners; print results; do not persist');
  process.exit(1);
}

console.log(`[exp-cloud-scanner] target=${args.target} site=${args.site} baseline=${args.baseline}`);

const startedAt = new Date().toISOString();

const [alphaFindings, betaFindings] = await Promise.all([
  runMetadataScanner({ target: args.target, site: args.site, baselinePath: args.baseline }),
  runCrawlScanner({ target: args.target, site: args.site }),
]);

console.log(`[exp-cloud-scanner] alpha=${alphaFindings.length} findings, beta=${betaFindings.length} findings`);

const validated = crossValidate(alphaFindings, betaFindings);

const summary = {
  scanned_at: startedAt,
  finished_at: new Date().toISOString(),
  target: args.target,
  site: args.site,
  baseline: args.baseline,
  totals: {
    alpha_only: validated.alphaOnly.length,
    beta_only: validated.betaOnly.length,
    agreement: validated.agreement.length,
    divergence_critical: validated.divergence.length,
  },
  findings: {
    agreement: validated.agreement,
    alpha_only: validated.alphaOnly,
    beta_only: validated.betaOnly,
    divergence: validated.divergence,
  },
};

console.log(`[exp-cloud-scanner] agreement=${summary.totals.agreement} alpha_only=${summary.totals.alpha_only} beta_only=${summary.totals.beta_only} divergence_CRITICAL=${summary.totals.divergence_critical}`);

if (!args['dry-run']) {
  await persistResults(args.output, summary);
  console.log(`[exp-cloud-scanner] results persisted to ${args.output}`);
}

if (summary.totals.divergence_critical > 0) {
  console.error(`[exp-cloud-scanner] EXIT 2 -- divergence between scanners requires manual review`);
  process.exit(2);
}
process.exit(0);
