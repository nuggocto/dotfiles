---
name: zig
description: >
  Production-grade Zig systems and backend guidance focused on explicit memory
  management, predictable performance, clear boundaries, and operational
  reliability.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
---

# Zig

Use this skill for production-grade Zig services, daemons, proxies, data-plane components, CLIs, and performance-sensitive backend tooling. Prefer the repository's existing stack over generic defaults; use the defaults below only when the codebase has no clear standard.

## Workflow

1. Identify the executable shape and constraints: target, runtime model, allocator strategy, external I/O, latency target, and deployment model.
2. Read only the files that govern the change: `build.zig`, `build.zig.zon`, entrypoints, config, protocol or adapter code, tests, generated bindings, and CI.
3. Preserve existing package, build, and dependency choices unless they are unsafe, broken, or clearly blocking the request.
4. Make the smallest change that keeps allocator ownership, lifetimes, error flow, and module boundaries obvious.
5. Verify with the narrowest useful commands first; widen to full fmt/test/build checks for broader changes.

## Default posture

- Prefer the standard library and small dependencies.
- Prefer explicit allocator ownership, concrete types, and bounded resource lifetimes.
- Prefer thin protocol layers, explicit error unions, and simple control flow.
- Prefer measurable allocation and data-layout choices over abstraction-heavy designs.
- Do not add broad `comptime`, hidden allocation, or wide FFI surfaces without a clear payoff.

## Defaults when the repo has no standard

| Area | Default | Notes |
| --- | --- | --- |
| Toolchain | Zig stable pinned by the repo | Keep CI and local tooling aligned |
| Build | `build.zig` + `build.zig.zon` | Keep the build graph explicit |
| Formatting | `zig fmt` | Format touched files or the full package |
| Testing | `zig test` + `zig build test` | Start narrow, then run the build graph |
| Allocators | Explicit allocator threading | Use `GeneralPurposeAllocator` in apps and testing allocators in tests |
| Logging | `std.log` or repo choice | Keep levels and context consistent |
| JSON | `std.json` | Keep parsing and serialization explicit |
| Time | `std.time` | Use one time-source strategy per service |
| IDs | UUIDv7 or repo standard | Prefer one ID strategy per service |
| Integration tests | Black-box binary tests or repo harness | Use real processes when external behavior matters |
| FFI | Narrow C ABI wrappers | Isolate unsafe boundaries and ownership |
| Security checks | Debug + `ReleaseSafe` verification | Catch bounds and invariant failures early |

If the repository already uses custom allocators, event loops, protocol layers, or C libraries, stay consistent unless the user explicitly asks for a migration.

## Architecture defaults

- Keep protocol handlers focused on parsing input, validating it, calling core logic, and encoding output.
- Keep business rules, orchestration, and ownership of long-lived resources in service or core modules.
- Keep networking, storage, FFI, and wire-format details in adapter or infrastructure modules.
- Keep startup, config, allocator wiring, and shutdown behavior near the entrypoint.
- Keep caches, pools, arenas, and hot-path data structures explicit about lifetime and bounds.

Suggested layout when starting from scratch:

```text
build.zig
build.zig.zon
src/
  main.zig
  lib.zig
  config.zig
  app/
  core/
  io/
  platform/
test/
```

## Zig conventions

- Use `snake_case` for files and package-style module names.
- Use `camelCase` for functions, variables, parameters, and fields.
- Use `PascalCase` for structs, enums, unions, error sets, and other named types.
- Use `SCREAMING_SNAKE_CASE` only for foreign constants or when the repository already standardizes on it.
- Name allocator parameters `allocator` unless a narrower name materially improves clarity.
- Prefer tagged unions, enums, and narrow structs over parallel flags and nullable state combinations.

## Allocators, lifetimes, and ownership

- Pass allocators explicitly to code that allocates; do not hide allocator choice in deep helper layers.
- The code that allocates should make ownership and freeing rules obvious at the API boundary.
- Pair fallible allocation and initialization with `errdefer`; pair cleanup with `defer`.
- Prefer stack allocation, fixed buffers, or caller-provided buffers when bounds are known and practical.
- Use arenas only when lifetime boundaries are simple, coarse-grained, and easy to verify.
- Prefer slices and views that preserve ownership clarity over copying for convenience.

## Errors and observability

- Never ignore errors or replace recoverable failures with `unreachable` in runtime paths.
- Model expected failures with error unions, explicit status mapping, and narrow conversion points.
- Add context at I/O, parsing, and FFI boundaries before errors cross higher-level APIs.
- Keep client-facing or protocol-facing error surfaces stable even when internal causes vary.
- Use `std.log` or the repository logger with consistent context for request IDs, object IDs, and resource limits when available.
- Avoid silent truncation, dropped return values, and implicit fallbacks at critical boundaries.

## Concurrency, I/O, and performance

- Prefer simple synchronous-looking control flow unless the repository already standardizes on a more complex runtime model.
- Every thread, worker, queue, and background task needs an owner, shutdown path, and explicit bound.
- Be explicit about blocking I/O, batching, and backpressure; do not hide them behind convenience wrappers.
- Avoid shared mutable state when message passing, ownership transfer, or sharding is clearer.
- Be clear when performance depends on layout, cache behavior, allocation rate, or copies.
- Measure hot paths before introducing `comptime` specialization, SIMD, or branch-heavy micro-optimizations.

## Networking, storage, and security

- Set explicit request, buffer, and payload size limits.
- Validate lengths, offsets, counts, and enum/tag values at every external boundary.
- Keep protocol parsing, serialization, and storage mapping at the edges, not in core business logic.
- Keep SQL, key-value, file, or FFI details behind small adapter APIs.
- Parameterize queries, cap batch sizes, and make retry behavior bounded and visible.
- Minimize raw pointer casts and unsafe C interop; wrap them in small auditable functions.
- Avoid logging secrets, raw tokens, or sensitive buffers; zero or overwrite sensitive data when practical.

## Testing and verification

- Keep `test` blocks close to the code when that improves locality and understanding.
- Add integration tests around binaries, protocols, or external dependencies when unit tests would hide important behavior.
- Use leak-detecting or fail-fast allocators in tests when memory ownership is part of the risk.
- Run `zig fmt`, focused `zig test`, `zig build test`, and `zig build` for substantial changes.
- Run critical paths in both `Debug` and `ReleaseSafe` builds when bounds, overflow, or invariants matter.

## Guardrails

- Do not blur ownership of allocated memory across unrelated layers.
- Do not introduce `comptime` abstraction when concrete code or a small runtime branch is easier to audit.
- Do not widen FFI surfaces or pointer aliasing without a concrete need and clear boundary checks.
- Do not hide unbounded work in queues, retries, background threads, or allocator growth.
- Do not refactor broadly when a small explicit change solves the problem.

## Response expectations

When using this skill:

1. State the architecture and ownership impact of the change in plain language.
2. Call out trade-offs when choosing allocators, `comptime`, concurrency, or FFI boundaries.
3. Prefer concrete file-level guidance over abstract Zig advice.
4. End with the most relevant verification commands or follow-up checks.
