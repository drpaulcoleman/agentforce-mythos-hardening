/**
 * Cross-Validator -- Pillar III.8 the dual-agent scoring rubric.
 *
 *   Both clean       -> expected; pass
 *   Both flag same   -> high-confidence finding
 *   Alpha-only       -> medium-confidence (config drift not yet propagated)
 *   Beta-only        -> medium-confidence (effective exposure beyond manifest)
 *   Divergence       -> CRITICAL (manual review)
 *
 * NOT official Salesforce documentation.
 */

import { writeFile, mkdir } from 'node:fs/promises';
import { dirname } from 'node:path';

export function crossValidate(alpha, beta) {
  const alphaByHash = new Map(alpha.filter((f) => f.hash).map((f) => [f.hash, f]));
  const betaByHash = new Map(beta.filter((f) => f.hash).map((f) => [f.hash, f]));

  const agreement = [];
  const alphaOnly = [];
  const betaOnly = [];
  const divergence = [];

  for (const [hash, a] of alphaByHash) {
    const b = betaByHash.get(hash);
    if (b) {
      // Both flagged the same hash -- agreement, but check severity divergence
      if (a.severity !== b.severity) {
        divergence.push({
          hash,
          message: `Severity mismatch: alpha=${a.severity}, beta=${b.severity}`,
          alpha: a,
          beta: b,
        });
      } else {
        agreement.push({ hash, finding: a });
      }
    } else {
      alphaOnly.push(a);
    }
  }

  for (const [hash, b] of betaByHash) {
    if (!alphaByHash.has(hash)) {
      betaOnly.push(b);
    }
  }

  // Findings without a hash key (scan-failure, baseline-missing, etc.) cannot be
  // cross-validated; treat them as standalone alpha-only or beta-only.
  for (const a of alpha.filter((f) => !f.hash)) alphaOnly.push(a);
  for (const b of beta.filter((f) => !f.hash)) betaOnly.push(b);

  return { agreement, alphaOnly, betaOnly, divergence };
}

export async function persistResults(path, summary) {
  await mkdir(dirname(path) || '.', { recursive: true });
  await writeFile(path, JSON.stringify(summary, null, 2), 'utf-8');
}
