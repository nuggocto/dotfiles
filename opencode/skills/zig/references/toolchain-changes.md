# Zig toolchain changes

Read this reference when the task depends on version-sensitive Zig syntax,
standard-library APIs, build configuration, package metadata, testing, fuzzing,
I/O, concurrency, or C translation.

## Version policy

- Run `zig version` first and inspect the repository pin and CI.
- For new projects, use the latest stable Zig release.
- For existing projects, preserve the pin unless an upgrade is in scope. Then
  move to the latest compatible stable release after reading every skipped
  release note and compiling representative code.
- Use master documentation only for a project pinned to a development build.

## Review areas

- Container initialization, allocator arguments, ownership transfer, and
  deinitialization.
- Type-creation and reflection builtins, lazy declaration and field resolution,
  compile-time timing flags, and declaration-reference test helpers. In Zig 0.17,
  `@hasDecl` reports only public declarations, and `@backingInt`/`@fromBackingInt`
  replace the deprecated enum-conversion builtins.
- Entry-point forms, filesystem, process, reader/writer, task, future,
  cancellation, synchronization, and concurrency APIs.
- `build.zig` APIs, package identity, names, fingerprints, hashes, package paths,
  local overrides, cache layout, and minimum Zig version fields.
- Allocation-failure helpers, fuzz callback types, fuzz command flags, corpus
  replay, and test-runner output requirements.
- Packed and extern layout, vectors, pointer alignment, generated bindings, and
  every supported ABI affected by the change.

## C translation

- In Zig 0.17, use build-system C translation through the official `translate-c`
  package; `@cImport` is removed and `std.Build.Step.TranslateC` is deprecated.
- Pin a Zig 0.17-compatible `translate_c` dependency, initialize its `Translator`
  with the C source, target, optimization, and linked-library options, expose
  `translator.mod` through the root module's imports, and consume it with
  `@import("name")`.
- Follow the pinned translator package's API rather than carrying forward
  `b.addTranslateC` and `createModule()` examples from an older Zig release.
- Use translated source when the generated code needs review or edits. Use the
  build graph when cflags, targets, linked libraries, or generated-module
  ownership must be explicit.
- Match target triples and cflags between translation and final compilation.

## Zig 0.17 futures

- Treat every live `std.Io.Future(T)` as a lifecycle obligation. Call `await` or
  `cancel` on every path that owns it, and do not copy or concurrently operate on
  the same live future.
- Both operations return the callee's full result. Deferred cancellation must
  handle errors and release any resource returned when the task completed before
  the cancellation request took effect. Cancellation is also needed to release
  the async task resource on error paths.
- `io.async` is infallible and an `Io` implementation may call the function to
  completion before returning. Use `io.concurrent` only when concurrent caller
  progress is required for correctness, and handle
  `error.ConcurrencyUnavailable` as either unsupported concurrency or temporary
  resource exhaustion.

## Verification

- Compile every changed example with the selected compiler.
- Format and test narrowly first, then run affected optimization/safety modes,
  release artifacts, targets, ABIs, fuzzers, benchmarks, and memory tools.
- Distinguish compile-only foreign-target checks from tests that executed.

## Sources

- Versioned language and standard-library docs:
  `https://ziglang.org/documentation/`
- Downloads and release notes: `https://ziglang.org/download/`
- Build-system guide: `https://ziglang.org/learn/build-system/`
- Official C translation package:
  `https://codeberg.org/ziglang/translate-c`
- Zig 0.17 C translation migration notes:
  `https://ziglang.org/download/0.17.0/release-notes.html#C-Translation-Moving-to-External-Package`
