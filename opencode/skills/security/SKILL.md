---
name: security
description: >
  Audit software for real, exploitable security weaknesses: threat-model the
  system, review the high-impact vulnerability classes, verify findings safely,
  and report them with severity and concrete fixes. Use when asked to review
  security, find vulnerabilities, audit, threat-model, or harden a change.
license: MIT
metadata:
  author: opencode
  version: "1.2.0"
---

# Security

Use this skill to find real, exploitable weaknesses before an attacker does.
Think like an attacker and report like an engineer: produce a prioritized,
evidence-based account of what can go wrong and how to fix it, not a checklist
with green ticks. A clean scan is not proof of safety.

Stay defensive. Establish risk with the least-invasive evidence that is safe and
authorized; never cause the harm being demonstrated.

For resource-exhaustion and bounds issues, load the `tiger-style` skill only when
the user explicitly asks for TigerStyle. To confirm a fix behaves correctly,
load the `qa` skill. To add focused regression coverage, load the `test-quality`
skill.

## Engagement mode and authorization

- Determine the mode before starting: review-only, review-and-remediate, or
  retest. In review-only mode, report findings without modifying code. In
  remediation mode, preserve the evidence before applying the requested fix.
- A request to review code in the shared workspace authorizes source and
  configuration analysis plus local, isolated execution with synthetic data
  when it does not contact external services, use real credentials, mutate
  non-test data, consume material resources, or write outside the workspace and
  approved temporary locations.
- Before testing a deployed or external target, confirm written authorization or
  an applicable disclosure policy covering the exact targets, environments,
  accounts, dates, techniques, request-rate limits, data rules, third parties,
  contacts, and stop conditions.
- If active scope is unclear, continue only authorized non-invasive review and
  ask before sending traffic or executing intrusive tooling.

## Workflow

1. Establish the engagement mode, authorized scope, exclusions, data-handling
   rules, and stop conditions.
2. Build a threat model covering the architecture, data flows, assets, trust
   boundaries, attacker capabilities, assumptions, and security objectives.
3. Derive a review plan from the architecture and select applicable versioned
   standards or platform guidance rather than using a generic checklist alone.
4. Trace untrusted data and privileged actions from entry points through policy
   decisions to dangerous sinks and externally visible effects.
5. Before running tools, confirm their targets, network egress, credentials,
   request rate, package or plugin execution, and output destination.
6. Verify suspected issues with the least-invasive authorized evidence. If active
   verification would be unsafe or out of scope, report the evidence,
   preconditions, limitations, and confidence instead of suppressing the issue.
7. Record technical severity, remediation priority, and evidence confidence
   separately, then report findings in risk order.
8. In remediation mode, apply the smallest class-level fix, add a regression
   test, rerun relevant checks, document residual risk, and retest the original
   path.

## Threat modeling

- Model the system, dependencies, data flows and stores, trust boundaries, and
  privilege changes before enumerating threats.
- Identify confidentiality, integrity, availability, privacy, tenant-isolation,
  financial, safety, and operational assets and objectives.
- Name relevant attackers: unauthenticated outsiders, authenticated users,
  malicious insiders, compromised services, dependencies, build systems, or
  administrators.
- Enumerate entry points including APIs, headers, cookies, files, queues,
  webhooks, background jobs, inter-service calls, administrative paths, and
  deployment interfaces.
- For each meaningful threat, record mitigation, elimination, transfer, or
  explicit acceptance, plus an owner, verification criterion, and residual risk.
- Revisit the model after material architecture, dependency, trust-boundary, or
  feature changes and after incidents.

## Coverage baseline

- Derive coverage from the threat model. For web applications, use the current
  stable OWASP ASVS and WSTG as versioned baselines and mark areas reviewed, not
  applicable, or out of scope.
- For non-web software, supplement architecture-specific threats with the active
  language, platform, cloud, database, and deployment guidance.
- For product and build-lifecycle controls, select applicable practices from the
  current NIST SSDF. For AI or agentic systems, also use current AI-specific
  security guidance rather than treating them as ordinary request handlers.
- Prioritize by reachability and blast radius. A versioned baseline supports the
  review; it does not replace system-specific reasoning.

## What to review

- **Validation, injection, and output:** validate syntax and business semantics
  at trust boundaries. Prefer positive validation for constrained values; for
  free-form data enforce type, normalization, encoding, length, and resource
  limits. Validation does not replace parameterized APIs, safe interpreters,
  context-specific output encoding, or sanitization at dangerous sinks.
- **Authentication and sessions:** credential storage using current approved
  guidance, session lifecycle, token issuance and validation, MFA, recovery,
  revocation, replay resistance, and credential-stuffing controls.
- **Authorization:** deny by default and enforce policy at a trusted service
  layer for functions, objects, fields, tenants, delegation, and administrative
  actions. Test horizontal, vertical, cross-tenant, mass-assignment,
  stale-entitlement, service-to-service, and confused-deputy paths. A
  user-controlled identifier is not itself a vulnerability; missing policy is.
- **Business logic and concurrency:** workflow bypass, duplicate or reordered
  actions, replay, automation abuse, races, TOCTOU, idempotency, and integrity
  failures around money or critical state.
- **APIs and protocols:** OAuth/OIDC and self-contained tokens, GraphQL,
  WebSockets, gRPC, HTTP framing and cache behavior, webhooks, redirects, and
  architecture-specific trust transitions.
- **Secrets:** source, history, artifacts, logs, CI output, process state, and
  crash dumps. Prefer workload identity, short-lived credentials, and managed
  secret storage. Environment variables and mounted files are delivery
  mechanisms, not automatically secure storage.
- **Cryptography and data protection:** approved implementations and
  algorithm-specific rules for keys, IVs, nonces, randomness, TLS, and
  certificates. Require encryption where data classification, regulation, or
  the threat model requires it, and verify key separation and lifecycle.
- **Server-side requests and browser request forgery:** SSRF, destination and DNS
  validation, network egress, redirects, and CSRF where ambient credentials make
  cross-origin requests dangerous.
- **Files, deserialization, and parsing:** unsafe native deserialization, XXE,
  archive and path traversal, file-type confusion, decompression bombs,
  unbounded nesting, and parser memory-safety boundaries.
- **Native and runtime safety:** memory corruption, unsafe or FFI boundaries,
  integer overflow and truncation, runtime or sandbox escapes, privilege
  separation, compiler hardening, and unsafe interactions across language or
  process boundaries.
- **Dependencies and software supply chain:** deployed-version applicability,
  lock and integrity data, source-control and CI/CD permissions, untrusted pull
  request and workflow execution, runner and build isolation, protected release
  references, install scripts, SBOMs, provenance, signing, artifact integrity,
  compromised maintainers, and reachable known vulnerabilities.
- **Configuration and deployment:** fail-open behavior, debug settings, default
  credentials, CORS and security headers, public storage, IAM, containers, IaC,
  network exposure, observability, backup, and recovery configuration.
- **Detection and incident readiness:** security-event and administrative audit
  logging, actor and object attribution, sensitive-data redaction, log injection,
  tamper resistance, alertability, time synchronization, retention, and whether
  responders can reconstruct critical actions.
- **AI and agentic systems:** treat prompts, retrieved content, model output,
  memory, and agent-to-agent messages as untrusted. Review tool authority,
  identity propagation, data access and egress, delegation, approval boundaries,
  goal or memory poisoning, and unsafe execution of model-generated output.
- **Resource exhaustion:** unbounded loops, recursion, parsing, allocation,
  retries, queues, fan-out, concurrency, and missing limits, quotas, or rate
  controls. Load the `benchmark` skill only for authorized non-destructive capacity work.

## Tooling

Tools find known and obvious issues so human review can focus on logic and
context. Scanner output is a lead, not a confirmed vulnerability.

| Purpose | Tools | Safety and interpretation |
| --- | --- | --- |
| Dependency review | `osv-scanner`, `trivy`, native ecosystem tools | Confirm deployed version, applicability, reachability, advisory quality, exploit maturity, and compensating controls |
| Secret scanning | `gitleaks`, `trufflehog` | Prefer local scanning; do not verify discovered credentials or send them to external services |
| Static analysis | `semgrep`, CodeQL, language security linters | Tune rules and manually establish the reachable path and controls |
| Container and IaC | `trivy`, `checkov`, `hadolint` | Review effective deployment configuration, not templates alone |
| Dynamic testing | OWASP ZAP, Burp Suite | Use only within active authorization; prefer isolated non-production targets and synthetic data |
| Fuzzing | language-native fuzzers, `AFL++` | Sandbox targets, bound resources, and protect external dependencies |

Treat security tools as supply-chain dependencies. Prefer already-installed,
approved tools with a known version and integrity; verify their publisher and
source; pin versions, container digests, and CI actions to immutable references;
verify checksums, signatures, or attestations when available. Before running a
tool, check whether it executes package hooks or plugins, sends code or metadata
off-machine, verifies tokens online, creates traffic, or stores sensitive output.
Run with least privilege and bounded egress; use local targets, synthetic data,
and approved output locations by default.

## Safe verification

- Establish a complete path from attacker-controlled input or authority to the
  security impact using source, configuration, logs, controlled test accounts,
  synthetic records, non-sensitive canaries, or controlled callbacks.
- Do not access another party's data. Demonstrate authorization failures with
  tester-controlled accounts and synthetic objects or prove the missing policy
  through source and configuration analysis.
- Stop once the weakness is established. If sensitive data appears, stop,
  preserve only the minimum approved evidence, and follow the incident contact
  path.
- Do not authenticate with discovered secrets. Record only the secret type and
  location or an approved safe fingerprint, notify the owner, and have them
  rotate or revoke it. Perform rotation directly only when the engagement
  explicitly authorizes that operational action. Assess possible exposure
  through the incident process.
- Note prerequisites, privileges, user interaction, reachable controls, and
  whether a mitigation blocks the path in the assessed environment.
- Confirm that a fix closes the root-cause path and does not merely hide the
  symptom.

## Evidence confidence

- **Confirmed:** safely demonstrated within authorization using controlled data.
- **High:** a complete reachable source-to-sink or policy-bypass path is proven,
  but active exploitation is unnecessary or unsafe.
- **Medium:** the path is plausible but an important runtime control or
  precondition remains unverified.
- **Low:** based on incomplete context or scanner evidence; report it as a lead
  requiring validation, not as a confirmed vulnerability.

## Severity and remediation priority

- Record technical severity, remediation priority, and evidence confidence as
  separate fields.
- Technical severity describes the security consequence and exploit conditions.
  If CVSS is requested, use the current CVSS version and publish the score,
  vector, and nomenclature; do not label an informal judgment as CVSS.
- Remediation priority also considers environment and exposure, asset
  criticality, exploitation or KEV status, safety, privacy, regulation, business
  impact, available mitigations, and the cost of delay.
- Map the best-supported Base or Variant CWE to the root cause when useful. Do
  not guess, map to a broad CWE category, or treat CWE as a severity score.
- Do not inflate severity to be heard or bury a critical issue under
  informational scanner noise.

## Remediation and closure

- In review-only mode, do not change code without a request.
- In review-and-remediate mode, preserve the original finding, fix the
  vulnerability class rather than one payload, add focused regression coverage,
  and run both security checks and behavioral verification.
- Track accepted findings through owner assignment, priority, target date,
  remediation or documented risk acceptance, regression testing, retest, and
  closure.
- Escalate to incident response when evidence suggests prior exploitation,
  credential exposure, or unintended disclosure.
- Avoid unrelated hardening during a focused fix unless the user expands scope.

## Reporting findings

- Use one consistent finding shape: `ID · title · location · affected
  surface · preconditions · impact · safe evidence · technical severity ·
  remediation priority · confidence · root cause/CWE · fix · validation`.
- Include a precise CWE or OWASP reference only when it fits; do not force a
  taxonomy label onto uncertain evidence.
- Store evidence only in an approved access-controlled location and collect the
  minimum necessary material. Redact secrets and PII and avoid placing payloads
  or sensitive architecture in chat, public issues, commits, or unapproved
  external services.
- State what was reviewed, not applicable, and out of scope. An honest "not
  reviewed" beats a false claim that the system is secure.
- For third-party or vendor issues, use the approved responsible-disclosure
  channel and rules.

## Guardrails

- Do not actively probe a target without authorization for that exact target and
  method.
- Do not run destructive, denial-of-service, data-exfiltrating, persistence, or
  lateral-movement tests. Prove the risk without causing the harm.
- Do not actively exploit production unless the written rules of engagement
  explicitly authorize the exact method, data, rate, monitoring, and stop
  conditions.
- Do not use discovered credentials, access another party's records, create a
  backdoor, or leave test access behind.
- Do not transmit source, dependencies, findings, secrets, tokens, PII, or tool
  output to an external service unless explicitly approved.
- Do not suppress a credible issue merely because active exploitation is unsafe;
  label its evidence, limitations, and confidence.
- Do not claim the system is secure. State the assessed scope, evidence, and
  residual uncertainty.

## Response expectations

When using this skill:

1. Lead with the risk verdict and highest-priority confirmed or high-confidence
   findings.
2. Use the finding shape above and separate confirmed vulnerabilities from
   unverified scanner leads.
3. Be explicit about authorization, coverage, assumptions, exclusions, and
   residual risk.
4. In remediation mode, report the fix, regression coverage, verification, and
   remaining risk after the findings.
