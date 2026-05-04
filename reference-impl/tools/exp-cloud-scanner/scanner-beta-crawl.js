/**
 * Scanner Beta -- Public-site crawl detector.
 *
 * Walks the unauthenticated face of an Experience Cloud site and probes
 * Aura/LWC controller endpoints, GraphQL introspection (when API access
 * leaks), and record-id-shaped URLs. Compares observable response shape
 * against the approved baseline.
 *
 * NOT official Salesforce documentation.
 */

export async function runCrawlScanner({ target, site }) {
  const findings = [];

  // ---- 1. Resolve the public-site origin URL ----
  // In a real implementation, query the org for the site URL via:
  //   sf data query --query "SELECT Name, BaseUrl FROM Network" --target-org <target>
  // For this skeleton we fabricate the URL pattern.
  const origin = `https://${site}.example.salesforce-experience.com`;

  // ---- 2. Probe canonical Aura endpoint reachability ----
  const auraEndpoint = `${origin}/s/sfsites/aura`;
  try {
    const res = await fetch(auraEndpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ message: '{"actions":[]}' }),
    });
    if (res.status === 200) {
      // 200 alone is normal -- the endpoint exists. We're checking for content
      // shape that suggests the endpoint accepts unauthenticated calls beyond
      // the empty-actions probe.
      const body = await res.text();
      if (body.length > 4096) {
        findings.push({
          severity: 'medium',
          category: 'aura-verbose-response',
          message: `Aura endpoint at ${auraEndpoint} returned ${body.length} bytes for an empty-actions probe. Investigate whether descriptor metadata is leaking.`,
          vector: 'B',
          hash: `aura:${site}`,
        });
      }
    }
  } catch (err) {
    // Network failures are interesting but not necessarily findings.
    findings.push({
      severity: 'low',
      category: 'aura-probe-failed',
      message: `Aura probe failed: ${err.message}`,
      vector: 'B',
    });
  }

  // ---- 3. Probe GraphQL introspection (where API access is mistakenly exposed) ----
  const graphqlEndpoint = `${origin}/services/data/v63.0/graphql`;
  try {
    const res = await fetch(graphqlEndpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ query: '{ __schema { types { name } } }' }),
    });
    if (res.status === 200) {
      findings.push({
        severity: 'critical',
        category: 'graphql-guest-introspection',
        message: `GraphQL introspection succeeded against ${graphqlEndpoint} from an unauthenticated context. The guest profile likely has API Enabled; revoke immediately.`,
        vector: 'B',
        hash: `graphql:${site}`,
      });
    }
  } catch (err) {
    // Network failures are normal here -- most orgs do NOT expose GraphQL to guests.
  }

  // ---- 4. Probe record-id-shaped URLs ----
  // Real implementation iterates over a curated list of public-page paths and
  // synthesizes plausible record IDs to test for over-share. Placeholder here.

  return findings;
}
