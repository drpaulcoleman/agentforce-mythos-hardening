# Reference Implementation — Salesforce CRM Security Hardening

**Companion code for the whitepaper at [`https://drpaulcoleman.github.io/agentforce-mythos-hardening/`](https://drpaulcoleman.github.io/agentforce-mythos-hardening/).**
**NOT official Salesforce documentation.** All artifacts are illustrative and require validation against your target API version before deployment. © 2026 Dr. Paul Coleman.

---

## What's here

A Salesforce DX project that implements the patterns recommended in the whitepaper. Each artifact has a comment header pointing to the whitepaper section it demonstrates. Treat this as a starter — fork it, adapt naming conventions to your org, validate against your API version, and deploy through your normal change-management gate.

## Quick start

```bash
# 1. Authenticate to a scratch org or sandbox
sf org login web --alias hardening-scratch

# 2. Validate the project compiles (no deployment, runs Apex tests)
sf project deploy validate --source-dir force-app --test-level RunLocalTests --target-org hardening-scratch

# 3. Run static analysis (requires Salesforce Code Analyzer v5: sf plugins install @salesforce/plugin-code-analyzer)
#    Note: sfdx-scanner (v4) was retired August 2025; Code Analyzer v5 is the replacement.
sf code-analyzer run --workspace force-app --rule-selector 'Recommended;Security' --config-file ci/code-analyzer-config.yml --view detail

# 4. Run the Experience Cloud guest-profile scanner against your sandbox
node tools/exp-cloud-scanner/index.js --target hardening-scratch

# 5. Run the Connected App attestation report
node tools/connected-app-attestation/attest.js --target hardening-scratch
```

## Doc-to-code map

Each row has three loadable links:

- **Whitepaper anchor** → opens the rendered whitepaper page on GitHub Pages at the relevant section.
- **Artifact (view)** → opens the file's syntax-highlighted source view on GitHub.com.
- **Raw** → fetches the file's raw content (for `curl`, `wget`, or direct download).

### Pillar 1 — Identity & Authentication
| Whitepaper anchor | Artifact (view) | Raw |
|---|---|---|
| [1.6 Apex SAML JIT handler](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#i-custom-auth) → [App. B.1](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-b) | [`AcmeSamlJitHandler.cls`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/force-app/main/default/classes/AcmeSamlJitHandler.cls) | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/force-app/main/default/classes/AcmeSamlJitHandler.cls) |
| [1.4 Custom Login Flow](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#i-login-flow) → [App. B.3](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-b) | [`LoginFlowConcurrentLimitController.cls`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/force-app/main/default/classes/LoginFlowConcurrentLimitController.cls) | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/force-app/main/default/classes/LoginFlowConcurrentLimitController.cls) |
| Custom-metadata for IdP-group → PSG mapping | [`IdP_Group_Permission_Mapping__mdt/`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/tree/main/reference-impl/force-app/main/default/objects/IdP_Group_Permission_Mapping__mdt) | (folder; clone repo for raw access) |

### Pillar 2 — Access Control
| Whitepaper anchor | Artifact (view) | Raw |
|---|---|---|
| [2.2 PSG migration shape](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#ii-permset-migration) → [App. F](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-f) | [`permissionsets/`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/tree/main/reference-impl/force-app/main/default/permissionsets) · [`permissionsetgroups/Sales_Manager`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/tree/main/reference-impl/force-app/main/default/permissionsetgroups) | (folder; clone repo for raw access) |

### Pillar 4 — Connected Apps & ECAs
| Whitepaper anchor | Artifact (view) | Raw |
|---|---|---|
| [4.1 ECA transition](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#iv-eca-transition) → [App. D.1](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-d) | [`Acme_Integration.connectedApp-meta.xml`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/force-app/main/default/connectedApps/Acme_Integration.connectedApp-meta.xml) + ECA placeholder | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/force-app/main/default/connectedApps/Acme_Integration.connectedApp-meta.xml) |

### Pillar 5 — API + mTLS
| Whitepaper anchor | Artifact (view) | Raw |
|---|---|---|
| [5.1 Named Credentials](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#v-named-credentials) → [App. D.2](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-d) | [`Treasury_API.namedCredential-meta.xml`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/force-app/main/default/namedCredentials/Treasury_API.namedCredential-meta.xml) | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/force-app/main/default/namedCredentials/Treasury_API.namedCredential-meta.xml) |
| [5.2 Mutual TLS](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#v-mtls) | External Credential placeholder | — |

### Pillar 8 — Detection & Response
| Whitepaper anchor | Artifact (view) | Raw |
|---|---|---|
| [8.5 Transaction Security policies](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#viii-transaction-security) → [App. E.1](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-e) | [`BlockHighVolumeBulkApi.cls`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/force-app/main/default/classes/BlockHighVolumeBulkApi.cls) + policy XML | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/force-app/main/default/classes/BlockHighVolumeBulkApi.cls) |
| [8.5 Report-export MFA gate](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#viii-transaction-security) → [App. E.2](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-e) | [`ReportExportThresholdMfa.cls`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/force-app/main/default/classes/ReportExportThresholdMfa.cls) | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/force-app/main/default/classes/ReportExportThresholdMfa.cls) |
| [8.1 Health Check baseline](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#viii-health-check) | [`health-check-custom-baseline.xml`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/baselines/health-check-custom-baseline.xml) | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/baselines/health-check-custom-baseline.xml) |

### Pillar 3 — Experience Cloud audit (Appendix G dual-agent scanner)
| Whitepaper anchor | Artifact (view) | Raw |
|---|---|---|
| [3.8 Automated scanner pattern](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#iii-scanner) → [App. G](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-g) | [`tools/exp-cloud-scanner/`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/tree/main/reference-impl/tools/exp-cloud-scanner) | (folder; clone repo for raw access) |

### Pillar 4 — OAuth attestation (Appendix M.4 quarterly cadence)
| Whitepaper anchor | Artifact (view) | Raw |
|---|---|---|
| [4.9 OAuth Usage attestation](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#iv-detection-attestation) → [App. M.4](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#appendix-m) | [`tools/connected-app-attestation/`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/tree/main/reference-impl/tools/connected-app-attestation) | (folder; clone repo for raw access) |

### Pillar 9 — DevSecOps
| Whitepaper anchor | Artifact (view) | Raw |
|---|---|---|
| [9.2 Static analysis as a gate](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#ix-static-analysis) | [`ci/pmd-apex-rules.xml`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/ci/pmd-apex-rules.xml) · [`ci/code-analyzer-config.yml`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/ci/code-analyzer-config.yml) | [PMD raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/ci/pmd-apex-rules.xml) · [code-analyzer-config raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/ci/code-analyzer-config.yml) |
| [9.4 CI deployment gates](https://drpaulcoleman.github.io/agentforce-mythos-hardening/#ix-deployment-approval) | [`ci/github-actions/`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/tree/main/reference-impl/ci/github-actions) | (folder; clone repo for raw access) |

### Data exports (machine-readable)

| File | Purpose | View | Raw |
|---|---|---|---|
| `data/checklist.json` | Appendix M Day-1 / Week-1 / Month-1 / Quarterly checklist as JSON | [view](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/data/checklist.json) | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/data/checklist.json) |
| `data/glossary.json` | Glossary entries with cross-links | [view](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/data/glossary.json) | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/data/glossary.json) |
| `data/risk-register.json` | Top-15 risk register with controls and residuals | [view](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/data/risk-register.json) | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/data/risk-register.json) |
| `data/standards-mapping.json` | NIST CSF / CIS CSC / ISO / SOC 2 / HIPAA / PCI / EU AI Act mappings | [view](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/reference-impl/data/standards-mapping.json) | [raw](https://raw.githubusercontent.com/drpaulcoleman/agentforce-mythos-hardening/main/reference-impl/data/standards-mapping.json) |

## Disclaimers (also in the whitepaper)

- **This is not official Salesforce documentation.** The author takes responsibility for all opinions and any errors. Where this code conflicts with official Salesforce documentation, official Salesforce documentation governs.
- **Code samples are illustrative.** Method signatures, interface contracts, and metadata-schema element names evolve across Salesforce releases. Validate against the current Apex Reference Guide and Metadata API Developer Guide for your target API version before deploying.
- **No warranty.** Provided "AS IS"; the author is not liable for damages arising from use.

## License

See [`LICENSE`](https://github.com/drpaulcoleman/agentforce-mythos-hardening/blob/main/LICENSE) at the repo root.
