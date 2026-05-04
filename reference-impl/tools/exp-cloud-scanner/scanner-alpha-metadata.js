/**
 * Scanner Alpha -- Metadata-side drift detector.
 *
 * Pulls the Experience Cloud site's guest profile + sharing rules + class
 * access via the Metadata API, diffs the live state against an approved
 * baseline manifest in version control. Any drift becomes a finding.
 *
 * Required permissions on the integration user invoking this tool:
 *   - View Setup and Configuration
 *   - Modify Metadata Through Metadata API Functions = NO (read-only)
 *   - API Enabled
 *
 * NOT official Salesforce documentation.
 */

import { execFile as execFileCb } from 'node:child_process';
import { promisify } from 'node:util';
import { readFile } from 'node:fs/promises';

const execFile = promisify(execFileCb);

export async function runMetadataScanner({ target, site, baselinePath }) {
  const findings = [];

  // ---- 1. Pull live guest profile metadata via SF CLI ----
  let liveProfile;
  try {
    const { stdout } = await execFile('sf', [
      'org', 'list', 'metadata',
      '--metadata-type', 'Profile',
      '--target-org', target,
      '--json',
    ], { maxBuffer: 32 * 1024 * 1024 });
    const meta = JSON.parse(stdout);
    liveProfile = (meta.result || []).find((p) =>
      typeof p.fullName === 'string' && p.fullName.toLowerCase().includes(site.toLowerCase())
    );
  } catch (err) {
    findings.push({
      severity: 'critical',
      category: 'scan-failure',
      message: `metadata pull failed: ${err.message}`,
      vector: 'A',
    });
    return findings;
  }

  if (!liveProfile) {
    findings.push({
      severity: 'high',
      category: 'site-not-found',
      message: `No guest profile matches site "${site}". Ensure the site name is spelled correctly and the integration user has Setup access.`,
      vector: 'A',
    });
    return findings;
  }

  // ---- 2. Load approved baseline ----
  let baseline;
  try {
    const raw = await readFile(baselinePath, 'utf-8');
    baseline = JSON.parse(raw);
  } catch (err) {
    findings.push({
      severity: 'high',
      category: 'baseline-missing',
      message: `Approved baseline not found at ${baselinePath}. Cannot diff. Generate one with --emit-baseline first.`,
      vector: 'A',
    });
    return findings;
  }

  // ---- 3. Diff -- placeholder logic, real implementation pulls full Profile body ----
  // Real implementation issues `sf project retrieve start --metadata Profile:<name>` and
  // parses the resulting profile-meta.xml. The shape below shows the API contract;
  // a production drop-in fills in the parser.
  for (const expected of (baseline.profile?.userPermissions || [])) {
    const liveValue = liveProfile.userPermissions?.[expected.name] ?? false;
    if (liveValue !== expected.enabled) {
      findings.push({
        severity: 'high',
        category: 'profile-drift',
        message: `Guest profile "${expected.name}" is ${liveValue} but baseline expects ${expected.enabled}.`,
        vector: 'A',
        hash: `profile:${liveProfile.fullName}:${expected.name}`,
      });
    }
  }

  for (const expected of (baseline.profile?.classAccesses || [])) {
    if (expected.guestAccessible === false) {
      findings.push({
        severity: 'medium',
        category: 'class-access-drift',
        message: `Class "${expected.name}" is granted to the guest profile but baseline excludes it.`,
        vector: 'A',
        hash: `class:${liveProfile.fullName}:${expected.name}`,
      });
    }
  }

  return findings;
}
