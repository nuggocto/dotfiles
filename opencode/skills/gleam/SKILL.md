---
name: gleam
description: >
  Production-grade Gleam guidance focused on typed functional design, explicit
  errors, BEAM/OTP reliability, multi-target portability, and the Mist, Wisp,
  Pog, Squirrel, and Lustre ecosystem. Use when working with .gleam files,
  gleam.toml, manifest.toml, Gleam packages, Erlang or JavaScript targets, web
  services, actors, supervisors, PostgreSQL, or Lustre applications.
license: MIT
metadata:
  author: opencode
  version: "1.1.0"
---

# Gleam

Use this skill for production-grade Gleam applications, packages, web services,
BEAM systems, browser applications, command-line tools, and cross-target
libraries. Apply Mist, Wisp, Pog, Squirrel, Lustre, and OTP guidance only when
those technologies are present or deliberately selected. Prefer the
repository's established target, runtime, package structure, and dependencies
over generic defaults.

Resolve the Gleam compiler, `gleam_stdlib`, dependency, Erlang/OTP, and
JavaScript runtime versions from `gleam.toml`, `manifest.toml`, toolchain files,
containers, and CI before consulting APIs. Use version-matched official docs and
HexDocs. Latest documentation is useful for evaluating an upgrade, not evidence
that an API exists in the locked project. Run `gleam --version` and
`gleam help <command>` when exact local CLI behavior matters.

Apply `@tiger_style/` as an engineering overlay for bounds, mailbox and queue
growth, process ownership, resource accounting, and important internal
invariants. Gleam, BEAM/OTP, browser, and package semantics take precedence for
errors, panics, supervision, process links, target portability, FFI, and tests.
Supervision does not replace validation, backpressure, timeouts, or durable
workflow design.

## Workflow

1. Identify the artifact and constraints: application or library, Erlang or
   JavaScript target, OTP or JavaScript runtime, entrypoint, supervision model,
   external I/O, persistence, supported platforms, and deployment model.
2. Start with `gleam.toml`, `manifest.toml`, CI, `src/`, `dev/`, `test/`,
   entrypoints, FFI files, generated inputs, and deployment configuration.
   Follow callers, custom types, actor messages, supervisors, and target-specific
   declarations until behavioral and compatibility contracts are clear.
3. Preserve the existing target, package, framework, process, and database
   choices unless they are unsafe, broken, or clearly block the request.
4. Make the smallest change that keeps transformations, pattern matching,
   expected errors, effects, process ownership, and target support explicit.
5. Before editing generated code, find the source SQL, schema, generator, and
   pinned version; change the input and regenerate instead of hand-editing.
6. Verify narrowly first, then widen to formatting, warnings-as-errors builds,
   tests, documentation, every supported target/runtime, integration behavior,
   and the CI-equivalent matrix.

## Source Hierarchy

When sources disagree, separate language facts from project policy:

1. The selected compiler's behavior, matching official documentation, tagged
   source, command help, and changelog.
2. Versioned HexDocs and tagged source for the exact dependency release.
3. The repository's manifest, configuration, tests, and CI for intended behavior
   and supported targets; these do not override language or runtime semantics.
4. Current core-team and maintainer guidance for design rationale and upgrades,
   with the publication date and version made explicit.

Main-branch docs and blog posts may describe unreleased behavior or obsolete
syntax. Preserve sound rationale, but verify every API and command locally.
Use current stdlib APIs rather than removed names such as `result.then`,
`function.tap`, or `list.range`; derive replacements from the selected stdlib's
documentation instead of translating calls mechanically.

## Default Posture

- Optimize for reading, debugging, and maintenance rather than minimum typing.
  Prefer straightforward, conventional code over clever abstractions.
- Prefer immutable data, explicit transformations, exhaustive pattern matching,
  and concrete domain types.
- Model invalid states out of existence with custom and opaque types rather than
  correlated booleans or `Option` fields.
- Keep pure domain logic separate from I/O and runtime effects where that
  separation improves reasoning and testing.
- Prefer Gleam and the core packages. Add externals, actors, frameworks, code
  generation, and complex abstractions only for a concrete requirement.
- Treat Erlang and JavaScript as different runtimes with shared source support,
  not identical execution environments.

## Opinionated Stack Options

Use these for a new project only when its requirements fit. They are strong
ecosystem choices, not language-wide requirements.

| Area | Option | Notes |
| --- | --- | --- |
| Build and packages | Gleam CLI, `gleam.toml`, committed `manifest.toml` | Keep compiler and runtime versions aligned with CI |
| Portable foundations | `gleam_stdlib`, `gleam_time`, `gleam_json`, `gleam_http` | Prefer core-team types instead of recreating them |
| BEAM primitives | `gleam_erlang` | Low-level processes, names, ports, nodes, and applications |
| BEAM application structure | `gleam_otp` | Typed actors and supervisors; use only for runtime ownership boundaries |
| Tests | `gleeunit` | Default test runner for Erlang and JavaScript targets |
| HTTP server | Mist | Small Erlang-target HTTP server with streaming, WebSocket, and SSE support |
| Web application layer | Wisp with the Mist adapter | Middleware and handler conventions; not an ORM or mandatory MVC framework |
| PostgreSQL | Pog | Supervised connection pool, parameterized queries, typed row decoders, and transactions |
| Generated PostgreSQL access | Squirrel plus Pog | Development-time SQL generator; not an ORM or migration tool |
| UI and HTML | Lustre | SPA, Web Components, SSR, or server components; choose the relevant mode |
| Snapshots | Birdie, selectively | Use for small reviewed output, never as a substitute for behavior assertions |

Stay consistent with existing alternatives. Do not migrate a working stack
merely to match this table.

## Modules, Names, And Documentation

- Use `snake_case` for modules, functions, constants, arguments, and variables;
  use `PascalCase` for types and variants. Treat acronyms as words: `Json`, not
  `JSON`.
- Use singular module path segments such as `app/payment/invoice`.
- Qualify imported functions and constants (`result.map`, `list.reverse`). Import
  types and constructors unqualified only when that remains clear.
- Annotate arguments and return values for every module function, including
  private functions. Local binding annotations are usually unnecessary.
- Give conversions `x_to_y` names, or `to_y` when the module already identifies
  the input type. Name fallible functions for the domain; reserve `try_` for a
  result-propagating variant of an existing operation.
- Use full descriptive names rather than abbreviations.
- Use `////` for module documentation and `///` immediately before documented
  functions and types. Explain domain rules, effects, errors, target support,
  process ownership, and non-obvious decisions.
- Put every published module under the package's unique namespace. The BEAM has a
  global module namespace, so collisions across packages fail compilation.
- Organize modules around business domains and cohesive public APIs, not
  `types`, `utils`, `services`, `controllers`, design patterns, or category
  theory. Do not split a cohesive module merely because it is large.

## Types And Public APIs

- Use custom types to encode domain states and transitions. Replace context-free
  booleans with descriptive variants when the distinction belongs to the domain.
- Use `pub opaque type` plus smart constructors when callers need the type but
  must not construct or pattern-match its representation.
- Expose only the accessors and operations callers need. Public constructors,
  variants, function signatures, errors, and module names are compatibility
  contracts.
- Type aliases do not create new types or additional safety. Use a custom or
  opaque type when values must not be mixed.
- Match known custom-type variants explicitly instead of using `_` catch-alls.
  Exhaustiveness is compiler assistance when the model evolves.
- Prefer subject-first builder functions so pipelines read naturally. Keep
  required configuration in the initial constructor and make policy-significant
  defaults visible.
- Lists are singly linked. Prefer prepending and one reversal over repeated
  append, avoid indexing and repeated length checks, and pattern-match empty and
  non-empty shapes directly. Prefer tail recursion for potentially large or
  unbounded input; ordinary recursion is appropriate when depth is small or
  bounded and it makes the code clearer. Hide accumulators behind a clear public
  function.

## Results, Options, And Panics

- Return `Result(value, error)` for operations that can fail. Use `Option` for
  genuinely optional data, not as a second failure convention; use
  `Result(value, Nil)` when failure needs no detail.
- Design errors around the domain and include context useful for diagnosis.
  Translate lower-level errors at boundaries with explicit pattern matching or
  `result.map_error`; do not expose dependency errors accidentally as public API.
- Chain compatible fallible operations with pattern matching or `result.try`.
  Do not discard results merely to silence a warning.
- Reserve `panic` and `let assert` for intentional programmer-error crashes in an
  application with an explicit failure policy. Libraries must not panic, except
  for narrowly designed OTP libraries whose supervision contract makes the crash
  part of the API.
- Use the language `assert` for test expectations, not application validation.
- Avoid check-then-assert. Pattern-match once so the compiler keeps the check and
  use together.
- "Let it crash" means unexpected process-local defects may be restarted by a
  designed supervisor. It does not mean malformed input, unavailable resources,
  timeouts, authorization failures, or business rejection should panic.

## Pipelines And Use Expressions

- A pipeline passes its left value to the first argument of the call on the
  right. Design subject-first APIs and use an explicit capture when piping into a
  different position.
- Before 1.18, if first-argument insertion did not type-check, Gleam could turn
  `a |> b(c)` into `b(c)(a)`. Gleam 1.18 deprecates this call-result fallback;
  replace it with an explicit capture.
- A `use` expression is callback syntax: everything after it becomes an
  anonymous function passed as the final argument. It is not built-in early
  return, cleanup, cancellation, or error handling.
- Prefer a regular function call when it is already readable. Use `use` when it
  clearly removes callback or `Result` nesting, and keep the right side a normal
  function call where possible.
- Judge `use` by the called function's documented semantics. Never infer resource
  cleanup or process behavior from syntax alone.

## Targets And Portability

- Gleam targets Erlang or JavaScript. Set and document the intended target for an
  application; compile and test every target a library claims to support.
- Prefer pure Gleam and cross-target core packages for portable libraries. The
  compiler tracks target support at expression level, but Gleam has no
  expression-level conditional-compilation API. Isolate target-specific behavior
  behind single-target externals, multi-target externals, or a Gleam fallback.
- Use sans-I/O design for portable clients and SDKs: construct requests and parse
  responses while letting callers choose transport, scheduling, retries, and
  rate limiting.
- Do not force one concurrent I/O API across BEAM and JavaScript when the runtimes
  require materially different promise, callback, or process semantics. A clear
  target-specific API is better than a misleading lowest common denominator.
- Account for representation differences at boundaries: Erlang integers are
  arbitrary precision while JavaScript `Int` values are numbers; JavaScript can
  produce NaN and infinity; strings, tuples, `Nil`, bit arrays, and generated
  custom types have target-specific foreign representations.
- Require Gleam 1.18+ when JavaScript 16-bit float, zero-sized, or constant-string
  bit-array segments affect correctness; earlier compilers have known encoding
  and code-generation defects in these cases.
- Test dynamic decoders, integer precision, floats, bit arrays, and FFI on each
  supported target and JavaScript runtime.

## BEAM Processes And OTP

- Use a process only when state ownership, concurrency, lifecycle, distribution,
  or failure isolation justifies it. Do not put every module or function behind
  an actor.
- Prefer `gleam_otp` actors to raw receive loops for long-lived typed state, and
  prefer supervised children to detached startup processes. Gleam OTP 1.0 was a
  breaking redesign, so use examples for the installed major version rather than
  pre-1.0 actor, task, or supervisor APIs.
- Every long-running process needs an owner, explicit shutdown behavior, restart
  policy, observable failures, and a reason to exist.
- Actor handlers are sequential. Keep them bounded and avoid slow network calls,
  CPU-heavy work, or blocking cleanup in a shared actor unless serialization is
  the intended contract.
- BEAM mailboxes are not bounded automatically. Apply admission control,
  backpressure, bounded concurrency, message-size limits, and overload behavior.
  Supervision does not prevent mailbox memory exhaustion.
- Use finite call and receive timeouts. Current `actor.call` and `process.call`
  APIs panic when the callee dies, a name is missing, or a timeout expires; when
  timeout is expected domain behavior, model it through an explicit reply and
  timed receive or isolate the call under supervision. A call timeout stops only
  the caller's wait: queued or in-flight work may still run and reply later. Do
  not blindly retry non-idempotent work; use operation identifiers,
  deduplication, or explicit cancellation semantics where required.
- Understand links and monitors before spawning. Current `process.spawn` is
  linked; never assume a spawn is detached because another language uses that
  default.
- Create a fixed set of `process.Name` values during startup and pass them down.
  Do not call `process.new_name` for request, tenant, database, path, or other
  unbounded values: each name creates a non-garbage-collected Erlang atom, and
  unregistering the name does not reclaim that atom.
- Choose supervisor strategy, restart intensity, child restart type, order, and
  shutdown behavior from dependency topology and actual cleanup behavior.
  Worker children need bounded cleanup and a finite shutdown timeout;
  `supervision.timeout` is ignored for supervisor children, whose subtrees shut
  down recursively. Making every child permanent can create restart loops.
- Put shared dependencies before consumers in the supervision tree. Use
  `RestForOne` only when later children genuinely depend on earlier children;
  otherwise prefer independent restart behavior.
- Use `gleam_erlang.application.priv_directory` for packaged assets instead of
  assuming the working directory. Configure an OTP application start module only
  for an application that owns startup, not a reusable library.
- Resolve the effective OTP minimum from all dependencies. A stdlib-compatible
  OTP version may still be too old for the selected `gleam_erlang` or framework.

## Mist And Wisp

- Mist is an Erlang-target HTTP server; Wisp adds web handler and middleware
  conventions. Use a direct Mist handler for a small service and add Wisp when
  its body parsing, forms, cookies, security helpers, simulation, and middleware
  reduce total complexity.
- Start production Mist services with `mist.supervised` under the application
  supervisor. Keep `mist.start` for simple standalone ownership when appropriate.
- Bind only to the required interface. Expose `0.0.0.0` or IPv6 publicly only
  when the deployment network boundary requires it.
- Mist 6 handles HTTP/1.0, HTTP/1.1, and HTTP/2. Its HTTP/2 path currently
  supports byte responses but not file responses, WebSockets, chunked responses,
  or SSE; verify required response and connection modes before selecting it.
- Request bodies are lazy. Set route-appropriate limits before reading, enforce a
  cumulative limit for streamed or chunked bodies, and read a body only once
  unless the application deliberately caches it.
- Authenticate before WebSocket or SSE upgrades. Bound connections, messages,
  subscriptions, and per-user fan-out; validate browser WebSocket origins.
- Treat direct peer addresses and forwarded headers according to the deployment
  proxy trust model. Never trust client-supplied forwarding headers globally.
- Resolve static and download paths from an allowlisted root. Reject traversal
  and symlink escape; do not serve the repository, configuration, database, or
  secret directories.
- For Wisp 2.x, use at least 2.2.2. Versions before 2.2.2 have a chunked
  multipart limit bypass; versions from 2.1.1 through 2.2.0 also have an encoded
  static-file path traversal vulnerability. Recheck current advisories before
  selecting a version.
- Set per-route body, upload, and chunk limits rather than relying blindly on
  Wisp defaults. Uploaded filenames are untrusted. Mist and other compliant
  adapters delete temporary files when request handling completes; other
  adapters must call `wisp.delete_temporary_files`. Move validated files before
  the handler returns if they are needed later or asynchronously.
- Use a stable secret key base of the documented minimum size across restarts and
  replicas. Signed cookies provide integrity, not confidentiality; store no
  secrets in them.
- Apply CSRF protection to cookie-authenticated state changes and keep GET/HEAD
  free of side effects. Design CORS and cross-origin authentication explicitly.
- Escape user-controlled HTML or use typed rendering. Add a complete,
  application-appropriate security-header policy; nonce CSP middleware alone is
  not a full policy.
- Crash-to-500 middleware is an HTTP boundary, not observability or recovery.
  Monitor recurring crashes and fix their cause.

## Pog And Squirrel

- Pog is the runtime PostgreSQL pool and query client. Create its fixed pool name
  during startup, add `pog.supervised` before dependent children, and pass a
  `pog.Connection` or typed application dependency to consumers.
- Parameterize every data value with Pog or generated Squirrel parameters.
  Never concatenate untrusted values into SQL. Map dynamic identifiers and sort
  expressions through a closed allowlist.
- Size pools against database capacity across every replica, not local
  concurrency alone. Set timeouts and queue-shedding behavior deliberately, and
  use a real query for readiness when the service requires PostgreSQL.
- Pog's `default_config` uses `SslDisabled`. `url_config` also uses it when the
  URL has no query string; a query string without `sslmode` is rejected.
  Explicitly select `SslVerified` or use
  `sslmode=verify-ca` or `sslmode=verify-full` for remote production databases,
  and install the required CA roots. Unverified TLS is vulnerable to
  interception; disabled TLS is only appropriate inside a separately secured
  transport boundary.
- Keep transactions short and perform all transaction work through the provided
  connection. Do not make slow external calls while holding a connection and
  database locks.
- A row-decoder failure happens after PostgreSQL executed the statement. Outside
  a transaction, an unexpected result type does not prove a write was rolled
  back.
- Do not decode PostgreSQL `numeric` to `Float` for exact money or other decimal
  domains without explicitly accepting precision loss.
- Squirrel is a development-time PostgreSQL code generator. It is not an ORM,
  query builder, migration system, or runtime pool.
- Keep Squirrel as a development dependency and Pog as a runtime dependency.
  Generate from one reviewable statement per `.sql` file, commit generated
  `sql.gleam`, and run `gleam run -m squirrel check` in CI.
- Generate against a migrated disposable or dedicated database matching the
  production schema and extensions. Use a least-privileged account and do not
  expose generation traffic or credentials over an untrusted network. Current
  Squirrel 4.7 generation has no direct TLS configuration; recheck the installed
  version before using a remote database.
- Verify Squirrel's supported PostgreSQL version and type matrix. Current 4.7
  requires PostgreSQL 16+, does not support every PostgreSQL type, maps `numeric`
  to `Float`, and cannot infer nullable parameters reliably.
- Prefer separate explicit SQL statements for setting and clearing nullable
  fields. Do not universalize sentinel values that can collide with valid data.

## Lustre

- Lustre supports distinct SPA, Web Component, HTML/SSR, and server-component
  modes; choose one deliberately rather than treating them as interchangeable.
  Lustre 5 changed runtime, event, component, and server-component APIs, so match
  examples to the installed major version.
- Use a full Lustre application when effects are required and the simpler model
  only for state-only behavior. Keep initialization, update, and view pure where
  possible; put I/O in effects and feed results back as messages.
- Prefer ordinary view functions over stateful components. Use a component when
  an encapsulated update loop and lifecycle are genuinely useful.
- Use keyed elements for reordered collections. Add memoization only after
  measuring; retained dependency state and frequent invalidation can make it
  slower.
- Prefer typed elements and text nodes. Never pass untrusted content to unsafe
  raw-HTML APIs.
- Treat SSR hydration data as untrusted serialized input. Include no secrets,
  decode on the client, and handle missing, malformed, or stale state.
- For larger full-stack systems, consider separate Erlang server, JavaScript
  client, and cross-target shared packages. This keeps target-specific
  dependencies and runtime assumptions visible.
- Keep `lustre_dev_tools` in development dependencies. It can automatically
  download pinned Bun and Tailwind executables into the project and verifies
  embedded SHA-256 hashes; account for this network and executable supply-chain
  boundary, or configure a reviewed local or system binary.
- Its production build can minify bundles but does not fingerprint bundles or
  copied assets. Add a content-hashing or versioning step before serving them
  with immutable cache headers, and define an explicit cache policy.
- Server components still require transport integration. Authenticate and
  authorize each connection, verify CSRF and browser origin server-side, bound
  connection and message growth, and clean up subscriptions on disconnect.
- Use `lustre/dev/simulate` for pure model/view/message behavior, but remember it
  does not execute effects or reproduce browser event propagation. Use browser
  end-to-end tests for hydration, focus, accessibility, Web Components, network
  effects, and reconnection.

## Externals And Interoperability

- Prefer Gleam implementations and existing packages. The official externals
  guide says most projects should not need foreign functions.
- Keep every external declaration fully annotated and behind a small Gleam API.
  The compiler trusts the declaration; it cannot verify the foreign function,
  representation, return type, or exception behavior.
- Design the public API for Gleam, not as a mechanical copy of Erlang, Elixir, or
  JavaScript. Use a precise external handle type rather than a broad `Pid` or
  `Dynamic` type.
- Do not use `Dynamic` to weaken a known FFI type. Use it only for genuinely
  untyped input and decode immediately at the trust boundary.
- Convert foreign exceptions and irregular return values into typed results.
  Bare `ok`/`error` atoms are not Gleam `Result` values; Erlang character lists
  are not Gleam UTF-8 strings; improper lists are not Gleam lists.
- Elixir externals still use the `erlang` target and the `Elixir.ModuleName`
  module name. Load `@elixir/` when substantial Elixir behavior is in scope.
- Since Gleam 1.13, use generated JavaScript constructors, predicates, and field
  accessors for Gleam data. Do not depend on compiler-internal object layouts or
  mutate JavaScript arrays used as Gleam tuples. Zero-field variants are
  singleton values on current JavaScript output, so never use object identity or
  historical layouts as an interoperability contract.
- Gleam does not manage npm dependencies. Declare, lock, audit, and document
  JavaScript packages using the selected runtime's package manager; do not vendor
  them into published Hex packages merely for convenience.
- Native code and NIFs share the BEAM process. Keep regular NIF calls short,
  classify unavoidable blocking work correctly, and remember that a crashing
  NIF can crash the VM. Load the relevant native-language and `@security/` skills
  for that boundary.

## Dependencies, Manifests, And Publishing

- Commit `manifest.toml` for deterministic builds and auditing. Do not hand-edit
  it; use Gleam dependency commands and inspect the resulting diff.
- Use Gleam 1.18+ when resolving or downloading Hex dependencies so package
  checksums and requirements are verified from signed registry metadata.
- Declare every imported package directly. A transitive dependency is not an
  implicit public dependency.
- Use compatible SemVer requirements while setting the package's Gleam
  requirement to the earliest compiler actually supported. Pin application
  toolchains and runtimes in CI and deployment.
- Prefer immutable Git commit references over branches or mutable tags when a
  dependency is not on Hex. Gleam 1.18 Git dependencies can specify `path` for a
  package subdirectory in a monorepo; inspect the generated manifest entry.
- Put shipped code in `src/`, tests in `test/`, and development programs or
  generators in `dev/`. Only `dev/` and `test/` may rely on development
  dependencies.
- Use the canonical `dev_dependencies` and `tag_prefix` configuration spellings
  rather than the legacy accepted hyphenated aliases.
- Keep package-internal helpers beneath the package's internal namespace when
  they should not become stable public API.
- For published packages, document the API, generate and inspect docs, audit the
  export tarball, include licenses and required files, and follow real SemVer.
  Do not publish a prototype merely to distribute an unreleased dependency.

## Security Boundaries

- Load `@security/` for authentication, authorization, cryptography, untrusted
  paths or URLs, uploads, process execution, deserialization, external code, or
  privileged operations.
- Decode untyped JSON and foreign data immediately into domain types. Bound body,
  header, upload, decompression, parser, collection, mailbox, queue, concurrency,
  response, and per-request work.
- Never generate atoms or process names from untrusted or unbounded input.
- Treat file serving and uploads as traversal and lifecycle boundaries, outbound
  networking as an SSRF boundary, and JavaScript/Erlang externals as untyped code.
- Use parameterized SQL, verified TLS, least-privileged database users, explicit
  transaction scope, and server-owned authorization context.
- Keep secrets out of URLs, logs, signed-but-readable cookies, generated files,
  client hydration state, crash reports, and test snapshots.
- Review package locks, Hex/Git/npm provenance, advisories, generated code, FFI,
  build scripts, and runtime images as supply-chain inputs.

## Testing And Verification

- Use `@test_quality/` when writing or reviewing tests. `gleam test` runs the
  package's `<package>_test.main`; with gleeunit, that function must import
  `gleeunit` and call `gleeunit.main()`. Gleeunit then discovers public functions
  under `test/` whose names end in `_test`; a panic fails the test.
- Prefer Gleam's `assert` and `let assert` in tests. Older
  `gleeunit/should` examples are obsolete for new code.
- Test success and exact error variants, opaque smart constructors, exhaustive
  state transitions, decoder failures, and target-specific representations.
- Keep process tests bounded with monitors, finite receives, and timeouts. Do not
  sleep for guessed scheduling delays. Tear down supervisors, pools, sockets,
  files, and browser resources between tests. Reuse a bounded set of process
  names across test cases; creating and unregistering fresh names still leaks
  atoms for the lifetime of the VM.
- Test supervision deliberately by crashing children and asserting the intended
  restart, escalation, and retained or rebuilt state.
- Test Wisp handlers with `wisp/simulate`, then retain focused real-socket Mist
  tests for streaming, limits, proxy behavior, WebSockets, and shutdown.
- Test Pog against a migrated disposable PostgreSQL instance, including
  unavailable pools, timeouts, constraints, transaction rollback, decoder
  failure, and pool saturation. Run Squirrel drift checks in CI.
- Test Lustre pure behavior with simulation and small reviewed snapshots where
  useful; use a real browser for DOM, hydration, accessibility, effects, and
  reconnection.
- Cross-target packages should build and test Erlang and JavaScript. Also run
  every JavaScript runtime the package claims to support.
- Use `@qa/` for the shipped server, browser application, library integration,
  deployment artifact, startup, readiness, shutdown, and upgrade behavior.

Derive exact commands from the pinned compiler and repository. A common baseline
for an Erlang-target application is:

```sh
gleam --version
gleam deps download
gleam format --check
gleam build --warnings-as-errors --target erlang
gleam test --target erlang
gleam docs build
```

For a portable package, add the supported JavaScript runtime matrix, for example:

```sh
gleam build --warnings-as-errors --target javascript
gleam test --target javascript --runtime nodejs
```

If Deno is in the supported matrix, gleeunit requires read permissions for
`gleam.toml`, `test`, and `build`; configure these under `[javascript.deno]`
before running `gleam test --target javascript --runtime deno`.

`gleam check` and `gleam test` do not currently accept
`--warnings-as-errors`; keep the explicit build gate. Use
`gleam run -m squirrel check` only when Squirrel is configured. Do not recommend
`gleam fix` when the selected compiler reports that it performs no fixes. CLI
runtime names and `gleam.toml` values may differ, such as `nodejs` versus `node`;
verify both with local help and versioned configuration docs.

## Performance And Operations

- Use `@benchmark/` for performance claims. Measure the shipped target and
  runtime with production-equivalent data, process topology, pool sizes,
  connection behavior, and external services.
- Bound actor mailboxes, WebSocket/SSE connections, database queues, request
  bodies, retries, and fan-out before load testing.
- Account for list traversal, immutable updates, process message size and copying,
  retained binaries, serialization, FFI crossings, browser rendering, and
  database round trips. Optimize measured hot paths, not functional-style myths.
- A single actor serializes its mailbox and can become a bottleneck. Partition
  state or remove the process only when ownership semantics and measurements
  support the change.
- Keep control-plane branching out of high-volume data paths where batching or a
  simpler transformation improves predictability.
- Profiling explains a benchmark result but can perturb scheduling and latency;
  validate conclusions with an unprofiled comparison.
- Emit structured operational context for requests, actors, database operations,
  and crashes without exposing secrets. Monitor mailbox growth, restart storms,
  pool checkout failures, query timeouts, and long-lived connections.

## Deployment

- For BEAM servers, prefer `gleam export erlang-shipment` when it matches the
  deployment model. Run it with a pinned compatible Erlang runtime; the shipment
  is not itself a bundled VM or a complete OTP release.
- Use `gleam export escript` only with a compiler that supports it and for an
  appropriate single-file BEAM CLI, not as the default server deployment.
- Distinguish liveness from readiness. Mist listening does not prove Pog reached
  PostgreSQL or that migrations and required dependencies are available.
- Define graceful shutdown ownership and deadlines for HTTP acceptance,
  long-lived streams, workers, supervisors, and database connections.
- JavaScript output is ES modules, not a production bundle. Use and pin suitable
  ecosystem tooling for browser assets, source maps, minification, and runtime
  package dependencies.
- Build and run as a non-root user where practical, keep secrets out of images,
  and verify the artifact in the same target/runtime combination used in
  production.

## Review Checklist

- Are the compiler, dependency, target, OTP or JavaScript runtime, and CI versions
  known and matched to the docs?
- Do custom and opaque types prevent invalid states, and are public variants and
  errors intentional compatibility contracts?
- Are expected failures returned as `Result`, panics reserved for designed
  process-local defects, and FFI exceptions translated?
- Does every actor, supervisor child, mailbox, pool, connection, stream, and
  callback have bounded work and an explicit lifecycle?
- Can untrusted input create atoms, paths, SQL, HTML, redirects, outbound
  requests, messages, or unbounded allocations?
- Are Mist/Wisp body and connection limits, Pog pool/TLS/transaction policy,
  Squirrel generation, and Lustre target mode explicit where used?
- Are all claimed targets/runtimes, real external dependencies, deployment
  artifact, and important failure path tested?

## Guardrails

- Do not recreate core Gleam package types or conventions.
- Do not fragment cohesive domain APIs into technical layers or generic utility
  modules.
- Do not panic in ordinary libraries or use assertions for external failure.
- Do not use actors merely to organize code or supervision as a retry policy.
- Do not create process names or atoms from unbounded input.
- Do not treat Erlang and JavaScript representations or concurrency as identical.
- Do not use `Dynamic` where a precise FFI type is known.
- Do not require Wisp, Squirrel, Lustre, or OTP when a smaller direct design fits.
- Do not hand-edit `manifest.toml`, Squirrel output, or other generated code.
- Do not rely on stale package examples without the locked version's HexDocs.

## Primary References

- Official documentation: `https://gleam.run/documentation/`
- Conventions, patterns, and anti-patterns:
  `https://gleam.run/documentation/conventions-patterns-and-anti-patterns`
- Writing Gleam and `gleam.toml`: `https://gleam.run/writing-gleam/`
- Command-line reference: `https://gleam.run/command-line-reference/`
- Externals guide: `https://gleam.run/documentation/externals`
- Gleam language tour: `https://tour.gleam.run/`
- Core package docs: `https://hexdocs.pm/gleam_stdlib/`,
  `https://hexdocs.pm/gleam_erlang/`, and `https://hexdocs.pm/gleam_otp/`
- Mist: `https://hexdocs.pm/mist/`
- Wisp: `https://hexdocs.pm/wisp/`
- Pog: `https://hexdocs.pm/pog/`
- Squirrel: `https://hexdocs.pm/squirrel/`
- Lustre: `https://hexdocs.pm/lustre/`
- Gleeunit: `https://hexdocs.pm/gleeunit/`
- Gleam version 1, by Louis Pilfold:
  `https://gleam.run/news/gleam-version-1/`

## Response Expectations

For substantial changes using this skill:

1. State the compiler, target, runtime, process/supervision, and compatibility
   impact.
2. Call out custom-type, error, effect, mailbox, timeout, FFI, database, and
   security contracts.
3. Explain framework and package choices from requirements rather than popularity.
4. Point to official or version-matched HexDocs when API details matter.
5. End with exact repository-appropriate format, warnings-as-errors build, test,
   target/runtime, integration, security, QA, or benchmark verification performed.
