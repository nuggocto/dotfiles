---
name: odin
description: >
  Production-grade Odin guidance focused on explicit ownership, allocator
  lifetimes, data-oriented design, C interoperability, and reliable systems
  code. Use when working with Odin code, .odin files, Odin packages, odin
  build/check/test commands, or native applications and libraries written in
  Odin.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
---

# Odin

Use this skill for production-grade Odin applications, libraries, tools, games, engines, and systems software. Prefer the repository's established structure and compiler policy over generic defaults.

Odin is pre-1.0 and evolves quickly. Before relying on syntax, semantics, attributes, flags, or `core` and `vendor` APIs, run `odin version` and inspect the repository's toolchain pin and CI. Prefer matching compiler and library source, installed compiler help, and documentation from the same release or commit. The official specification page currently documents grammar, not a complete normative semantic specification. Treat current website and package documentation as potentially newer than the selected compiler, and call out every mismatch explicitly.

For performance-sensitive, storage, engine, or infrastructure code, apply `@tiger_style/` as an engineering overlay. Odin semantics and this skill take precedence for assertions, errors, ownership, bounds checks, allocators, and FFI.

## Workflow

1. Identify the artifact and constraints: executable or library, target OS and architecture, compiler version, foreign dependencies, threading model, latency and memory budgets, and deployment model.
2. Start with build scripts, package entrypoints, configuration, relevant `.odin` files, tests, foreign declarations, and CI. Follow imports and callers until ownership, lifetime, and ABI contracts are understood.
3. Preserve existing package, allocator, build, and platform choices unless they are unsafe, broken, or clearly block the request.
4. Before editing, account for every allocation, borrowed view, resource handle, thread, and foreign callback affected by the change.
5. Make the smallest change that keeps data flow, ownership, errors, layout, and synchronization visible.
6. Verify with the repository-selected compiler and its supported flags, first narrowly and then across affected targets and build modes.

## Default Posture

- Prefer explicit procedures, concrete data, and direct control flow over framework-shaped abstraction.
- Design from data layout, access patterns, ownership, lifetime, and failure modes before choosing types and package boundaries.
- Prefer `int` for ordinary arithmetic and indexing. Use fixed-width, unsigned, endian-specific, or foreign integer types only when representation, modular arithmetic, protocol, SIMD, or ABI requirements demand them.
- Prefer useful zero values and initialization that leaves objects safe to inspect and destroy.
- Keep bounds and type-assertion checks enabled. Disable a check only in a small measured region with a locally obvious proof.
- Avoid `rawptr`, unchecked multi-pointer access, `transmute`, `auto_cast`, and uninitialized `---` values unless their benefit and safety contract are concrete.
- Avoid dependencies and generic machinery that do not reduce total complexity.

## Packages And Names

- Use the repository's style. Conventional Odin uses `snake_case` for packages, procedures, variables, and files; `Ada_Case` for types and enum values; and `SCREAMING_SNAKE_CASE` for constant data values. Do not apply constant-value naming to every `::` declaration because procedures and types are also constant declarations.
- Keep package names short and let package qualification provide context instead of repeating namespaces in every declaration.
- All package declarations are public by default. Treat package-level declarations as API unless deliberately marked `@(private)` or file-private.
- Organize packages around cohesive capabilities or data ownership, not class hierarchies or generic technical layers.
- Keep `using` local and rare; do not obscure field origin or create avoidable name collisions.
- Use `when` for compile-time selection and `if` for runtime behavior.
- Before editing generated bindings or other generated code, find and modify the source or generator input, then regenerate with the repository-pinned tool.

## API Design

- Make ownership, borrowing, mutation, lifetime, nullability, allocator choice, and thread restrictions evident from names, signatures, and documentation.
- Use package-qualified procedures rather than imitating methods or inheritance. Keep related operations consistently named.
- Use verbs such as `init`, `clone`, `take`, `clear`, `reset`, and `destroy` consistently when they clarify lifecycle semantics.
- Return a borrowed slice or string only when its backing storage is guaranteed to outlive every consumer.
- Prefer slices for bounded borrowed sequences and stable handles or indices when container growth may invalidate pointers.
- Use distinct types, enums, bit sets, and tagged unions to prevent domain values and states from being mixed accidentally.
- Use default arguments only when the default is unsurprising and does not hide ownership, allocation, or security policy.
- Keep callbacks rare. When required, specify user data, invocation lifetime, calling thread, reentrancy, and whether arguments may be retained.
- Add polymorphism or procedure values only when multiple implementations or runtime substitution justify the extra indirection.

## Ownership And Memory

- Give every allocation and resource one clear owner and one clear release path.
- Place `defer` immediately after successful acquisition when lexical cleanup matches the lifetime. Ordinary deferred statements are not run if the thread panics, so do not rely on panic for recoverable control flow or for releasing resources that must be released.
- Slice and string values do not encode ownership. They may reference borrowed storage or allocations that the caller must release; track backing storage, allocator, owner, and lifetime separately and distinguish borrowed views from owned results.
- Dynamic arrays and maps contain backing state. Copies can alias the same allocation or resource; do not copy owner-like values unless the semantics are intentional.
- Container growth, replacement, or deletion can invalidate element pointers, slices, strings, and other views. Do not retain them across mutation unless the API guarantees stability.
- Destroy nested owned allocations explicitly. Deleting an outer container does not recursively release allocations owned by its elements.
- Do not let data allocated from `context.temp_allocator`, a scratch arena, stack storage, or another short-lived region escape that lifetime.
- Pass an allocator explicitly at an ownership boundary when callers must control lifetime or policy. An `allocator := context.allocator` default is appropriate when caller interception is intentionally part of the API.
- Prefer arenas, pools, or other specific allocation strategies when they model a subsystem's actual lifetime better than scattered allocation, but do not introduce custom allocators without a measured or correctness-driven reason.
- Test partial initialization and every cleanup path. A destroy procedure should tolerate every state its initialization contract says can be observed.

## Context

- Treat `context` as Odin's mechanism for scoped interception of called code, especially allocation, temporary allocation, logging, assertions, and randomness. Do not use it as a general dependency-injection container.
- Pass essential business and system dependencies explicitly.
- Keep context overrides in the narrowest possible lexical scope and restore behavior naturally by leaving that scope.
- Do not mark a procedure `"contextless"` merely because its body does not visibly read `context`; called Odin procedures may use it.
- For non-Odin callbacks and new threads, establish or pass the intended context deliberately rather than assuming propagation.
- Do not access runtime context internals intended for compiler or core-library implementation.

## Errors, Assertions, And Panics

- Represent expected failure with explicit return values: multiple returns, error enums, tagged unions, optionals, or comma-ok forms as appropriate.
- Check, propagate, translate, or intentionally discard every fallible result. Many allocation and container operations expose a trailing `runtime.Allocator_Error` through `#optional_allocator_error`, so syntax may permit silently omitting it. Capture and handle that result whenever allocation failure is not provably irrelevant.
- Add useful context at I/O, parsing, allocation, platform, and FFI boundaries without exposing secrets.
- Use exhaustive `switch` handling when every error or state variant matters. Use `#partial switch` only when deliberately ignoring the remaining variants is safe.
- Reserve `assert` and panic for programmer defects and violated internal invariants, not malformed input, unavailable resources, allocation failure, I/O errors, or other expected runtime conditions.
- Ordinary assertions can be disabled. Never place required side effects, validation, cleanup, or state transitions inside them. Use an always-active invariant mechanism only when process termination is truly the intended policy.
- Validate safety preconditions before unchecked access, pointer conversion, or foreign calls in every relevant build configuration.
- Keep naked returns to short procedures where the returned values remain obvious.

## Data-Oriented Design And Performance

- Start from how data is traversed and transformed, how often it changes, and which subsystem owns it.
- Choose array-of-structures or structure-of-arrays from measured access patterns, not ideology.
- Prefer dense contiguous storage for hot iteration and separate hot fields from cold metadata when measurement shows a benefit.
- Batch allocation, I/O, synchronization, and foreign calls to amortize fixed costs.
- Use stable IDs or indices instead of pointers when data moves or containers grow.
- Keep important loops simple and predictable. Estimate memory footprint, bandwidth, and work before optimizing.
- Benchmark representative release builds before and after layout or allocator changes. Include conversion and maintenance costs in the decision.
- Do not assume zero-copy is free: borrowed lifetimes, fragmented access, pinning, and foreign ownership may cost more than a deliberate copy.

## Collections, Strings, And Integers

- Range iteration values are copies unless explicitly iterated by reference. Do not mutate a copied iteration variable expecting the collection to change.
- Odin `string` is an immutable pointer-length byte view conventionally interpreted as UTF-8; validity is not enforced. `len` and indexing operate on bytes, while range iteration decodes runes and assumes UTF-8. Validate untrusted text explicitly and name byte offsets as such.
- Use comma-ok map lookup when absence differs from the element type's zero value.
- Do not retain pointers into maps or growable arrays across mutations unless the implementation contract guarantees validity.
- Check ranges before narrowing conversions. Make truncation or modular behavior explicit when it is intentional.
- Do not import C's signed-integer undefined-behavior rules into Odin. Current Odin defines signed overflow deterministically, minimum signed value divided by `-1` as that minimum value, unsigned arithmetic as wrapping, and oversized shifts as zero. Runtime division by zero follows compiler policy. Confirm these semantics and available policy flags against the pinned compiler, and still reject arithmetic that violates allocation-size, indexing, protocol, or domain constraints.
- Parse and validate untrusted bytes field by field; do not map them directly onto native structs whose layout or padding is not a protocol contract.

## Concurrency

- Prefer partitioned ownership and message passing over unrestricted shared mutable state.
- Document which thread owns mutable data and which synchronization primitive protects each shared field.
- Synchronize all conflicting shared access. Do not use an ordinary flag or counter as if it were atomic.
- Do not copy synchronization values marked or documented as non-copyable after initialization. Keep them at stable addresses and pass pointers.
- Confirm allocator and container thread safety before sharing allocator-backed data between threads.
- Keep lock scopes short. Avoid calling unknown callbacks or foreign code while holding a lock unless reentrancy and lock ordering are understood.
- Bound work queues, thread creation, and fan-out. Give long-lived threads an owner, stop condition, and join policy.
- Use supported race detection as evidence, not proof; reason about ownership and happens-before relationships independently.

## C And Foreign Interoperability

- Match the foreign ABI exactly: calling convention, symbol name, type width, signedness, layout, alignment, nullability, and variadic rules.
- Use target-matched `core:c` types where they represent the actual C declaration, but inspect the pinned package and target headers. Current `c.char` aliases `u8` and assumes unsigned plain `char`; use `c.schar`, `c.uchar`, or a generated target-specific binding when signedness matters. Odin `int` is not C `int`.
- Declare C variadic parameters with the pinned compiler's `#c_vararg` form and obey C default argument promotions. Odin variadic parameters are not C varargs.
- Use `cstring` for NUL-terminated C text, `rawptr` for `void *`, and `[^]T` only when the valid extent is known separately.
- Represent a C union with an ABI-verified `struct #raw_union`; an ordinary Odin `union` is tagged.
- Specify who allocates and frees every foreign object. Keep allocation and deallocation on the same side unless the API provides a matching release function.
- Copy foreign data when its lifetime, alignment, mutability, or termination cannot be guaranteed.
- Keep callback state alive until the foreign library can no longer invoke the callback. Prevent panics or foreign exceptions from crossing an ABI boundary.
- Wrap raw declarations in a small checked Odin API so unsafe ABI details do not spread through the application.
- Verify required layouts with compile-time assertions and test bindings on every supported target ABI.

## Security Boundaries

- When handling authentication, cryptography, untrusted files, network protocols, paths, commands, plugins, or parsers, load `@security/` and threat-model the boundary.
- Bound input, output, decompression, recursion, allocation, collection growth, and work per request or frame.
- Treat file paths as traversal boundaries, outbound addresses as SSRF boundaries, command arguments as injection boundaries, and foreign decoders as memory-safety boundaries.
- Use cryptographically secure randomness for secrets; do not assume a convenient default pseudo-random generator is appropriate for key material.
- Avoid logging secrets, raw tokens, private keys, or sensitive buffers. Use a guaranteed erasure mechanism when the threat model requires memory clearing.

## Testing And Verification

- Define tests as `@(test) name :: proc(t: ^testing.T)` using `core:testing`; keep tests independent because the test runner can execute them concurrently.
- Test ownership and lifecycle edges: empty values, partial initialization, allocator failure where injectable, growth invalidation, temporary allocator escape, cleanup, bad foreign inputs, and thread shutdown.
- Exercise byte/rune boundaries, missing map keys, integer limits, null pointers, callback lifetime, and ABI layout where relevant.
- Keep memory tracking enabled in normal tests. Current runners report leaks and bad frees by default but require `ODIN_TEST_FAIL_ON_BAD_MEMORY=true` to make them fail; enable that policy in CI when the selected compiler supports it.
- Record and replay random seeds for nondeterministic failures. Run concurrency-sensitive tests repeatedly and with normal parallelism.
- Use one test thread only to diagnose order or race issues, not to hide them.
- Derive exact commands from the pinned compiler and artifact. A typical current package baseline is:

```sh
odin version
odin check . -no-entry-point -vet -warnings-as-errors
odin test . -vet -warnings-as-errors -define:ODIN_TEST_FAIL_ON_BAD_MEMORY=true
```

- For an executable, also run `odin build . -debug -vet -warnings-as-errors`. For a library, use its intended `-build-mode:lib`, `-build-mode:dll`, or repository wrapper. Add `-strict-style` only when the repository intentionally follows that compiler style.
- Also test an optimized build and every affected target. Use address or thread sanitizers only on supported compiler/platform combinations and in separate jobs where required.
- Odin currently has no official `odin fmt` source formatter. Do not invent formatter commands; follow repository formatting and the compiler's style diagnostics.

## Review Checklist

- Does each allocation, handle, thread, and callback have one owner and bounded lifetime?
- Can any returned or retained view outlive or be invalidated by its backing storage?
- Does copying a value accidentally duplicate ownership or alias mutable resource state?
- Are temporary allocations confined to their allocator lifetime?
- Are expected failures handled as data rather than assertions or panics?
- Are iteration values, string indexes, map absence, narrowing conversions, and integer limits interpreted correctly?
- Is shared mutable state synchronized, and are non-copyable synchronization objects stable?
- Does every FFI declaration match the target ABI and document ownership and callback lifetime?
- Do debug, optimized, test, vet, memory-tracking, and supported sanitizer configurations pass?

## Guardrails

- Do not translate C or C++ patterns mechanically when Odin has a clearer typed representation.
- Do not hide allocation, ownership transfer, or essential dependencies behind convenience APIs.
- Do not use `context` as ambient application state.
- Do not disable checks globally to improve an unmeasured hot path.
- Do not retain pointers or views across potentially relocating mutations.
- Do not hand-edit generated bindings.
- Do not rely on stale Odin syntax, flags, or package APIs without checking the selected compiler.

## Response Expectations

For substantial changes using this skill:

1. State the ownership, lifetime, layout, and concurrency impact in plain language.
2. Call out allocator and FFI contracts explicitly.
3. Explain performance choices from access patterns and measurements rather than slogans.
4. Point to version-matched official Odin docs, package docs, compiler/core source, or creator rationale when specifics matter.
5. End with the exact repository-appropriate verification commands and target matrix.
