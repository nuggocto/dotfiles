---
name: zig-backend
description: Zig backend development for performance-critical systems. http.zig (httpz), pg.zig, std.json, explicit allocators, zero hidden allocations. Covers memory management patterns, error sets, testing, cross-compilation, and deployment.
---

# Zig Backend Project Guidelines

## Project Philosophy

Zig is for **performance-critical systems** requiring predictable behavior, zero hidden allocations, and explicit control. We embrace Zig's core philosophy: communicate intent precisely, favor reading over writing, and avoid hidden control flow. No garbage collector, no hidden allocations, no macros.

### Project Tiers

Zig excels across all tiers due to its composability. Choose your architecture:

| Tier | Description | Architecture |
|------|-------------|--------------|
| **Tier 1** | CLI tools, scripts, microservices | Single-file or flat structure, direct API calls, minimal abstraction |
| **Tier 2** | Standard REST APIs, services | Modular structure, repository pattern, explicit allocators |
| **Tier 3** | High-frequency trading, game servers, distributed systems | Custom allocators, lock-free data structures, SIMD, kernel-bypass networking |

> **Rule:** Start with Tier 1 (flat), refactor to Tier 2 when `main.zig` exceeds 400 lines or you need test isolation, use Tier 3 when every microsecond matters.

### Zero-Cost Philosophy

"Zero hidden allocations" means allocations are explicit, not that we avoid them. We use arenas for request handling, pools for connections, and page allocators for long-lived data. Control means choosing the right strategy, not avoiding heap allocation entirely.

---

## Tech Stack

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Language** | Zig 0.14.x/0.15.x | **Required** | Latest stable (not master) |
| **HTTP Server** | http.zig (httpz) | **Required** | Pure Zig, ~120K req/s, WebSocket support |
| **Web Framework** | JetZig | **Optional** | Higher-level, file-based routing |
| **Database** | pg.zig | **Required** | PostgreSQL client |
| **Redis** | redis.zig | **Optional** | If caching needed |
| **JSON** | std.json | **Required** | Built-in, zero-allocation parsing available |
| **Logging** | std.log | **Required** | Structured, scoped loggers |
| **Testing** | Built-in | **Required** | `zig test` with std.testing |
| **Build System** | build.zig/zon | **Required** | Native build system |
| **CI/CD** | GitHub Actions | **Required** | Cross-platform builds |
| **Allocation Tracking** | std.heap.GeneralPurposeAllocator | **Required** | Dev/QA leak detection |
| **Argon2** | zigcrypto/libsodium | **Optional** | Password hashing (bring your own) |

### Infrastructure

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Deployment** | Docker | **Required** | Multi-stage builds, static binaries |
| **Version Control** | Jujutsu (jj) | **Recommended** | Better UX, Git-compatible |
| **Process Manager** | systemd/Dokploy | **Optional** | For production deployment |

---

## Zig Version & Stability

### Current Stable: 0.14.x/0.15.x

Zig 1.0 expected 2026. Breaking changes between versions are managed via:
- Pin Zig version in `build.zig.zon` or Dockerfile
- Use `zigup` or `zvm` for version management
- Lock CI to specific version, update quarterly

### Key 0.14+/0.15+ Patterns

- **Self-hosted backend:** Default for Debug (5x faster compilation)
- **New I/O interface:** `std.Io` decouples I/O from async (coming)
- **Incremental compilation:** Experimental but usable with `-fincremental`
- **Comptime improvements:** Better error messages for meta-programming

---

## File Structure

### Tier 1: CLI/Small Service (Flat)

```
.
├── build.zig
├── build.zig.zon
└── src/
    ├── main.zig               # Entry point, routes, handlers
    ├── config.zig             # Env loading
    ├── db.zig                 # Direct queries (simple repo)
    └── models.zig             # Shared types
```

### Tier 2: Service (Modular)

```
.
├── build.zig
├── build.zig.zon
├── src/
│   ├── main.zig               # Entry point, minimal wiring
│   ├── root.zig               # Library exports
│   ├── config.zig             # Configuration (12-factor)
│   │
│   ├── http/                  # HTTP layer
│   │   ├── server.zig         # Server setup, middleware chain
│   │   ├── router.zig         # Route definitions
│   │   ├── middleware/
│   │   │   ├── auth.zig
│   │   │   ├── logging.zig
│   │   │   └── security.zig   # Headers, rate limiting
│   │   └── handlers/
│   │       ├── health.zig
│   │       ├── users.zig
│   │       └── donations.zig
│   │
│   ├── domain/                # Business logic
│   │   ├── user.zig           # User domain + inline tests
│   │   ├── donation.zig
│   │   └── errors.zig         # Error sets (UserError, etc.)
│   │
│   ├── storage/               # Data access
│   │   ├── postgres.zig       # Connection pool management
│   │   ├── user_repo.zig      # User queries
│   │   └── donation_repo.zig
│   │
│   └── lib/                   # Utilities
│       ├── json.zig
│       ├── validation.zig
│       └── crypto.zig         # Argon2 wrapper
│
└── zig-out/
```

### Tier 3: High-Performance (Specialized)

Add:
```
src/
  allocators/               # Custom allocators
    arena_pool.zig          # Thread-local arenas
    slab.zig                # Fixed-size object pool
  lockfree/                 # Lock-free data structures
    queue.zig
  simd/                     # SIMD utilities
    json_parser.zig
```

---

## Naming Conventions

### Standard Zig Conventions

| Type | Convention | Example |
|------|------------|---------|
| **Types (struct, enum, union, error)** | TitleCase | `User`, `HttpError` |
| **Namespaces (no fields)** | snake_case | `std.mem`, `httpz` |
| **Functions returning type** | TitleCase | `ArrayList(T)` |
| **Functions returning value** | camelCase | `parseInt`, `createUser` |
| **Variables** | snake_case | `user_id` |
| **Constants** | snake_case | `max_connections` |
| **Error values** | TitleCase | `OutOfMemory`, `InvalidInput` |
| **Fields** | snake_case | `.user_name` |
| **Files with state** | TitleCase | `Server.zig`, `User.zig` |
| **Files (namespace only)** | snake_case | `http_client.zig` |

### Acronym Casing

- **2 letters:** Uppercase: `IO`, `ID`, `UI`
- **3+ letters:** TitleCase: `Http`, `Json`, `Url`, `Uuid`

Examples:
```zig
const userId: Uuid = ...;                    // Type: Uuid, var: userId
const httpClient: HttpClient = ...;          // HttpClient type
const ioReader: IO.Reader = ...;             // IO is 2 letters
```

---

## Memory Management

### Allocator Pattern

Functions that allocate must receive an explicit `Allocator`. First parameter after `self`.

**Correction to common myth:** You CAN store allocators in structs when they represent resource ownership:

```zig
// Good - Arena owns its allocator reference
const RequestArena = struct {
    allocator: Allocator,      // Stored because arena owns this scope
    arena: std.heap.ArenaAllocator,

    pub fn init(allocator: Allocator) RequestArena {
        return .{
            .allocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator),
        };
    }

    pub fn deinit(self: *RequestArena) void {
        self.arena.deinit();
    }
};

// Bad - Passing allocator when not needed
fn processData(data: []const u8, allocator: Allocator) !void {
    // If this function doesn't allocate, don't take allocator
}
```

### Allocator Strategy by Scope

| Scope | Allocator | Pattern |
|-------|-----------|---------|
| **Global** | `page_allocator` or static buffer | Long-lived app state |
| **Request** | `ArenaAllocator` | All allocations freed at end |
| **Connection** | `FixedBufferAllocator` | Reuse buffer per connection |
| **Processing** | `GeneralPurposeAllocator` | Complex intermediate work |
| **Testing** | `testing.allocator` | Leak detection |

### Resource Cleanup: `defer` & `errdefer`

Always cleanup immediately after acquisition:

```zig
const conn = try pool.acquire();
defer conn.release();        // Always released

const row = try conn.query("SELECT ...");
defer row.deinit();          // Always freed

const data = try allocator.alloc(u8, 1024);
defer allocator.free(data);  // Freed on success AND failure

// For rollback on error only:
const tempFile = try createTemp();
errdefer tempFile.delete();  // Only if we fail after this point
```

---

## Error Handling

### Error Sets

Define explicit error sets for domains. Don't use `anyerror` in libraries.

```zig
pub const UserError = error{
    NotFound,
    InvalidEmail,
    DuplicateUsername,
    InsufficientFunds,
    Unauthorized,
};

pub const StorageError = error{
    ConnectionLost,
    QueryFailed,
    ConstraintViolation,
};

// Union of possible errors
pub const ServiceError = UserError || StorageError || std.mem.Allocator.Error;
```

### Propagation vs Handling

```zig
// Propagate with `try` - default choice
const user = try userRepo.findById(id);

// Handle with `catch` - when you can recover
const port = std.process.getenv("PORT") orelse "8080";
const parsed = std.fmt.parseInt(u16, port, 10) catch |err| {
    std.log.err("Invalid PORT env var: {}", .{err});
    return error.InvalidConfig;
};

// Conditional handling
const result = riskyOperation() catch |err| switch (err) {
    error.NotFound => null,           // OK, return null
    error.Timeout => retry(),         // Try again
    else => return err,               // Propagate others
};
```

### Error Traces

Zig has automatic error return traces (stack traces). Don't wrap errors with context strings in hot paths. If you need context, log it separately:

```zig
// Good - let stack trace show location
return error.UserNotFound;

// OK for debugging - but prefer structured logging
if (user == null) {
    std.log.debug("User not found: id={d}", .{id});
    return error.UserNotFound;
}
```

---

## HTTP Server (http.zig)

### Server Setup

```zig
const httpz = @import("httpz");

pub fn run(allocator: Allocator, config: Config) !void {
    var app = App{
        .allocator = allocator,
        .db_pool = try createPool(allocator, config.db_url),
    };
    defer app.db_pool.deinit();

    var server = try httpz.Server().init(allocator, .{
        .port = config.port,
        .workers = .{
            .count = config.worker_count,
        },
    });
    defer server.deinit();

    var router = try server.router(.{});

    // Routes
    router.get("/health", healthHandler);

    // User routes with middleware
    router.group("/api/v1/users", &router.group(.{
        .middleware = &.{authMiddleware},
    }), struct {
        pub fn index(req: *httpz.Request, res: *httpz.Response) !void {
            // Handler
        }
    });

    try server.listen();
}
```

### Middleware Pattern

```zig
fn authMiddleware(req: *httpz.Request, res: *httpz.Response, next: httpz.Next) !void {
    const token = req.header("Authorization") orelse {
        res.status = 401;
        return;
    };

    if (!validateToken(token)) {
        res.status = 403;
        return;
    }

    try next();  // Continue to handler
}
```

### Handler Structure

```zig
fn createUser(req: *httpz.Request, res: *httpz.Response) !void {
    // 1. Parse request (arena allocates)
    const body = try req.body();
    const input = try std.json.parseFromSlice(
        CreateUserInput, 
        req.arena, 
        body, 
        .{}
    );

    // 2. Validate
    try input.validate() catch |err| {
        res.status = 400;
        try res.json(.{ .error = "Invalid input" });
        return;
    };

    // 3. Call service
    const user = try userService.create(req.arena, input);

    // 4. Respond
    res.status = 201;
    try res.json(user);
}
```

---

## Database (pg.zig)

### Connection Pool

```zig
const pg = @import("pg");

pub const Pool = struct {
    inner: pg.Pool,

    pub fn init(allocator: Allocator, config: Config) !Pool {
        return .{
            .inner = try pg.Pool.init(allocator, .{
                .connect = .{
                    .port = config.db_port,
                    .host = config.db_host,
                },
                .auth = .{
                    .username = config.db_user,
                    .password = config.db_password,
                    .database = config.db_name,
                },
                .size = 10,  // Pool size
            }),
        };
    }

    pub fn deinit(self: *Pool) void {
        self.inner.deinit();
    }

    pub fn acquire(self: *Pool) !pg.Conn {
        return self.inner.acquire();
    }
};
```

### Query Pattern

```zig
// In storage/user_repo.zig
pub const UserRepo = struct {
    pool: *Pool,

    pub fn findById(self: UserRepo, allocator: Allocator, id: Uuid) !?User {
        const conn = try self.pool.acquire();
        defer conn.release();

        const row = (try conn.row(
            "SELECT id, name, email FROM users WHERE id = $1",
            .{id},
        )) orelse return null;
        defer row.deinit();

        return User{
            .id = row.get(0, Uuid),
            .name = try row.getAlloc(1, []const u8, allocator),
            .email = try row.getAlloc(2, []const u8, allocator),
        };
    }

    pub fn create(self: UserRepo, user: User) !void {
        const conn = try self.pool.acquire();
        defer conn.release();

        try conn.exec(
            "INSERT INTO users (id, name, email) VALUES ($1, $2, $3)",
            .{ user.id, user.name, user.email },
        );
    }
};
```

### Transaction Boundaries

pg.zig supports transactions. Service layer should own them:

```zig
// In service/user_service.zig
pub fn transferCredits(
    self: UserService, 
    allocator: Allocator,
    from: Uuid, 
    to: Uuid, 
    amount: i64
) !void {
    const conn = try self.pool.acquire();
    defer conn.release();

    // Start transaction
    try conn.begin();
    errdefer conn.rollback() catch {};  // Rollback on error

    try self.repo.debit(conn, from, amount);
    try self.repo.credit(conn, to, amount);

    try conn.commit();
}
```

---

## JSON Handling

### Parsing (Type-Safe)

```zig
const User = struct {
    id: Uuid,
    name: []const u8,
    email: []const u8,
};

fn parseUser(allocator: Allocator, json: []const u8) !User {
    return try std.json.parseFromSlice(User, allocator, json, .{
        .ignore_unknown_fields = true,  // Forward compatibility
    });
}
```

### Zero-Allocation Parsing (Advanced)

For high-throughput paths, use streaming parser:

```zig
fn parseUserFast(reader: anytype) !User {
    var parser = std.json.Reader.init(allocator);
    defer parser.deinit();

    // Stream parsing without allocating full tree
    // Implementation depends on specific schema
}
```

### Serialization

```zig
fn sendUser(res: *httpz.Response, user: User) !void {
    try res.json(user, .{ .emit_null_optional_fields = false });
}
```

---

## Validation

### Parse, Don't Validate

Use types to make illegal states unrepresentable:

```zig
pub const Email = struct {
    value: []const u8,

    pub fn parse(allocator: Allocator, raw: []const u8) !Email {
        // Validate format
        if (!std.mem.contains(u8, raw, "@")) {
            return error.InvalidEmail;
        }

        // Normalize (lowercase)
        const normalized = try std.ascii.allocLowerString(allocator, raw);

        return .{ .value = normalized };
    }
};

pub const User = struct {
    email: Email,  // Can't construct with invalid email
    age: u8,       // Can't be negative (type prevents it)
};
```

### Sanity Checks

```zig
pub fn validateInput(input: CreateUserInput) !void {
    if (input.name.len == 0 or input.name.len > 100) {
        return error.InvalidNameLength;
    }

    if (input.age < 13) {
        return error.TooYoung;
    }
}
```

---

## Testing

### Inline Tests (Idiomatic)

Tests live in same file as code (standard library style):

```zig
const User = struct {
    name: []const u8,

    pub fn validate(self: User) !void {
        if (self.name.len == 0) return error.EmptyName;
    }
};

test "User.validate rejects empty name" {
    const user = User{ .name = "" };
    try std.testing.expectError(error.EmptyName, user.validate());
}

test "User.validate accepts valid name" {
    const user = User{ .name = "Alice" };
    try user.validate();
}
```

### Test Allocators

Always use `std.testing.allocator` to detect leaks:

```zig
test "user repository creates user" {
    const allocator = std.testing.allocator;

    // Setup
    var pool = try TestPool.init(allocator);
    defer pool.deinit();

    const repo = UserRepo{ .pool = &pool };

    // Execute
    const user = try repo.create(allocator, .{
        .name = "Test",
        .email = "test@example.com",
    });
    defer allocator.free(user.email);  // If allocated

    // Assert
    try std.testing.expectEqualStrings("Test", user.name);
}
```

### Integration Tests

For database tests, use testcontainers or ephemeral DBs:

```zig
test "integration: full user flow" {
    const allocator = std.testing.allocator;

    // Setup test DB (using testcontainers via shell, or in-memory SQLite equivalent)
    const db = try TestDatabase.create(allocator);
    defer db.destroy();

    // Run full flow
    const app = try App.init(allocator, db.config());
    defer app.deinit();

    // Test HTTP endpoint
    const response = try app.request(.{
        .method = .POST,
        .path = "/users",
        .body = "{"name":"Test","email":"test@test.com"}",
    });

    try std.testing.expectEqual(201, response.status);
}
```

---

## Security

### Memory Safety (Debug/ReleaseSafe)

- Use `std.testing.allocator` in tests (detects leaks)
- Zero sensitive data before freeing:

```zig
const password: []u8 = try allocator.alloc(u8, 64);
defer {
    @memset(password, 0);  // Zero memory
    allocator.free(password);
}
```

### Input Validation

- Parse don't validate (use strong types)
- Bounds checking is enabled by default
- Slice safety: `buffer[0..len]` panics if out of bounds in Debug/ReleaseSafe

### Cryptography

Use `std.crypto` for primitives, bring Argon2 via libsodium or zigcrypto:

```zig
const std = @import("std");

// Hashing
var hash: [32]u8 = undefined;
std.crypto.hash.sha2.Sha256.hash(password, &hash, .{});

// Random
var buf: [32]u8 = undefined;
std.crypto.random.bytes(&buf);

// Argon2 (external library)
const argon2 = @import("argon2");
const params = argon2.Params{
    .m_cost = 47104,  // 46 MiB (OWASP)
    .t_cost = 1,
    .p_cost = 1,
};
```

### Request Size Limits

Prevent DoS via large payloads:

```zig
fn safeHandler(req: *httpz.Request, res: *httpz.Response) !void {
    const max_size = 1024 * 1024;  // 1MB
    const body = req.body() catch |err| {
        if (err == error.BodyTooBig) {
            res.status = 413;  // Payload Too Large
            return;
        }
        return err;
    };

    if (body.len > max_size) {
        res.status = 413;
        return;
    }
}
```

---

## Build System

### build.zig Structure

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Dependencies
    const httpz = b.dependency("httpz", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("httpz", httpz.module("httpz"));

    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    b.step("run", "Run the app").dependOn(&run_cmd.step);

    // Tests
    const test_step = b.step("test", "Run unit tests");
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}
```

### build.zig.zon (Dependencies)

```zig
.{
    .name = "myapp",
    .version = "0.1.0",
    .minimum_zig_version = "0.14.0",

    .dependencies = .{
        .httpz = .{
            .url = "git+https://github.com/karlseguin/http.zig#0.14.0",
            .hash = "1220...",
        },
    },

    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
}
```

---

## CI/CD (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        zig-version: ['0.14.0']

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: ${{ matrix.zig-version }}

      - name: Cache Zig
        uses: actions/cache@v3
        with:
          path: ~/.cache/zig
          key: zig-${{ matrix.zig-version }}-${{ hashFiles('build.zig.zon') }}

      - name: Format Check
        run: zig fmt --check src/

      - name: Build
        run: zig build

      - name: Test
        run: zig build test

      - name: Release Build
        run: zig build -Doptimize=ReleaseFast

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.14.0

      - name: Check for TODO/FIXME
        run: |
          if grep -r "TODO\|FIXME" src/ --include="*.zig"; then
            echo "Found TODO/FIXME markers"
            exit 1
          fi

  docker:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Docker Login
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Docker Build
        run: docker build -t app:${{ github.sha }} .

      - name: Docker Push
        run: |
          docker tag app:${{ github.sha }} ${{ secrets.DOCKER_USERNAME }}/app:${{ github.sha }}
          docker push ${{ secrets.DOCKER_USERNAME }}/app:${{ github.sha }}
```

---

## Deployment

### Dockerfile (Multi-stage)

```dockerfile
# Build stage
FROM alpine:latest AS builder
RUN apk add --no-cache zig

WORKDIR /app
COPY build.zig build.zig.zon ./
COPY src ./src

# Build static binary
RUN zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseFast

# Runtime stage (scratch or distroless)
FROM scratch
WORKDIR /app

# Copy binary
COPY --from=builder /app/zig-out/bin/myapp /app/myapp

# Copy CA certs if making HTTPS requests
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/

EXPOSE 8080

ENTRYPOINT ["/app/myapp"]
```

### Cross-Compilation

Zig excels at this:

```bash
# Linux AMD64 static
zig build -Dtarget=x86_64-linux-musl

# Linux ARM64 static  
zig build -Dtarget=aarch64-linux-musl

# Windows
zig build -Dtarget=x86_64-windows-gnu

# macOS
zig build -Dtarget=aarch64-macos
```

---

## Justfile

```justfile
set dotenv-load

# Build
build:
    zig build

release:
    zig build -Doptimize=ReleaseFast

# Testing
test:
    zig build test

test-filter name:
    zig build test -- --test-filter {{name}}

# Development
dev:
    zig build run

watch:
    zig build --watch

# Code Quality
fmt:
    zig fmt src/

fmt-check:
    zig fmt --check src/

lint:
    @echo "Running zig build verify..."
    zig build -Dverify
    @echo "Checking for TODOs..."
    ! grep -r "TODO\|FIXME" src/ --include="*.zig" || true

# Cross-compilation
cross-linux:
    zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseFast

cross-windows:
    zig build -Dtarget=x86_64-windows-gnu -Doptimize=ReleaseFast

cross-arm:
    zig build -Dtarget=aarch64-linux-musl -Doptimize=ReleaseFast

# Docker
docker-build:
    docker build -t myapp:latest .

docker-run:
    docker run -p 8080:8080 myapp:latest

clean:
    rm -rf zig-out/ zig-cache/

# Security check
security-check:
    @echo "Checking for unsafe patterns..."
    ! grep -r "catch unreachable" src/ --include="*.zig" || true
    @echo "Checking for missing errdefer..."
    # This is manual - review acquire() calls
```

---

## Code Quality Checklist

Before committing:

- [ ] All allocations have corresponding `defer`/`errdefer`
- [ ] Errors handled explicitly or propagated with `try`
- [ ] No `catch unreachable` in production code
- [ ] `zig fmt` applied
- [ ] `zig build test` passes
- [ ] No memory leaks (`std.testing.allocator` used)
- [ ] No `TODO` or `FIXME` without issue reference
- [ ] Cross-compilation tested (`just cross-linux`)
- [ ] Request size limits checked (prevent DoS)
- [ ] Sensitive data zeroized before free (`@memset`)
- [ ] Public functions have doc comments (`///`)
- [ ] Error sets defined explicitly (not `anyerror`)

---

## Quick Reference

**Build:**
- `zig build` - Debug build
- `zig build -Doptimize=ReleaseFast` - Optimized
- `zig build --watch` - Watch mode (0.14+)

**Format:**
- `zig fmt src/` - Auto-format
- `zig fmt --check src/` - Check only

**Test:**
- `zig test src/file.zig` - Test single file
- `zig build test` - Run all tests
- `zig build test -- --test-filter "pattern"` - Filter tests

**Cross-compile:**
- `zig build -Dtarget=x86_64-linux-musl` - Linux static
- `zig build -Dtarget=aarch64-macos` - macOS ARM

**Dev tools:**
- `zigup` - Version manager
- `zls` - Language server
- `zvm` - Alternative version manager

---

## Zig Zen

1. Communicate intent precisely
2. Edge cases matter
3. Favor reading code over writing code
4. Only one obvious way to do things
5. Runtime crashes are better than bugs
6. Compile errors are better than runtime crashes
7. Reduce the amount one must remember
8. Memory is a resource
