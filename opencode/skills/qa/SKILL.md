---
name: qa
description: >
  Verify that a feature or fix actually works before it ships: run it,
  exercise it like a real user, probe edge cases and error states, and report
  findings with reproduction steps. Use when asked to QA, verify, smoke-test,
  or sanity-check a change.
license: MIT
metadata:
  author: opencode
  version: "1.1.0"
---

# QA

Use this skill to verify release behavior by running the product and observing
the result. Passing automated tests, static checks, and code review are relevant
but insufficient evidence that a feature is fit to release; combine them with
end-to-end behavior and state the limits of every evidence source.

Keep `@qa/` focused on observed release behavior. Use `@security/` for
authorized adversarial testing, `@test_quality/` for automated tests and flaky
test remediation, `@benchmark/` for non-browser performance measurement, and
`@web-perf/` for browser performance and Core Web Vitals. QA may run safe
acceptance checks but must not claim a security, accessibility, or performance
audit unless that specialist scope was exercised.

## Workflow

1. Establish acceptance criteria and test oracles from approved requirements,
   user outcomes, API or protocol contracts, prior supported behavior, and
   product decisions. Treat the implementation as a scope clue, not the sole
   definition of correct behavior. Record assumptions and conflicts.
2. Perform change-impact and risk analysis: changed surfaces, affected users and
   roles, shared components, data and schema, integrations, background work,
   feature flags, supported clients, upgrade or rollback, and failure impact and
   likelihood.
3. Before execution, confirm the authorized target, build or artifact, accounts,
   allowed actions and side effects, test data, stop conditions, and cleanup
   plan. Prefer an isolated local or staging environment.
4. Record the initial environment and existing noise before testing so unrelated
   console errors, logs, or dirty data are not attributed to the change.
5. Start with the highest-value release check for the identified risk: smoke,
   happy path, data integrity, recovery, migration, rollback, or permission
   behavior. Do not force the happy path to be first when another failure would
   dominate release risk.
6. Exercise the feature end to end as a real supported user, then use time-boxed
   exploratory charters for boundaries, alternate state, interruption,
   concurrency, and dependency failure.
7. Inspect side channels and durable effects: logs, console, network responses,
   events, queues, files, database state, and cleanup. A clean UI over stack
   traces or corrupt state is not a pass.
8. Run justified regression checks across affected callers, contracts, shared
   components, permissions, persistence, jobs, flags, and supported clients.
9. Restore the agreed state, verify cleanup, and report any residual test data or
   side effects.
10. Report findings and the release verdict without silently changing the tested
    build, configuration, dependencies, or data.

## Test dimensions

- **Inputs:** empty, whitespace, long, Unicode, malformed, wrong type,
  normalization, and boundary-sized values. Use `@security/` before adversarial
  or intrusive payloads.
- **State:** first run, no data, existing data, stale data, stale session,
  repeated action, double-submit, refresh, back navigation, and retry.
- **Identity and permissions:** supported roles, unauthenticated behavior,
  expired access, ownership changes, and tenant boundaries where applicable.
- **Failure and recovery:** dependency unavailable or slow, timeout, permission
  denied, cancellation, partial completion, restart, retry, idempotency, and
  rollback.
- **Boundaries:** zero, one, typical, limit, limit plus one, pagination,
  timezone, locale, clock, storage, and quota edges.
- **Lifecycle:** install, startup, migration, upgrade, downgrade, rollback,
  shutdown, and restart when the change affects those paths.
- **Compatibility:** supported browser, OS, device, viewport, runtime,
  locale/timezone, network condition, and feature-flag combinations based on the
  product's support matrix.
- **Accessibility:** for applicable user-facing changes, spot-check keyboard
  operation, focus order and visibility, accessible names and errors, zoom or
  reflow, contrast, and screen-reader-critical behavior. Do not infer WCAG
  conformance from automation or an accessibility-tree snapshot alone.

## Environment and evidence

Record enough context to reproduce the run:

- Build commit, artifact SHA or image digest, dirty state, date, and time.
- Target environment and URL, material configuration and feature flags, and
  dependency state.
- Account, role, and synthetic test-data identifiers without exposing secrets or
  personal data.
- Browser, OS, device, viewport, runtime, and tool versions when applicable.
- Exact commands or user steps, preconditions, expected oracle, actual result,
  and relevant artifact, trace, screenshot, log, or network evidence.
- Any deviation from the planned environment, test data, or procedure.

Preserve representative pass evidence and all failure evidence. Redact secrets,
tokens, personal data, and sensitive internal details before reporting or
storing artifacts.

## Intermittent results

- Preserve the first failure. A later pass does not erase it.
- Repeat only under a stated diagnostic protocol on the same build and controlled
  environment and data. Record every outcome, count, timing, seed or order, and
  suspected product, test, or infrastructure cause.
- Do not retry until green. Use `INCONCLUSIVE` while a release-relevant
  intermittent result remains unexplained, `BLOCKED` when infrastructure
  prevents useful execution, and `FAIL` when evidence supports a product defect.
- Route automated-test flakiness investigation and repair to `@test_quality/`.

## Verdicts

- **PASS:** the agreed acceptance and exit criteria were exercised and met with
  no release-blocking issue in the tested scope.
- **PASS WITH KNOWN ISSUES:** criteria were met and only explicitly non-blocking
  issues remain; list them and the residual risk.
- **FAIL:** a release criterion failed or evidence shows a release-blocking
  product risk.
- **BLOCKED:** a missing prerequisite, inaccessible environment, credentials,
  data, or infrastructure prevented meaningful execution.
- **INCONCLUSIVE:** evidence is insufficient, contradictory, intermittent, or
  requirements are materially ambiguous.

State the release recommendation separately as `ship`, `hold`, or `no
recommendation`. QA supplies evidence and residual risk; the named decision
owner makes the release decision.

## Reporting findings

- For each issue include title, environment and build, preconditions,
  deterministic reproduction steps or observed frequency, expected result,
  actual result, user impact, severity, evidence, and affected scope.
- Severity describes impact. Track release priority separately using likelihood,
  exposure, recoverability, affected users, and available workarounds.
- Report what passed, failed, was blocked, was inconclusive, and was not covered.
  An honest "not tested" beats a false green.
- List the regression checks selected and why, plus exclusions and residual
  risk.

## Guardrails

- Do not use production merely because it is the most realistic environment.
  Production testing requires explicit authorization for the exact actions and
  effects.
- Do not trigger real payments, emails, messages, webhooks, destructive writes,
  load, or third-party effects unless explicitly authorized and controlled.
- Use synthetic or minimal data, label test artifacts, restore the agreed state,
  and report anything that could not be cleaned up.
- Do not modify the product, build, configuration, dependencies, or data to get
  past a blocker. Report `BLOCKED` and request direction.
- If a fix is explicitly authorized, preserve the original evidence, identify
  the intervention as a new build or baseline, and rerun affected checks from
  setup. Never present the modified run as the original result.
- Do not report "works" from code reading alone, and do not test only the demo
  path the author expected.
- Do not hide intermittent or once-seen failures, retry until green, or downgrade
  them without evidence.
- Do not expose secrets, tokens, personal data, or sensitive production records
  in screenshots, logs, reports, or external tools.

## Response expectations

When using this skill:

1. Lead with the QA verdict and the separate release recommendation.
2. Identify the exact build, environment, data, and accounts exercised.
3. List release-blocking findings first, each with reproducible steps or observed
   frequency, expected versus actual behavior, impact, and evidence.
4. Summarize passed checks, regression scope, cleanup, and residual risk.
5. End with blocked, inconclusive, and untested areas and the smallest next step
   needed to reduce uncertainty.
