---
name: fastapi
description: >
  Production-grade FastAPI and Pydantic guidance focused on ASGI lifecycle,
  dependency scopes, async correctness, validated API contracts, security,
  streaming, testing, and deployment. Use when working with FastAPI, Starlette,
  Pydantic request/response models, APIRouter, Depends, Uvicorn, or ASGI APIs.
license: MIT
metadata:
  author: opencode
  version: "1.0.0"
---

# FastAPI

Apply `@python/` first for Python semantics, typing, exceptions, task ownership, packaging, security, testing, and performance. This skill adds FastAPI, Starlette, Pydantic, ASGI, and deployment-specific guidance. Apply `@tiger_style/` as an overlay for bounded resources and explicit invariants without replacing HTTP validation, exception handling, cancellation, or dependency cleanup.

FastAPI remains pre-1.0. Resolve exact FastAPI, Starlette, Pydantic, AnyIO, HTTPX, Uvicorn, Python, ORM, and security-library versions from `pyproject.toml`, lockfiles, installed metadata, and CI before using APIs. Pin and test the intended FastAPI minor or exact release; do not assume current online docs match the repository. Preserve FastAPI's compatible Starlette constraints instead of independently upgrading transitive internals without evidence.

## Workflow

1. Identify the service constraints: API consumers, compatibility policy, trust boundaries, authentication, storage, async/sync drivers, streaming or WebSockets, background work, worker model, proxy topology, and deployment limits.
2. Start with `pyproject.toml`, lockfile, app factory/entrypoint, routers, dependencies, schemas, exception handlers, middleware, lifespan, persistence, tests, OpenAPI checks, and deployment configuration. Follow dependency trees and service calls until resource and authorization contracts are understood.
3. Preserve established ORM, migration, auth, HTTP client, settings, and deployment choices unless unsafe or deliberately migrating.
4. Make the smallest change that keeps transport parsing, authorization, business policy, transaction ownership, and response contracts distinct.
5. Verify endpoint behavior, dependency teardown, lifespan, OpenAPI, async/blocking behavior, security boundaries, and deployment configuration with version-matched tools.

## Structure And Boundaries

- Compose feature-oriented `APIRouter` modules into a small application entrypoint. Use router prefixes, dependencies, tags, and documented responses deliberately.
- Keep handlers focused on HTTP translation: validated input, authentication/authorization dependency results, one application operation, and response mapping.
- Keep business policy independent of FastAPI types when that improves reuse and testing. Do not pass `Request`, `Response`, or `HTTPException` deep into domain and persistence code.
- Use an app factory when tests or deployments need different configuration or resources.
- Keep process-owned resources in lifespan and request-owned resources in dependencies. Avoid import-time network connections, model loading, event-loop work, and mutable singleton initialization.
- Before editing generated OpenAPI clients, schemas, or ORM output, change generator inputs and regenerate with pinned tools.

## Lifespan And Process Resources

- Use `FastAPI(lifespan=...)` with `@asynccontextmanager` for pools, shared HTTP clients, model loading, telemetry, and process-owned resources. Treat deprecated startup/shutdown event handlers as legacy unless the pinned version requires them.
- Code before lifespan `yield` must make the worker ready or fail startup; code after it must perform bounded deterministic shutdown.
- Providing lifespan disables startup/shutdown handlers, and mounted sub-application lifespans do not automatically run. Test the actual application topology.
- Lifespan executes independently in every worker. Account for one pool, model copy, cache, and telemetry exporter per process.
- Expose process resources through typed dependencies or deliberate lifespan/app state. Do not construct pools, clients, or large models per request.
- Run one-time migrations and administrative setup outside replicated worker startup.

## Dependencies

- Prefer `Annotated[T, Depends(provider)]` and reusable annotated aliases where they preserve type information and clarify policy.
- Dependencies may be sync or async and compose recursively. Keep dependency graphs shallow enough to reason about and reserve them for request concerns, resource acquisition, and policy seams rather than arbitrary business execution.
- Dependencies are cached once per request by default. Use `use_cache=False` only when every injection genuinely requires a fresh value.
- A dependency with one `yield` is a context manager. Use `try/finally`, preserve teardown ordering, and re-raise caught exceptions or raise a deliberate replacement; never swallow failures around `yield`.
- Check the pinned FastAPI dependency-scope API. Request-scoped cleanup can occur after response sending; function-scoped cleanup occurs before response sending. Choose based on whether serialization or streaming still needs the resource.
- Never pass request-scoped sessions, uploads, responses, or clients into background work. Pass immutable identifiers and reacquire resources in the worker.
- Override dependencies in tests narrowly and restore overrides after each test.

## Async, Sync, And Blocking Work

- Use `async def` when the handler and dependencies await non-blocking I/O. Use ordinary `def` for blocking libraries when FastAPI's thread-pool execution is appropriate.
- FastAPI offloads sync handlers and sync dependencies, not ordinary sync helper functions called directly from `async def`.
- Never run blocking database calls, filesystem operations, synchronous SDKs, password hashing, model inference, or CPU-heavy work directly on the event loop.
- Use a sync handler, a deliberately bounded AnyIO thread call, process execution, or durable worker according to lifetime and cancellation requirements.
- Starlette's shared thread limiter is also used by sync endpoints, dependencies, uploads, file responses, and sync background tasks. Do not increase capacity without measuring queue time, memory, pool sizes, and downstream limits.
- Bound external calls, concurrent tasks, executor submissions, model inference, and connection pools. Cancellation of thread work does not reliably stop already-running code.
- Keep streaming generators and WebSocket loops cancellation-aware and release upstream clients, files, sessions, and subscriptions in `finally`.

## Pydantic Models And Validation

- Use explicit Pydantic request and response models. FastAPI response models validate, serialize, document, and filter output; `response_model` overrides the return annotation.
- Separate create, update, public, internal, and persistence models when their capabilities differ. Never rely on ad hoc exclusion to prevent password hashes, tokens, or private fields from escaping.
- Pydantic is coercive and ignores extra fields by default. Choose `ConfigDict(extra="forbid")`, field strictness, or model strictness intentionally for external contracts.
- Do not enable global strictness blindly for query strings, headers, or environment variables because those sources naturally begin as strings. Test Python-input and JSON-input behavior separately where strict conversion matters.
- Nullable is not optional: `str | None` remains required unless a default is supplied. Enable default validation when defaults must satisfy field contracts.
- For Pydantic v2 use `model_validate`, `model_validate_json`, `model_dump`, `model_dump_json`, `model_copy`, `model_json_schema`, `TypeAdapter`, `field_validator`, and `model_validator`. Preserve v1 APIs only in an explicitly version-constrained legacy project.
- Prefer built-in constraints and deterministic after-validators. Keep validators free of network, database, and mutable global side effects. A `TypeError` in a v2 validator is not automatically a validation error.
- Use `model_construct()` only for already trusted validated data and after profiling demonstrates value.
- Treat subclass/polymorphic serialization as a security decision; verify which fields can appear and do not enable serialize-as-any behavior globally around sensitive models.
- Match Pydantic validation failures by stable error type, not English message text or exact incidental schema layout.

## Settings And Secrets

- Use the separate `pydantic-settings` package when present and version-match its API. Create one validated settings object at startup with explicit prefixes and required production fields.
- Make source precedence intentional across initialization, environment, dotenv, mounted secrets, and custom/cloud sources; test aliases, case sensitivity, nested delimiters, and defaults.
- Use `.env` only for local development. Production secrets belong in a secret store or mounted secret files.
- Fail startup when required configuration is missing. Do not log full settings dumps or place secrets in OpenAPI examples.
- `SecretStr` masks common display paths but is not secure storage and does not remove copies from memory.

## Errors And HTTP Contracts

- Raise `HTTPException`; do not return it. Map expected domain failures centrally through exception handlers rather than scattering transport policy through service code.
- Use Starlette's `HTTPException` base when a handler must include errors originating below FastAPI.
- Define one stable error envelope with a machine code, safe message, optional field details, and request/trace ID. Keep unexpected exception details in telemetry and return a generic 500.
- Use status constants. Return 401 with `WWW-Authenticate` for missing or invalid credentials and 403 for authenticated-but-forbidden actions.
- Never return or indiscriminately log request bodies, validation payloads, prompts, uploads, cookies, authorization headers, or internal exception text.
- Once streaming response headers are sent, later failures cannot become a structured HTTP error. Validate and acquire failure-prone prerequisites before starting the stream where practical.

## Authentication And Authorization

- Load `@security/` for authentication, authorization, cryptography, uploads, user-controlled URLs/paths, commands, templates, or privileged endpoints.
- Prefer a maintained identity provider and standards-compliant OIDC/JWT verification over inventing an authentication protocol.
- Verify fixed allowed algorithms, signature, issuer, audience, expiry, not-before, and key rotation. JWT payloads are signed, not encrypted.
- Separate authentication from authorization. Dependencies establish identity; application/service policy enforces tenant, ownership, role, and scope against server-owned data.
- Never trust caller-supplied owner or tenant identifiers as authorization evidence. Test cross-tenant and object-level access explicitly.
- Use Argon2id for human passwords through a maintained library, generic login errors, short-lived access credentials, secure refresh/revocation design, rate limits, and CSRF protection for cookie-authenticated state changes.

## Middleware, CORS, And Proxies

- Middleware ordering is semantic: the last added wraps earlier middleware. Test request, response, exception, background-task, and dependency-cleanup interactions.
- Prefer pure ASGI middleware for tracing, request IDs, body accounting, and `ContextVar`-sensitive behavior. `BaseHTTPMiddleware` has context-propagation limitations.
- Keep request-specific middleware state inside each call, never on a shared middleware instance.
- Do not enable CORS unless a cross-origin browser client requires it. Allowlist exact origins, methods, and headers; credentialed CORS must not use broad wildcards. CORS is browser policy, not authorization.
- Trust forwarded headers only from actual proxies. Never expose a service that trusts all forwarded peers directly to untrusted networks.
- Configure host validation, TLS termination, proxy path/root behavior, and generated redirects/OpenAPI server URLs for the real topology.

## Database And Transactions

- Use one session per request or explicit unit of work; never share a session across concurrent requests or tasks.
- Match endpoint style to the driver: async sessions from async paths, sync sessions from sync paths or deliberate thread offloading.
- Let the application operation own commit and rollback. Avoid hidden commits in repository helpers and keep transactions short.
- Never hold a transaction while waiting on remote APIs, LLMs, streaming clients, WebSockets, or background work.
- Use a process-wide engine/pool created in lifespan and request-scoped sessions cleaned with dependencies.
- Size database pools across all replicas and workers. Before schema, index, transaction, or performance-sensitive query changes, load the matching database skill.
- Use expand-and-contract migrations, account for lock behavior and overlapping releases, and run bounded backfills separately from worker startup.

## Persistence with SQLModel and SQLAlchemy

- Prefer SQLModel as the default persistence layer for new FastAPI code; it composes Pydantic models with SQLAlchemy tables and reduces translation boilerplate. Use SQLAlchemy directly when the project already standardizes on it, when SQLModel's model merging is too restrictive, or when advanced mapper/ORM features are required.
- Resolve exact SQLModel, SQLAlchemy, Alembic, and driver versions from `pyproject.toml`, lockfiles, and installed metadata before using APIs. SQLModel releases track SQLAlchemy closely; mismatched versions break table definitions and relationship helpers.
- Use Alembic for schema migrations. Keep migration scripts versioned, reversible, and reviewed. Run migrations from a dedicated deploy step or init container; do not run them inside every worker startup.
- Match the engine and session style to the endpoint: `create_async_engine` + `AsyncSession` for `async def` paths with an async driver such as `asyncpg` or `psycopg` in async mode; `create_engine` + `Session` for sync paths or deliberate thread offloading. Do not mix sync SQLAlchemy calls into `async def` handlers without explicit thread execution.
- Create one process-wide engine in lifespan and bind request-scoped sessions through dependencies. Close sessions in `finally` and roll back on unhandled exceptions before re-raising.
- Define SQLModel tables with explicit primary keys, indexes, constraints, and nullable semantics. Keep `table=True` models separate from public Pydantic response models when field exposure, computed fields, or serialization rules differ.
- Use relationships and lazy loading deliberately. Default lazy loading in async code raises errors or blocks the event loop; prefer explicit `selectinload`, `joinedload`, or eager strategies, and load related data before serialization.
- Never return SQLModel/SQLAlchemy objects directly from endpoints without an explicit response model or DTO. Map to Pydantic response models to control field exposure and avoid leaking internal state, passwords, tokens, or implicit relationships.
- Keep transactions short and owned by the application operation. Do not commit inside generic repository helpers unless that is the explicit contract, and never hold a transaction open across I/O boundaries.

## Background Work

- `BackgroundTasks` run after the response in the application process. Use them only for short, best-effort, non-critical work whose loss on crash or deploy is acceptable.
- Use a transactional outbox and durable queue/worker for billing, webhooks, indexing, code execution, retries, idempotency, scheduling, cancellation, or audit requirements.
- Pass immutable identifiers, not request sessions, temporary uploads, sockets, or live model objects. Re-open resources inside the job.
- Record job publication and completion outcomes. Do not report durable success to the client before durable enqueue succeeds.

## Uploads, Streaming, And WebSockets

- Use `UploadFile` for non-trivial uploads; a `bytes` file parameter reads the entire body into memory. Treat filenames and declared content types as untrusted.
- Enforce total request limits and timeouts at the edge/server plus endpoint-specific size, file-count, part-count, and decompression limits. Multipart parser limits do not replace a total body limit.
- Generate storage names, prevent path traversal, inspect or scan hostile formats where required, clean temporary files, and prefer direct object-storage uploads for very large objects.
- When consuming `Request.stream()`, do not later expect `.body()`, `.json()`, or `.form()` to remain available. Bound each upstream read and total bytes.
- Streaming chunks bypass Pydantic response serialization. Own encoding, media type, disconnect behavior, cleanup, and backpressure explicitly.
- Authenticate WebSockets during handshake, authorize each subscription/action, validate every message, and bound message size, rate, outbound queue, and idle lifetime.
- Catch disconnects and clean resources. In-memory connection registries work only in one process and disappear on restart; use external coordination for multiple workers.
- CORS does not secure WebSockets. Validate allowed origins where browser-origin policy matters.

## OpenAPI

- Treat generated OpenAPI as a versioned public contract. Lint and diff it in CI and run compatibility or client-generation checks before release.
- Give operations stable unique IDs and document every intended status, error envelope, auth requirement, media type, and streaming format.
- `responses={...}` documents alternatives but does not enforce arbitrary directly returned `Response` objects. Test runtime responses against the declared contract.
- Pydantic/FastAPI may generate separate input and output schemas. Preserve or change that behavior deliberately because it affects clients.
- Do not use response include/exclude shortcuts as the main public contract when OpenAPI still advertises the full model.

## Testing

- Use `TestClient` for synchronous tests and as a context manager when lifespan must run.
- For async tests, use the repository's AnyIO/pytest setup with `httpx.AsyncClient` and ASGI transport. HTTPX ASGI transport does not run lifespan automatically; use an explicit lifespan manager.
- Prefer an app factory and fixture-owned clients. Restore dependency overrides and close all resources after each test.
- Test validation and content-type failures, response filtering, error envelopes, authn/authz boundaries, transaction rollback, lifespan failure/cleanup, upload limits, streaming cancellation, WebSocket disconnects, proxy headers, and CORS policy.
- Set transport exception behavior appropriately when testing the actual 500 response rather than expecting the application exception to escape.
- Use disposable real databases for SQL, pool, transaction, migration, and isolation behavior; mocks do not validate those contracts.
- Snapshot or semantically diff OpenAPI and preserve regression tests for production failures.

## Deployment And Observability

- Run the version-pinned FastAPI/Uvicorn command from the repository. Development reload is not a production supervisor.
- Each worker is a separate process with separate memory and lifespan resources. Account for model size, pools, caches, and thread limits per worker.
- In orchestrated containers, prefer one application process per container and platform-level replication unless measured requirements justify an internal worker manager.
- Use exec-form container commands so termination signals reach the server. Run as non-root from immutable locked artifacts and use an external supervisor for restart.
- Separate startup, readiness, and liveness. Readiness waits for required resources and turns false before termination; graceful shutdown needs enough time for requests, streams, WebSockets, queue publication, and lifespan cleanup.
- Configure concurrency, keep-alive, graceful timeout, request duration, header/body limits, WebSocket limits, and trusted proxy IPs against the pinned server version.
- Emit bounded structured logs, metrics, and traces with request/trace ID, route template, method, status, latency, in-flight work, downstream timing, pool saturation, validation failures, worker restarts, and job outcomes.
- Capture unhandled exceptions once, propagate trace context to outbound calls and jobs, and keep telemetry export non-blocking and bounded.

## Guardrails

- Do not perform blocking work directly in `async def`.
- Do not create pools, sessions, HTTP clients, or large models per request without a measured reason.
- Do not retain request-scoped resources in background tasks or streaming work beyond their scope.
- Do not treat `BackgroundTasks` as durable execution.
- Do not return ORM/internal models without an explicit reviewed response contract.
- Do not trust wildcard forwarded headers, wildcard credentialed CORS, filenames, MIME declarations, tenant IDs, or JWT algorithms.
- Do not use in-memory WebSocket coordination with multiple workers as if it were shared or durable.
- Do not run migrations independently in every worker.
- Do not parse Pydantic errors by message or add deprecated v1 APIs to new v2 code.
- Do not log request bodies, prompts, source code, credentials, settings, or uploads by default.

## Response Expectations

For substantial changes using this skill:

1. State HTTP contract, dependency scope, resource lifetime, transaction, and async/blocking impact.
2. Call out validation, response filtering, authentication, authorization, and size/timeout boundaries.
3. Explain lifespan, background-work durability, streaming/WebSocket, and worker implications where relevant.
4. Point to version-matched official FastAPI, Starlette, Pydantic, AnyIO, HTTPX, and Uvicorn docs when specifics matter.
5. End with exact repository-appropriate format, type, test, OpenAPI, migration, and deployment verification commands.
