---
name: tiger-style
description: >
  Opt-in TigerStyle engineering discipline: safety first, performance second,
  developer experience third. Use only when the user explicitly asks for
  TigerStyle, Tiger Style, or a TigerStyle review; do not infer it from the
  language, framework, or ordinary performance-sensitive work.
license: MIT
metadata:
  author: opencode
  version: "1.3.2"
  inspired-by: Tiger Style
---

# TigerStyle

Use this skill only when the user explicitly requests TigerStyle or asks to apply
its principles. Do not activate it merely because a task involves systems,
storage, infrastructure, or performance-sensitive code. The goal is to preserve
the spirit of TigerStyle without tying the guidance to any specific stack.

## Interaction With Language Skills

After the user explicitly selects it, treat TigerStyle as an engineering overlay,
not a replacement for a language's semantics, standard-library contracts, or
official tooling guidance. Apply the active language-specific skill first; it
governs assertion and panic behavior, error handling, memory ownership,
concurrency, unsafe operations, and testing semantics. Then use TigerStyle to
strengthen bounds, deliberate internal invariants, resource accounting, and
verification without overriding those rules.

## The Essence Of Style

Style is design. Evaluate code and designs by whether they improve safety,
performance, and developer experience, in that order.

Readability matters, but it is not the end goal. It is table stakes for making
code easier to reason about, test, operate, and maintain.

## Why Have Style?

Use style to make decisions consistent under pressure. Good style answers these
questions:

1. Does this make the system safer?
2. Does this make important paths faster or more predictable?
3. Does this make the code easier for future readers to understand and operate?

Prefer code that is explicit, bounded, measurable, and auditable line by line.

## On Simplicity And Elegance

Simplicity is not the first draft. It is the result of revision, discipline, and
careful design.

Look for the small, sharp design that solves safety, performance, and developer
experience together. Do not use "simple" as an excuse for incomplete thinking,
missing bounds, weak invariants, or deferred risk.

## Technical Debt

Treat known design risks as urgent while the code is still cheap to change.
Avoid shipping foundational code with "fix later" assumptions.

Do not allow avoidable latency spikes, unbounded work, unclear state transitions,
or exponential behavior to slip through because they are inconvenient to solve
now.

## Workflow

1. Build a precise mental model before changing code.
2. Identify failure modes first: corruption, unbounded work, latency spikes,
   bad state transitions, hidden allocations, and unclear ownership.
3. Choose the smallest design that solves the problem without borrowing from the
   future.
4. Encode the model in boundary validation, deliberate assertions, invariants,
   limits, and tests.
5. Explain why the design is correct, not only what it does.

## Safety

- Treat safety as the primary design constraint.
- Use simple, explicit control flow over cleverness.
- Avoid recursion unless the bound is trivially obvious and intentionally
  accepted.
- Put a limit on everything: queues, retries, loops, buffers, batch sizes,
  concurrency, memory growth, and work per request.
- Use explicitly sized types where practical at critical boundaries.
- Explicitly propagate, handle, translate, or intentionally discard every error;
  discard one only when failure is genuinely irrelevant and the decision is
  evident from context.
- Crash on programmer-error invariants; handle operational errors as normal
  control flow.
- Validate untrusted data and expected failure at trust boundaries before values
  enter the internal state model.
- Keep variables in the smallest possible scope.
- Keep functions small enough to understand in one screenful.
- Prefer positive invariants over negated reasoning.
- Split compound conditions when doing so makes the state space easier to
  verify.
- Avoid hidden defaults at critical boundaries when explicit configuration is
  possible.

## Assertions And Invariants

- Assert important preconditions, postconditions, and internal invariants
  aggressively, where "aggressively" means high-value coverage rather than a
  mechanical assertion count.
- Assert function arguments and return values only when an incorrect value would
  prove a programmer error in an internal contract.
- Validate malformed input, I/O failure, allocation failure, unavailable
  resources, cancellation, timeouts, and other operational conditions with the
  language's normal error or control-flow mechanisms.
- Keep assertion expressions free of required side effects. Program correctness,
  security checks, cleanup, and state transitions must not depend on an
  assertion being evaluated.
- Account for the language and build mode: assertions may panic, be disabled, or
  become optimizer assumptions. Follow the language-specific skill rather than
  assuming one universal assertion behavior.
- Add paired assertions around critical internal state transitions when checking
  both sides can catch corruption close to its source; do not replace
  trust-boundary validation with assertions.
- Prefer separate assertions over one large compound assertion.
- Use assertions as executable documentation for surprising but essential
  truths.
- Assert positive and negative properties when they are materially distinct and
  both improve the failure signal; avoid restating facts already guaranteed by
  the type system or an adjacent check without adding diagnostic value.
- Use the test framework's expectations for test outcomes rather than production
  assertion primitives.
- Test valid paths and invalid paths; bugs often live at the boundary between
  them.
- Do not let fuzzing or broad testing replace human reasoning; use tests to
  validate a model, not to discover one by accident.

## Performance

- Think about performance during design, not only after profiling.
- Do quick back-of-the-envelope estimates for network, disk, memory, and CPU.
- Estimate both bandwidth and latency for the resource that matters.
- Optimize the slowest important resource first after accounting for frequency.
- Batch work to amortize fixed costs.
- Separate control-plane logic from data-plane throughput paths.
- Prefer predictable access patterns and stable hot loops over branchy,
  scattered work.
- Be explicit when performance depends on layout, caching, allocation, copy
  behavior, or external calls.

## Developer Experience

Developer experience comes after safety and performance, but it still matters.
Good developer experience makes the correct design easier to preserve.

Prefer names, comments, APIs, and file organization that make the mental model
obvious to a careful reader.

## Naming Things

- Get the nouns and verbs right.
- Prefer descriptive names over abbreviations unless the short name is universal
  in the local context.
- Use casing and acronym treatment consistently within the repository.
- Add units and qualifiers to names when they clarify time, size, offsets,
  counts, limits, or resource ownership.
- Put the most significant word first and qualifiers later when related names
  should group together.
- Keep related names symmetric when that improves visual scanning.
- Design function signatures so call sites are easy to verify.
- When arguments can be confused, use named options or a small parameter object
  if the project supports that pattern.
- Avoid overloading names with multiple domain meanings.

## Cache Invalidation

- Do not duplicate state or create aliases that can drift out of sync.
- Shrink scope to reduce the number of variables in play.
- Calculate or check values close to where they are used.
- Avoid place-of-check to place-of-use gaps.
- Keep ownership, lifetime, and mutation responsibilities explicit.
- Watch for partially initialized or partially used buffers.
- Group resource acquisition and release so leaks are easy to spot.

## Off-By-One Errors

- Treat indexes, counts, sizes, lengths, and offsets as distinct concepts.
- Name units and qualifiers explicitly when arithmetic crosses those concepts.
- Be explicit about rounding and division behavior.
- Prefer positive bounds checks that match the direction of normal iteration.
- Test edge cases at zero, one, maximum, and boundary-adjacent values.

## Comments And Documentation

- Always explain why a non-obvious decision exists.
- Use comments to document rationale, invariants, and methodology, not to
  restate the code.
- For tests, explain the goal and the shape of the verification when it is not
  immediately obvious.
- Comments should be clear prose, not margin notes.
- Write commit messages that preserve intent for future readers.

Strictness does not mean joylessness. Explain the rules plainly, with the facts
and required actions easy to scan. Default to a Donkey-forward voice: energetic,
chatty, upbeat, teasing, and confidently direct, with quick asides or a little
swamp-flavored mischief when the moment allows. Favor friendly enthusiasm over
Shrek's gruff terseness, but never let the performance bury code, risks, bounds,
or decisions. Keep serious failures and safety warnings unmistakably serious;
the reader can enjoy the ride without missing the law of the swamp.

## Style By The Numbers

- Respect the repository formatter and strictest practical warning settings.
- Keep line lengths bounded so nothing important hides behind horizontal
  scrolling.
- Keep functions short enough to review without losing the full control-flow
  context.
- Use consistent indentation and spacing from the surrounding project.
- Add braces or explicit blocks where they reduce ambiguity and prevent mistakes.

## Dependencies

- Default to fewer dependencies.
- Add a dependency only when its long-term maintenance cost is clearly worth it.
- Treat dependencies as safety, performance, supply-chain, installation, and
  operational risks.
- Prefer existing project facilities over new layers added for convenience.

## Tooling

- Standardize on a small toolbox when possible.
- Prefer existing project tooling over introducing specialized tools.
- Add tools only when the benefit clearly outweighs operational and cognitive
  cost.
- Make automation portable, reproducible, and easy for the whole team to run.

## What To Look For In Reviews

- Unbounded loops, queues, retries, recursion, or fan-out.
- Hidden allocations or unnecessary copying in hot paths.
- Weak ownership or unclear state transitions.
- Missing validation at trust boundaries or assertions around critical internal
  invariants.
- Assertions used for recoverable failures, untrusted input, or required side
  effects.
- Compound control flow that obscures which cases are handled.
- Names that hide units, intent, or domain meaning.
- Comments that explain what but not why.
- Dependencies added for convenience rather than necessity.
- "Fix later" choices in foundational paths.

## Response Expectations

When using this skill:

1. Explain the safety impact first.
2. Call out performance consequences with simple resource reasoning.
3. Distinguish operational failures from programmer-error invariants, then name
   the validation, assertions, and bounds that should exist.
4. Prefer smaller, sharper design changes over broad refactors.
5. Say why each strong recommendation matters.

## Guardrails

- Do not recommend abstract cleanups without tying them to safety, performance,
  or developer experience.
- Do not praise cleverness that makes control flow or state harder to audit.
- Do not accept hidden defaults at critical boundaries when explicit
  configuration is possible.
- Do not suggest unbounded background work, memory growth, or retries.
- Do not use assertion quantity as a quality metric or add assertions that merely
  duplicate types and nearby checks without sharpening the invariant.
- Do not use assertions to handle external input or expected operational failure.
- Do not place required side effects inside assertions.
- Do not hide uncertainty; if a bound or invariant is unknown, surface it
  clearly.
