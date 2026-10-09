---
name: zig
description: >
  Production-grade Zig guidance focused on explicit ownership, allocator
  lifetimes, error handling, comptime discipline, C interoperability, and
  reliable systems code. Use when working with Zig code, .zig files,
  build.zig, build.zig.zon, zig build/test/fmt commands, or native libraries,
  applications, and tooling written in Zig.
license: MIT
metadata:
  author: opencode
  version: "1.1.1"
---

# Zig

Use this skill for production-grade Zig applications, libraries, tools, systems
software, and C interoperability. Prefer the repository's established structure,
toolchain pin, build graph, allocation policy, and target matrix over generic
defaults.

Zig is pre-1.0 and intentionally changes language, standard-library, build, and
package APIs. Before relying on syntax or an API, run `zig version` and inspect
the repository's toolchain pin, `build.zig.zon`, `build.zig`, CI, and editor
configuration. Use the matching versioned language reference, standard-library
docs, release notes, installed source, and compiler help. Use master docs only
for a project pinned to a development build. Compile every generated example;
do not assume an older Zig example still works. For new projects, use Zig 0.17.0
(latest stable verified 2026-10-09). For existing projects, preserve the pin unless
an upgrade is part of the request, then move to the latest compatible release
after reviewing the migration notes. Read `references/toolchain-changes.md` when
the task depends on version-sensitive standard-library, build, package, testing,
or C-translation behavior.

For performance-sensitive, storage, engine, or infrastructure code, make bounds,
resource accounting, internal invariants, and measurements proportionate to the
program's actual constraints. Zig semantics govern errors, assertions, safety
modes, ownership, allocators, pointers, concurrency, FFI, and tests. Do not turn
application-specific storage-engine policies into universal Zig rules.

## Workflow

1. Identify the artifact and constraints: executable or library, pinned Zig
   version, supported targets, ABI boundaries, threading and I/O model, latency,
   memory and binary-size budgets, and deployment environment.
2. Start with `build.zig.zon`, `build.zig`, entrypoints, relevant `.zig` files,
   tests, generated inputs, foreign headers, and CI. Follow imports and callers
   until ownership, lifetime, error, layout, and feature contracts are clear.
3. Preserve existing modules, dependencies, allocation strategy, build steps,
   and target policy unless they are unsafe, broken, or block the request.
4. Before editing, account for every allocation, borrowed slice, resource handle,
   thread, callback, and generated artifact affected by the change.
5. Make the smallest change that keeps ownership, errors, state transitions,
   bounds, and synchronization visible.
6. Verify narrowly first, then exercise the repository's formatting, test,
   optimized-safety, release, target, fuzz, benchmark, and CI matrix as relevant.

## Source Hierarchy

When sources disagree, separate toolchain facts from project policy:

1. The exact compiler's behavior together with its matching language reference,
   standard-library and build-system source, compiler help, release notes, and
   relevant known issues. Stable releases can still contain compiler bugs or
   miscompilations, so review the issue tracker for critical code paths.
2. The repository's toolchain pin, build files, manifest, tests, and CI for the
   intended behavior and supported matrix; these do not override Zig semantics.
3. Current official design guidance when evaluating an upgrade.
4. Practitioner writing for rationale and production lessons, with its date and
   Zig version made explicit.

Blog posts and repositories may contain excellent ideas with obsolete syntax.
Preserve the principle, not an uncompiled code sample.

## Default Posture

- Prefer explicit data, control flow, ownership, and errors over hidden policy or
  framework-shaped abstraction.
- Prefer `const`; use `var` only when the binding or addressed value must mutate.
- Prefer useful initialized states. Use `undefined` only when every read is
  provably preceded by initialization, and keep that proof local.
- Prefer slices for bounded borrowed sequences. Use many-item, sentinel, C, and
  raw pointers only when the contract requires them.
- Prefer runtime safety in testing and production unless a documented, measured
  requirement justifies compiling a relevant module in ReleaseFast or
  ReleaseSmall. Treat `@setRuntimeSafety(false)` as a narrowly scoped unsafe
  optimization with a local proof; never make correctness or security depend on
  a check that may be disabled.
- Prefer the standard library and a small, integrity-pinned dependency set.
- Do not add comptime machinery, `inline`, custom allocators, unsafe casts, or
  concurrency before a concrete correctness, API, or measured performance need.

## Style And Names

- Run `zig fmt` and follow the repository's naming conventions. The official
  default is `TitleCase` for types and functions returning `type`, `camelCase`
  for other functions, and `snake_case` otherwise.
- Avoid redundant namespace names: prefer `json.Value` over `json.JsonValue`.
- Avoid vague names such as `Manager`, `Context`, `State`, `Data`, `utils`, and
  `misc` when a domain noun or verb can express the role.
- Name counts, indexes, byte sizes, offsets, capacities, durations, ownership,
  and units so arithmetic and resource policy are auditable.
- Use `///` for declaration documentation and `//!` for module documentation.
  Document ownership, lifetime, invalidation, errors, and safety requirements of
  public APIs.
- Use Zig's official terms "safety-checked Illegal Behavior" and "unchecked
  Illegal Behavior." `std.debug.assert` and `unreachable` express programmer
  assertions: violations panic when runtime safety is enabled and become
  optimizer assumptions with unchecked Illegal Behavior when it is disabled.
  Do not use "assume" as a synonym for all unchecked Illegal Behavior.

## APIs And Data Modeling

- Make ownership, borrowing, mutation, allocator choice, lifetime, nullability,
  thread restrictions, and invalidation rules evident in signatures and docs.
- Use distinct types, enums, error sets, and tagged unions to make invalid states
  unrepresentable and keep state transitions exhaustive.
- Use option structs when same-typed positional arguments are easy to swap or
  defaults encode important policy. Pass uniquely typed dependencies such as an
  allocator directly when that keeps the call clearer.
- Return borrowed slices or pointers only when the backing storage and its
  invalidation conditions are part of the contract.
- Do not infer ownership or allocation provenance from mutable metadata such as
  length or capacity. Store provenance explicitly when release behavior differs.
- Zig has no language-enforced move-only types. Treat copies of allocator-backed
  containers, owner-like structs, synchronization primitives, and foreign
  handles as ownership operations. Provide an explicit `clone` when duplication
  is valid; for transfer APIs, prefer a pointer-based operation that leaves the
  source in a documented empty or non-owning state. Ensure two value copies
  cannot both release the same resource.
- Prefer direct, concrete APIs. Add generic duck typing or reflection only when
  it removes real duplication or enforces a useful compile-time contract.

## Ownership And Allocation

- Zig does not have a borrow checker or automatic lifetime enforcement. Every
  allocation and resource needs one clear owner, lifetime, and release path.
- Libraries that allocate should normally accept `std.mem.Allocator` from the
  caller. Do not choose a process-wide allocator inside reusable code unless that
  policy is the API's purpose.
- Choose allocation by lifetime and constraints: stack or fixed buffers for
  small bounded storage, arenas for bulk lifetime release, pools for stable
  repeated shapes, and general-purpose allocators only where lifetimes vary.
- Pair the selected version's allocation and release operations correctly, such
  as `alloc` with `free` and `create` with `destroy`.
- Derive container initialization, allocator arguments, ownership transfer, and
  deinitialization from the selected standard library. Do not copy container
  examples from another Zig release.
- Put `defer` immediately after successful acquisition when lexical cleanup fits.
  Put `errdefer` immediately after each successful step that partial
  initialization must roll back.
- Treat `error.OutOfMemory` as a normal possible failure unless the application
  deliberately defines OOM as process-fatal. Test OOM paths when the API promises
  cleanup or recovery.
- Slices and pointers do not own storage. Container growth, replacement, or
  deinitialization can invalidate views and element pointers; do not retain them
  across mutation without an explicit stability guarantee.
- Do not return stack-backed, arena-backed, scratch, or temporary storage beyond
  its lifetime. Do not read uninitialized padding or expose it across an ABI,
  hash, equality, persistence, or network boundary.
- TigerBeetle's startup allocation and allocation-free main loop are excellent
  for its bounded storage engine, not a default for every Zig program. Adopt that
  model only when worst-case accounting and latency requirements justify it.

## Errors, Assertions, And Safety Modes

- Represent expected failure with error unions and optionals. Use `try` for
  propagation, `catch` for deliberate recovery or translation, and exhaustive
  `switch` handling when behavior differs by error.
- Prefer explicit error sets at stable public and function-pointer boundaries.
  Inferred error sets are useful internally but can change with implementation,
  become generic, complicate recursion, and widen compatibility impact.
- Handle, propagate, translate, or intentionally discard every error. Add context
  at I/O, parsing, allocation, process, and FFI boundaries without leaking
  secrets.
- Reserve assertions and panic for programmer defects and violated internal
  invariants. Validate malformed input, unavailable resources, OOM, I/O errors,
  timeouts, and cancellation through normal control flow.
- `unreachable` and `catch unreachable` assert that a path cannot occur. Use them
  only after a local proof; never use them to silence an unhandled operational
  error or invalid external input.
- Runtime-safety defaults apply per module: Debug and ReleaseSafe enable checks;
  ReleaseFast and ReleaseSmall disable them. `@setRuntimeSafety` can override a
  scope, and a build graph can mix module optimization modes. Record the modes
  of all relevant modules rather than inferring whole-artifact safety from one
  build flag.
- Keep assertion expressions free of required side effects. Use paired assertions
  for high-value internal state transitions when they improve defect detection,
  without replacing trust-boundary validation.
- Treat ordinary integer overflow as a design decision. Use checked operations
  when overflow is recoverable, wrapping operators only for intentional modular
  arithmetic, saturating operations only for intentional clamping, and explicit
  division semantics when rounding matters.

## Pointers, Layout, And Raw Bytes

- Prefer normal coercions. Use `@ptrCast`, `@alignCast`, pointer arithmetic, and
  integer-pointer conversion only with a precise representation, alignment,
  provenance, aliasing, lifetime, and bounds argument.
- Never let a safety-mode check be the only proof protecting an unsafe pointer
  operation in ReleaseFast or ReleaseSmall.
- Use `extern struct` or `extern union` only for an ABI contract and `packed`
  types only for deliberate bit layout. Verify size, alignment, offsets, backing
  types, endianness, and target assumptions at compile time and in tests.
- Verify packed, extern, enum, union, pointer-alignment, and vector rules against
  the selected compiler. Do not rely on apparent layout equivalence or compiler
  diagnostics as a complete lifetime proof.
- Do not compare, hash, persist, or transmit arbitrary structs as raw bytes until
  padding, pointers, endianness, and unique bit representation are proved.
- Parse untrusted formats field by field. Native struct layout is not a wire or
  disk format unless the format explicitly defines and verifies it.

## Comptime Discipline

Prefer ordinary functions and data where they suffice. When changing comptime,
reflection, generic instantiation, or compile-time performance, read
[references/comptime.md](references/comptime.md).

## Concurrency And I/O

- Give every thread, task, callback, queue, and I/O operation an owner, bounded
  lifetime, cancellation or stop policy, and join or completion policy.
- Prefer partitioned ownership and message passing over unrestricted shared
  mutable state. Bound thread creation, queues, fan-out, buffering, and work per
  event.
- Document the synchronization protecting each shared field. Use atomics only
  with a stated ordering argument; an ordinary flag is not synchronization.
- Keep lock scopes short and avoid invoking unknown callbacks or foreign code
  while holding a lock unless reentrancy and lock ordering are understood.
- Confirm allocator, container, and I/O object thread-safety before sharing them.
- I/O, process, reader/writer, task, and concurrency APIs are especially
  version-sensitive. Pass only required capabilities into reusable code and
  derive every task's ownership, completion, cancellation, and error behavior
  from the pinned standard library.

## Build, Packages, And Toolchain

Keep generated files and build actions in the repository's dependency graph.
For build, package, generated-code, or test-step changes, read
[references/build-packages.md](references/build-packages.md).

## C And Foreign Interoperability

Make ABI, ownership, release, and callback lifetime contracts explicit. For
foreign bindings, exported symbols, callbacks, or C translation, read
[references/ffi.md](references/ffi.md).

## Security Boundaries

- Load the `security` skill when a change creates or alters an authentication,
  cryptography, untrusted-file, network-data, path, command, plugin, parser,
  serialization, or privileged-operation boundary.
- Bound input, output, decompression, recursion, allocation, collection growth,
  concurrency, and work per request or event.
- Treat path handling as a traversal boundary, outbound networking as an SSRF
  boundary, process arguments as an injection boundary, and C libraries or
  foreign decoders as memory-safety boundaries.
- Validate length and offset arithmetic before allocation, slicing, copying, or
  pointer conversion. Check narrowing conversions and multiplication overflow.
- Use cryptographically secure randomness for secrets and avoid logging or
  retaining sensitive buffers. Use a guaranteed erasure mechanism only when the
  threat model requires it; an ordinary unused write may be optimized away.
- Review dependency hashes, build scripts, generated code, and foreign libraries
  as supply-chain inputs.

## Performance And Benchmarking

Measure before adding complexity for speed. For profiling, optimization, or
performance claims, read
[references/performance.md](references/performance.md) and use the `benchmark` skill.

## Testing, QA, And Verification

- Load the `test-quality` skill when writing or reviewing tests. Prefer specific
  `std.testing` expectations such as equality, slice, string, and exact-error
  checks over a generic boolean assertion when they improve diagnostics.
- Use `std.testing.allocator` for allocating unit tests so the default runner can
  report leaks. Inject allocator failure where OOM cleanup is part of the
  contract.
- When allocation-failure cleanup is contractual, use the selected standard
  library's allocation-failure test helper and satisfy its determinism and reset
  requirements. Do not ignore incomplete failure coverage.
- Test ownership and lifecycle edges: empty state, partial initialization, each
  `errdefer` path, allocation failure, growth invalidation, cleanup, and repeated
  initialization or deinitialization as permitted by the API.
- Test zero, one, maximum, maximum plus one, integer conversion, alignment,
  endianness, malformed input, error identity, and unsupported target behavior.
- Zig analyzes declarations lazily. Instantiate affected generic APIs and
  representative optional branches for supported targets; declaration-reference
  helpers alone do not establish behavior.
- Use randomized model tests, fuzzing, or deterministic simulation when they
  exercise meaningful invariants. Derive callback and command syntax from the
  selected toolchain. Preserve each reported crash input and replay it
  deterministically before fixing the bug.
- Combine leak-detecting Zig allocators with platform memory tools where
  supported, targeted reproductions, and regression tests for the exact
  ownership failure.
- When tests run through `zig build`, keep stdout free for the build-runner and
  test-runner protocol; use `std.testing` diagnostics or stderr for test output.
  `addTest` only compiles; execution needs a run step such as `addRunArtifact`.
  Label foreign-target checks as compile-only unless an emulator or target system
  actually ran them. Successful compilation is not evidence that tests executed.
- Load the `qa` skill when the change needs validation of the shipped executable
  or library integration as a real
  consumer. Unit tests and successful compilation do not verify packaging,
  startup, foreign loading, shutdown, or supported-platform behavior.

Derive exact commands from the repository and pinned compiler. A common baseline
is:

```sh
zig version
zig fmt --check build.zig src
zig build test
zig build
```

Use `zig test path/to/root.zig` when the project intentionally tests a source
root directly. Inspect `zig build --help` for project-defined steps and options.
Also test the affected optimized safety mode, release artifact, and target matrix.

## Guardrails

- Do not translate C, C++, Rust, or Go ownership patterns mechanically into Zig.
- Do not present TigerBeetle's project-specific limits or Ghostty's allocation
  choices as universal Zig requirements.

## Primary References

- Versioned Zig language and standard-library docs:
  `https://ziglang.org/documentation/`
- Official build-system guide: `https://ziglang.org/learn/build-system/`
- Zig downloads and release notes: `https://ziglang.org/download/`
- TigerBeetle architecture and deterministic simulation:
  `https://github.com/tigerbeetle/tigerbeetle/tree/main/docs`
- Mitchell Hashimoto's Zig writing: `https://mitchellh.com/zig`
- Mitchell Hashimoto's error-injection case study:
  `https://mitchellh.com/writing/tripwire`
- Ghostty memory-leak case study:
  `https://mitchellh.com/writing/ghostty-memory-leak-fix`
- Andrew Kelley's writing: `https://andrewkelley.me/`

## Response Expectations

For substantial changes using this skill, unless the user requests another format:

1. State the Zig version, target, ownership, lifetime, and safety-mode impact.
2. Call out allocator, error, layout, concurrency, comptime, and FFI contracts.
3. Explain performance choices from constraints and measurements, not slogans.
4. Point to version-matched Zig docs or source and identify historical guidance
   when rationale comes from an older article.
5. End with exact repository-appropriate format, test, build, optimized-safety,
   target, memory, security, QA, or benchmark verification performed.
