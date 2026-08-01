---
name: test_quality
description: >
  Write and review high-quality tests: deterministic, behavior-focused, and
  worth their maintenance cost. Use when writing unit, integration, end-to-end,
  property-based, or fuzz tests; reviewing test code; fixing flaky tests; or
  when the user asks if the tests are any good.
license: MIT
metadata:
  author: opencode
  version: "1.2.0"
---

# Test Quality

Use this skill when writing or reviewing tests. The goal is tests that fail
when behavior breaks, pass when it works, and stay cheap to read and maintain.
A test that cannot fail, or fails for unrelated reasons, is worse than no test.

## Workflow

1. Identify the behavior under test and the contract it protects.
2. Write the test against that behavior, not against the implementation.
3. Make the test fail once on purpose to confirm it fails for the right reason.
4. Cover the boundaries: zero, one, max, empty, invalid input, and error paths.
5. Run the suite repeatedly (and in parallel where supported) to catch flakiness
   before it lands.

## Behavior, not implementation

- Test through the public interface; avoid reaching into private state.
- A refactor that preserves behavior should not break the test.
- One test verifies one behavior; name it after that behavior, not the method.
- Keep arrange-act-assert visible; avoid logic (loops, conditionals) inside a
  single test case. Use table-driven tests for multiple cases of one behavior.

## Determinism and isolation

- No sleeps for synchronization; wait on conditions, channels, or fakes.
- Inject time, randomness, and IDs; never depend on wall clock or seed luck.
- No shared mutable state between tests; each test sets up and tears down its
  own data so order and parallelism never matter.
- A test that fails once in fifty runs is broken. Fix it or delete it; do not
  retry it into passing.

## Assertions

- Assert on concrete values and shapes, not just "no error" or "not nil".
- Assert the negative space too: what must not happen, what must not be
  returned, what must not be written.
- Prefer several precise assertions over one giant equality on a blob.
- Error-path tests assert which error, not merely that one occurred.

## Mocking

- Mock at real seams (network, clock, external services), not at every layer.
- Over-mocked tests verify the mock wiring, not the behavior; prefer real
  collaborators or integration tests when mocks would hide the bug.
- Never assert on incidental call counts or call order unless that ordering is
  the contract.

## Unit testing

- Use a unit test for a focused behavior whose dependencies can be supplied
  directly without recreating the system around it.
- Keep the setup smaller than the behavior being verified. Large fixture
  graphs usually mean the test boundary or production interface is wrong.
- Include valid, invalid, and boundary-adjacent inputs that can change the
  result. Do not generate cases merely to increase the test count.
- Verify state transitions, returned values, and important side effects through
  the unit's public contract. Do not test private helpers separately when the
  public behavior already covers them.
- Keep each case short enough that its inputs, action, and expected outcome can
  be audited together. Prefer a small table when cases share the same contract.
- Use real values and collaborators when they are cheap and deterministic;
  substitute only the dependency that makes the test unsafe, slow, or unstable.

## Integration testing

- Use an integration test when the risk lives at a real boundary: database
  queries, serialization, filesystem behavior, queues, network protocols, or
  communication between components.
- Exercise the real boundary implementation. Replacing the boundary with a mock
  turns the test into a unit test and can hide schema, protocol, and lifecycle
  defects.
- Use isolated, disposable resources owned by the test. Make setup and cleanup
  explicit, bounded, and safe on failure, timeout, and cancellation.
- Assert both sides of the contract where useful: the public response and the
  durable state, message, file, or request produced at the boundary.
- Test compatibility failures, malformed data, partial failure, timeout, and
  rollback behavior when those are credible operational risks.
- Keep fixtures minimal and local. Do not copy a production-sized dataset when
  a few records expose the same behavior more clearly and quickly.
- Do not repeat every unit case. Cover interactions and boundary behavior that
  isolated tests cannot establish.

## End-to-end testing

- Reserve end-to-end tests for critical user journeys that cross real system
  boundaries. Keep the suite small rather than repeating every unit-test case.
- Exercise the shipped entrypoint, binary, API, or UI instead of private
  application state. An internal component without a public journey has
  integration coverage, not end-to-end coverage.
- Use controlled real collaborators where practical. Never target unrelated
  user data, processes, services, or production systems without explicit
  authorization.
- Make the test own every process, socket, file, account, and record it creates.
  Guarantee cleanup on success, assertion failure, timeout, and cancellation.
- Use readiness signals, observable conditions, or deterministic IPC instead of
  sleeps. Give every helper and external operation a bounded timeout.
- Assert the complete public contract that matters: status or exit code, stdout,
  stderr, structured-output shape, durable effects, and important negative
  behavior such as forbidden writes or side effects.
- Run platform-dependent journeys on each supported native platform. A
  cross-compile check does not establish native end-to-end behavior.
- Treat intermittent end-to-end failures as defects. Preserve the first failure,
  identify the source of nondeterminism, and never retry the suite into green.
- End-to-end tests complement focused unit and integration tests; they do not
  replace either layer or exploratory QA.

## Property-based and fuzz testing

- Use property-based tests for invariants over a broad input space; use fuzzing
  for parser, protocol, state-machine, memory-safety, and trust-boundary code
  where generated inputs can expose failures humans will not enumerate.
- Define the model and invariant before generating inputs. Fuzzing validates a
  reasoned contract; it does not replace understanding the system.
- Bound every campaign by time, input size, operation count, recursion depth,
  memory, and concurrency. A test must not create unbounded work or resources.
- Make failures reproducible. Record the seed or crashing input, minimize it,
  and promote valuable regressions into small deterministic tests.
- Preserve and version a compact corpus containing structurally distinct,
  high-value inputs. Do not retain thousands of redundant cases.
- Check more than crashes when the contract permits: round trips, invariants,
  idempotence, resource limits, forbidden state transitions, and differential
  behavior against a trusted implementation.
- Run sanitizers and runtime safety checks when supported. Treat hangs,
  excessive allocation, and pathological latency as failures, not only panics
  or crashes.
- Keep fuzz targets narrow, fast, and free of unrelated I/O. Reset all mutable
  state between inputs so results do not depend on execution order.
- Separate bounded deterministic fuzz regression tests from longer campaigns.
  CI must have an explicit budget; extended campaigns belong in scheduled or
  dedicated jobs.

## What not to test

- Trivial getters, framework behavior, and generated code.
- Exact copies of the implementation's logic restated as the expected value.
- Snapshot/golden tests for output nobody reviews on change.
- Combinatorial case dumps where boundary analysis or one stated invariant
  provides the same confidence with less code and runtime.

## Guardrails

- Do not add a test that passes against a broken implementation.
- Do not silence or skip a failing test to make the suite green.
- Do not let test helpers grow logic complex enough to need their own tests.
- Do not chase coverage numbers; chase uncovered behaviors and edge cases.
- Put explicit limits on test duration, generated input size, retries,
  concurrency, and resources. No test is allowed unbounded work.
- Delete redundant, unreadable, or low-signal tests. Test volume is not test
  quality.

## Response expectations

When using this skill:

1. Name the behavior each test protects and the failure it would catch.
2. Call out flakiness risks (time, ordering, shared state) explicitly.
3. Point out missing edge cases rather than praising the happy path.
4. Recommend deleting bad tests as readily as adding good ones.
5. State whether coverage is unit, integration, end-to-end, property-based,
   fuzz, or exploratory QA; do not label an internal-component test as
   end-to-end.
