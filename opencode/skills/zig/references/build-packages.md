# Zig builds and packages

Read this reference when changing the build graph, package metadata, generated
code, test steps, or release artifacts. Resolve APIs from the pinned compiler.

- Treat `build.zig` as code that declares a dependency graph. Zig 0.17 separates
  configuration from execution and caches configuration; declare file/directory
  reads with the `dependOn*` APIs or deliberately poison the cache. Use explicit
  step dependencies and lazy paths, including `findProgramLazy` for execution-time
  program discovery; do not perform build actions while constructing the graph.
- Use `standardTargetOptions` and `standardOptimizeOption` when creating a new
  conventional project, unless the artifact intentionally constrains them.
- Do not hardcode `zig-out` or cache paths, mutate source files during a normal
  build, or bypass the graph for generated files.
- `addTest` creates a test compilation artifact; it does not execute tests. For
  host-runnable targets, connect `addRunArtifact` to the test step. For foreign
  targets, run through a configured emulator or system integration when
  execution is required; otherwise label the check as compile-only and never
  report that the tests ran.
- Derive package identity, hashes, fingerprints, local overrides, cache paths,
  and manifest fields from the selected Zig release. Declare an accurate minimum
  Zig version, include all build inputs and licenses in package paths, and inspect
  every manifest or identity change after package commands.
- Treat generated bindings and source as generated: modify the source header,
  schema, or generator input, then regenerate with the pinned toolchain.
- Keep tests, fuzzers, benchmarks, validation, and release artifacts discoverable
  as named `zig build` steps when the repository build graph owns them.
