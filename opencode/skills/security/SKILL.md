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
  version: "1.0.0"
---

# Security

Use this skill to find real, exploitable weaknesses before an attacker does.
Think like an attacker, report like an engineer: the goal is a prioritized,
reproducible account of what can go wrong and how to fix it — not a checklist
with green ticks. A clean scan is not proof of safety; it is the floor.

This skill is for auditing software you own or are explicitly authorized to
test. Stay defensive: prove risk to get it fixed, never to exploit it.

For resource-exhaustion and bounds issues, pair with `@tiger_style/`; to confirm
a fix actually behaves, use `@qa/`; to lock it in with a regression test, use
`@test_quality/`.

## Workflow

1. Confirm scope and authorization: what is in scope, what is off-limits, and
   that you may test it at all. If unclear, ask before probing.
2. Build a threat model: assets, trust boundaries, entry points, and the
   attacker whose reach you are reasoning about.
3. Map the attack surface from the model: every input, every privileged action,
   every secret, every external call, and the deployment around them.
4. Review against the high-impact vulnerability classes, following untrusted
   data from entry point to sink.
5. Verify suspected issues with the smallest safe proof of concept; do not
   report on suspicion alone.
6. Triage by impact and likelihood, then report each finding with location,
   reproduction, severity, and a concrete fix. Do not silently fix what you find.

## Threat modeling

- Identify assets worth protecting: credentials, PII, money movement, tokens,
  and the integrity of critical state.
- Map trust boundaries: where data crosses from less-trusted to more-trusted —
  network edges, process boundaries, and privilege changes.
- Enumerate entry points: every input the system accepts, including headers,
  query params, cookies, files, queues, webhooks, and inter-service calls.
- Name the attacker: unauthenticated outsider, authenticated user, malicious
  insider, or compromised dependency — each has different reach.
- Treat all input as hostile until validated at the boundary; validate by
  allowlist, not denylist.
- Assume any single control will fail; layer defenses so one bypass is not game
  over. Security has layers, like onions.

## What to review

Prioritize by blast radius. These classes cause most real breaches.

- **Injection:** untrusted input reaching an interpreter — SQL, NoSQL, OS
  commands, LDAP, XPath, template engines, or `eval`. Flag string-built queries
  and shelled-out commands; require parameterization and allowlists.
- **Cross-site scripting:** unescaped output in HTML, JS, attributes, or URLs.
  Check stored and reflected paths and any `innerHTML`-style escape hatches.
- **Authentication:** password storage (Argon2id, bcrypt, or scrypt — never fast
  hashes), session lifecycle, token issuance and expiry, MFA, account recovery,
  and credential-stuffing resistance.
- **Authorization:** every privileged action must check the *current* user's
  rights on the *specific* object. Hunt for IDOR (object IDs taken straight from
  the request), missing function-level checks, and confused-deputy paths.
- **Secrets:** hardcoded keys, tokens, and passwords in source, config, history,
  or logs. Verify secrets come from a vault or environment, not the repo.
- **Cryptography:** standard primitives only — no homemade crypto, no ECB, no
  static IVs or nonces, a CSPRNG for anything security-bearing, and correct
  TLS and certificate validation.
- **SSRF and request forgery:** server-side fetches of user-supplied URLs, and
  state-changing requests without CSRF defenses.
- **Deserialization and parsing:** native deserialization of untrusted data,
  XXE, zip and path traversal, and unbounded parsers.
- **Sensitive data exposure:** PII and secrets in responses, errors, logs, and
  analytics; over-broad API fields; missing encryption at rest.
- **Dependencies and supply chain:** known CVEs, unpinned or unverified
  packages, lockfile integrity, and risky install-time scripts.
- **Configuration and deployment:** debug mode in production, default
  credentials, permissive CORS, missing security headers, open buckets, and
  container or IaC misconfiguration.
- **Resource exhaustion:** unbounded loops, allocations, retries, or fan-out,
  and missing rate limits or quotas — see `@tiger_style/`.

## Tooling

Tools find the known and the obvious so human review can focus on logic and
context. Run what fits the stack; never read a clean scan as proof of safety.

| Purpose | Tool | Notes |
| --- | --- | --- |
| Dependency CVEs | `osv-scanner`, `trivy`, native (`cargo audit`, `npm audit`, `pip-audit`, `govulncheck`) | Run in CI; fail on known-exploitable |
| Secret scanning | `gitleaks`, `trufflehog` | Scan the working tree and full history |
| Static analysis (SAST) | `semgrep`, CodeQL, language security linters | Tune rules; triage every finding |
| Container and IaC | `trivy`, `checkov`, `tfsec`, `hadolint` | Images, Terraform, Dockerfiles |
| Dynamic testing (DAST) | OWASP ZAP, Burp Suite | Against a non-production target only |
| Fuzzing | language-native fuzzers, `AFL++` | For parsers and trust boundaries |

## Verifying findings

- A vulnerability is a claim until you can show the path from input to impact.
  Reproduce it before reporting.
- Prove exploitability with the smallest safe proof of concept — read a value
  you should not, do not drop a table.
- Test against a local or staging copy you control, never production data or
  third-party systems.
- Distinguish exploitable from theoretical: note preconditions, required
  privileges, and whether an existing control already blocks it.
- Confirm the fix closes the path and does not just hide the symptom.

## Triage and severity

- Rank by impact times likelihood, not by how clever the bug is.
- Impact is what the attacker gains: account takeover and remote code execution
  outrank a verbose error message.
- Likelihood is how reachable and how hard: unauthenticated and one request
  beats insider-only with physical access.
- Do not inflate severity to be heard, and do not bury a critical under a pile
  of informational lint.

## Reporting findings

- For each finding: location (`file:line`), vulnerability class with a CWE or
  OWASP reference, impact, reproduction, severity, and a concrete fix.
- Redact real secrets and PII; reference where they live, do not paste them.
- Give remediation the developer can apply, and prefer fixing the class, not the
  one instance.
- Recommend a regression test for each fix so the hole stays closed — see
  `@test_quality/`.
- State plainly what was reviewed, what was found, and what was out of scope. An
  honest "not reviewed" beats a false "secure".

## Guardrails

- Only assess software you own or are explicitly authorized to test; confirm
  scope before probing.
- No destructive, denial-of-service, or data-exfiltrating tests; prove the risk,
  do not cause the harm.
- Do not run exploits against production or third-party systems.
- Report findings; do not quietly weaponize them or leave a backdoor "for
  testing".
- Do not paste discovered secrets, tokens, or PII into reports, commits, or
  external services.
- Do not claim the system is "secure"; state what was reviewed, what was found,
  and what was out of scope.
- Do not drown real risks in low-value noise; verify before reporting and
  prioritize ruthlessly.
- For third-party or vendor issues, follow responsible disclosure.

## Response expectations

When using this skill:

1. Lead with the risk verdict and the highest-severity findings first.
2. Give each finding a location, impact, reproduction, severity, and fix.
3. Be honest about coverage: what was reviewed, what was not, and what you
   assumed.
4. Prefer concrete, class-level remediation over generic security advice.
5. Order findings by exploitability and impact, not by category.
