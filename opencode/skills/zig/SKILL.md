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
  version: "1.1.0"
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
do not assume an older Zig example still works.

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
- In Zig 0.16, initialize allocator-external `std.ArrayList(T)` with `.empty` or
  `initCapacity`, and pass the same allocator to allocation, ownership-transfer,
  and `deinit` operations. Do not copy older managed-container examples;
  `ArrayListUnmanaged` is now a deprecated alias.
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
- Current Zig forbids pointers in packed structs and unions, requires packed
  union fields to fill the backing integer, and requires explicit tag or backing
  types for enum or packed types in extern contexts. Treat explicitly aligned
  and naturally aligned pointer types as distinct even where coercion exists.
- Runtime-known vector indexes are invalid; iterate or convert to an array. Do
  not rely on vector/array pointer coercions merely because layouts appear equal,
  and do not mistake diagnostics for obvious local-address escapes for complete
  lifetime checking.
- Do not compare, hash, persist, or transmit arbitrary structs as raw bytes until
  padding, pointers, endianness, and unique bit representation are proved.
- Parse untrusted formats field by field. Native struct layout is not a wire or
  disk format unless the format explicitly defines and verifies it.

## Comptime Discipline

- Use `comptime` to require compile-time values, generate types or tables, select
  platform implementations, and make unsupported states fail compilation.
- Prefer ordinary functions and data when they work at both compile time and
  runtime. Do not use comptime as a blanket optimization or abstraction system.
- Keep reflection focused and readable. Exhaustive tagged-union transformations
  and generated bindings can justify it; replacing straightforward code usually
  does not.
- On Zig 0.16, use the individual type-creating builtins such as `@Int`,
  `@Pointer`, `@Fn`, `@Struct`, `@Union`, `@Enum`, and `@Tuple`; `@Type` was
  removed and error sets must be declared with `error{...}` rather than reified.
- Use `inline` only when semantics require inline iteration or measurement proves
  the trade. Do not raise the evaluation branch quota before examining the
  algorithm and generated work.
- Audit compile time with the pinned compiler's supported timing facilities. In
  Zig 0.16, `zig build --time-report` forces a full rebuild, reports detailed Zig
  source compilation timing, and implies `--webui`; inspect build-runner work,
  linking, generated code, binary size, and cache behavior separately. Do not
  assume `comptime` or `inline` is free.
- Zig lazily analyzes declarations and, since 0.16, lazily resolves container
  types. A struct or file struct, union, enum, or opaque type resolves only when
  its size or a field type is required. Importing a module, using a type as a
  namespace, or forming a non-dereferenced `*T` does not prove that `T` resolves.
  CI must instantiate supported generic APIs, reference optional branches, and
  force representative field-dependent use for every supported target and
  feature combination. In 0.16, `std.testing.refAllDecls` references
  declarations in tests, but it does not force field resolution, instantiate
  generic call sites, cover target-dependent branches, or replace behavior tests.

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
- Zig's I/O and concurrency APIs are especially version-sensitive. Derive exact
  types and lifecycle behavior from the pinned standard library rather than old
  examples.
- Zig 0.16 introduced `std.Io`; standard-library operations that may block or
  introduce nondeterminism generally require an explicit `std.Io`. `main` may
  take no parameter, `std.process.Init.Minimal`, or `std.process.Init`. A
  parameterless `main` has no standard-library access to arguments or the
  environment; `Init.Minimal` supplies raw forms, while `Init` also supplies
  allocators, a default `Io`, a parsed environment map, and preopens. Pass only
  required values and capabilities into reusable code. Do not mechanically port
  0.15 filesystem, process, synchronization, Reader, or Writer APIs: files and
  directories moved under `std.Io`, Io-task synchronization moved from
  `std.Thread`, and APIs including `std.Thread.Pool`, `GenericReader`,
  `AnyReader`, and `FixedBufferStream` were removed. `std.Io.Evented` remains
  experimental.
- Treat every Zig 0.16 `std.Io.Future(T)` as a single-owner lifecycle obligation:
  call `await` or `cancel` on every exit path, and do not copy or concurrently
  operate on a live Future. Both operations release the task resource and return
  the callee's full result. Deferred cancellation must therefore handle errors
  and release any resource returned by a task that completed despite the
  cancellation request. `io.async` is infallible and may call the function to
  completion before returning. Use `io.concurrent` only when concurrent caller
  progress is required for correctness; handle `error.ConcurrencyUnavailable`,
  which can mean temporary resource exhaustion or unsupported concurrency.
  Derive exact APIs from the pinned release because master continues to change.

## Build, Packages, And Toolchain

- Treat `build.zig` as code that declares a dependency graph. Use explicit step
  dependencies and lazy paths; do not perform build actions eagerly while
  constructing the graph.
- Use `standardTargetOptions` and `standardOptimizeOption` when creating a new
  conventional project, unless the artifact intentionally constrains them.
- Do not hardcode `zig-out` or cache paths, mutate source files during a normal
  build, or bypass the graph for generated files.
- `addTest` creates a test compilation artifact; it does not execute tests. For
  host-runnable targets, connect `addRunArtifact` to the test step. For foreign
  targets, run through a configured emulator or system integration when
  execution is required; otherwise label the check as compile-only and never
  report that the tests ran.
- Zig 0.16 package identity is the pair of enum-literal `.name` and
  `.fingerprint`. Preserve the fingerprint for new versions of the same project,
  continuations of abandoned projects, and temporary `--fork` overrides. For a
  permanent fork of a maintained upstream, delete the root package's fingerprint
  and run `zig build` to generate a new identity. Dependencies with no
  fingerprint or a string rather than enum-literal name are rejected. Declare an
  accurate `.minimum_zig_version`. Audit `.paths` because only selected files are
  hashed and retained after fetching; include all build inputs and licenses. For
  URL dependencies, `.hash` identifies the contents and the URL is only a
  retrieval location. `.path` dependencies have no package hash. Package fetches
  use the project-local `zig-pkg` directory, while the global cache retains
  canonical compressed package data; keep ignore files and `.paths` aligned with
  every required generated input, source file, and license.
- In Zig 0.16, `zig build --fork=PATH` provides an ephemeral project override.
  `PATH` must contain `build.zig.zon`; matching packages anywhere in the
  dependency tree resolve by `.name` and `.fingerprint`, ignoring `.version` and
  before fetching. An override that matches nothing is an error. Preserve the
  upstream fingerprint for this workflow. Use a manifest `.path` dependency only
  when the local dependency is intentionally persistent. Inspect all manifest,
  fingerprint, path, and hash changes after package commands.
- Treat generated bindings and source as generated: modify the source header,
  schema, or generator input, then regenerate with the pinned toolchain.
- Keep tests, fuzzers, benchmarks, validation, and release artifacts discoverable
  as named `zig build` steps when the repository build graph owns them.

## C And Foreign Interoperability

- Match the foreign ABI exactly: calling convention, symbol, integer width and
  signedness, layout, alignment, nullability, sentinel, ownership, and callback
  lifetime.
- Prefer C ABI types and narrow checked wrappers around raw declarations. Convert
  pointer-plus-length inputs to slices only after validating the pair.
- Keep C pointers such as `[*c]T` at translated or ABI boundaries rather than in
  ordinary handwritten Zig APIs.
- Specify who allocates and frees every foreign object. Keep allocation and
  deallocation on the same side unless the foreign API provides a matching
  release function.
- Keep callback state alive until the foreign library cannot call it again. Catch
  and translate recoverable Zig errors before returning through a C ABI. Do not
  rely on recovering from a Zig panic: the default panic path aborts or traps
  rather than unwinding. Catch foreign exceptions on the foreign side so they do
  not unwind through Zig frames.
- C translation is version-sensitive. In Zig 0.16, `@cImport` remains available
  but is deprecated, and translation uses Aro rather than libclang. Prefer
  `b.addTranslateC`, expose `createModule()` through the root module's imports,
  and consume it with `@import("name")`. Check the exact selected release rather
  than inferring a stable API from master.
- Verify bindings on every supported target ABI. Cross-compilation is a Zig
  strength, not evidence that an untested target-specific ABI is correct.

## Security Boundaries

- Load `@security/` for authentication, cryptography, untrusted files or network
  data, paths, commands, plugins, parsers, serialization, or privileged actions.
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

- Think from data layout, access patterns, allocation, copying, branch behavior,
  and the slowest relevant resource. Estimate network, disk, memory, and CPU
  before optimizing.
- Batch fixed-cost I/O, allocation, synchronization, and foreign calls. Keep hot
  loops simple and separate control-plane branching when measurement supports it.
- Use `@benchmark/` for performance claims. Benchmark a correct production-like
  artifact in the intended optimization and safety mode, and report compiler
  version, target CPU, allocator, linking, LTO, and relevant build options.
- Do not benchmark Debug unless Debug performance is the question. Compare
  ReleaseSafe and ReleaseFast only when their different safety policies are
  acceptable and explicitly reported.
- Measure allocations, peak memory, binary size, startup, and tail behavior in
  addition to throughput when those resources matter.
- Do not assume zero-copy, packed layout, custom allocation, comptime generation,
  or unchecked access is faster. Include lifecycle and maintenance cost, then
  prove the effect with representative measurements.

## Testing, QA, And Verification

- Use `@test-quality/` when writing or reviewing tests. Prefer specific
  `std.testing` expectations such as equality, slice, string, and exact-error
  checks over a generic boolean assertion when they improve diagnostics.
- Use `std.testing.allocator` for allocating unit tests so the default runner can
  report leaks. Inject allocator failure where OOM cleanup is part of the
  contract.
- In Zig 0.16, when allocation-failure cleanup is contractual, prefer
  `std.testing.checkAllAllocationFailures`. Its test function must accept a
  `std.mem.Allocator` first, return `!void`, reset shared state on every run, and
  have deterministic allocation behavior. Accept `SwallowedOutOfMemoryError`
  only for intentional OOM recovery. `NondeterministicMemoryUsage` means not all
  allocation points were covered and should normally be fixed, not ignored.
- Test ownership and lifecycle edges: empty state, partial initialization, each
  `errdefer` path, allocation failure, growth invalidation, cleanup, and repeated
  initialization or deinitialization as permitted by the API.
- Test zero, one, maximum, maximum plus one, integer conversion, alignment,
  endianness, malformed input, error identity, and unsupported target behavior.
- Use randomized model tests, fuzzing, or deterministic simulation when they
  exercise meaningful invariants. Zig 0.16 `std.testing.fuzz` callbacks receive
  `*std.testing.Smith`, not the older `[]const u8`. Run the build step containing
  the fuzz tests with `zig build <step> --fuzz` for unlimited fuzzing or
  `--fuzz=N` for a bounded iteration count. Unlimited mode enables the Web UI and
  can use multiple workers controlled by `-j`; bounded mode uses one worker.
  Preserve the reported crash file and replay it deterministically through
  `std.testing.FuzzInputOptions.corpus`, commonly with `@embedFile`, before fixing
  the bug.
- Follow Mitchell Hashimoto's practical pattern: combine leak-detecting Zig
  allocators with platform memory tools, Valgrind where supported, targeted
  reproductions, and regression tests for the exact ownership failure.
- When tests run through `zig build`, keep stdout free for the build-runner and
  test-runner protocol; use `std.testing` diagnostics or stderr for test output.
  Successful test compilation is not evidence that tests executed.
- Use `@qa/` to exercise the shipped executable or library integration as a real
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

## Practitioner Lessons

- Language features and test suites complement rather than replace careful
  design, review, targeted failure testing, fuzzing, and prompt bug repair.
  Practitioner-specific lessons should be tied to a dated source and translated
  to the selected Zig version.
- Mitchell Hashimoto and Ghostty: allocation provenance must be explicit;
  mutable size metadata is not ownership. Install `errdefer` cleanup immediately,
  reproduce rare paths, and use multiple memory-debugging tools.
- TigerBeetle: bound resources, model performance before implementation, assert
  important internal contracts, use fixed-width domain values, and combine
  randomized model tests with deterministic fault simulation.
- These are transferable methods, not APIs to copy blindly. Ghostty's dynamic
  pools, libxev's caller-owned operation storage, and TigerBeetle's startup
  allocation solve different constraints.

## Review Checklist

- Is the exact Zig version known, and do syntax, stdlib, build, and package APIs
  match it?
- Does every allocation, view, handle, thread, callback, and foreign object have
  an explicit owner and bounded lifetime?
- Can mutation invalidate retained slices or pointers, or can copying duplicate
  owner-like state?
- Are expected errors handled as data and internal invariants asserted without
  relying on disabled safety checks?
- Are integer, length, offset, alignment, layout, and raw-byte assumptions proved?
- Is comptime use smaller and clearer than the runtime or generated alternative,
  and are all lazy branches compiled in CI?
- Are untrusted inputs, allocation growth, queues, retries, recursion, and work
  bounded?
- Do Debug, ReleaseSafe or the shipped safety mode, tests, release artifacts,
  affected targets, and relevant memory tools pass?

## Guardrails

- Do not translate C, C++, Rust, or Go ownership patterns mechanically into Zig.
- Do not hide allocation, ownership transfer, invalidation, or essential policy
  behind convenience APIs.
- Do not use `unreachable`, unchecked casts, or disabled safety to make the
  compiler accept an unproved assumption.
- Do not make correctness depend on Debug-only behavior.
- Do not overuse comptime, reflection, generics, or inline code.
- Do not retain pointers or slices across potentially relocating mutations.
- Do not hand-edit generated code or hardcode build output paths.
- Do not present TigerBeetle's project-specific limits or Ghostty's allocation
  choices as universal Zig requirements.
- Do not rely on stale syntax, flags, or stdlib APIs without the pinned compiler.

## Primary References

- Zig 0.16 language and standard-library docs:
  `https://ziglang.org/documentation/0.16.0/`
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

For substantial changes using this skill:

1. State the Zig version, target, ownership, lifetime, and safety-mode impact.
2. Call out allocator, error, layout, concurrency, comptime, and FFI contracts.
3. Explain performance choices from constraints and measurements, not slogans.
4. Point to version-matched Zig docs or source and identify historical guidance
   when rationale comes from an older article.
5. End with exact repository-appropriate format, test, build, optimized-safety,
   target, memory, security, QA, or benchmark verification performed.
