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
  version: "1.0.0"
---

# QA

Use this skill to verify behavior by running it, not by reading the code.
Passing tests and a clean diff are not evidence that the feature works; QA is
about observing the real thing doing the real job.

## Workflow

1. Establish the acceptance criteria: what should work, for whom, and what
   counts as broken. If unstated, derive them from the ticket, PR description,
   or the change itself, and say which ones you assumed.
2. Run the application or feature in the most realistic environment available.
3. Walk the happy path first, end to end, exactly as a user would.
4. Probe the edges: empty states, boundary values, invalid input, repeated or
   concurrent actions, slow or failing dependencies, back/refresh/retry.
5. Check the side channels: logs, console, network responses, and persisted
   data — a clean UI on top of stack traces is not a pass.
6. Spot-check adjacent features the change could plausibly have broken.
7. Report findings; do not silently fix what you find.

## What to probe

- Inputs: empty, whitespace, very long, unicode, wrong type, injection-shaped.
- State: first run, no data, existing data, double-submit, stale session.
- Failure: dependency down, timeout, permission denied, mid-flow cancel.
- Boundaries: zero, one, limit, limit + 1, pagination edges, timezone edges.

## Reporting findings

- For each issue: reproduction steps, expected vs actual, severity, and any
  relevant log or error output.
- Severity is about user impact, not how interesting the bug is: data loss and
  broken core flows outrank cosmetic glitches.
- State plainly what was verified and passed, what failed, and what was not
  covered — an honest "not tested" beats a false green.

## Guardrails

- Do not report "works" based on code reading alone; only on observed behavior.
- Do not fix bugs mid-QA; report first, fix when asked. The exception is a
  blocker that prevents further verification — fix it, flag it, continue.
- Do not test only the demo path the author had in mind.
- Do not hide flaky or once-seen failures; report them with what you observed.

## Response expectations

When using this skill:

1. Lead with the verdict: pass, fail, or pass-with-issues.
2. List what was exercised and how, so the verification is reproducible.
3. Order issues by severity, each with steps and expected vs actual.
4. End with what was not covered and what would be worth testing next.
