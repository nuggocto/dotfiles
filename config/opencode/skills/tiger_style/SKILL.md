---
name: tiger_style
description: >
  Apply Tiger-style engineering principles: safety first, performance second,
  developer experience third. Use when reviewing or writing Go, Rust, or Odin
  systems code, performance-sensitive backends, storage engines, core
  infrastructure, or when the user wants a strict, disciplined coding style.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
  inspired-by: /home/bun/Downloads/TIGER_STYLE.md
---

# Tiger Style

Use this skill when the user wants a strict, systems-oriented coding style for Go, Rust, or Odin with strong opinions about safety, performance, simplicity, and disciplined implementation. This style is especially useful for storage engines, databases, distributed systems, infrastructure, and performance-sensitive backend code.

## Core priority order

Evaluate decisions in this order:

1. Safety
2. Performance
3. Developer experience

Readability matters, but only insofar as it improves those outcomes. Prefer code that is explicit, bounded, measurable, and easy to reason about under stress.

## Workflow

1. Build a precise mental model of the system before changing code.
2. Identify the failure modes first: corruption, unbounded work, latency spikes, bad state transitions, hidden allocations, and unclear ownership.
3. Look for the smallest design that solves the problem without borrowing technical debt from the future.
4. Encode the model in assertions, invariants, limits, and tests.
5. Explain why the design is correct, not just what it does.

## General posture

- Prefer simple, explicit control flow over cleverness.
- Prefer a few excellent abstractions over many convenient ones.
- Prefer bounded behavior over open-ended flexibility.
- Prefer proactive design work over reactive cleanup.
- Prefer code that can be audited line by line under pressure.

## Safety rules

- Treat safety as the primary design constraint.
- Avoid recursion unless the bound is trivially obvious and accepted by the user; iterative control flow is the default.
- Put a limit on everything: queues, retries, loops, buffers, batch sizes, concurrency, memory growth, and work per request.
- Use explicitly sized types where practical at critical boundaries.
- Handle all errors explicitly; do not ignore error values.
- Crash on programmer-error invariants; handle operational errors as normal control flow.
- Keep variables in the smallest possible scope.
- Keep functions small enough to understand in one screenful; split large functions by centralizing control flow in the parent and moving leaf work into helpers.
- Prefer positive invariants over negated reasoning.
- Split compound conditions when doing so makes the state space easier to verify.

## Assertions and invariants

- Assert preconditions, postconditions, and internal invariants aggressively.
- Add assertions at multiple points for the same critical property when data crosses boundaries.
- Prefer separate assertions over one large compound assertion.
- Use assertions as executable documentation for surprising but essential truths.
- Test both the valid path and the invalid path; bugs often live at the boundary between them.
- Do not let fuzzing or broad testing replace human reasoning; use tests to validate a model, not to discover one by accident.

## Performance rules

- Think about performance during design, not only after profiling.
- Do quick back-of-the-envelope estimates for network, disk, memory, and CPU.
- Optimize the slowest important resource first.
- Batch work to amortize fixed costs.
- Separate control-plane logic from data-plane throughput paths.
- Prefer predictable access patterns and stable hot loops over branchy, scattered work.
- Be explicit when performance depends on layout, caching, allocation, or copy behavior.

## Simplicity and technical debt

- Simplicity is not the first draft; it is the result of revision and discipline.
- Do not accept known technical debt as an easy shortcut for foundational code.
- Solve design risks while the code is still hot and cheap to change.
- Do not ship avoidable showstoppers with the intention of fixing them later.

## Naming and API design

- Take time to get nouns and verbs right.
- Prefer descriptive names over abbreviations, except in narrow low-level contexts where the meaning is obvious.
- Use consistent casing and acronym treatment within the language and repository.
- Add units and qualifiers to names when they clarify meaning, especially for time, size, offsets, counts, and limits.
- Design function signatures so call sites are easy to verify.
- When arguments can be confused, use a struct or named options pattern if the language supports it.
- Keep related names symmetric when that improves readability.

## Comments and documentation

- Always explain why a non-obvious decision exists.
- Use comments to document rationale, invariants, and methodology, not to restate the code.
- For tests, explain the goal and the shape of the verification when it is not immediately obvious.
- Write commit messages that preserve intent for future readers.

## Dependencies and tooling

- Default to fewer dependencies.
- Add a dependency only when its long-term maintenance cost is clearly worth it.
- Prefer the language's standard tooling and existing project tooling over introducing new layers.
- Standardize on a small toolbox when possible; too many tools add operational and cognitive cost.

## Language mapping

Apply the principles idiomatically rather than mechanically:

- In Rust, map the style to explicit ownership, assertions, bounded async/concurrency, and careful allocation behavior.
- In Go, map it to explicit error handling, bounded goroutines, small interfaces, and predictable package boundaries.
- In Odin, map it to explicit data layout, simple control flow, manual discipline around allocation and lifetimes, and strong boundary checks.

Do not force one language's idioms onto the other; preserve the spirit of explicitness, boundedness, invariants, and disciplined performance reasoning.

## What to look for in reviews

- Unbounded loops, queues, retries, recursion, or fan-out.
- Hidden allocations or unnecessary copying in hot paths.
- Weak ownership or unclear state transitions.
- Missing assertions around critical invariants.
- Compound control flow that obscures which cases are handled.
- Names that hide units, intent, or domain meaning.
- Comments that explain what but not why.
- Dependencies added for convenience rather than necessity.
- "Fix later" choices in foundational paths.

## Response expectations

When using this skill:

1. Explain the safety impact first.
2. Call out performance consequences with simple resource reasoning.
3. Name the invariants and bounds that should exist.
4. Prefer smaller, sharper design changes over broad refactors.
5. Say why each strong recommendation matters.

## Guardrails

- Do not recommend abstract "cleanups" without tying them to safety, performance, or developer experience.
- Do not praise cleverness that makes control flow or state harder to audit.
- Do not accept hidden defaults at critical boundaries when explicit configuration is possible.
- Do not suggest unbounded background work, memory growth, or retries.
- Do not hide uncertainty; if a bound or invariant is unknown, surface it clearly.
