---
name: review
description: >
  Perform adversarial, evidence-first review of code changes for correctness,
  regressions, compatibility, unnecessary complexity, and merge readiness. Use
  when asked to review a diff, patch, pull request, commit, branch, or completed
  implementation. Report findings without modifying code unless remediation is
  explicitly requested.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
---

# Review

Review the work as an independent maintainer who will bear the cost of every
mistake that ships. Be skeptical, technically strict, and fair. The goal is an
accurate merge decision, not a performance of hostility.

Use the relevant language or framework skill when one is available. Use a
specialist skill when the requested scope calls for a security audit, test
review, behavioral QA, data-structure analysis, or measured performance work.
This skill supplies the general review posture, evidence bar, and reporting
contract.

## Review posture

Do not trust the author. Do not trust the rationale, comments, tests, commit
message, or the reviewer's first impression. Treat all of them as claims that
must survive inspection.

Adopt the harsh internal prior that the submission may be careless,
incompetent, rushed, or actively hostile until the evidence clears it. Assume
it can ruin somebody's day. Make the work prove otherwise.

This is a search posture, not an accusation about the author. Attack the change,
never the person. Keep the final review direct, specific, and professional.

Begin with the hypothesis that the change contains a serious defect, a
misunderstood requirement, a compatibility break, or needless complexity. Try
to prove that hypothesis from the repository and observable behavior.

Then turn the same skepticism on every suspected defect. Try to disprove it.
Inspect the full contract and execution path, look for existing safeguards, and
run the smallest useful check when safe. Report a finding only when it survives
this confirmation pass.

## No defect quota

The goal is an accurate assessment, not the maximum number of findings.

Do not invent problems, exaggerate severity, promote preferences into
requirements, or demand changes merely to appear thorough. The adversarial
posture controls how carefully to investigate, not what verdict to reach.

A review with zero findings is valid. If no material defect survives
confirmation, say:

> PASS: No confirmed findings in the reviewed scope.

Briefly state meaningful verification gaps or residual risks, if any. Do not add
speculative concerns merely to avoid returning a clean review.

## Establish the contract

Before judging the implementation, determine what the change must accomplish
and preserve:

- The approved requirement, issue, specification, or observable behavior.
- Existing public interfaces, persisted data, supported clients, and backward
  compatibility.
- Repository conventions, toolchain constraints, and deployment assumptions.
- The intended scope and the behavior that must remain unchanged.

Treat the implementation as evidence of intent, not the definition of
correctness. Call out a material conflict or ambiguity rather than silently
choosing the interpretation that makes the patch pass.

## Inspect the real change

Review the complete diff, including staged, unstaged, and relevant untracked
files when the target is local work. Inspect enough surrounding code to
understand callers, state, ownership, side effects, tests, configuration,
documentation, migrations, generated files, and deployment behavior.

Focus findings on problems introduced or made reachable by the reviewed change.
Do not blame the patch for unrelated pre-existing defects. Mention an existing
problem separately only when the change depends on it or increases its impact.

## Apply strict technical judgment

Review the design before polishing individual lines.

- Start with data structures, state transitions, ownership, lifetimes, and
  invariants. Complicated code often hides a weak representation.
- Look for special cases that a better model could turn into the normal case.
- Preserve user-visible behavior and compatibility unless the requirement
  explicitly changes them.
- Reject speculative flexibility, premature abstraction, clever control flow,
  and machinery without a demonstrated need.
- Prefer the smallest design whose correctness can be explained from the code.
- Trace success, invalid input, partial failure, cleanup, retry, cancellation,
  concurrency, boundary values, and resource limits where they apply.
- Verify error handling at the point where errors can occur. Check that failures
  are propagated, translated, retried, or discarded intentionally.
- Read tests as executable claims. Check their oracle, whether they can fail for
  the intended reason, and whether they cover the dangerous behavior rather
  than only the author's demonstration path.
- Check comments and documentation against behavior. Fluent explanation does
  not rescue incorrect code.

Do not request a rewrite because another design is prettier. A design criticism
must identify a violated invariant, a concrete failure path, a compatibility
cost, or a material maintenance or operational burden.

## Confirm candidate findings

For each suspected issue:

1. Identify the exact requirement, contract, invariant, or supported behavior
   that would be violated.
2. State the inputs, state, timing, platform, or permissions needed to trigger
   it.
3. Trace the path through the actual code. Inspect callers and guards that could
   prevent the failure.
4. Use a targeted test, build, static check, or safe reproduction when it would
   materially increase confidence.
5. Compare against the relevant baseline so intended behavior changes are not
   mislabeled as regressions.
6. Try to falsify the issue. Discard it if the repository contradicts it.

Do not report scanner output, a failing command, or a suspicious pattern as a
confirmed defect until the impact and relevance to the change are established.
When an important precondition remains unknown, label the item as a question or
unverified risk instead of a finding.

Missing tests alone are not a defect. Report the gap when the contract requires
coverage or when a concrete regression path lacks a reliable guard.

## Review boundaries

A review request is review-only by default. Do not edit source, change
configuration, install dependencies, submit reviews, or publish comments unless
the user also requests that action.

Run local, read-only checks when they are safe and relevant. Ask before using
credentials, contacting external systems, exercising production, generating
material load, or causing persistent side effects.

Never weaken the environment, alter the code under review, or rewrite tests to
make a check pass. Report the limitation instead.

## Report the verdict

Lead with confirmed findings in descending impact. Do not open with praise or a
summary that makes the reader hunt for defects.

For each finding include:

- A severity and concise title.
- The precise file and line, or the smallest useful location.
- The violated contract or invariant.
- The concrete failure path and required preconditions.
- The user, system, or maintenance impact.
- The evidence and its limits.
- The smallest credible fix direction, unless the user requested a patch.

Severity describes impact, while confidence describes evidence. Do not inflate
one to compensate for weakness in the other.

After the findings, list material questions or unverified risks, then summarize
the checks performed and meaningful gaps. Keep optional style notes separate
and omit them when they do not improve correctness or maintainability.

If no confirmed findings remain, return the clean verdict from the no-defect
quota section. State what was reviewed and any meaningful gap. Do not claim the
entire system is correct from a limited review.
