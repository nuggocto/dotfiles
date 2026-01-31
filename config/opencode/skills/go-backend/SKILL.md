---
name: go-backend
description: Go backend development with stdlib-first mentality. Chi router, pgx+sqlc, Goose migrations, slog logging, Argon2id passwords, UUIDv7, testcontainers. Covers project structure, layered architecture (handler/service/repository), error handling, testing, security, and deployment.
---

# Go Backend Project Guidelines

## Project Philosophy

This project follows a **stdlib-first mentality** with minimal, focused dependencies. Security-conscious defaults are non-negotiable. Code should be explicit, readable, and maintainable.

### Project Tiers

Not every rule applies to every project size. Determine your tier:

| Tier | Description | Architecture |
|------|-------------|--------------|
| **Tier 1** | CLI tools, microservices, < 5 endpoints | Handlers may call sqlc directly; skip repository layer if overkill |
| **Tier 2** | Standard REST APIs, medium complexity | Follow this guide as documented |
| **Tier 3** | Platforms, monoliths, > 50 endpoints | Add CQRS, Event Sourcing, Circuit Breakers, DDD patterns |

> **Rule:** Start with Tier 1, refactor to Tier 2 when handlers exceed 200 lines, escalate to Tier 3 when you need distributed transactions.

### Stdlib-First Clarification

"Stdlib-first" means we don't import a library to save 5 lines of code. We use Chi (not Gin) because it's stdlib-composable, sqlc because it generates stdlib-compatible code, and validator because regex validation is error-prone. We avoid "frameworks" that hide `net/http`.

---

## Tech Stack

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Router** | Chi | **Required** | stdlib-compatible, idiomatic Go |
| **Database** | pgx + sqlc | **Required** | Generated type-safe Go from SQL |
| **Migrations** | Goose | **Required** | SQL migrations only, no Go migrations |
| **Logging** | slog | **Required** | Structured logging, stdlib |
| **Validation** | go-playground/validator | **Required** | With custom UUIDv7 validator |
| **Password Hashing** | Argon2id | **Required** | Via `golang.org/x/crypto/argon2` |
| **IDs** | UUIDv7 | **Required** | Time-sortable, `github.com/google/uuid` |
| **Testing** | testcontainers-go | **Required** | Integration tests with real dependencies |
| **CI/CD** | GitHub Actions | **Required** | Cloud-native CI/CD |
| **Deployment** | Dokploy/K8s | **Recommended** | Hetzner + Dokploy default, K8s for scale |
| **Payments** | Polar.sh | **Optional** | Only if handling subscriptions |
| **Caching** | Redis / Dragonfly | **Optional** | Skip if <100 RPM or single instance |
| **Message Queues** | RabbitMQ / RedPanda | **Optional** | Skip if sync processing suffices |
| **Tracing** | OpenTelemetry | **Optional** | Single service can use structured logs |
| **Docs** | Swag/ogen | **Optional** | OpenAPI generation from Go code |
| **VCS** | Jujutsu (jj) | **Recommended** | Better UX, Git-compatible. CI uses Git. |

---

## Go Code Standards

### File Structure

```
cmd/
  seed/                    # Seed data for local development
    main.go                
  server/                  # Entry point - wiring only
    main.go                

internal/
  config/                  # Configuration
    config.go              # Config struct definition
    env.go                 # Environment loading & validation

  router/                  # Route definitions & middleware chain
    router.go              # SetupRouter() - composition root
    versions.go            # v1, v2 mount points (if multi-version)

  handler/                 # HTTP layer (THIN)
    *_handler.go           # Parse request -> call service -> format response

  service/                 # Business logic layer
    *_service.go           # Validation, orchestration, side effects
    transaction.go         # TxManager for database transactions

  repository/              # Data access layer (wraps sqlc)
    *_repository.go        # Domain-aware repository using sqlc

  middleware/              # HTTP middleware
    auth.go
    logging.go
    ratelimit.go
    security.go            # Headers, CORS, etc.

  database/
    sqlc/                  # Generated code - NEVER edit manually
      models.go
      querier.go
      db.go

  model/                   # Domain models

  apierror/                # API error types and helpers

  validator/               # Custom validators

  client/                  # (Optional) External API clients
    anilist.go             
    discord.go             
    # Use circuit breakers here for external APIs

  bootstrap/               # (Optional) Dependency injection
    app.go                 # Only if main.go exceeds 100 lines
    wire.go                

sql/
  sqlc.yaml                
  schema/                  # Goose SQL migrations
    YYYYMMDDHHMMSS_description.sql
  queries/                 # SQL query files
    users.sql

test/                      # Integration tests only
  integration/
    *_test.go
  testutil/
    fixtures.go

Dockerfile
justfile
.env
.env.example
docker-compose.yml
README.md
```

---

### The Flow

```
HTTP Request
    |
+-----------------------------------------------------+
|  HANDLER (internal/handler/)                        |
|  - Parse JSON body                                  |
|  - Extract URL params / query params                |
|  - Call service                                     |
|  - Handle service errors -> HTTP status codes       |
|  - Format HTTP response                             |
+-----------------------------------------------------+
    |
+-----------------------------------------------------+
|  SERVICE (internal/service/)                        |
|  - Business validation                              |
|  - Transaction boundaries (TxManager)               |
|  - Orchestrate multiple repositories                |
|  - Trigger side effects (notifications, cache)      |
|  - Return domain errors (not HTTP errors)           |
+-----------------------------------------------------+
    |
+-----------------------------------------------------+
|  REPOSITORY (internal/repository/)                  |
|  - Database queries only (thin wrappers)            |
|  - Convert sqlc types <-> domain models             |
|  - Accept pgx.Tx for transactional support          |
+-----------------------------------------------------+
    |
Database
```

---

### Layer Responsibilities

| Layer | Does | Does NOT | Test Focus |
|-------|------|----------|------------|
| Handler | Parse HTTP, call service, write response | Business logic, DB calls | Request/response serialization, status codes |
| Service | Business rules, transactions, orchestration | HTTP concerns, raw SQL | Business logic, error paths, transaction rollback |
| Repository | DB queries, type conversion | Business logic, HTTP concerns | SQL mapping, error translation |

---

### Transaction Boundaries

Service layer owns transactions. Pass `pgx.Tx` to repositories when needed:

```go
// internal/service/transaction.go
type TxManager interface {
    WithTx(ctx context.Context, fn func(pgx.Tx) error) error
}

// internal/service/transfer.go
func (s *TransferService) Transfer(ctx context.Context, from, to string, amount int) error {
    return s.txManager.WithTx(ctx, func(tx pgx.Tx) error {
        if err := s.repo.Debit(ctx, tx, from, amount); err != nil {
            return fmt.Errorf("debiting account %s: %w", from, err)
        }
        if err := s.repo.Credit(ctx, tx, to, amount); err != nil {
            return fmt.Errorf("crediting account %s: %w", to, err)
        }
        return nil
    })
}
```

Repository method signatures:
```go
// Without transaction
func (r *Repo) GetUser(ctx context.Context, id uuid.UUID) (*User, error)

// With transaction support
func (r *Repo) GetUserTx(ctx context.Context, tx pgx.Tx, id uuid.UUID) (*User, error)
```

---

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| **Files** | snake_case | `user_repository.go` |
| **Packages** | lowercase | `handler`, `service` |
| **Structs** | PascalCase | `UserService` |
| **Interfaces** | PascalCase | `UserRepository`, `EmailSender` |
| **Variables** | camelCase | `userID`, `donationCount` |
| **Constants** | PascalCase (exported) | `MaxRetries` |
| **Errors** | `Err` prefix | `ErrUserNotFound` |
| **Handlers** | `<Entity>Handler` | `UserHandler` |
| **Services** | `<Entity>Service` | `UserService` |
| **Repositories** | `<Entity>Repository` | `UserRepository` |
| **Constructors** | `New<Type>` | `NewUserService` |
| **Context keys** | Unexported type | `type ctxKey string` |
| **Mutex** | `mu` suffix or prefix | `usersMu`, `mu sync.Mutex` |

**Getter Naming:**
- **Avoid `Get` prefix for simple field accessors:** `user.Name()`, `config.Timeout()`
- **Use `Get` prefix for operations with side effects/lookup:** `svc.GetUserByEmail()` (hits DB), `cache.Get(key)`, `repo.GetByID(ctx, id)`

**ID/Acronym Casing:**
- Use `ID` not `Id` (e.g., `userID`, `GetByID`)
- Acronyms keep uppercase: `httpClient`, `userID`, `ServeHTTP` (interface satisfaction), `XMLName`

---

### Function Size & Complexity

- **Target:** <40 lines for logic functions, <60 for orchestration (handlers, service coordination)
- **Rule:** If it doesn't fit on one screen, extract helpers named after *what* they do
- **Exception:** HTTP handlers may reach 80-100 lines for parsing/validation/response formatting without being complex
- **Extract aggressively:** Complex conditionals deserve named functions

---

### Anti-Patterns We Avoid

**No God Classes / Fat Handlers**

Bad - One handler managing multiple unrelated entities:
```
handler/sports.go (1,600+ lines) -> teams, players, matches
```

Good - Focused handlers:
```
handler/team.go
handler/player.go
```

**Constructor Injection Only**

Bad:
```go
h.Rating = NewRatingHandler(...)
h.Rating.SetCache(cache)           // Post-construction
```

Good:
```go
ratingService := service.NewRatingService(repo, cache, notifier)
h.Rating = NewRatingHandler(ratingService)
```

**Never Ignore Errors**
- No `data, _ := fn()` unless explicitly documented why error is safe to ignore
- No `fmt.Println` for logging (use `slog`)
- No `panic` except in `main()` for unrecoverable startup failures

---

### Tool Dependencies (Go 1.24+)

Use `tool` directives in `go.mod` to track dev tools:

```bash
go get -tool github.com/sqlc-dev/sqlc/cmd/sqlc@latest
go tool sqlc generate -f sql/sqlc.yaml
```

For Go <1.24 support, use `tools/tools.go` with `//go:build tools` tag.

---

### Error Handling

| Situation | Use |
|-----------|-----|
| Define domain error | `var ErrX = errors.New("x")` |
| Return domain error | `return ErrUserNotFound` |
| Add context to error | `fmt.Errorf("doing X: %w", err)` |
| Check specific error | `errors.Is(err, ErrX)` |
| Check error type | `errors.As(err, &target)` |

**Critical:** Always use `%w` (not `%v`) when wrapping to preserve error chains.

---

### Logging with slog

Always structured. Use `slog.String()`, `slog.Any()`. Never `fmt.Sprintf` in logs.

```go
slog.Info("user_created",
    slog.String("user_id", user.ID.String()),
    slog.Duration("duration", time.Since(start)),
)
```

**OpenTelemetry Integration:** Use `otelslog` handler to auto-attach trace/span IDs.

---

### Validation

Register custom UUIDv7 validator with go-playground/validator. Use struct tags: `validate:"required,email,uuidv7,min=3,max=50"`.

---

### Password Hashing (Argon2id)

OWASP 2025 recommended parameters:
- **Memory-heavy:** m=47104, t=1, p=1
- **CPU-heavy:** m=19456, t=2, p=1

---

### Context Handling

- **Always first parameter**, named `ctx`
- **Never store in structs**
- **Never use `context.Background()`** except in `main()` or top-level initialization
- **Propagate to all DB queries, HTTP calls, cache lookups**
- **Check cancellation** in long-running operations: `if err := ctx.Err(); err != nil { return err }`

---

### HTTP Standards

**Status Constants:** Always use `net/http` constants (`http.StatusOK`, not `200`).

**Response Formats:**
- Success: `{ "data": T }`
- Error: `{ "error": string, "code": string, "details": map }`
- Paginated: `{ "data": []T, "total": int, "page": int, "per_page": int }`

**API Versioning:** Use URL path `/v1/users`, `/v2/users`. Mount as separate chi routers.

```go
r.Route("/v1", func(r chi.Router) {
    r.Mount("/users", handler.NewUserHandlerV1())
})
r.Route("/v2", func(r chi.Router) {
    r.Mount("/users", handler.NewUserHandlerV2())
})
```

**Deprecation:** When deprecating v1, return `Sunset` HTTP header with date.

---

### Pagination

| Type | Use Case | Pros | Cons |
|------|----------|------|------|
| **Offset** | Admin panels, small datasets (<10k rows) | Simple, total count, jump to page | Slow on large datasets, inconsistent with concurrent inserts |
| **Cursor** | Feeds, large datasets, public APIs | Fast, consistent, scales well | No page jumping, no total count |

**Default:** Cursor-based with UUIDv7 for public APIs; offset-based for admin/internal tools.

---

### Health Checks

Every service must expose:

- **Liveness** `GET /health/live` - Is the process running? (Kubernetes livenessProbe)
- **Readiness** `GET /health/ready` - Can accept traffic? (Checks DB, cache connections)

---

### Rate Limiting

Use `golang.org/x/time/rate` for in-memory; Redis for distributed.

| Endpoint | Rate | Burst | Strategy |
|----------|------|-------|----------|
| `/auth/login` | 5/s | 10 | Per-IP |
| `/auth/register` | 2/s | 5 | Per-IP |
| `/auth/forgot-password` | 1/s | 3 | Per-IP |
| `/api/*` (auth) | 100/s | 200 | Per-User (Redis) |
| `/api/*` (public) | 20/s | 40 | Per-IP |

**Response:** `429 Too Many Requests` with headers:
- `Retry-After: <seconds>`
- `X-RateLimit-Remaining: <count>`
- `X-RateLimit-Reset: <unix-timestamp>`

---

### Security Headers Middleware

Set on all responses:
```
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Strict-Transport-Security: max-age=31536000; includeSubDomains (prod only)
Content-Security-Policy: default-src 'self'
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

**CSRF:** Only required for cookie-based sessions. If using JWT in `Authorization` header (typical for APIs), CSRF protection is unnecessary.

---

### Request Size Limits

Use `http.MaxBytesReader` to prevent DoS via large payloads:

```go
r.Use(func(next http.Handler) http.Handler {
    return http.MaxBytesHandler(next, maxRequestSize)
})
```

---

### Request Timeouts

Beyond router middleware, set specific timeouts for external calls:

```go
ctx, cancel := context.WithTimeout(ctx, 3*time.Second) // DB query timeout
defer cancel()

// Or for HTTP clients
client := &http.Client{Timeout: 10 * time.Second}
```

---

## Testing Standards

### Table-Driven Tests ONLY

All tests must use table-driven format covering:
- Happy path
- Error paths (invalid inputs, expected failures)
- Edge cases (empty strings, nil values, boundaries)
- Domain errors (ErrNotFound, ErrUnauthorized)

```go
func TestCreateUser(t *testing.T) {
    tests := []struct {
        name    string
        input   CreateUserInput
        wantErr error
    }{
        {
            name:    "valid user creates successfully",
            input:   CreateUserInput{Email: "test@example.com"},
            wantErr: nil,
        },
        {
            name:    "invalid email returns ErrInvalidEmail",
            input:   CreateUserInput{Email: "invalid"},
            wantErr: ErrInvalidEmail,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // test logic
        })
    }
}
```

### Best Practices

- Use `t.Parallel()` for independent tests
- Use `t.Helper()` in test helper functions
- Use `t.Cleanup()` instead of `defer` for teardown

### Integration Tests (testcontainers)

Spin up real dependencies. Each test must use isolated database schemas or table truncation in `t.Cleanup()` to prevent pollution.

```go
func TestIntegration_CreateUser(t *testing.T) {
    t.Parallel()

    ctx := context.Background()
    container := setupPostgres(t) // returns *postgres.PostgresContainer
    defer container.Terminate(ctx)

    // Run test...
}
```

### Contract Testing

When integrating external APIs (AniList, Discord, Polar), use record/replay with `go-vcr` or Pact to prevent breaking changes on their side from breaking your CI.

---

## Database Standards

### Goose Migrations

- **Location:** `sql/schema/`
- **Naming:** `YYYYMMDDHHMMSS_description.sql`
- Always include `-- +goose Up` and `-- +goose Down`
- Migrations must be reversible

### sqlc Configuration

- **Config:** `sql/sqlc.yaml`
- Use `pgx/v5` as sql_package
- Enable `emit_json_tags` and `emit_interface`
- Output to `internal/database/sqlc`

### Repository Layer

Thin wrappers around sqlc:

```go
func (r *UserRepository) GetByID(ctx context.Context, id uuid.UUID) (*User, error) {
    u, err := r.q.GetUser(ctx, id)
    if err != nil {
        if errors.Is(err, pgx.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, fmt.Errorf("db query failed: %w", err)
    }
    return toDomainUser(u), nil
}
```

**Rules:**
- Translate `pgx.ErrNoRows` -> domain errors
- Convert sqlc types <-> domain models
- Accept `pgx.Tx` for transactional variants

---

## Security Defaults

- **Dependency Scanning:** Run `govulncheck ./...` in CI
- **Password Hashing:** Argon2id with OWASP params
- **IDs:** UUIDv7 (not sequential, not guessable)
- **Input Validation:** All endpoints validated
- **SQL Injection:** Prevented via sqlc prepared statements
- **HTTPS:** Enforced in production (HSTS)
- **RealIP Warning:** Only use Chi's `middleware.RealIP` if behind trusted reverse proxy (Cloudflare, Nginx). Otherwise validate IPs.

---

## Observability

### Logging (slog)
- Structured JSON in production
- Debug level in development
- Correlation IDs from OpenTelemetry context

### Metrics (Prometheus)
Expose at `/metrics`:
- `http_requests_total` (counter) - by method, endpoint, status
- `http_request_duration_seconds` (histogram) - by method, endpoint
- `db_query_duration_seconds` (histogram) - by query

### Tracing (OpenTelemetry)
- Use OTLP exporter (gRPC)
- Set service name in resource
- Add HTTP middleware for automatic spans
- Record errors with `span.RecordError(err)`
- Use Jaeger for local dev (UI port 16686)

### Alerting
Monitor:
- Error rate > 1% for 5 minutes
- P99 latency > 2s
- Database connection pool exhaustion

---

## Infrastructure (Optional)

Add these only when needed.

### Caching (Redis/Dragonfly)
**Dragonfly:** Single-node, multi-threaded Redis alternative. Use when single-node performance matters, need Redis compatibility.

**Pattern:** Cache-Aside
1. Try cache first
2. On miss, fetch from DB
3. Store in cache (ignore error - cache is optional)
4. Invalidate on update/delete

### Message Queues

**RabbitMQ:** Traditional messaging, complex routing
**RedPanda:** Kafka-compatible, lighter than Kafka, good for event streaming

### External API Clients (`internal/client/`)

Use circuit breakers to prevent cascading failures:

```go
import "github.com/sony/gobreaker"

var cb *gobreaker.CircuitBreaker

func init() {
    cb = gobreaker.NewCircuitBreaker(gobreaker.Settings{
        Name:        "anilist-api",
        MaxRequests: 100,
        Interval:    0,
        Timeout:     2 * time.Second,
    })
}
```

---

## CI/CD

### GitHub Actions

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.24'
      - name: Govulncheck
        run: |
          go install golang.org/x/vuln/cmd/govulncheck@latest
          govulncheck ./...

  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.24'
      - name: golangci-lint
        uses: golangci/golangci-lint-action@v6
        with:
          version: latest

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.24'
      - name: Unit Tests
        run: go test -short -race ./...
      - name: Integration Tests
        run: go test -race -v -run Integration ./...

  build:
    runs-on: ubuntu-latest
    needs: [security, lint, test]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.24'
      - name: Build
        run: CGO_ENABLED=0 go build -ldflags="-w -s" -o bin/server ./cmd/server
      - name: Upload Artifact
        uses: actions/upload-artifact@v4
        with:
          name: binary
          path: bin/server

  docker:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - name: Docker Login
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      - name: Docker Build & Push
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/app:${{ github.sha }} .
          docker push ${{ secrets.DOCKER_USERNAME }}/app:${{ github.sha }}
```

### Validation Steps

Add these checks to CI or pre-commit hooks:
```bash
# Validate docker-compose syntax
docker-compose config -q

# Validate Justfile
just --fmt --check-unformatted

# Check OpenAPI spec valid (if using)
swagger validate ./api/swagger.json
```

---

## Deployment

### Default: Hetzner + Dokploy + Cloudflare

| Component | Purpose |
|-----------|---------|
| **VPS** | Hetzner (cheap, reliable) |
| **Platform** | Dokploy (self-hosted PaaS) |
| **CDN** | Cloudflare (DDoS, SSL) |

**Features:**
- `jj push` or `git push` to deploy
- Docker container management
- SSL certificates
- Environment variables

### Alternative: Kubernetes

Use when:
- Multiple services needing orchestration
- Auto-scaling requirements
- High availability across regions

**GitOps:** ArgoCD (full-featured) or FluxCD (lighter)

---

## Version Control

### Jujutsu (jj) - Recommended for Local

Better UX than Git, but **CI uses Git**.

| Git | Jujutsu |
|-----|---------|
| `git commit` | `jj new` + `jj describe` |
| `git add -p` | Automatic (working copy = change) |
| `git stash` | `jj new` (changes mutable) |
| `git rebase -i` | `jj squash`, `jj edit`, `jj split` |
| `git branch` | `jj bookmark` |

### Commands
```bash
jj git init              # Initialize
jj status                # Status
jj log                   # Beautiful log
jj new                   # Create change (mutable commit)
jj describe -m "msg"     # Set message
jj git push              # Push to remote
jj rebase -d main        # Rebase onto main
```

---

## Justfile

Every project must include:

```justfile
# Build
build:
    CGO_ENABLED=0 go build -ldflags="-w -s" -o bin/server ./cmd/server

# Run
run:
    go run ./cmd/server

# Testing
test:
    go test -race -v ./...

test-unit:
    go test -short -v ./...

test-integration:
    go test -v -run Integration ./...

# Code Quality
lint:
    go vet ./...
    staticcheck ./...
    go tool govulncheck ./...

sqlc:
    sqlc generate -f sql/sqlc.yaml

# Database
migrate-up:
    goose -dir sql/schema postgres "$DATABASE_URL" up

migrate-down:
    goose -dir sql/schema postgres "$DATABASE_URL" down

migrate-create name:
    goose -dir sql/schema create {{name}} sql

# Development
dev:
    air

deps:
    go mod download
    go mod tidy

# Docker
docker-build:
    docker build -t myapp:latest .

docker-up:
    docker-compose up -d

docker-down:
    docker-compose down

docker-logs:
    docker-compose logs -f

# Security
security-scan:
    go tool govulncheck ./...

# CI Validation
ci-checks:
    just lint
    just test
    docker-compose config -q
```

---

## Code Quality Checklist

Before committing:

- [ ] Functions focused (<60 lines unless simple orchestration)
- [ ] Zero ignored errors (`_ =` only with documented justification)
- [ ] slog used for structured logging (no `fmt.Println`)
- [ ] Input validation on all endpoints
- [ ] Transaction boundaries correct (service layer owns them)
- [ ] Context cancellation checked in long-running ops
- [ ] Table-driven tests for new logic
- [ ] Migrations reversible (`Down` works)
- [ ] sqlc regenerated if queries changed (`just sqlc`)
- [ ] **Never edited `internal/database/sqlc/`**
- [ ] Repository translates sqlc <-> domain types
- [ ] `go vet ./...` passes
- [ ] `staticcheck ./...` passes
- [ ] `govulncheck ./...` passes (no known CVEs)
- [ ] Graceful shutdown handled (SIGINT/SIGTERM)
- [ ] Database URLs use `sslmode=require` in production
- [ ] No `panic` outside `main()`
- [ ] OpenAPI regen if handlers changed (optional projects)

---

## Quick Reference

**sqlc:**
```bash
sqlc generate -f sql/sqlc.yaml
```

**Goose:**
```bash
goose -dir sql/schema postgres "$DATABASE_URL" up
goose -dir sql/schema postgres "$DATABASE_URL" down
goose -dir sql/schema create add_users_table sql
```

**Testing:**
```bash
go test -v ./...                    # All tests
go test -short ./...                # Unit only
go test -run Integration ./...      # Integration only
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

**Security:**
```bash
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...
```
