---
name: test_quality
description: >
  Write and review high-quality tests: deterministic, behavior-focused, and
  worth their maintenance cost. Use when writing new tests, reviewing test
  code, fixing flaky tests, or when the user asks if the tests are any good.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
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

## What not to test

- Trivial getters, framework behavior, and generated code.
- Exact copies of the implementation's logic restated as the expected value.
- Snapshot/golden tests for output nobody reviews on change.

## Guardrails

- Do not add a test that passes against a broken implementation.
- Do not silence or skip a failing test to make the suite green.
- Do not let test helpers grow logic complex enough to need their own tests.
- Do not chase coverage numbers; chase uncovered behaviors and edge cases.

## Response expectations

When using this skill:

1. Name the behavior each test protects and the failure it would catch.
2. Call out flakiness risks (time, ordering, shared state) explicitly.
3. Point out missing edge cases rather than praising the happy path.
4. Recommend deleting bad tests as readily as adding good ones.
