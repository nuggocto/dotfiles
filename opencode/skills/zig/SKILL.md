---
name: zig
description: >
  Production-grade Zig systems and backend guidance focused on explicit memory
  management, predictable performance, clear boundaries, and operational
  reliability. Use when working with Zig code, .zig files, build.zig projects,
  or Zig services, daemons, CLIs, and data-plane components.
license: MIT
metadata:
  author: opencode
  version: "1.1.0"
---

# Zig

Use this skill for production-grade Zig services, daemons, proxies, data-plane components, CLIs, and performance-sensitive backend tooling. Prefer the repository's existing stack over generic defaults; use the defaults below only when the codebase has no clear standard.

When language or library behavior is uncertain, identify the repository's Zig version and consult the matching official language reference, standard library source, and build-system documentation. Do not use `master` documentation for a pinned release unless investigating future behavior; Zig APIs change quickly.

For performance-sensitive, systems-level, or data-plane code, apply `@tiger_style/` as an engineering overlay. Zig semantics and the rules in this skill take precedence: TigerStyle may add bounds and deliberate internal-invariant checks, but it must not turn external input or operational failures into assertions.

## Workflow

1. Identify the executable shape and constraints: target, runtime model, allocator strategy, external I/O, latency target, and deployment model.
2. Read only the files that govern the change: `build.zig`, `build.zig.zon`, entrypoints, config, protocol or adapter code, tests, generated bindings, and CI.
3. Preserve existing package, build, and dependency choices unless they are unsafe, broken, or clearly blocking the request.
4. Make the smallest change that keeps allocator ownership, lifetimes, error flow, and module boundaries obvious.
5. Verify with the narrowest useful commands first; widen to full fmt/test/build checks for broader changes.

## Default posture

- Prefer the standard library and small dependencies.
- Prefer explicit allocator ownership, concrete types, and bounded resource lifetimes.
- Prefer thin protocol layers, error unions, and simple visible control flow.
- Prefer measurable allocation and data-layout choices over abstraction-heavy designs.
- Use `comptime` when values must be compile-time known, for type construction and generics, or for compile-time validation; avoid reflective machinery or performance specialization without a clear payoff.
- Preserve Zig's guarantees of no hidden control flow and no hidden allocation at API boundaries.

## Defaults when the repo has no standard

| Area | Default | Notes |
| --- | --- | --- |
| Toolchain | Zig version pinned by the repo | Keep CI and local tooling aligned; Zig APIs change quickly |
| Build | `build.zig` + `build.zig.zon` | Keep the build graph explicit |
| Formatting | `zig fmt` | Format touched files or the full package |
| Testing | `zig test` + `zig build test` | Start narrow, then run the build graph |
| Allocators | Caller-selected allocators | Reusable code accepts an allocator; applications choose one near the composition root |
| Logging | `std.log` or repo choice | Keep levels and context consistent |
| JSON | `std.json` | Keep parsing and serialization explicit |
| Integration tests | Black-box binary tests or repo harness | Use real processes when external behavior matters |
| FFI | Narrow C ABI boundaries | Isolate ABI conversion, pointer validity, and ownership rules |
| Runtime safety | `Debug` + `ReleaseSafe` verification | Also test the optimization mode that is actually shipped |

If the repository already uses custom allocators, event loops, protocol layers, or C libraries, stay consistent unless the user explicitly asks for a migration.

## Application structure

Zig does not prescribe an `app/core/io/platform` directory layout. Start with a flat structure and split modules only when doing so clarifies ownership, dependencies, or independently testable behavior.

- Keep protocol handlers focused on parsing input, validating it, calling core logic, and encoding output.
- Keep business rules, orchestration, and ownership of long-lived resources in service or core modules.
- Keep networking, storage, FFI, and wire-format details in adapter or infrastructure modules.
- Keep startup, config, allocator wiring, and shutdown behavior near the entrypoint.
- Keep caches, pools, arenas, and hot-path data structures explicit about lifetime and bounds.

## Zig conventions

- Name declarations according to the value they represent, not merely their syntactic form.
- Use `TitleCase` for types, type aliases, and functions that return `type`.
- Use `camelCase` for other functions and callable values.
- Use `snake_case` for variables, parameters, fields, namespaces, and other non-callable values.
- Name a file `TitleCase.zig` when its implicit struct is a type with top-level fields; use `snake_case` for other files and directories.
- Apply ordinary casing to acronyms. Reserve forms such as `SCREAMING_SNAKE_CASE` for established external conventions such as `ENOENT` or an existing repository standard.
- Choose names in their fully qualified context: prefer `json.Value` over `json.JsonValue`, and avoid vague segments such as `Manager`, `Context`, `utils`, or `misc` when a domain name is available.
- Do not use underscore prefixes to imply privacy or special behavior.
- Name allocator parameters `allocator` unless a narrower name materially improves clarity.
- Prefer tagged unions, enums, and narrow structs over parallel flags and nullable state combinations.

## Values and initialization

- Prefer `const` over `var` whenever the binding does not need mutation.
- Use `undefined` only for storage guaranteed to be overwritten before any read or otherwise never observed.
- After `undefined` is coerced to a type, it is indistinguishable from an ordinary value and may contain a nonsensical bit pattern.
- Treat Debug and `ReleaseSafe` initialization of undefined memory with `0xaa` as an implementation aid, never a language guarantee.

## Allocators, lifetimes, and ownership

- Reusable or library code that allocates should normally accept an allocator rather than choose one globally.
- Applications should choose the main allocator near the composition root, usually the entrypoint, and pass it or purpose-specific sub-allocators to code that needs them.
- For every API that returns or retains a pointer or slice, document who owns the backing memory, who frees it, and which operations or events invalidate it.
- After successfully acquiring a resource that must be released if later work fails, place `errdefer` immediately after the acquisition. Use `defer` for cleanup required on every exit path.
- Prefer stack allocation, fixed buffers, or caller-provided buffers when bounds are known and practical.
- Use arenas only when allocations share one clear bulk lifetime that is easy to verify.
- Treat slices and container views as borrowed data whose lifetime may end on mutation, resize, reset, or deinitialization.
- Treat `error.OutOfMemory` as a normal possible allocation failure unless the application has an explicit, documented abort policy at its outer boundary.

## Assertions, validation, and illegal behavior

- Assertions represent programmer errors and internal invariants. They are not a substitute for runtime validation.
- Handle malformed or untrusted input, I/O failure, allocation failure, unavailable resources, cancellation, and other expected runtime conditions with errors or normal control flow.
- Use `std.debug.assert` only when a false condition means the caller or implementation violated an internal contract. Keep assertion expressions free of required side effects.
- In `Debug` and `ReleaseSafe`, a failed `std.debug.assert` reaches `unreachable` and panics. In `ReleaseFast` and `ReleaseSmall`, assertions are optimized away and may become optimizer assumptions.
- Use `unreachable`, optional unwrapping, and `catch unreachable` only when impossibility is guaranteed by construction, the type or state model, or a preceding exhaustive check.
- Use `std.testing.expect*` in tests so failures remain detectable in every optimization mode.
- When TigerStyle calls for aggressive assertions, add non-redundant checks that sharpen important internal invariants at useful boundaries. Do not mechanically assert every argument or return value.
- Do not disable runtime safety broadly. Any scoped exception needs a demonstrated benefit and a locally auditable proof that safety remains intact.

## Errors and observability

- Explicitly propagate, handle, translate, or intentionally discard each error. Discard an error only when failure is genuinely irrelevant and that decision is evident from context.
- Model expected failures with error unions, explicit status mapping, and narrow conversion points.
- Generally avoid `anyerror` in public APIs. Inferred error sets are appropriate for implementation-local functions; use explicit sets when API stability, recursion, function pointers, exhaustive handling, or cross-target consistency requires them.
- Add operational context at I/O, parsing, and FFI handling boundaries, and avoid duplicating the same error log at every propagation layer.
- Keep client-facing or protocol-facing error surfaces stable even when internal causes vary.
- Use `std.log` or the repository logger with consistent context for request IDs, object IDs, and resource limits when available.
- Avoid silent truncation, dropped return values, and implicit fallbacks at critical boundaries.

## Concurrency, I/O, and performance

- Prefer simple synchronous-looking control flow unless the repository already standardizes on a more complex runtime model.
- Every thread, worker, queue, and background task needs an owner, shutdown path, and explicit bound.
- Be explicit about blocking I/O, batching, and backpressure; do not hide them behind convenience wrappers.
- Minimize shared mutable state; where sharing is necessary, make synchronization, ownership, cancellation, and lifetime explicit.
- Be clear when performance depends on layout, cache behavior, allocation rate, or copies.
- Use `comptime` freely for semantic requirements such as generics and compile-time validation. Measure representative hot paths before introducing `comptime` specialization, SIMD, layout changes, or branch-heavy work specifically for performance.

## Networking, storage, and security

- Set explicit request, buffer, and payload size limits.
- Validate lengths, offsets, counts, and enum/tag values at every external boundary.
- Keep protocol parsing, serialization, and storage mapping at the edges, not in core business logic.
- Keep SQL, key-value, file, or FFI details behind small adapter APIs.
- Parameterize queries, cap batch sizes, and make retry behavior bounded and visible.
- Minimize raw pointer casts and unchecked C pointer operations; wrap them in small auditable functions.
- Avoid logging secrets, raw tokens, or sensitive buffers; zero or overwrite sensitive data when practical.

## Serialization and protocol contracts

- Use `std.json` or the repository parser for edge DTOs; avoid forcing core types to match wire shape.
- Make allocator ownership for parsed or serialized data explicit, including who calls `deinit` or frees buffers.
- Treat field names, defaults, unknown-field behavior, numeric bounds, and time formats as protocol decisions.
- Validate payload size and nesting depth before or during parsing when input is external.
- Keep binary protocol encoding and decoding at adapter boundaries with round-trip tests for stable formats.

## Testing and verification

- Keep `test` blocks close to the code when that improves locality and understanding.
- Add integration tests around binaries, protocols, or external dependencies when unit tests would hide important behavior.
- Use `std.testing.expect*` rather than `std.debug.assert` for test outcomes.
- Use `std.testing.allocator` for ordinary test allocations so the default runner can report leaks.
- Use `std.testing.FailingAllocator` to exercise allocation-failure and cleanup paths when OOM handling is part of the contract.
- Run `zig fmt`, focused `zig test <file>`, `zig build test`, and `zig build` for substantial changes.
- Exercise critical paths in `Debug` or `ReleaseSafe` to detect safety-checked illegal behavior, and also test the optimization mode actually shipped.
- Use `zig build -Doptimize=ReleaseSafe` only when the build exposes the standard optimize option; otherwise use the repository's build interface.

## Guardrails

- Do not blur ownership of allocated memory across unrelated layers.
- Do not read a value or memory region before every byte that may be observed has been initialized.
- Do not use `comptime` metaprogramming when concrete code or a small runtime branch communicates intent more clearly.
- Do not widen FFI surfaces or pointer aliasing without a concrete need and clear boundary checks.
- Do not hide unbounded work in queues, retries, background threads, or allocator growth.
- Do not use assertions, `unreachable`, or disabled runtime safety to bypass recoverable failures.
- Do not refactor broadly when a small explicit change solves the problem.

## Source discipline

- Treat the language reference and standard library source matching the repository's pinned Zig version as authoritative for semantics and APIs.
- Use current `master` documentation only for projects tracking `master` or when explicitly evaluating a future migration.
- Use Andrew Kelley's writing and talks for design rationale such as visible control flow, explicit allocation, readable code, and careful use of `unreachable`, not as a substitute for versioned API documentation.
- Keep TigerStyle recommendations labeled as an independent engineering discipline rather than attributing them to Andrew Kelley or the Zig project.

## Response expectations

When using this skill:

1. State the architecture and ownership impact of the change in plain language.
2. Call out trade-offs when choosing allocators, `comptime`, concurrency, or FFI boundaries.
3. Prefer concrete file-level guidance over abstract Zig advice.
4. Point to relevant Zig standard library or package docs when specifics matter.
5. End with the most relevant verification commands or follow-up checks.
