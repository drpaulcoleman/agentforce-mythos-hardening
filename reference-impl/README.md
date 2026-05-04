# Reference Implementation — Salesforce CRM Security Hardening

**Companion code for [`../index.html`](../index.html) (the whitepaper).**
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

# 3. Run static analysis (requires SFDX Scanner plugin: sf plugins install @salesforce/sfdx-scanner)
sf scanner run --target 'force-app/**/*.cls' --format table --engine pmd --pmdconfig ci/pmd-apex-rules.xml

# 4. Run the Experience Cloud guest-profile scanner against your sandbox
node tools/exp-cloud-scanner/index.js --target hardening-scratch

# 5. Run the Connected App attestation report
node tools/connected-app-attestation/attest.js --target hardening-scratch
```

## Doc-to-code map

Every file below maps to a specific whitepaper section. Open the whitepaper card, then jump to the implementing artifact.

### Pillar 1 — Identity & Authentication
| Whitepaper anchor | Artifact |
|---|---|
| [1.6 Apex SAML JIT handler](../index.html#i-custom-auth) → [App. A.1](../index.html#appendix-a) | [`force-app/main/default/classes/AcmeSamlJitHandler.cls`](./force-app/main/default/classes/AcmeSamlJitHandler.cls) |
| [1.4 Custom Login Flow](../index.html#i-login-flow) → [App. A.3](../index.html#appendix-a) | [`force-app/main/default/classes/LoginFlowConcurrentLimitController.cls`](./force-app/main/default/classes/LoginFlowConcurrentLimitController.cls) |
| Custom-metadata for IdP-group → PSG mapping | [`force-app/main/default/objects/IdP_Group_Permission_Mapping__mdt/`](./force-app/main/default/objects/IdP_Group_Permission_Mapping__mdt/) |

### Pillar 2 — Access Control
| Whitepaper anchor | Artifact |
|---|---|
| [2.2 PSG migration shape](../index.html#ii-permset-migration) → [App. E](../index.html#appendix-e) | `permissionsets/Base_Sales_User`, `Manager_Scope`, `Quote_Creator`; `permissionsetgroups/Sales_Manager` |

### Pillar 4 — Connected Apps & ECAs
| Whitepaper anchor | Artifact |
|---|---|
| [4.1 ECA transition](../index.html#iv-eca-transition) → [App. C.1](../index.html#appendix-c) | [`force-app/main/default/connectedApps/Acme_Integration.connectedApp-meta.xml`](./force-app/main/default/connectedApps/Acme_Integration.connectedApp-meta.xml) + ECA placeholder |

### Pillar 5 — API + mTLS
| Whitepaper anchor | Artifact |
|---|---|
| [5.1 Named Credentials](../index.html#v-named-credentials) → [App. C.2](../index.html#appendix-c) | [`force-app/main/default/namedCredentials/Treasury_API.namedCredential-meta.xml`](./force-app/main/default/namedCredentials/Treasury_API.namedCredential-meta.xml) |
| [5.2 Mutual TLS](../index.html#v-mtls) | External Credential placeholder |

### Pillar 8 — Detection & Response
| Whitepaper anchor | Artifact |
|---|---|
| [8.5 Transaction Security policies](../index.html#viii-transaction-security) → [App. D.1](../index.html#appendix-d) | [`force-app/main/default/classes/BlockHighVolumeBulkApi.cls`](./force-app/main/default/classes/BlockHighVolumeBulkApi.cls) + policy XML |
| [8.5 Report-export MFA gate](../index.html#viii-transaction-security) → [App. D.2](../index.html#appendix-d) | [`force-app/main/default/classes/ReportExportThresholdMfa.cls`](./force-app/main/default/classes/ReportExportThresholdMfa.cls) |
| [8.1 Health Check baseline](../index.html#viii-health-check) | [`baselines/health-check-custom-baseline.xml`](./baselines/health-check-custom-baseline.xml) |

### Pillar 3 — Experience Cloud audit (Appendix F dual-agent scanner)
| Whitepaper anchor | Artifact |
|---|---|
| [3.8 Automated scanner pattern](../index.html#iii-scanner) → [App. F](../index.html#appendix-f) | [`tools/exp-cloud-scanner/`](./tools/exp-cloud-scanner/) |

### Pillar 4 — OAuth attestation (Appendix O.4 quarterly cadence)
| Whitepaper anchor | Artifact |
|---|---|
| [4.9 OAuth Usage attestation](../index.html#iv-detection-attestation) → [App. O.4](../index.html#appendix-o) | [`tools/connected-app-attestation/`](./tools/connected-app-attestation/) |

### Pillar 9 — DevSecOps
| Whitepaper anchor | Artifact |
|---|---|
| [9.2 Static analysis as a gate](../index.html#ix-static-analysis) | [`ci/pmd-apex-rules.xml`](./ci/pmd-apex-rules.xml), [`ci/sfdx-scanner-config.json`](./ci/sfdx-scanner-config.json) |
| [9.4 CI deployment gates](../index.html#ix-deployment-approval) | [`ci/github-actions/`](./ci/github-actions/) |

### Data exports (machine-readable)
- [`data/checklist.json`](./data/checklist.json) — Appendix O Day-1 / Week-1 / Month-1 / Quarterly checklist as JSON
- [`data/glossary.json`](./data/glossary.json) — Appendix L glossary entries with cross-links
- [`data/risk-register.json`](./data/risk-register.json) — top-15 risk register with controls and residuals
- [`data/standards-mapping.json`](./data/standards-mapping.json) — NIST CSF / CIS CSC / ISO / SOC 2 / HIPAA / PCI / EU AI Act mappings

## Disclaimers (also in the whitepaper)

- **This is not official Salesforce documentation.** The author takes responsibility for all opinions and any errors. Where this code conflicts with official Salesforce documentation, official Salesforce documentation governs.
- **Code samples are illustrative.** Method signatures, interface contracts, and metadata-schema element names evolve across Salesforce releases. Validate against the current Apex Reference Guide and Metadata API Developer Guide for your target API version before deploying.
- **No warranty.** Provided "AS IS"; the author is not liable for damages arising from use.

## License

See [`../LICENSE`](../LICENSE) at the repo root.
