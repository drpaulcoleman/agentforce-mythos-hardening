# Salesforce CRM Security Hardening

A vendor-neutral, threat-informed hardening reference for the **customer side** of the Salesforce shared-responsibility partnership. Ten pillars from Identity to Defensive AI, twenty-two appendices, fully attributed, with a working Salesforce DX companion implementation.

> ## **[→ Read the whitepaper at drpaulcoleman.github.io/agentforce-mythos-hardening](https://drpaulcoleman.github.io/agentforce-mythos-hardening/)**
>
> The published page is the primary deliverable. This README is the GitHub-side summary for people who land in the repo first.

---

## What this is

A single-page, self-contained HTML whitepaper that addresses real Salesforce CRM threats from the 2024–2026 corpus (UNC6040 vishing, UNC6395 / Salesloft Drift OAuth supply-chain, Krebs-pattern Experience Cloud guest exposure, browser-extension session hijack, AI prompt-injection via web forms, and the April 2026 Mythos third-party-vendor incident) and provides the customer-side hardening playbook for each.

**Audience.** Salesforce admins, developers, architects, SIs, ISVs, partners, and CISOs / executives. The document carries two view modes (Executive Summary ↔ Full Technical Readout) on a folder-tab fold so the same content can be read at two depths.

**What it isn't.**

- **Not official Salesforce documentation.** Salesforce, Inc. has not reviewed, endorsed, or approved this document. Where it conflicts with official Salesforce documentation, official documentation governs.
- **Not legal advice.** The breach-notification timing matrix (Appendix R) is a starting point; coordinate with qualified counsel.
- **Not a vendor selection guide.** SSPM / SIEM / backup vendor categories are discussed; specific vendors are not ranked.

The author takes responsibility for all opinions, recommendations, interpretations, and any errors. © 2026 Dr. Paul Coleman.

---

## What's in the repo

```
agentforce-mythos-hardening/
├── index.html                    # the whitepaper -- open at the GitHub Pages URL above
├── reference-impl/               # companion Salesforce DX project (see below)
├── README.md                     # this file
├── LICENSE
└── .gitignore                    # docs/ source PDFs, scratch audit prompts
```

### `index.html` — the whitepaper

| | |
|---|---|
| Lines | ~7,500 |
| Cards | 140+ |
| Pillars | 10 |
| Appendices | 22 (A–V) |
| Mermaid diagrams | 20+ |
| References | 43 footnoted, all hyperlinked |
| Render | Self-contained: open the file directly in a browser, no build step |

**[→ Open the live page](https://drpaulcoleman.github.io/agentforce-mythos-hardening/)** — search box, sidebar nav, dual-view tab fold, interactive maturity scorecard (Appendix S), Mermaid diagrams, minimap.

### `reference-impl/` — companion Salesforce DX project

A working Salesforce DX project that implements the patterns in the whitepaper. Every artifact has an inline header comment that points back to the whitepaper section it demonstrates, and the [`reference-impl/README.md`](./reference-impl/README.md) holds the full doc-to-code map.

```
reference-impl/
├── README.md                          # doc-to-code map
├── sfdx-project.json + package.json
├── force-app/main/default/
│   ├── classes/                       # 4 Apex classes + 4 test classes
│   │   ├── AcmeSamlJitHandler         (Pillar 1.6 -- group-driven entitlement)
│   │   ├── LoginFlowConcurrentLimitController  (Pillar 1.4 -- session ceiling)
│   │   ├── BlockHighVolumeBulkApi     (Pillar 8.5 / App. D.1 -- TxSec policy)
│   │   └── ReportExportThresholdMfa   (Pillar 8.5 / App. D.2 -- TxSec policy)
│   ├── permissionsets/  +  permissionsetgroups/
│   │                                  # 3 PermSets composing into 1 PSG (Pillar 2.2 / App. E)
│   ├── connectedApps/  +  externalClientApps/
│   │                                  # ConnectedApp + ECA pair (Pillar 4.1 / App. C.1)
│   ├── namedCredentials/  +  externalCredentials/
│   │                                  # mTLS Named Credential + per-user EC (Pillar 5.1)
│   ├── transactionSecurityPolicies/   # 2 policies bound to the Apex above
│   ├── objects/IdP_Group_Permission_Mapping__mdt/
│   │                                  # custom-metadata mapping table for the JIT handler
│   └── customMetadata/                # 1 seed row
├── baselines/health-check-custom-baseline.xml   # Pillar 8.1 baseline
├── ci/
│   ├── pmd-apex-rules.xml             # PMD ruleset (Pillar 9.2 gate)
│   ├── sfdx-scanner-config.json
│   └── github-actions/                # static analysis + deploy-validate workflows
├── tools/
│   ├── exp-cloud-scanner/             # Pillar 3.8 dual-agent guest-profile scanner (Node)
│   └── connected-app-attestation/     # Pillar 4.9 quarterly OAuth attestation (Node)
└── data/                              # machine-readable JSON exports for tooling
    ├── checklist.json                 # Appendix O as JSON
    ├── glossary.json                  # Appendix L as JSON
    ├── risk-register.json             # the Risk Register
    └── standards-mapping.json         # NIST CSF / CIS / ISO / SOC 2 / HIPAA / PCI / EU AI Act
```

Quick start:

```bash
sf org login web --alias hardening-scratch
sf project deploy validate \
    --source-dir reference-impl/force-app \
    --test-level RunLocalTests \
    --target-org hardening-scratch
```

See [`reference-impl/README.md`](./reference-impl/README.md) for the full doc-to-code map.

---

## How to read the whitepaper

1. **Pick a tab.** The published page opens in **Full Technical Readout** mode. Click **Executive Summary** in the folder-tab strip to switch to the CIO / boardroom lens. The same topics appear at two depths; the URL fragment routing remembers your view.
2. **Search.** The header has a search box that scans card titles, headings, and the `data-search` keyword index. Press `/` to focus it.
3. **Use the sidebar.** Sections are grouped: Threat Brief → 10 Pillars → Cross-Cutting → 22 Appendices. The interactive Maturity Self-Assessment is Appendix S.
4. **Anchor links.** Every claim is footnoted; every footnote links into Appendix M (References). Every glossary term in the Quick Reference table links to its primary in-doc treatment.
5. **Print.** A `@media print` stylesheet hides chrome, expands both tabs, and renders external URLs after their links so the printed copy is self-contained.

---

## Reading paths by role

| If you are a... | Start here | Then read |
|---|---|---|
| **Salesforce admin with 4 hours** | [Appendix O.1 (Day 1 checklist)](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-o) → [90-Minute Sprint](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#exec-90-min-sprint) | Pillar 1 (Identity) → Pillar 4 (Connected Apps) |
| **Salesforce architect** | [Threat Brief](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#threat-landscape) | Pillars 2 → III → IV in order; Appendices A–F |
| **CISO / executive** | [Executive Summary tab → BLUF](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#exec-bluf) | [Mythos Reality Check](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#exec-mythos-reality) → [Talking-Point Cards](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#exec-talking-points) → [Appendix S Maturity Scorecard](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-s) |
| **SI / consultant** | [Critical Path Gantt](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#critical-path) | [Cost & Licensing](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#cost-license) → [Appendix V industry overlays](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-v) |
| **ISV / partner** | [Pillar 4 Connected Apps](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#pillar-iv) | [4.5 AppExchange Security Review limits](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#iv-appexchange) → [4.6 ISV repo compromise pattern](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#iv-isv-compromise) |
| **On-call security responder** | [Appendix Q IR runbook templates](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-q) | [Appendix R breach-notification timing matrix](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-r) |
| **Compliance / audit** | [Appendix P standards mapping](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-p) (NIST CSF / CIS / ISO / SOC 2 / HIPAA / PCI / EU AI Act) | [Appendix S Maturity Scorecard](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-s) |

---

## Versioning

The published document tracks semver in its header badge. The current version is in `<meta name="document-version">` and in [Appendix N (Changelog)](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-n).

| Bump | When |
|---|---|
| Patch (1.x.**y**) | Typo fixes, link maintenance, citation updates, theming patches |
| Minor (1.**x**.0) | New pillar subsection, new appendix entry, expanded threat brief |
| Major (**x**.0.0) | Pillar restructure, removed sections, audience or scope change |

The repo's git history is the audit trail; every `vN.N.N` commit message documents what changed and why.

---

## Errata, corrections, contributions

**Spotted a factual error, broken link, outdated Salesforce feature reference, or suspect a hallucination?** File a [GitHub issue](https://github.com/drpaulcoleman/agentforce-mythos-hardening/issues) with:
- The section anchor (e.g., `#pillar-iv` or `#appendix-c`)
- The exact text in question
- A primary source if you have one

The document has been audit-passed by Codex CLI and Gemini CLI for hallucinations and toxicity (changelog entries v1.2.0 and v1.3.0 document the audits + the fixes applied), but corrections are always welcome.

---

## License

Source code in `reference-impl/` is provided under the LICENSE at the repo root. The whitepaper itself is © 2026 Dr. Paul Coleman, all rights reserved. The whitepaper may be cited and quoted with attribution; redistribution or adaptation requires written permission.

**Trademarks.** Salesforce®, Agentforce™, Einstein™, Data Cloud™, Apex™, Flow™, Lightning®, Shield™, Trailhead™, Hyperforce™ are trademarks of Salesforce, Inc. Claude™, Opus™, Sonnet™, Haiku™, and Project Glasswing are trademarks of Anthropic, PBC. ChatGPT™ and o-series are trademarks of OpenAI, Inc. Gemini™ is a trademark of Google LLC. Used here for educational and technical reference purposes only under nominative fair use.

This document is independent and is **not** affiliated with, endorsed by, or sponsored by Salesforce, Inc. or Anthropic, PBC.
