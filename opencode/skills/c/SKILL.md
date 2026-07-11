---
name: c
description: >
  Production-grade C guidance focused on explicit ownership, undefined-behavior
  avoidance, portable APIs and ABIs, resource safety, diagnostics, sanitizers,
  and rigorous verification. Use when working with C source or headers, .c/.h
  files, C libraries, native services, embedded systems, Make/CMake/Meson C
  targets, or C interoperability boundaries.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
---

# C

Use this skill for production-grade C applications, libraries, operating-system components, embedded software, native services, tools, and FFI boundaries. Confirm that `.h` files belong to C rather than C++ before applying language-specific rules. Prefer the repository's established dialect, portability contract, build system, and style.

Before relying on syntax, library behavior, compiler extensions, attributes, or flags, determine the selected C standard, compiler and minimum version, libc, operating systems, architectures, ABI, feature-test macros, and CI matrix. ISO C defines the language; compiler and platform documentation define extensions and implementation behavior. SEI CERT C and mature projects provide evidence and risk guidance, not substitutes for the project's contract.

For performance-sensitive, storage, embedded, or infrastructure code, apply `@tiger_style/` as an engineering overlay. C semantics and this skill take precedence for undefined behavior, assertions, ownership, cleanup, concurrency, signals, ABI, and tooling.

## Workflow

1. Identify the artifact and constraints: executable or library, C dialect, hosted or freestanding environment, targets, ABI stability, threading and signal model, allocation policy, real-time constraints, and threat model.
2. Start with build files, toolchain files, public headers, implementation, tests, generated-code inputs, and CI. Follow callers and ownership paths until behavior and compatibility contracts are understood.
3. Preserve existing compiler, build, platform abstraction, and dependency choices unless they are unsafe, broken, or clearly block the request.
4. Model failure first: invalid input, overflow, truncation, partial initialization, allocation failure, cleanup failure, aliasing, races, ABI mismatch, and interrupted I/O.
5. Make the smallest change that leaves ownership, bounds, state transitions, errors, and platform assumptions auditable.
6. Verify with every affected compiler, architecture, build mode, analyzer, and sanitizer from the support matrix.

## Project Contract

- Use the repository's C standard. C17 is a practical portability baseline for new unconstrained projects; use C23 features only when the compiler and libc matrix supports them or a reviewed fallback exists.
- Distinguish ISO C, POSIX, GNU C, Win32, kernel, and freestanding code. Do not use one environment's guarantees in another.
- Keep platform adaptation and compiler feature detection in narrow modules or headers.
- Prefer capability checks over OS-name guesses. Define every required feature-test macro before any header is included in each translation unit, including through project headers; prefer consistent build-system definitions when the macro is project-wide.
- Treat public source compatibility, binary compatibility, serialized formats, and FFI as separate contracts.
- Do not impose Linux kernel style, curl's historical C baseline, SQLite's process, or JPL's safety-critical restrictions universally. Apply domain-specific rules only when the project's environment warrants them.
- Before editing generated parsers, bindings, protocol code, or configuration outputs, modify the generator input and regenerate with the pinned tool.

## Simplicity And Structure

- Prefer straightforward control flow, small cohesive modules, and explicit state over macro metaprogramming or object-system emulation.
- Use the repository formatter and naming style. C has no single universal naming convention; consistency and namespace clarity matter more than importing another project's style.
- Keep internal declarations `static` where appropriate and export only intentional API symbols.
- Keep headers self-contained, minimal, and safe for repeated inclusion. Include what the header requires rather than relying on inclusion order.
- Put declarations in the narrowest scope and initialize objects before use.
- Use comments for ownership, units, invariants, representation, concurrency, and non-obvious rationale, not line-by-line narration.
- Keep macros parenthesized and side-effect-safe when a macro is truly needed. Prefer functions, `static inline` functions, enums, and typed constants when they provide the required semantics.
- Never pass side-effecting expressions to a macro that may evaluate an argument more than once.

## API Design

- Document ownership, borrowing, mutability, lifetime, nullability, units, valid ranges, allocator, error domain, and thread safety for every pointer-bearing API.
- Prefer opaque types for public APIs unless callers genuinely need a stable layout.
- Prefer pointer-plus-count interfaces for bounded or binary data. State whether counts and capacities are bytes or elements and encode units in names.
- Use `const` for borrowed read-only data, understanding that it does not make the underlying object immutable through all aliases.
- Do not return pointers to automatic storage or storage invalidated by the next call, mutation, reallocation, or destructor unless that contract is explicit and appropriate.
- Provide a matching destructor when a library returns owned resources. Do not make callers guess which allocator or subsystem releases them.
- Define output-parameter state on failure: unchanged, zeroed, or partially initialized and destroyable.
- Use status enums or structured error APIs when callers need to distinguish failures. A boolean is insufficient when recovery depends on the cause.
- For extensible ABI structs, use a reviewed size/version scheme and specify initialization and unknown-field behavior.
- Avoid exposed bit-fields, compiler-sized enums, padding assumptions, and platform-dependent fundamental widths across stable ABIs.
- Specify callback user data, retention, calling thread, reentrancy, cancellation, and final invocation semantics.

## Ownership And Cleanup

- Give each resource one clear owner and pair each acquisition with its exact release operation.
- Release in reverse acquisition order. When a function acquires multiple resources, a forward-flow `goto` cleanup chain is often clearer and safer than duplicated exits.
- Initialize owner objects to a state that their cleanup function can safely accept. Update ownership only after an operation succeeds.
- Preserve the primary error if cleanup also fails; report cleanup failure separately when it matters.
- Check allocation-size addition and multiplication before calling an allocator.
- Define a project policy for zero-size allocation. Do not depend on whether `malloc(0)` returns null or a unique pointer.
- Do not use zero as the new size for `realloc`. For non-null `ptr`, C23 makes `realloc(ptr, 0)` undefined behavior, while C17 permits deprecated implementation-defined behavior. `realloc(NULL, 0)` follows `malloc(0)` semantics but should still be avoided under the project's explicit zero-size policy. Express deallocation with `free` explicitly.
- Assign nonzero `realloc` results through a temporary so failure preserves the original allocation. After success, use only the returned pointer; the original pointer and every pointer derived from it are invalid even if the returned address is numerically unchanged.
- Do not mix allocators or C runtimes across a DLL/shared-library boundary. Export a matching release function when necessary.
- Treat stack size as bounded. Avoid large automatic arrays, unbounded variable-length arrays, and recursion without a proven depth suitable for the target.
- Use a guaranteed erasure primitive for secrets when required; ordinary `memset` may be optimized away.

## Integers, Sizes, And Conversions

- Treat every narrowing and signed/unsigned conversion as a potential correctness or security bug.
- Validate external lengths, offsets, counts, timestamps, and file sizes before conversion or arithmetic.
- Use `size_t` for object sizes and valid in-memory element counts, while checking conversions at APIs that use different types.
- Check allocation arithmetic before performing it. Use C23 `<stdckdint.h>` checked arithmetic only when supported; otherwise use explicit precondition checks such as `count > SIZE_MAX / sizeof *items`.
- Never assume signed overflow wraps. It is undefined behavior.
- Rely on unsigned wrap only for intentional, documented modular arithmetic, not as a substitute for bounds checking.
- Validate divisors, signed-minimum divided by `-1`, shift counts, and left operands before arithmetic whose behavior can be undefined.
- Use `sizeof *ptr` for allocations tied to a pointer's target type.
- Use exact-width `<stdint.h>` types only where exact representation matters and the implementation provides them. Use `<inttypes.h>` format macros for those types and `%zu` for `size_t`.
- Do not silence conversion diagnostics with an unchecked cast. Prove and enforce the range first.

## Arrays, Pointers, And Object Representation

- Prove every subscript, pointer increment, and byte count stays within the same array object or one-past endpoint allowed by C.
- Do not form out-of-bounds pointers even when they are never dereferenced.
- If an API allows `NULL` with a zero count, branch before pointer arithmetic or library calls whose contracts still require valid pointers.
- Use `memmove` when ranges may overlap; `memcpy` requires non-overlap.
- Track both source and destination bounds for every copy, append, decode, and format operation.
- Do not cast arbitrary byte storage to a structure pointer unless alignment, lifetime, effective type, aliasing, representation, and bounds are all valid.
- Use `memcpy` to transfer values to or from potentially unaligned byte storage; still define byte order and validate representation explicitly.
- Do not serialize native structs by dumping object bytes. Padding, alignment, endianness, and representation are not portable protocols.
- Avoid type-punning through incompatible pointers. Use a standards-compliant representation technique supported by the selected dialect.
- Treat every `restrict` qualifier as a caller-visible aliasing contract, not documentation or a mere optimization hint. Do not add it without proving the selected standard's association rules, and do not violate the contract with overlapping access when an object is modified.
- Use `==` and `!=` only with pointer operands permitted by the selected standard, remembering that one-past and an immediately following object can compare equal. Do not apply relational operators to unrelated object pointers. Subtract pointers only within the same array object or one past it, and ensure the result is representable in `ptrdiff_t`.
- Treat pointer provenance and object lifetime as correctness constraints, not merely address arithmetic.

## Strings And Bytes

- Distinguish text, NUL-terminated strings, counted byte sequences, and binary blobs in types, names, and contracts.
- Never call a string function unless NUL termination within the accessible object is established.
- Carry destination capacity with writable buffers and reserve space for the terminator.
- Avoid unbounded `strcpy`, `strcat`, `sprintf`, and `scanf` string conversions.
- Do not treat `strncpy` as a general safe string copy; it may omit termination and pads the destination.
- Check `snprintf` return values for errors and truncation using the documented contract of the target implementation.
- Cast a possibly negative `char` to `unsigned char` before passing it to `<ctype.h>` classification or conversion functions, except for `EOF` where accepted.
- Do not modify string literals.
- Validate text encoding separately from memory bounds. A bounded byte string is not automatically valid UTF-8 or locale text.
- Do not depend on optional Annex K `_s` interfaces unless every supported implementation provides the required semantics.

## Undefined And Unspecified Behavior

- Do not write correctness that depends on signed overflow, out-of-bounds pointer formation or access, use-after-free, double-free, invalid lifetime, uninitialized reads, misalignment, aliasing violations, invalid variadic arguments, data races, unsequenced modifications, or invalid shifts.
- Do not use `memcmp` as semantic struct equality unless a reviewed contract proves there is no padding in the struct or its members, no indeterminate byte participates, and every relevant value has a unique object representation. Otherwise compare members individually.
- Do not depend on unspecified evaluation order. Split expressions when order matters.
- Do not assume `char` signedness, integer widths, endianness, pointer representation, enum width, or floating-point details beyond the project contract.
- Use `_Static_assert` in C11-C17, or include `<assert.h>` before using its `static_assert` macro. In C23, prefer the `static_assert` keyword without requiring that header. Use these assertions for width, alignment, and layout assumptions required by an ABI or algorithm.
- Compiler options such as `-fwrapv` or `-fno-strict-aliasing` change selected implementation behavior; they do not make generally invalid code portable.
- When behavior is implementation-defined and intentionally used, document the implementation guarantee and test every supported toolchain.

## Errors, Assertions, And `errno`

- Check every return value that can report a meaningful failure. Handle short reads and writes, interruption, partial progress, and end-of-file according to the API.
- Do not discard an error merely to satisfy a warning. If failure is irrelevant, make that decision visible.
- Use assertions for internal programmer-error invariants, never for malformed input, allocation failure, I/O failure, unavailable resources, or other expected conditions.
- Never put required side effects inside `assert`; defining `NDEBUG` removes the expression.
- Read `errno` only when the called function documents that it is meaningful. Save it before another call can overwrite it.
- Set `errno = 0` before a call only when that function's contract requires it to distinguish a valid result from failure.
- Prefer a library-owned error domain over exposing raw `errno` as the entire public API.
- Return enough diagnostic context for the handling boundary without leaking secrets or relying on a global mutable error buffer.
- Keep format strings literal when possible. Never pass attacker-controlled text as a format string.
- For variadic APIs, retrieve the type produced by default argument promotions and never read past the supplied arguments. Match every `va_start` and `va_copy` with `va_end` in the same function, use `va_copy` rather than assignment to duplicate a `va_list`, and do not reuse a `va_list` after a callee consumes it unless the contract permits and it is correctly reinitialized.

## Concurrency And Signals

- A data race is undefined behavior. `volatile` is not synchronization.
- Protect shared mutable state with mutexes or C atomics and document which lock or atomic protocol protects each field.
- Use sequentially consistent atomics by default. Use weaker memory orders only with a documented proof and focused tests.
- Do not assume atomic types are lock-free when lock freedom is a requirement; query or constrain the implementation.
- Establish lock ordering, wait on condition variables in a loop that rechecks the predicate, and keep synchronization objects alive until all users have stopped.
- Prefer reviewed locks and ownership partitioning over custom lock-free algorithms unless measured requirements justify the proof burden.
- Make thread ownership, cancellation, shutdown, and join behavior explicit. Bound queues and producer fan-out.
- In signal handlers, call only operations guaranteed async-signal-safe by the target contract. Communicate with normal code through a reviewed signal-safe mechanism.
- Do not access ordinary shared state from a signal handler. `volatile sig_atomic_t` has a narrow signal-specific role and does not provide thread synchronization.

## ABI, FFI, And Public Libraries

- Treat exported symbols, calling conventions, public layouts, enum values, and ownership rules as compatibility contracts once stability is promised.
- Prefer opaque handles and functions over externally allocated public structs.
- Specify exact widths, nullability, allocator, error domain, callback lifetime, and threading rules at every foreign boundary.
- Do not expose `long`, bit-fields, implementation-sized enums, or compiler-specific extensions in a cross-platform ABI without an explicit platform contract.
- Add `extern "C"` guards to public headers intended for C++ consumers.
- Hide internal symbols and export only the intended surface using the repository's platform mechanism.
- Do not let C++ exceptions, Rust panics, Odin panics, or other foreign unwinding cross the C ABI boundary.
- Keep allocation and release on the same side of the ABI unless a matching allocator contract is explicitly shared.
- Verify required layout with compile-time assertions and ABI tests on every supported target.

## Preprocessor And Build Boundaries

- Use include guards or the repository-supported equivalent consistently.
- Keep conditional compilation small and test every supported branch. Prefer platform modules over deeply interleaved `#ifdef` logic.
- Use feature-detection macros or build-system checks for compiler and library capabilities.
- Avoid redefining reserved identifiers and implementation macros.
- Do not put non-`static` object or function definitions in headers unless the linkage design explicitly requires it.
- Keep third-party warning policy separate from first-party code. Do not weaken diagnostics globally to accommodate generated or vendor sources.

## Security Boundaries

- When code handles untrusted input, authentication, cryptography, paths, commands, archives, network protocols, plugins, or privileged operations, load `@security/` and threat-model the boundary.
- Bound input, output, decompression ratios, recursion, allocations, collection growth, retries, and total work.
- Treat integer conversion and allocation arithmetic as part of memory safety.
- Treat paths as traversal boundaries, outbound destinations as SSRF boundaries, subprocess construction as injection boundaries, and format strings as code-like inputs.
- Use cryptographically secure random APIs appropriate to the target for keys and tokens. Do not use `rand()` for security.
- Prefer memory-safe implementation languages for new exposed components when constraints permit; if C is required, isolate parsers and unsafe boundaries and raise the verification bar.

## Diagnostics And Hardening

- Derive exact flags from supported compiler versions and CI. A reasonable GCC/Clang starting profile for controlled C17 code is:

```sh
-std=c17 -Wall -Wextra -Wpedantic
-Wconversion -Wsign-conversion -Wshadow -Wformat=2 -Wundef
-Wstrict-prototypes -Wmissing-prototypes -Wcast-align -Wcast-qual
```

- Add warnings incrementally in an existing codebase and understand each finding. Do not add casts or blanket suppressions merely to make the build quiet.
- Use warnings-as-errors for controlled first-party code in pinned CI. Do not impose blanket `-Werror` on downstream builders, unknown compiler versions, generated code, or third-party headers.
- Run at least one compiler-integrated static analyzer and a second independent analyzer when risk justifies it. Keep suppressions narrow, reviewed, and explained.
- Treat production hardening as target-specific. Consult current OpenSSF/compiler/platform guidance before selecting stack protection, fortification, PIE/PIC, RELRO, control-flow, or linker flags.
- Test production binaries as well as instrumented binaries. Hardening and sanitizers are complementary, not substitutes for correct code.

## Testing, Sanitizers, And Fuzzing

- Test behavior and contracts, including zero, one, maximum valid, and first-invalid values.
- Cover truncated and malformed input, embedded NULs, integer boundaries, overlapping ranges, partial I/O, allocation failure, partial initialization, and cleanup.
- Inject allocation failures at each acquisition point where practical and verify that every intermediate state is safely released.
- Run AddressSanitizer plus UndefinedBehaviorSanitizer in a dedicated supported configuration, commonly with `-fno-omit-frame-pointer -g` and non-recovering sanitizer policy.
- Run ThreadSanitizer separately for exercised concurrent code. Use MemorySanitizer only with a compatible Clang environment and sufficiently instrumented dependencies.
- A clean sanitizer run is not proof of correctness. Sanitizers cover executed paths and have platform and defect-class limits.
- Fuzz parsers, decoders, protocol handlers, file readers, and state machines with deterministic, fast harnesses. Bound each input and avoid sleeps, network access, and unrelated global state in the hot loop.
- Start fuzzing from useful seeds, combine it with sanitizers, minimize every failure, and preserve it as a regression test.
- Test every supported compiler family and relevant 32/64-bit, endian, hosted/freestanding, and optimized configuration. Use CI as the source of truth for the matrix.
- Verify stable ABI compatibility when promised and test public headers from both C and supported C++ consumers.

## Review Checklist

- Is every pointer's ownership, valid range, lifetime, nullability, and mutability clear?
- Can any size arithmetic overflow before allocation, copy, indexing, or conversion?
- Are all objects initialized before use and safely destroyable after partial initialization?
- Are all copies bounded, correctly terminated where needed, and overlap-safe?
- Does any expression depend on undefined, unspecified, or implementation behavior outside the project contract?
- Are return values, short operations, `errno`, cleanup failures, and assertions handled correctly?
- Is shared state synchronized under the C memory model, and is signal handling restricted to safe operations?
- Is the public ABI free of accidental layout, allocator, compiler, and exception assumptions?
- Do warning, analyzer, sanitizer, fuzz, optimized, and platform-matrix jobs exercise the change?

## Guardrails

- Do not invent a universal C style or architecture when the repository already has one.
- Do not solve type or warning problems with unexplained casts, macros, pragmas, or disabled diagnostics.
- Do not use assertions for external failures or required side effects.
- Do not return borrowed storage without a precise lifetime contract.
- Do not serialize native object representations as protocols.
- Do not use `volatile` as thread synchronization.
- Do not deploy sanitizers as production hardening without an explicit supported design.
- Do not apply safety-critical restrictions mechanically outside a safety-critical or similarly bounded system.

## Response Expectations

For substantial changes using this skill:

1. State the ownership, bounds, failure, concurrency, and ABI impact in plain language.
2. Identify every implementation-defined or platform-specific assumption.
3. Explain cleanup and partial-initialization behavior explicitly.
4. Point to the selected C standard, compiler/platform docs, SEI CERT C, or target-specific hardening guidance when specifics matter.
5. End with exact repository-appropriate compiler, test, analyzer, sanitizer, fuzz, and target-matrix commands.
