---
name: rust-backend
description: Rust backend development with zero-cost abstractions. Axum 0.8, SQLx, Tokio, Tower middleware, thiserror, tracing, garde validation, Argon2id, secrecy. Covers DDD project structure, layered architecture, error handling, testing with testcontainers, security, and deployment.
---

# Rust Backend Project Guidelines

## Project Philosophy

This project follows **zero-cost abstractions** with memory safety guaranteed at compile time. We leverage Rust's type system to make illegal states unrepresentable. Security-conscious defaults are non-negotiable.

### Project Tiers

Not every project needs full DDD architecture. Determine your tier:

| Tier | Description | Architecture |
|------|-------------|--------------|
| **Tier 1** | CLI tools, microservices, < 5 endpoints | Flat structure, handlers call SQLx directly, skip repository abstraction |
| **Tier 2** | Standard REST APIs, medium complexity | **Follow this guide as documented** (DDD structure) |
| **Tier 3** | Platforms, monoliths, > 50 endpoints | Add CQRS, Event Sourcing, separate read/write models, bounded contexts with clear anti-corruption layers |

> **Rule:** Start with Tier 1, refactor to Tier 2 when `main.rs` exceeds 300 lines, escalate to Tier 3 when you have complex domain logic requiring event sourcing.

### Stdlib-First Clarification

"Zero-cost abstractions" means we use the type system aggressively (zero-cost), not that we avoid dependencies. We use Axum (not Actix-web) for its composability with Tower, SQLx for compile-time checked queries, and `garde` for validation because manual validation is error-prone.

---

## Tech Stack

### Backend (Rust)

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Language** | Rust (latest stable) | **Required** | Memory-safe, zero-cost abstractions |
| **Edition** | 2024 | **Required** | Latest stable edition |
| **Web Framework** | Axum 0.8 | **Required** | Built on Tower/Tokio, composable middleware |
| **Async Runtime** | Tokio | **Required** | Concurrent connection handling |
| **Database** | SQLx 0.8 | **Required** | Compile-time checked queries |
| **Middleware** | Tower | **Required** | Rate limiting, timeouts |
| **Sessions** | tower-sessions | **Optional** | Only for cookie-based auth |
| **JWT** | jsonwebtoken | **Optional** | If using stateless auth |
| **Password Hashing** | argon2 | **Required** | Argon2id, zeroize on drop |
| **Secrets** | secrecy | **Required** | Zeroize sensitive data from memory |
| **HTTP Client** | reqwest | **Required** | With `tower-http` middleware for retries |
| **Validation** | garde | **Required** | Modern validator with derive macros |
| **Error Handling** | thiserror 2 | **Required** | Derive macro for custom errors |
| **Logging** | tracing | **Required** | Structured logging, OpenTelemetry integration |
| **Metrics** | metrics + metrics-exporter-prometheus | **Optional** | Skip if <100 RPM |
| **Message Queue** | lapin | **Optional** | Skip if sync processing suffices |
| **Object Storage** | rust-s3 | **Optional** | S3/R2 compatible |
| **IDs** | uuid | **Required** | UUIDv7 for time-sortable IDs |
| **Date/Time** | time | **Required** | Timezone-aware (preferred over chrono) |
| **Dev Reload** | cargo-watch | **Required** | Auto-recompile |
| **Testing** | testcontainers-rs | **Required** | Real PostgreSQL/RabbitMQ in Docker |
| **Parameterized Tests** | rstest | **Recommended** | Clean parameterized test syntax |
| **Security Audit** | cargo-deny, cargo-audit | **Required** | License/vulnerability auditing |

### Infrastructure

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **CI/CD** | GitHub Actions | **Required** | Cloud-native CI/CD |
| **Deployment** | Dokploy/K8s | **Recommended** | Hetzner + Dokploy default |
| **Monitoring** | Prometheus + Grafana | **Optional** | Skip if logs suffice |
| **Tracing** | OpenTelemetry / Jaeger | **Optional** | Single service can use structured logs |
| **Caching** | Redis / Dragonfly | **Optional** | Skip if single instance |
| **Message Queues** | RabbitMQ / RedPanda | **Optional** | Lapin for RabbitMQ, rdkafka for RedPanda |
| **Payments** | Polar.sh | **Optional** | Via reqwest |

---

## Rust Code Standards

### File Structure

#### Tier 2-3: Domain-Driven Design (Recommended)

Group by feature, not by layer. Each domain is self-contained.

```
src/
  main.rs                 # Entry point, minimal wiring
  lib.rs                  # Library root, feature flags
  startup.rs              # Application startup logic (graceful shutdown, tracing)
  config.rs               # Configuration (12-factor, env-based)
  router.rs               # Route assembly only (no business logic)

  domain/                 # Business domains (DDD)
    mod.rs                # Re-exports

    user/
      mod.rs              # pub use self::{model, service, handlers}
      model.rs            # User entity, value objects, domain events
      repository.rs       # DB operations (ports)
      service.rs          # Business logic, transaction boundaries
      handlers.rs         # HTTP handlers + routes() function
      error.rs            # Domain-specific errors (UserError)

    auth/
      mod.rs
      service.rs          # AuthService with transaction support
      middleware.rs       # CurrentUser extractor

  infrastructure/         # Technical implementations (adapters)
    mod.rs
    database.rs           # Connection pool, transaction manager
    cache.rs              # Redis implementation
    queue.rs              # RabbitMQ implementation
    security/             # Argon2, JWT, encryption
      mod.rs
      password.rs
      token.rs

  shared/                 # Cross-cutting concerns
    mod.rs
    errors.rs             # AppError (global error type)
    extractors.rs         # Custom Axum extractors (ValidatedJson)
    pagination.rs         # CursorPage, OffsetPage
    middleware/           # Tower middleware stack
      mod.rs              # build_middleware_stack()
      request_id.rs
      security_headers.rs
      metrics.rs

sql/
  migrations/             # SQLx migrations
  queries/                # Optional: hand-written SQLx queries

tests/
  integration/            # Integration tests only
    mod.rs
    helpers.rs            # TestClient, authenticate_user()
    user_tests.rs
```

#### Tier 1: Flat Structure (CLI/Small Service)

```
src/
  main.rs
  handlers.rs             # All routes
  db.rs                   # SQLx queries
  models.rs               # Shared models
  config.rs
```

**Why DDD for Tier 2+?**
- **Cohesion**: Everything for `user` in one place
- **Navigation**: One folder = one feature  
- **Testing**: Natural service boundaries
- **Scaling**: Each domain owns its logic

---

### The Flow

```
HTTP Request
    |
+-----------------------------------------------------+
|  HANDLERS (domain/*/handlers.rs)                    |
|  - Extract JSON/Path/Query params                   |
|  - Call service methods                             |
|  - Map domain errors -> HTTP responses              |
|  - Return Json<T> or AppError (IntoResponse)        |
+-----------------------------------------------------+
    |
+-----------------------------------------------------+
|  SERVICE (domain/*/service.rs)                      |
|  - Business validation (not DB constraints)         |
|  - Transaction boundaries (TxManager)               |
|  - Orchestrate multiple repositories                |
|  - Emit domain events                               |
|  - Return domain errors (UserError, AuthError)      |
+-----------------------------------------------------+
    |
+-----------------------------------------------------+
|  REPOSITORY (domain/*/repository.rs)                |
|  - SQLx queries only                                |
|  - Convert sqlx rows -> domain models               |
|  - Accept `&mut Transaction` for transactional ops  |
|  - No business logic (just query logic)             |
+-----------------------------------------------------+
    |
Database
```

---

### Layer Responsibilities

| Layer | Does | Does NOT | Test Strategy |
|-------|------|----------|---------------|
| Handlers | Parse HTTP, call service, map errors | Business logic, direct DB calls | Request serialization, status codes, auth extraction |
| Service | Business rules, transactions, orchestration | HTTP concerns, raw SQL | Business logic, transaction rollback scenarios |
| Repository | SQLx queries, type conversion | Business logic, HTTP concerns | Query mapping, error translation |

---

### Transaction Boundaries

Service layer owns transactions. Pass `&mut Transaction` (sqlx::Transaction<Postgres>) to repositories:

```rust
// infrastructure/database.rs
pub struct TxManager {
    pool: PgPool,
}

impl TxManager {
    pub async fn with_tx<F, T, E>(&self, f: F) -> Result<T, E>
    where
        F: for<'a> FnOnce(&'a mut Transaction<'static, Postgres>) -> BoxFuture<'a, Result<T, E>>,
        E: From<sqlx::Error>,
    {
        let mut tx = self.pool.begin().await?;
        let result = f(&mut tx).await;

        match result {
            Ok(val) => { tx.commit().await?; Ok(val) }
            Err(e) => { tx.rollback().await?; Err(e) }
        }
    }
}

// domain/user/service.rs
impl UserService {
    pub async fn transfer_credits(&self, from: Uuid, to: Uuid, amount: i64) -> Result<(), UserError> {
        self.tx_manager.with_tx(|tx| async move {
            self.repo.debit(tx, from, amount).await?;
            self.repo.credit(tx, to, amount).await?;
            Ok(())
        }.boxed())
        .await
        .map_err(|e| match e {
            UserError::InsufficientFunds => UserError::InsufficientFunds,
            _ => UserError::TransactionFailed,
        })?
    }
}
```

Repository signatures:
```rust
// Without transaction
async fn get_by_id(&self, id: Uuid) -> Result<User, UserError>;

// With transaction support
async fn get_by_id_tx<'a>(
    &self, 
    tx: &mut Transaction<'a, Postgres>, 
    id: Uuid
) -> Result<User, UserError>;
```

---

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| **Files/Modules** | snake_case | `user_repository.rs`, `mod user_service` |
| **Structs** | PascalCase | `UserService`, `CreateUserRequest` |
| **Enums** | PascalCase | `UserRole::Admin` |
| **Traits** | PascalCase, descriptive | `Repository`, `EmailSender` |
| **Functions/Methods** | snake_case | `get_by_id`, `validate_input` |
| **Variables** | snake_case | `user_id`, `donation_count` |
| **Constants** | SCREAMING_SNAKE_CASE | `MAX_RETRIES` |
| **Type aliases** | PascalCase | `type Result<T> = std::result::Result<T, AppError>` |
| **Lifetimes** | short, lowercase | `'a`, `'ctx` |
| **Generics** | single uppercase | `T`, `E`, `S: State` |
| **Error types** | `Error` suffix | `UserError`, `AppError` |
| **Builder structs** | `Builder` suffix | `UserBuilder` |
| **Handlers** | action + resource | `create_user`, `get_donation_by_id` |
| **Services** | `Service` suffix | `UserService` |
| **Repositories** | `Repository` suffix | `UserRepository` |
| **Conversions** | `from_*`, `to_*`, `into_*` | `from_dto()`, `to_string()` |
| **Getters** | **No prefix** | `user.name()` not `user.get_name()` |
| **Setters** | `set_*` prefix | `user.set_name()` |
| **Booleans** | `is_`, `has_`, `can_` | `is_active`, `has_permission` |
| **Fallible constructors** | `try_new`, `try_from` | `Config::try_new()` |
| **Async** | no suffix | `get_user()` not `get_user_async()` |
| **Unsafe** | `*_unchecked` | `get_unchecked()` |
| **Test modules** | `tests` or `mod tests` | `#[cfg(test)] mod tests` |

**Rust Idioms:**
- Use `Id` not `ID`: `user_id`, `UserId`, `get_by_id()`
- Use `Uuid` not `UUID`: `Uuid::now_v7()`
- Acronyms in snake_case stay lowercase: `http_client`, `user_id`
- Acronyms in PascalCase use only first letter uppercase: `HttpClient`, `UserId`
- Exception: Two-letter acronyms stay uppercase: `IO` -> `IoConfig`

---

### Imports and Module Structure

**Prefer `crate::` for clarity**, but `super::` is acceptable in tests or tightly coupled sibling modules.

```rust
// Good - explicit
use crate::domain::user::{model::User, service::UserService};

// Acceptable in tests
use super::*;

// Avoid in domain code (unclear boundaries)
use super::model::User;
```

**Re-exports (`pub use`):**
Use `pub use` to define the public API of a module, but don't re-export external types unnecessarily.

```rust
// domain/user/mod.rs - defines public API
pub use model::{User, UserId};
pub use service::UserService;
pub use error::UserError;

// Don't re-export external types unless necessary
// pub use sqlx::Error; // Bad - leaks implementation
```

---

### Function Size & Complexity

- **Target:** <40 lines for logic functions, <60 for orchestration (handlers, service coordination)
- **Rule:** If it doesn't fit on one screen, extract helpers named after *what* they do
- **Exception:** HTTP handlers with extensive validation may reach 80-100 lines
- **Extract aggressively:** Complex `match` statements or `if` chains deserve named functions

---

### Error Handling

Use `thiserror` for domain errors with automatic conversion to HTTP responses.

```rust
// shared/errors.rs
#[derive(Debug, thiserror::Error)]
pub enum AppError {
    #[error("User not found")]
    UserNotFound,

    #[error("Validation failed: {0}")]
    Validation(#[from] garde::Report),

    #[error("Database error")]
    Database(#[from] sqlx::Error),

    #[error("Unauthorized")]
    Unauthorized,
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, message) = match self {
            AppError::UserNotFound => (StatusCode::NOT_FOUND, self.to_string()),
            AppError::Validation(_) => (StatusCode::BAD_REQUEST, self.to_string()),
            AppError::Database(_) => {
                tracing::error!("Database error: {:?}", self);
                (StatusCode::INTERNAL_SERVER_ERROR, "Internal server error".to_string())
            }
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, self.to_string()),
        };

        (status, Json(json!({ "error": message }))).into_response()
    }
}
```

**Error Guidelines:**
- Use `?` operator liberally for propagation
- Use `.ok_or(AppError::UserNotFound)?` for Option->Result
- Add context with `.with_context(|| format!("Failed to load user {}", id))?` when needed (requires `anyhow` for internal errors, convert to AppError at boundary)
- Never expose internal error details to clients (log them, send generic message)

---

### Logging with tracing

Always use structured logging. Instrument services and handlers.

```rust
use tracing::{info, instrument};

#[instrument(skip(self), fields(user_id = %id))]
pub async fn get_user(&self, id: Uuid) -> Result<User, UserError> {
    info!("Fetching user from database");
    // ...
}
```

**Guidelines:**
- Use `#[instrument]` on service methods (skip pools/clients)
- Use `info!` for business events, `debug!` for queries, `error!` for failures
- Add fields with `%` (Display) or `?` (Debug): `info!(user_id = %id, "User created")`

---

### Validation with garde

Use `garde` for request validation with automatic Axum integration via `axum-valid`.

```rust
use garde::Validate;

#[derive(Validate, Deserialize)]
pub struct CreateUserRequest {
    #[garde(length(min = 3, max = 50))]
    pub name: String,

    #[garde(email)]
    pub email: String,

    #[garde(length(min = 12))]
    pub password: String,
}
```

**Handler extraction:**
```rust
async fn create_user(
    ValidatedJson(req): ValidatedJson<CreateUserRequest>, // Returns 400 on validation fail
    State(service): State<UserService>,
) -> Result<Json<User>, AppError> {
    // req is guaranteed valid here
}
```

---

### Security Defaults

- **Password Hashing:** Argon2id with OWASP High Memory: `m=47104 (46 MiB), t=1, p=1`
- **Secrets:** Use `secrecy::SecretString` for passwords/tokens, zeroizes on drop
- **JWT:** Short expiration (15min access, 7day refresh), validate `exp`, `iat`, `sub`
- **IDs:** UUIDv7 (time-sortable, not sequential)
- **SQL:** Never use `format!` for queries (SQLx prevents this at compile time)
- **Headers:** Security headers middleware (CSP, HSTS, X-Frame-Options)

---

### Request Timeouts

Always set timeouts for external calls and DB operations:

```rust
// Database connection timeout
let pool = PgPoolOptions::new()
    .acquire_timeout(Duration::from_secs(3))
    .idle_timeout(Duration::from_secs(10))
    .connect(&database_url)
    .await?;

// HTTP client with timeout
let client = reqwest::Client::builder()
    .timeout(Duration::from_secs(10))
    .connect_timeout(Duration::from_secs(5))
    .build()?;

// Tower timeout middleware
let middleware = ServiceBuilder::new()
    .layer(TimeoutLayer::new(Duration::from_secs(30)));
```

---

### Pagination

| Type | Use Case | Default |
|------|----------|---------|
| **Cursor** | Public APIs, feeds, large datasets | Default for Tier 2+ |
| **Offset** | Admin panels, small datasets | For internal tools |

```rust
// Cursor-based
pub struct CursorPage<T> {
    pub data: Vec<T>,
    pub next_cursor: Option<Uuid>,
    pub has_more: bool,
}

// Offset-based  
pub struct OffsetPage<T> {
    pub data: Vec<T>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
    pub total_pages: i64,
}
```

---

### Health Checks

Every service must expose:
- `GET /health/live` - Liveness (is process running?)
- `GET /health/ready` - Readiness (DB connected, ready for traffic)

```rust
// shared/health.rs
pub async fn health_check(State(pool): State<PgPool>) -> impl IntoResponse {
    match sqlx::query("SELECT 1").fetch_one(&pool).await {
        Ok(_) => (StatusCode::OK, "healthy"),
        Err(_) => (StatusCode::SERVICE_UNAVAILABLE, "unhealthy"),
    }
}
```

---

### Rate Limiting

Use `tower-governor` with different limits per endpoint:

```rust
let governor_conf = Arc::new(
    GovernorConfigBuilder::default()
        .per_second(5)
        .burst_size(10)
        .per_millisecond(100)
        .finish()
        .unwrap()
);

let app = Router::new()
    .route("/auth/login", post(login))
    .layer(GovernorLayer {
        config: governor_conf,
    });
```

| Endpoint | Strategy | Limits |
|----------|----------|--------|
| `/auth/login` | Per-IP | 5 req/s, burst 10 |
| `/auth/register` | Per-IP | 2 req/s, burst 5 |
| `/api/*` (auth) | Per-User | 100 req/s, burst 200 |
| `/api/*` (public) | Per-IP | 20 req/s, burst 40 |

---

### External API Clients

Use reqwest with middleware for retries and circuit breakers:

```rust
use reqwest::Client;
use reqwest_middleware::{ClientBuilder, Middleware};
use reqwest_retry::{RetryTransientMiddleware, policies::ExponentialBackoff};
use reqwest_tracing::TracingMiddleware;

let retry_policy = ExponentialBackoff::builder().build_with_max_retries(3);
let client = ClientBuilder::new(Client::new())
    .with(TracingMiddleware::default())
    .with(RetryTransientMiddleware::new_with_policy(retry_policy))
    .build();
```

**Circuit Breaker Pattern:**
Use `backon` or implement state machine (Closed/Open/HalfOpen) for external APIs like Polar.sh to prevent cascading failures.

---

### Feature Flags

Use features for optional functionality and test utilities:

```toml
[features]
default = ["tracing"]
metrics = ["dep:metrics", "dep:metrics-exporter-prometheus"]
test-utils = ["tokio/rt-multi-thread", "dep:fake", "dep:rstest"]
```

**Pattern:**
- `default = []` - minimal features
- `test-utils` - Mock implementations, fixtures, test helpers (only enabled in tests)
- `metrics` - Prometheus instrumentation
- `tracing` - OpenTelemetry/Jaeger support

---

### Graceful Shutdown

Handle SIGINT/SIGTERM properly:

```rust
pub async fn run() {
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();
    let app = create_app(pool);

    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .unwrap();
}

async fn shutdown_signal() {
    let ctrl_c = async {
        signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    let terminate = async {
        signal::unix::signal(signal::unix::SignalKind::terminate())
            .expect("failed to install signal handler")
            .recv()
            .await;
    };

    tokio::select! {
        _ = ctrl_c => {},
        _ = terminate => {},
    }

    tracing::info!("signal received, starting graceful shutdown");
    // Close DB pool, flush traces, etc.
}
```

---

## Testing Standards

### Unit Tests

Place in `#[cfg(test)] mod tests` at bottom of each file. Use `rstest` for parameterized tests:

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use rstest::rstest;

    #[rstest]
    #[case("valid@example.com", true)]
    #[case("invalid-email", false)]
    fn test_email_validation(#[case] email: &str, #[case] expected: bool) {
        let result = validate_email(email);
        assert_eq!(result.is_ok(), expected);
    }
}
```

### Integration Tests (testcontainers)

Use `testcontainers` with real databases. Use `test-utils` feature for helpers:

```rust
// tests/integration/helpers.rs
pub async fn setup_test_app() -> (TestClient, Container<Postgres>) {
    let container = Postgres::default().start().await;
    let pool = create_pool(&container).await;
    run_migrations(&pool).await;

    let app = create_app(pool);
    (TestClient::new(app), container)
}

// tests/integration/user_tests.rs
#[tokio::test]
async fn test_create_user() {
    let (client, _container) = setup_test_app().await;

    let response = client
        .post("/users")
        .json(&json!({"name": "Test", "email": "test@example.com"}))
        .send()
        .await;

    assert_eq!(response.status(), 201);
}
```

### Test Features

Enable test utilities only in tests:

```toml
[dev-dependencies]
my_app = { path = "..", features = ["test-utils"] }
fake = "2.9"
```

```rust
// domain/user/mod.rs
#[cfg(any(test, feature = "test-utils"))]
pub mod fixtures {
    pub fn fake_user() -> User {
        User {
            id: Uuid::now_v7(),
            name: fake::faker::name::en::Name().fake(),
        }
    }
}
```

---

## CI/CD (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

env:
  CARGO_TERM_COLOR: always
  RUST_BACKTRACE: 1

jobs:
  security-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: rustsec/audit-check@v1.4.1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

  deny-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: EmbarkStudios/cargo-deny-action@v1
        with:
          command: check all

  fmt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt
      - run: cargo fmt --all -- --check

  clippy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy
      - uses: Swatinem/rust-cache@v2
      - run: cargo clippy --all-features -- -D warnings

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2

      - name: Install SQLx CLI
        run: cargo install sqlx-cli --no-default-features --features native-tls,postgres

      - name: Prepare SQLx (if using offline mode)
        run: cargo sqlx prepare --check

      - name: Run unit tests
        run: cargo test --lib --all-features

      - name: Run integration tests
        run: cargo test --test integration --all-features

  build:
    runs-on: ubuntu-latest
    needs: [fmt, clippy, test]
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
      - run: cargo build --release --all-features

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: binary
          path: target/release/my_app

  docker:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ${{ secrets.DOCKER_USERNAME }}/app:${{ github.sha }}
```

---

## Deployment

### Default: Hetzner + Dokploy + Cloudflare

| Component | Purpose |
|-----------|---------|
| **VPS** | Hetzner (cheap, EU-based) |
| **Platform** | Dokploy (self-hosted PaaS) |
| **CDN** | Cloudflare (DDoS, SSL) |

**Dokploy features:**
- Git push to deploy
- Docker container management
- Environment variables
- Automatic SSL

### Alternative: Kubernetes

Use ArgoCD or FluxCD for GitOps when scaling beyond single VPS.

---

## Justfile

```justfile
set dotenv-load

# Build
build:
    cargo build --release

build-dev:
    cargo build

# Run
run:
    cargo run

dev:
    cargo watch -x run

# Testing
test:
    cargo test --all-features

test-unit:
    cargo test --lib

test-integration:
    cargo test --test integration

# Code Quality
lint:
    cargo clippy --all-features -- -D warnings

fmt:
    cargo fmt --all

fmt-check:
    cargo fmt --all -- --check

deny:
    cargo deny check all

audit:
    cargo audit

sqlx-prepare:
    cargo sqlx prepare -- --all-features

# Security & Quality Checks (CI simulation)
check: fmt-check lint deny audit test
    @echo "All checks passed!"

# Database
migrate:
    sqlx migrate run --source sql/migrations

migrate-create name:
    sqlx migrate add {{name}} --source sql/migrations

# Docker
docker-build:
    docker build -t myapp:latest .

docker-up:
    docker-compose up -d

docker-down:
    docker-compose down

docker-logs:
    docker-compose logs -f
```

---

## Dockerfile

Multi-stage build using distroless for minimal attack surface:

```dockerfile
# Build stage
FROM rust:latest-bookworm AS builder
WORKDIR /app

# Cache dependencies
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release
RUN rm -rf src

# Build application
COPY . .
RUN cargo build --release

# Runtime stage
FROM gcr.io/distroless/cc-debian12:nonroot
WORKDIR /app

COPY --from=builder /app/target/release/my_app /app/my_app

USER nonroot:nonroot

EXPOSE 8080
ENV RUST_LOG=info

ENTRYPOINT ["/app/my_app"]
```

---

## Code Quality Checklist

Before committing:

- [ ] Functions focused (<60 lines unless simple orchestration)
- [ ] Zero `.unwrap()` in production code (use `?` or `match`)
- [ ] `tracing` used for structured logging (no `println!`)
- [ ] Input validation on all endpoints (garde)
- [ ] Transaction boundaries correct (service layer owns them)
- [ ] Secrets use `SecretString` (zeroize)
- [ ] Migrations tested (up and down)
- [ ] `cargo clippy -- -D warnings` passes
- [ ] `cargo fmt` applied
- [ ] `cargo deny check` passes (licenses, bans)
- [ ] `cargo audit` passes (no vulnerabilities)
- [ ] SQLx prepared if using offline mode
- [ ] Graceful shutdown handled (SIGINT/SIGTERM)
- [ ] No `TODO` or `FIXME` without issue reference
- [ ] `test-utils` feature for mocks/fixtures

---

## Quick Reference

**Development:**
- `cargo watch -x run` - Dev with auto-reload
- `cargo build --release` - Release build

**Testing:**
- `cargo test --lib` - Unit tests only (fast)
- `cargo test --test integration` - Integration tests
- `cargo test -- --nocapture` - With output

**Security:**
- `cargo deny check` - License/ban check
- `cargo audit` - Vulnerability scan
- `cargo vet` - Supply chain audit (if using vet)

**Database:**
- `sqlx migrate run` - Run migrations  
- `cargo sqlx prepare` - Offline query metadata
- `sqlx migrate add <name>` - Create migration

**Release:**
- `cargo build --release` - Optimized binary
