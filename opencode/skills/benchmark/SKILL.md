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
  version: "1.1.1"
---

# Benchmark

Use this skill when the user wants trustworthy performance measurements, not
vibes. A benchmark is an experiment: define the question, run the production-like
artifact, control the environment, collect enough samples, and report the result
with the uncertainty and caveats attached.

Pair this skill with the relevant language skill when the repository makes the
runtime obvious: `@rust/`, `@zig/`, `@go/`, `@gleam/`, or `@python/`. For
systems, storage, infrastructure, hot paths, or resource-exhaustion concerns,
also apply `@tiger-style/`. For real end-user verification use `@qa/`; for
regression tests around benchmarked behavior use `@test-quality/`; for
denial-of-service or quota risks use `@security/`. For browser Core Web Vitals
and page-load work, use `@web-perf/` as the measurement companion.

## Non-Negotiables

- Match the production code path, compiler and runtime options, target hardware,
  and deployment constraints. End-to-end tests should use the shipped artifact;
  microbenchmarks may use harness-built executables with equivalent optimization
  and features.
- Do not benchmark debug builds, dev servers, hot-reload modes, REPL sessions, or
  build-tool wrapper overhead unless that mode is deployed or is the explicit
  subject of the measurement.
- Always separate correctness from speed. A faster wrong result is a failure.
- For service or request latency, report the distribution and SLO-relevant
  percentiles rather than averages alone. For microbenchmarks, use the harness's
  statistically valid estimator and uncertainty.
- Report size whenever the artifact, binary, container image, bundle, memory
  footprint, install footprint, or dependency weight matters.
- Compare baseline and candidate under the same workload model, machine, build
  flags, runtime versions, data set, cache state, and controlled load variable.
- Preserve both machine-readable raw output and exact commands and configuration
  so someone else can reproduce and audit the run.
- Redact secrets, tokens, personal data, and sensitive endpoint details from
  commands, configuration, environment capture, raw output, and reports. Store
  raw artifacts only in an approved location.
- Distinguish operations, measurement samples, and independent runs. Report the
  effect size with harness-native uncertainty or run-to-run variability.
- Say when the result is not trustworthy. A noisy benchmark with caveats is more
  useful than a confident lie.

## Workflow

1. Identify the decision the benchmark must support: regression check, release
   validation, bottleneck hunt, implementation comparison, capacity estimate, or
   size budget.
2. Read the existing benchmark, build, profiling, and CI conventions before
   inventing new tooling.
3. Define the workload: input size, data shape, load model, concurrency or
   arrival rate, duration, request mix, cache state, cold or warm start,
   external dependencies, and success criteria.
4. Verify correctness with tests or known-good outputs before timing anything.
5. Build the production-equivalent artifact and record the exact command,
   profile, feature flags, target, optimization level, and relevant environment
   variables.
6. Stabilize and record the environment: quiet machine, power and thermal state,
   CPU placement and quotas when practical, pinned dependencies, known data set,
   and no unrelated heavy processes.
7. Warm up the runtime, cache, JIT, VM, database pool, and service dependencies
   when measuring steady state. Measure cold start separately.
8. Use harness-managed calibration and enough independent repetitions and
   observations to support the metric. Do not treat inner loop iterations as
   independent experimental samples.
9. Capture latency, throughput, errors, CPU, memory, allocation behavior, size,
   startup time, and any domain-specific resource that could explain the result.
10. Randomize or interleave repeated baseline and candidate runs to distribute
    drift, then compare against a predeclared practical threshold and the
    measured noise or uncertainty.
11. Benchmark and profile in the order that best locates and explains the
    bottleneck. Profiling is diagnostic and may perturb timing; validate claims
    with a separate unprofiled benchmark.
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

## Statistical Comparisons

- Use independent process runs or harness forks in addition to inner iterations
  when comparing implementations. One process performing a million operations
  is not a million independent experiments.
- Predeclare the practical regression budget and estimate the benchmark's noise
  floor. Statistical significance alone does not make a change important, and a
  non-significant result does not prove equivalence.
- Report the effect estimate, independent run count, and harness-native
  confidence interval, uncertainty, or run-to-run range. If uncertainty crosses
  the decision threshold, report the result as inconclusive.
- Randomize or interleave run order when drift is possible. Do not run every
  baseline first and every candidate second without a reason.
- Do not rerun until a preferred result becomes significant. When many metrics
  or benchmarks are tested, account for multiple comparisons or label the
  analysis exploratory.

## Percentiles

- p50 is the median recorded latency or operation duration. It represents a
  median user only when sampling and aggregation are explicitly user-weighted.
- p95 is the common tail that usually exposes cache misses, GC, retries, lock
  waits, and slow external calls.
- p99 is the severe tail. Size the run so enough observations lie beyond the
  target percentile and account for correlation; no fixed sample count alone
  guarantees a trustworthy estimate.
- Max is not a percentile or a stable regression statistic. Report it as an
  observed diagnostic tied to the run duration and sample count.
- Do not derive p95 or p99 from mean and standard deviation. Record raw samples,
  use a benchmark harness that reports percentiles, or use an HDR histogram.
- Report sample count and duration next to percentiles. `p99=120ms` without
  sample count is incomplete.
- Do not average per-run or per-instance percentiles. Merge compatible raw
  observations or histograms, or report the distribution of run-level results.
- Record histogram range, precision, overflow or dropped values, and timeout
  handling when those settings can change the reported tail.

## Load Models

- Declare the workload feedback model (open or closed), the controlled load
  variable (arrival rate or concurrency), and whether the test is a capacity
  sweep.
- Compare at the same offered arrival rate for latency-at-load questions, at the
  same concurrency for fixed-user questions, and across a load curve for
  capacity questions.
- For arrival-rate tests, report target and achieved rate, dropped or late
  starts, errors and timeouts, and whether latency starts at the scheduled or
  actual send time.
- Verify that the load generator is not CPU, network, connection, or file
  descriptor limited before attributing saturation to the system under test.
- Label coordinated-omission correction and its expected-interval assumptions;
  corrected synthetic observations are not equivalent to directly scheduled
  open-loop requests.

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
- For microbenchmarks, use harness-managed calibration, consume outputs, and
  guard against dead-code elimination, constant folding, loop-invariant
  hoisting, state reuse, and timer or harness overhead.
- Reset mutable state at the scope required for every iteration. Exclude reset
  cost only when it is outside the behavior being measured.
- If manual batching is unavoidable, verify the operation count and optimizer
  effects. Inspect generated code or counters when a result is surprising.
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
| Service | Config, non-sensitive environment names and values, log level, pool sizes, dependency endpoints |
| Data | Fixture source, database size, migration version, seed method |

Record CPU affinity or migration, governor and boost state, SMT and NUMA
placement, power source, thermal state, VM or container quotas, and concurrent
load when they can materially affect the result. Match production behavior
rather than disabling features reflexively. For distributed tests, capture both
the load-generator and system-under-test hosts.

When the environment cannot be controlled, call that out and treat the result as
directional rather than definitive.

## Language Integration

Use repository conventions, the active language skill, and documentation for the
project's pinned toolchain before choosing exact commands or APIs.

- For compiled code, match optimization, target CPU, features, linking, safety
  checks, panic behavior, allocator, and relevant code-generation options.
- For JIT, VM, or garbage-collected runtimes, use harness-supported warmup and
  independent forks and report runtime, scheduler, heap, and GC settings.
- For browser work, use production assets and `@web-perf/` for Core Web Vitals,
  trace analysis, network throttling, and device profiles.
- For databases, use production-like volume and indexes and capture plans, rows,
  buffers, locks, cache state, and connection settings. Use the applicable
  database skill and avoid destructive measurements on production.

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

- Compiled artifacts: confirm optimization, features, target, linker, symbols,
  LTO, safety checks, and that build-tool overhead is outside the timed region.
- Managed runtimes: confirm production configuration, warmup, scheduler or
  worker count, heap and GC settings, and log level.
- JavaScript and frontend: confirm production bundles and no dev middleware.
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
- Predeclare thresholds that match product risk and exceed the measured noise
  floor; do not choose a threshold after seeing the result.
- Track the number of independent runs and the comparison policy used by CI.
- Avoid uncorrected significance tests across a large benchmark suite; classify
  exploratory signals separately from release gates.
- Track size budgets separately from latency budgets.
- Run expensive benchmarks on dedicated CI runners or scheduled jobs if normal CI
  is too noisy.
- Treat performance tests like other tests: deterministic enough to trust,
  behavior-focused, and cheap enough to maintain.

## Guardrails

- Do not run destructive or intentional denial-of-service tests. Run load tests
  capable of affecting availability only against isolated authorized targets
  with explicit limits, monitoring, and stop conditions; never direct them at
  production or third-party systems.
- Do not hide failed requests, panics, dropped messages, validation skips, or
  changed output semantics behind faster numbers.
- Do not compare benchmarks from different machines, runtimes, build profiles,
  data sets, or commit states without labeling the comparison as directional.
- Do not report p99 from a tiny sample. Say there were not enough samples.
- Do not average percentiles, confuse inner iterations with independent runs, or
  rerun until a preferred result becomes significant.
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
- Artifact SHA/digest and build command/profile:
- Tool/harness version and configuration:
- Workload/data and load model:
- Duration/operations/samples/independent runs:
- Concurrency or target/achieved arrival rate:

Results:
| Metric | Baseline | Candidate | Delta and uncertainty | Notes |
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
- Raw-result artifact:

Interpretation:
- What changed:
- Practical threshold and noise floor:
- Statistical or run-to-run uncertainty:
- Why it likely changed:
- Caveats:
- Next bottleneck or follow-up:
```

## Response Expectations

When using this skill:

1. Lead with the benchmark verdict and whether the result is trustworthy.
2. Include p50, p95, p99, throughput, error rate, size, and sample count when
   those metrics apply.
3. Include the effect estimate, uncertainty, and independent run count for
   baseline comparisons.
4. State the build mode and explicitly call out release, production, or optimize
   settings.
5. Include exact commands, raw-result location, environment, workload, and data
   assumptions.
6. Separate observed numbers from interpretation and recommendations.
7. Call out missing coverage honestly: cold start, concurrency, memory, size,
   database scale, network variability, or production parity.
8. Prefer the smallest next measurement that will reduce uncertainty.
