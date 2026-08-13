---
name: python
description: >
  Production-grade Python guidance focused on explicit APIs, typing, resource
  lifecycles, structured concurrency, packaging, security, testing, and
  measurable performance. Use when working with Python code, .py/.pyi files,
  pyproject.toml, Python packages, scripts, services, CLIs, or async programs.
license: MIT
metadata:
  author: opencode
  version: "1.1.0"
---

# Python

Use this skill for production-grade Python applications, libraries, services, CLIs, workers, data pipelines, and tooling. Apply framework-specific guidance only when that framework is present; load the `fastapi` skill for FastAPI applications. Preserve the repository's supported interpreter, architecture, packages, and frameworks. Always use uv, Ruff, and ty for Python environments, dependencies, execution, formatting, linting, and type checking; read `references/astral-tooling.md` for setup and FastAPI integration.

Resolve the supported Python range and actual execution interpreter from `[project].requires-python`, lockfiles, CI, containers, deployment configuration, and version-manager files before using syntax or APIs. `requires-python` is a compatibility contract, not an exact runtime pin. Run supported Python lines on their latest maintenance or security patch release. Pin the full interpreter version in owned artifacts when possible; on managed or distribution-provided runtimes, use the strongest reproducibility control the platform supports. Use version-matched Python and dependency documentation; do not assume the newest local interpreter represents the project. For interpreter upgrades or version-sensitive runtime behavior, read `references/runtime-upgrades.md`.

## Workflow

1. Identify the artifact and constraints: application or library, supported Python versions and implementations, entrypoint, trust boundaries, external I/O, concurrency model, latency and memory budgets, and deployment model.
2. Start with `pyproject.toml`, lockfiles, environment/toolchain files, entrypoints, implementation, tests, generated-code inputs, and CI. Follow imports, callers, protocols, plugin entry points, and deployment configuration until behavior and compatibility contracts are understood.
3. Confirm the interpreter used by repository commands; do not assume `python` or `python3` resolves correctly. Use uv to select, install, and invoke the required interpreter.
4. Preserve established package and framework choices unless they are unsafe, broken, or clearly block the request. Use uv, Ruff, and ty even when older project tooling is present.
5. Before editing generated code, identify its source and pinned generator, modify the input or template, and review regenerated output for unrelated churn.
6. Make the smallest change that keeps API, ownership, cleanup, exception, cancellation, and compatibility behavior explicit.
7. Verify narrowly first, then run the repository's Python-version, OS, optional-dependency, typing, lint, test, packaging, and deployment matrix affected by the change.

## Default Posture

- Prefer simple functions, plain data, and cohesive modules over speculative class hierarchies, decorators, metaclasses, and dynamic dispatch.
- Prefer explicit dependencies and data flow over ambient mutable globals, import-time side effects, monkeypatching, or service locators.
- Use standard-library facilities when they fit, but do not reimplement a mature dependency whose maintenance and security value clearly exceeds its cost.
- Keep work, memory growth, retries, queues, recursion, concurrency, input sizes, and timeouts bounded.
- Preserve public behavior unless the user requests a breaking change. Treat argument names, accepted values, return types, exceptions, side effects, and cancellation as API.
- Do not optimize from intuition. Measure representative behavior before introducing caches, native extensions, process pools, or implementation-specific tricks.

## Names, Modules, And APIs

- Follow PEP 8 and repository style: `snake_case` functions and variables, `PascalCase` classes, and `UPPER_CASE` constants.
- Prefix implementation details with `_`; use `__all__` when exports require deliberate control. Keep `__init__.py` lightweight and avoid eager import graphs.
- Put imports at module scope unless delayed import is justified by optional dependencies, cycles, startup cost, or platform behavior. Avoid wildcard imports and production `sys.path` mutation.
- Avoid network I/O, process creation, event-loop creation, logging configuration, and expensive mutable initialization at import time.
- Use keyword-only parameters for optional behavior likely to evolve and positional-only parameters when names should not become compatibility contracts.
- Use properties only for cheap attribute-like behavior; do not hide I/O, blocking work, or surprising mutation behind attribute access.
- Do not expose mutable internal state unless caller mutation is an explicit contract. Copy caller-owned mutable input when isolation is promised.
- Treat dataclass equality, ordering, hashing, mutability, pattern matching, and generated constructor signatures as API choices, not automatic defaults.

## Typing

- Type annotations are static metadata by default, not runtime validation. Validate external data independently at trust boundaries.
- Annotate public APIs, interfaces, callbacks, serialization boundaries, and non-obvious internal values. Let obvious local variables be inferred.
- Prefer `object` when any value is accepted but must be narrowed before use. Use `Any` only for a deliberate escape from checking or behavior the type system cannot reasonably express.
- Prefer abstract input types such as `Iterable`, `Sequence`, and `Mapping`; return concrete collections when the API promises them.
- Use small `Protocol` interfaces for structural behavior. Do not require inheritance solely to satisfy typing.
- Avoid broad union returns that force callers to rediscover state; prefer distinct operations, tagged results, or stable result objects when practical.
- Keep every `cast`, `# type: ignore`, and checker suppression narrow and justified. Include diagnostic codes where supported and detect unused suppressions.
- Use typing syntax supported by the minimum declared Python. Use `typing_extensions` for maintained backports instead of silently raising the runtime floor.
- Published annotations are library API. Test complex typing contracts and preserve their compatibility deliberately.
- Treat runtime annotation introspection as potentially executable behavior. Use the selected interpreter's documented annotation API, and do not add future imports or change annotation evaluation semantics without checking runtime consumers.

## Exceptions And Assertions

- Derive application exceptions from `Exception`, not `BaseException`. Avoid multiple inheritance from built-in exception classes.
- Catch the narrowest exception that can be handled correctly and keep the protected `try` block small.
- Avoid bare `except`; when top-level cleanup must catch termination exceptions, clean up and immediately re-raise unless the process boundary deliberately reports them.
- For new APIs, normally raise `TypeError` for unsupported argument types and `ValueError` for invalid values of accepted types. Preserve established public and protocol-specific exception contracts.
- Translate lower-level exceptions only when the abstraction benefits. Preserve causality with `raise DomainError(...) from exc`; suppress context only when it is deliberately irrelevant.
- Do not log and re-raise the same exception at every layer. Report it once where enough context exists to handle or terminate the operation.
- Use `assert` only for programmer-error invariants. Optimized execution can remove assertions, so never use them for validation, authorization, required side effects, or recoverable failure.
- Account for `ExceptionGroup` and `except*` when concurrent operations can fail together. Avoid `return`, `break`, or `continue` when the statement exits a `finally` block: it can suppress an exception or override an earlier return. Treat interpreter warnings about this control flow as failures and rewrite it.

## Resources And Mutability

- Manage files, sockets, locks, transactions, temporary resources, executors, and clients with `with` or `async with`; use `try/finally` when no context manager exists.
- Use `ExitStack` or `AsyncExitStack` for dynamic resource sets and `contextlib.aclosing()` when an async generator may exit early.
- Make cleanup deterministic. Do not rely on reference counting, `__del__`, garbage collection, or interpreter shutdown.
- Specify text encodings at persistence and protocol boundaries.
- Never use mutable function defaults for per-call state. Use `None` or a private sentinel and construct the value inside the function.
- Use `dataclasses.field(default_factory=...)` for mutable dataclass fields.
- Do not make mutable objects hashable unless equality and hash remain stable for their full membership in hashed collections.
- Prefer immutable configuration, identifiers, cache keys, and cross-task messages when that simplifies ownership.

## Asyncio And Task Ownership

- Use `asyncio.run()` or `asyncio.Runner` at application boundaries. Libraries must not call `asyncio.run()` inside a caller-owned event loop.
- Prefer structured concurrency with `asyncio.TaskGroup` on supported Python versions for related work whose scope owns completion and failure.
- Every created task needs an owner that retains it, observes exceptions, handles cancellation, and shuts it down. Do not create untracked fire-and-forget tasks.
- Treat cancellation as normal control flow. Put cleanup in `finally`; if catching `CancelledError`, perform bounded cleanup and normally re-raise. Do not swallow cancellation or use `uncancel()` casually.
- Use deadlines and timeouts around external I/O. Understand where timeout exceptions are raised and which operation remains alive after cancellation.
- Use `asyncio.shield()` rarely and only with explicit task ownership; shielding one cancellation path does not make work immortal.
- Never block the event-loop thread with synchronous I/O, CPU-heavy work, sleeps, lock waits, or blocking log handlers. Use an appropriate thread, process, job worker, or async implementation.
- Cancelling an await of thread or process work does not reliably stop code already running. Design cooperative stop behavior or isolate killable work.
- Apply backpressure with bounded queues, semaphores, connection limits, and bounded executor submission.
- Most asyncio objects are not thread-safe. Cross into an event loop with its documented thread-safe APIs.

## Threads, Processes, And Runtimes

- Do not treat the GIL as synchronization. Shared mutable state needs explicit locks, immutable transfer, or single-owner discipline on every Python build.
- Use threads primarily for overlapping blocking I/O or native code that releases the GIL. Use processes for isolation, killability, or CPU parallelism when their serialization and startup costs fit.
- Guard multiprocessing entrypoints with `if __name__ == "__main__":`; keep worker callables and arguments importable and picklable for `spawn` and `forkserver`.
- Do not assume `fork` is the default or safe. Follow the selected Python version and platform, let library callers supply a multiprocessing context, and document required start methods.
- Never deserialize untrusted process, queue, pipe, cache, or interpreter messages that use pickle.
- Free-threaded CPython is optional, not the universal runtime. Its context inheritance and warning-filter defaults can differ from a GIL-enabled build, and it typically uses more memory. Do not depend on built-in container locking as a language guarantee; test the actual runtime, memory capacity, and complete native dependency set under conventional and free-threaded builds before claiming support.
- On a free-threaded build, verify after loading production dependencies that
  `sys._is_gil_enabled()` is false when GIL-free execution is required;
  unsupported extension modules may automatically re-enable the GIL.
- Treat subinterpreters as isolated in-process runtime contexts, not security
  boundaries. They provide no concurrency by themselves;
  `InterpreterPoolExecutor` combines threads with one interpreter per worker for
  multicore parallelism and pickles callables, arguments, initializers, and
  results. Verify extension compatibility, memory cost, failure containment, and
  shutdown behavior.

## Security Boundaries

- Load the `security` skill when a change creates or alters an authentication, authorization, cryptography, untrusted-file, archive, URL, template, command, plugin, deserialization, or privileged-operation boundary.
- Validate external type, format, length, count, recursion, decompression, timeout, and memory limits before expensive work.
- Never use `eval`, `exec`, unsafe dynamic imports, templates, or object deserialization on untrusted input. Python is not a security sandbox; `ast.literal_eval()` still permits denial-of-service inputs.
- Never unpickle untrusted or tamperable data, including through `shelve`, multiprocessing, caches, or socket logging.
- Use `subprocess.run()` with an argument sequence, `shell=False`, a timeout, and `check=True` where failure matters. Do not concatenate untrusted text into shell commands.
- Parameterize database queries. Treat outbound URLs and redirects as SSRF boundaries, paths and archives as traversal boundaries, and uploads as hostile content.
- Use `secrets`, not `random`, for tokens. Use maintained password-hashing and cryptographic libraries rather than designing algorithms.
- Use secure `tempfile` creation APIs; never use `tempfile.mktemp()`.
- Treat Python's remote-debugging interface as code execution. Hardened deployments should control access and, when the threat model requires it, disable the interface through the selected runtime's command-line, environment, or build option.
- Do not log secrets, credentials, authorization headers, session identifiers, tokens, or unnecessary personal data.
- Pin deployment dependencies through a reviewed lock, use immutable artifacts or hashes where supported, scan advisories, and apply least privilege. Scanners do not replace threat modeling.

## Packaging And Dependencies

- Use `pyproject.toml` for modern projects. For distributable projects, declare
  `[build-system]`; use standard `[project]` metadata when supported by the
  selected backend.
- Put published runtime requirements in `[project.dependencies]`, published
  feature extras in `[project.optional-dependencies]`, and non-published
  development requirements in `[dependency-groups]` when supported by the
  established tool. Dependency groups are not distribution metadata.
- Do not invoke `setup.py` directly for install, develop, test, build, or upload operations.
- Libraries should declare constraints they actually support, keep a reproducible
  CI baseline, and also test a fresh resolution of the allowed range. Add upper
  bounds only for known incompatibilities. Applications should commit reviewed
  lock data for each deployment environment, including selected extras and
  dependency groups.
- Do not add an upper `requires-python` bound merely because a future release is untested. Pin the actual application/deployment interpreter separately.
- Build sdist and wheel artifacts through a PEP 517 frontend and test installation from those artifacts in clean environments.
- Validate metadata and artifact contents before publishing. Prefer trusted CI publishing over long-lived upload credentials.
- For new distributions, use an SPDX expression in `[project].license` and
  declare `[project].license-files`; do not introduce the deprecated license
  table or license classifiers.
- Use uv as the environment, dependency, lock, build, and command runner. Remove redundant package-manager configuration and lockfiles only after uv reproduces the required environments and deployment artifacts.

## Toolchain And Quality

- Use uv for Python installation, virtual environments, dependency resolution, lockfile generation, syncing, building, and running commands in every project. Make `uv.lock` the canonical lock for applications and development environments.
- Use Ruff for formatting and linting and ty for type checking. For Python 3.7 through 3.9 targets, account for ty's incomplete bundled standard-library stubs when reviewing diagnostics, but do not replace ty with another checker.
- Pin Ruff and ty in the development dependency group and `uv.lock`. Pin uv through CI actions, installer versions, or toolchain metadata. Reproduce the same versions locally and in CI.
- Use `ruff format` instead of Black and isort, and `ruff check` instead of Flake8, pydocstyle, and overlapping plugins. Keep rule selection explicit and version-locked; do not enable every rule blindly.
- Keep ty configuration in `[tool.ty]` in `pyproject.toml` and align it with the minimum supported Python. Enable rules deliberately and keep suppressions narrow.
- Run the pinned tools locally and in CI with the same commands: `uv run ruff check .`, `uv run ruff format --check .`, and `uv run ty check`.
- Use `pre-commit` only when the team enforces it consistently; ensure hooks match CI versions and do not replace CI checks.
- Do not add tools merely because they are popular. Each tool in the pipeline must justify its maintenance and review cost.

## Logging And Observability

- Create module loggers with `logging.getLogger(__name__)`. Applications configure handlers and root levels once at startup; libraries do not call `basicConfig()` or attach operational handlers.
- Use deferred logging formatting rather than eager string construction for potentially disabled or expensive messages.
- Use `logger.exception()` only while handling an exception. Include actionable structured context without duplicate tracebacks or secrets.
- Use stable fields for operation, request/trace ID, outcome, duration, retry count, and resource identifiers. Use `contextvars` for context propagation where appropriate.
- Do not create loggers from unbounded request, tenant, or connection identifiers.
- Keep file/network logging and telemetry export off event-loop and latency-critical paths; centralize multi-process file output.

## Testing And Verification

- Load the `test-quality` skill when writing or reviewing tests. Test observable behavior and contracts, including success, invalid input, boundaries, partial failure, retries, cleanup, timeout, cancellation, and shutdown.
- Keep tests deterministic by controlling clocks, randomness, timezone, locale, environment, network, filesystem, and concurrency. Do not synchronize with arbitrary sleeps.
- Prefer real collaborators, focused fakes, and integration tests over deep mock graphs. Patch where a name is looked up and use `autospec` or `spec_set` when mocking.
- Assert cleanup and absence of leaked tasks, threads, processes, files, connections, and warnings.
- Use property-based tests for parsers, serializers, normalization, state machines, round trips, and broad invariant spaces. Preserve minimized failures as ordinary regression tests.
- Fuzz hostile-input boundaries and native extensions with explicit time, memory, input-size, and recursion limits.
- Run the suite on the minimum and maximum supported Python versions, relevant OSes, architectures, and optional dependencies. Test prerelease Python for libraries when practical.
- Turn warnings from project-owned code into CI failures. Use targeted category, module, or message filters for dependency warnings so third-party deprecations do not break CI without review. Run targeted tests with development mode, asyncio debug mode, and resource warnings.
- Use the repository's pinned uv, Ruff, and ty versions with a target matching `requires-python`. Keep one canonical invocation for local and CI use.
- Build and install package artifacts for release-sensitive changes. Coverage indicates execution, not assertion quality; inspect meaningful branches rather than chasing a percentage.
- Load the `qa` skill when the change needs validation of the shipped service, CLI, or package as a real consumer; unit tests and the test suite do not verify packaging, startup, deployment, or upgrade behavior.

## Performance

- Load the `benchmark` skill for performance claims. Measure the shipped service, CLI, or package with production-equivalent data, process topology, and dependency versions.
- Establish a representative workload, baseline, target metric, and correctness check before optimization.
- Improve algorithms, data movement, I/O count, serialization, batching, and cache design before micro-optimizing syntax.
- Measure latency distributions, throughput, memory, startup, and allocation behavior relevant to the deployed workload; separate cold and warm paths.
- Use `timeit` for isolated microbenchmarks, profiling for attribution, and a separate benchmark for performance claims.
- Use `tracemalloc` for Python allocation growth and an appropriate statistical or production profiler for long-running or mixed native/Python stacks.
- Control interpreter version/build, dependency versions, CPU allocation, dataset, process state, and variance. Re-measure tail latency and memory after each change.
- Avoid CPython-specific tricks unless measurements justify the compatibility cost. Free-threading, multiprocessing, and interpreter pools are architecture choices, not automatic speedups.

## Guardrails

- Do not add dynamic behavior where ordinary functions, types, and explicit registration solve the problem.
- Do not hide blocking work, I/O, mutation, or process creation behind innocent-looking APIs.
- Do not rely on assertions, type hints, or linters as runtime validation.
- Do not leave tasks, threads, processes, executors, or clients without owners and shutdown behavior.
- Do not introduce overlapping non-Astral environment, formatter, linter, or type-checker tooling.
- Do not broaden a refactor when a targeted change preserves behavior more safely.

## Primary References

- Python releases: `https://www.python.org/downloads/`
- Versioned Python documentation: substitute the selected `X.Y` in `https://docs.python.org/X.Y/`
- Python packaging specifications: `https://packaging.python.org/specifications/`

## Response Expectations

For substantial changes using this skill, unless the user requests another format:

1. State Python-version, public API, resource-lifecycle, and concurrency impact.
2. Call out exception, cancellation, typing, and trust-boundary decisions.
3. Distinguish language/runtime facts from tool and package preferences.
4. Point to version-matched official Python, PyPA, and dependency documentation when specifics matter.
5. End with exact repository-appropriate format, lint, type, test, package-build, and environment-matrix commands.
