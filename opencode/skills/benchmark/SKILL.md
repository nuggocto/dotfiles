---
name: benchmark
description: >
  Benchmark codebases, services, CLIs, libraries, and hot paths with
  reproducible measurements: latency p50/p95/p99, throughput, size, memory,
  allocations, startup, and regression comparisons. Use when asked to
  benchmark, profile, measure performance, compare speed or size, tune latency,
  or validate performance changes across any programming language.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
---

# Benchmark

Use this skill when the user wants trustworthy performance measurements, not
vibes. A benchmark is an experiment: define the question, run the production-like
artifact, control the environment, collect enough samples, and report the result
with the uncertainty and caveats attached.

Pair this skill with the relevant language skill when the repository makes the
runtime obvious: `@rust/`, `@zig/`, `@go/`, `@elixir/`, or `@gleam/`. For
systems, storage, infrastructure, hot paths, or resource-exhaustion concerns,
also apply `@tiger_style/`. For real end-user verification use `@qa/`; for
regression tests around benchmarked behavior use `@test_quality/`; for
denial-of-service or quota risks use `@security/`. For browser Core Web Vitals
and page-load work, use `@web-perf/` as the measurement companion.

## Non-Negotiables

- Benchmark the artifact users actually run: release, production, optimized, or
  otherwise explicitly matched to the deployment target.
- Do not benchmark debug builds, dev servers, hot-reload modes, REPL sessions, or
  `cargo run`-style wrapper overhead unless that overhead is the thing being
  measured.
- Always separate correctness from speed. A faster wrong result is a failure.
- Report latency distributions, not only averages. Include p50, p95, p99, max,
  and sample count whenever latency matters.
- Report size whenever the artifact, binary, container image, bundle, memory
  footprint, install footprint, or dependency weight matters.
- Compare baseline and candidate under the same workload, machine, build flags,
  runtime versions, data set, cache state, and concurrency.
- Preserve raw outputs or exact commands so someone else can reproduce the run.
- Say when the result is not trustworthy. A noisy benchmark with caveats is more
  useful than a confident lie.

## Workflow

1. Identify the decision the benchmark must support: regression check, release
   validation, bottleneck hunt, implementation comparison, capacity estimate, or
   size budget.
2. Read the existing benchmark, build, profiling, and CI conventions before
   inventing new tooling.
3. Define the workload: input size, data shape, concurrency, duration, request
   mix, cache state, cold or warm start, external dependencies, and success
   criteria.
4. Verify correctness with tests or known-good outputs before timing anything.
5. Build the production-equivalent artifact and record the exact command,
   profile, feature flags, target, optimization level, and relevant environment
   variables.
6. Stabilize the environment: quiet machine, fixed power profile when practical,
   no thermal throttling, pinned dependency versions, known data set, and no
   unrelated heavy processes.
7. Warm up the runtime, cache, JIT, VM, database pool, and service dependencies
   when measuring steady state. Measure cold start separately.
8. Run enough iterations or requests to support the metric. p99 needs many
   samples; do not invent it from a tiny run.
9. Capture latency, throughput, errors, CPU, memory, allocation behavior, size,
   startup time, and any domain-specific resource that could explain the result.
10. Compare baseline and candidate with the same method. Prefer repeated runs or
    interleaved runs when noise is visible.
11. Profile only after a benchmark shows where performance matters. Profiling
    explains a result; it does not replace the benchmark.
12. Report the verdict, the numbers, the environment, the commands, the caveats,
    and the next bottleneck or next validation step.

## What To Measure

| Area | Metrics | Notes |
| --- | --- | --- |
| Latency | p50, p95, p99, max, sample count | Use real distributions or histograms, not averages alone |
| Throughput | requests/sec, ops/sec, jobs/sec, rows/sec, MiB/sec | Report error rate and saturation point beside throughput |
| Size | binary, bundle, container image, compressed artifact, install size, dependency weight | State stripped vs unstripped and compressed vs uncompressed |
| Memory | RSS, peak RSS, heap, retained bytes, allocation count/rate, GC pressure | Peak memory often matters more than final memory |
| CPU | user/system time, CPU percent, cycles, instructions, branch misses | Prefer profiler counters when available |
| Startup | cold start, warm start, first request, time to ready | Include dependency initialization and migrations only when in scope |
| I/O | read/write bytes, fsyncs, network bytes, query count, cache hit rate | Separate local, network, and database costs |
| Reliability | errors, timeouts, retries, dropped work, queue depth | Faster with more failures is not an improvement |

If a metric does not apply, say why. Do not force p99 onto a tiny synchronous
function benchmark if the harness only produces mean, median, and confidence
intervals; use the best statistically valid metric for that level and explain
the substitution.

## Percentiles

- p50 is the median user or operation experience.
- p95 is the common tail that usually exposes cache misses, GC, retries, lock
  waits, and slow external calls.
- p99 is the severe tail. It needs enough samples to be meaningful, usually
  thousands of observations at minimum and often tens of thousands for load
  tests.
- Max is not a percentile, but it is still useful for spotting outliers,
  timeouts, pauses, and accidental blocking work.
- Do not derive p95 or p99 from mean and standard deviation. Record raw samples,
  use a benchmark harness that reports percentiles, or use an HDR histogram.
- Report sample count and duration next to percentiles. `p99=120ms` without
  sample count is incomplete.
- For services, prefer open-loop or latency-corrected load generation when the
  question is tail latency under a target arrival rate. Closed-loop tools can
  hide coordinated omission.

## Size Discipline

- Define the size budget first: binary size, bundle size, Docker image size,
  memory footprint, install footprint, generated code size, or dependency size.
- Measure the same artifact users ship. Debug symbols, stripping, compression,
  LTO, target CPU, panic strategy, and allocator choices can change the answer.
- Report units precisely: bytes, KiB, MiB, MB, compressed, uncompressed, stripped,
  unstripped, static, dynamic, or on-disk.
- For binaries, collect both file size and section-level size when it helps:
  text, data, bss, debug, symbols, and dependencies.
- For containers, report image digest or tag, compressed registry size when
  available, and local unpacked size when relevant.
- For web bundles, report production bundle size, gzip or brotli size, largest
  chunks, and source-map/debug artifact handling.
- For libraries, watch dependency graph growth and transitive heavy packages,
  not only final binary size.

## Benchmark Types

| Type | Use For | Good Practice |
| --- | --- | --- |
| Microbenchmark | Algorithms, parsing, serialization, small hot functions | Use a harness, warm up, avoid dead-code elimination, isolate setup |
| Macrobenchmark | CLI commands, full requests, jobs, pipelines, service flows | Run production artifacts with realistic data and dependencies |
| Load test | HTTP, queues, RPC, DB-backed services | Report concurrency, arrival rate, duration, errors, latency distribution |
| Startup benchmark | CLIs, serverless, containers, first request | Measure cold and warm separately |
| Size benchmark | Binary, image, bundle, install, dependency graph | Keep flags and compression identical |
| Regression benchmark | Before/after comparison | Same hardware, same commit baseline method, repeated runs |
| Profiling run | Explaining a known result | Use profiler output to find causes, not as the result itself |

## Workload Design

- Name the real scenario being modeled: one user action, one API endpoint, one
  job type, one CLI command, one parser input class, or one hot loop.
- Include the input distribution, not just the largest or smallest example.
- Test boundary sizes: empty, one item, typical, large, limit, and limit plus
  one when limits are part of the risk.
- Separate cold caches from warm caches. Both are useful; mixing them makes the
  result hard to interpret.
- Keep setup outside the measured section unless setup cost is part of the user
  experience.
- Include failure and timeout behavior for services. Tail latency often comes
  from retries, queueing, and dependency stalls.
- For database-backed code, use production-like row counts, indexes, query plans,
  and connection pool settings. Tiny fixture databases lie.
- For concurrent code, sweep concurrency levels instead of reporting one lucky
  number. Identify saturation and the point where p99 or errors degrade.

## Environment Capture

Record enough context to make the benchmark auditable:

| Category | Capture |
| --- | --- |
| Code | Git SHA, branch, dirty state, benchmark files changed |
| Machine | CPU model, core count, RAM, OS, kernel, container or VM status |
| Runtime | Compiler, interpreter, VM, package manager, libc, runtime flags |
| Build | Command, profile, features, target, optimization level, linker, strip/LTO |
| Workload | Input data, duration, iterations, concurrency, arrival rate, cache state |
| Service | Config, environment variables, log level, pool sizes, dependency endpoints |
| Data | Fixture source, database size, migration version, seed method |

When the environment cannot be controlled, call that out and treat the result as
directional rather than definitive.

## Language Defaults

Use repository conventions first. These defaults apply when the project has no
clear benchmark standard.

| Stack | Default Benchmark Posture |
| --- | --- |
| Rust | Use `cargo bench` for harnessed benchmarks and `cargo build --release` for CLI/service artifacts. Time `target/release/<bin>`, not `cargo run`. Check `Cargo.toml` profiles, features, target CPU, LTO, panic strategy, and allocator. Use Criterion, Divan, or Iai-Callgrind when appropriate. Use `std::hint::black_box` or the harness equivalent to prevent dead-code elimination. |
| Zig | Do not benchmark `Debug`. Use the intended optimize mode: usually `-Doptimize=ReleaseFast` for speed, `ReleaseSafe` when safety checks are part of the target, and `ReleaseSmall` for size. Report target, CPU, allocator, and build options. Use repo harnesses, `std.time.Timer`, or black-box CLI benchmarks around built binaries. |
| Go | Use `go test -bench=. -benchmem -run=^$ -count=10` for package benchmarks. Report `GOMAXPROCS`, Go version, CPU, allocations/op, bytes/op, and ns/op. Use `pprof` for CPU, heap, mutex, and block profiles. Build CLIs with `go build` and benchmark the binary. |
| Elixir | Use Benchee or the repo's existing harness. Prefer `MIX_ENV=prod` for meaningful production performance unless measuring dev/test behavior intentionally. Warm the BEAM, report Elixir/OTP versions, scheduler count, reductions, memory, GC behavior, and log level. Avoid IEx and debug logging for timing. |
| Gleam | Benchmark the intended target: Erlang/OTP or JavaScript. For BEAM targets, use a Benchee-compatible harness or benchmark generated artifacts through the release path. Warm the VM, report OTP/runtime versions, target, scheduler count, and whether code runs through FFI or native Erlang modules. |
| JavaScript/TypeScript | Use production builds and `NODE_ENV=production`. Do not benchmark dev servers, transpiler watch mode, or hot reload. Report Node/runtime version, package manager, bundler mode, and V8 warmup. Use Tinybench, Benchmark.js, autocannon, k6, or browser tooling as appropriate. |
| Python | Prefer `pyperf` for reliable microbenchmarks. Pin interpreter, virtualenv, dependency versions, CPU affinity where practical, and warmup. Avoid one-off `timeit` or wall-clock loops for noisy claims. Report CPython/PyPy and relevant C-extension versions. |
| JVM | Use JMH for microbenchmarks. Never trust an ad hoc loop without warmup and dead-code controls. Report JVM version, flags, GC, heap sizing, warmup iterations, measurement iterations, and fork count. |
| C/C++ | Use release flags such as `-O2` or `-O3` plus the repo's `NDEBUG` and linker settings. Keep compiler, target CPU, sanitizers, LTO, and debug symbols explicit. Use Google Benchmark, perf, Valgrind/Callgrind, heaptrack, or platform profilers. |
| Web Frontend | Use production build artifacts. Report bundle size, compressed size, Core Web Vitals, network throttling, device profile, and cache state. Use the `@web-perf/` skill for Lighthouse, DevTools traces, LCP/INP/CLS, and render-blocking analysis. |
| Database | Use production-like data volume and indexes. Report query plan, rows scanned, buffers, timing, lock waits, cache state, and connection settings. Use `EXPLAIN ANALYZE` carefully and avoid destructive tests on production. |

## Tooling Defaults

Prefer tools already in the repository. If none exist, choose the smallest tool
that answers the benchmark question.

| Target | Useful Tools |
| --- | --- |
| CLI commands | `hyperfine`, shell `time`, `/usr/bin/time -v`, built binary loops with raw samples |
| HTTP services | `oha`, `wrk2`, `vegeta`, `k6`, `autocannon`, `fortio` |
| Functions/libraries | Criterion, Divan, Benchee, Go benchmark, JMH, Google Benchmark, pyperf, Tinybench |
| CPU profiling | `perf`, `pprof`, Instruments, VTune, samply, flamegraph tools |
| Memory profiling | heaptrack, Valgrind Massif, `pprof` heap, language runtime heap tools, `/usr/bin/time -v` |
| Allocation profiling | language benchmark `allocs/op`, heap profilers, allocator stats |
| Binary size | `size`, `llvm-size`, `bloaty`, `cargo bloat`, linker maps, stripped file size |
| Bundle/container size | bundler analyzers, `du`, image inspect tools, registry-reported compressed size |
| Database | `EXPLAIN ANALYZE`, query stats extensions, slow query logs, database-native profilers |

If a tool does not report p50/p95/p99 directly, export raw samples or use a
histogram tool. Do not pretend a tool's mean is a latency distribution.

## Release And Build Checks

- Rust: confirm `--release`, bench profile, feature flags, target dir, and that
  benchmark code is not measuring `cargo` compile or launch overhead.
- Zig: confirm `-Doptimize` mode and whether the chosen mode intentionally keeps
  safety checks.
- BEAM languages: confirm production config, warm VM, scheduler count, and log
  level. Benchmarking a dev supervision tree can measure development tooling
  more than application code.
- JavaScript and frontend: confirm production bundle and no dev middleware.
- Containers: confirm the image tag or digest and whether cold image pull is in
  scope.
- Databases: confirm schema, indexes, statistics, row counts, and cache state.
- Native extensions and FFI: confirm whether time includes boundary crossings,
  copying, scheduler blocking, and serialization.

## Reading Results

- If throughput improves but p99 gets worse, call it out. That is often a trade,
  not a clean win.
- If latency improves only by dropping errors, timeouts, validation, fsyncs,
  durability, or security checks, call it a regression.
- If p50 improves but p95/p99 degrade, look for lock contention, queueing, GC,
  retries, allocation spikes, slow I/O, or unfair scheduling.
- If average improves while max explodes, hunt for tail risk before celebrating.
- If binary or bundle size grows, connect it to dependencies, debug symbols,
  generated code, linking mode, compression, or feature flags.
- If results vary between runs, report the variance and investigate noise before
  making a strong claim.

## Regression Tracking

- Keep benchmark inputs versioned when they represent important workloads.
- Store baseline results only when the environment is stable enough to compare.
- Prefer thresholds that match product risk, not arbitrary percentages.
- Track size budgets separately from latency budgets.
- Run expensive benchmarks on dedicated CI runners or scheduled jobs if normal CI
  is too noisy.
- Treat performance tests like other tests: deterministic enough to trust,
  behavior-focused, and cheap enough to maintain.

## Guardrails

- Do not run destructive or denial-of-service load tests against production or
  third-party systems without explicit authorization.
- Do not hide failed requests, panics, dropped messages, validation skips, or
  changed output semantics behind faster numbers.
- Do not compare benchmarks from different machines, runtimes, build profiles,
  data sets, or commit states without labeling the comparison as directional.
- Do not report p99 from a tiny sample. Say there were not enough samples.
- Do not optimize code that is not on the measured hot path unless there is a
  clear size, safety, or simplicity reason.
- Do not add dependencies or benchmark harnesses casually; prefer existing repo
  tooling and small reproducible scripts.
- Do not confuse profiler percentages with benchmark results. Profiles explain;
  benchmarks decide.

## Report Template

Use this shape when reporting benchmark work:

```text
Verdict: pass | fail | inconclusive | directional

Scope:
- What was benchmarked:
- Baseline:
- Candidate:
- Decision this supports:

Environment:
- Machine/runtime:
- Build command/profile:
- Workload/data:
- Duration/samples/concurrency:

Results:
| Metric | Baseline | Candidate | Delta | Notes |
| --- | ---: | ---: | ---: | --- |
| latency p50 | | | | |
| latency p95 | | | | |
| latency p99 | | | | |
| max latency | | | | |
| throughput | | | | |
| error rate | | | | |
| CPU | | | | |
| memory / peak RSS | | | | |
| allocations | | | | |
| artifact size | | | | |
| startup / cold start | | | | |

Commands:
- Build:
- Benchmark:
- Size:
- Profile, if any:

Interpretation:
- What changed:
- Why it likely changed:
- Caveats:
- Next bottleneck or follow-up:
```

## Response Expectations

When using this skill:

1. Lead with the benchmark verdict and whether the result is trustworthy.
2. Include p50, p95, p99, throughput, error rate, size, and sample count when
   those metrics apply.
3. State the build mode and explicitly call out release, production, or optimize
   settings.
4. Include exact commands, environment, workload, and data assumptions.
5. Separate observed numbers from interpretation and recommendations.
6. Call out missing coverage honestly: cold start, concurrency, memory, size,
   database scale, network variability, or production parity.
7. Prefer the smallest next measurement that will reduce uncertainty.
