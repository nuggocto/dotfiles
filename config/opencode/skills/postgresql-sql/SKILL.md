---
name: postgresql-sql
description: PostgreSQL database design, migrations, queries, indexing, and performance optimization. Use for schema design, writing efficient SQL, migrations, and database best practices. Works with sqlc, SQLx, Squirrel, and raw SQL.
---

# PostgreSQL SQL Best Practices

## Philosophy

Write **raw SQL** with type-safe tooling. ORMs hide complexity and generate inefficient queries. We use:
- **sqlc** (Go) - Generate type-safe Go from SQL
- **SQLx** (Rust) - Compile-time checked queries
- **Squirrel** (Gleam) - SQL codegen for Gleam
- **pg.zig** (Zig) - Direct PostgreSQL access

**Principles:**
1. Schema is the source of truth
2. Migrations are version-controlled code
3. Every query should be explainable
4. Index for your queries, not your schema
5. Prefer constraints over application validation

---

## Schema Design

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Tables | snake_case, plural | `users`, `order_items` |
| Columns | snake_case | `created_at`, `user_id` |
| Primary keys | `id` | `id` |
| Foreign keys | `{table}_id` | `user_id`, `order_id` |
| Indexes | `idx_{table}_{columns}` | `idx_users_email` |
| Unique constraints | `uniq_{table}_{columns}` | `uniq_users_email` |
| Check constraints | `chk_{table}_{description}` | `chk_orders_positive_total` |
| Functions | snake_case, verb first | `get_user_stats()`, `calculate_total()` |

### Primary Keys

**Always use UUIDv7** for new tables (time-sortable, no sequential guessing):

```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- For UUIDv7, generate in application layer
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

**When to use BIGSERIAL:**
- Internal lookup tables (countries, statuses)
- High-write tables where UUID overhead matters
- Legacy system integration

```sql
CREATE TABLE countries (
    id BIGSERIAL PRIMARY KEY,
    code CHAR(2) NOT NULL UNIQUE,
    name TEXT NOT NULL
);
```

### Timestamps

**Always include audit timestamps:**

```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    -- ... other columns ...
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

### Soft Deletes

**Prefer soft deletes for user data:**

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email TEXT NOT NULL,
    deleted_at TIMESTAMPTZ,  -- NULL = active
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Partial unique index: email unique only for active users
CREATE UNIQUE INDEX uniq_users_email_active 
ON users (email) 
WHERE deleted_at IS NULL;

-- Default view excludes deleted
CREATE VIEW active_users AS
SELECT * FROM users WHERE deleted_at IS NULL;
```

### Foreign Keys

**Always define with explicit actions:**

```sql
CREATE TABLE orders (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shipping_address_id UUID REFERENCES addresses(id) ON DELETE SET NULL,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

| Action | Use When |
|--------|----------|
| `CASCADE` | Child has no meaning without parent (order_items -> orders) |
| `SET NULL` | Reference is optional (orders -> shipping_address) |
| `RESTRICT` | Prevent deletion if referenced (users -> critical_data) |
| `NO ACTION` | Check at transaction end (circular references) |

### Constraints

**Push validation to the database:**

```sql
CREATE TABLE products (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) BETWEEN 1 AND 200),
    price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
    status TEXT NOT NULL DEFAULT 'draft' 
        CHECK (status IN ('draft', 'active', 'archived')),
    
    -- Multi-column constraint
    sale_price_cents INTEGER,
    CONSTRAINT chk_sale_price_less_than_price 
        CHECK (sale_price_cents IS NULL OR sale_price_cents < price_cents)
);
```

### JSONB Columns

**Use for flexible/nested data, not to avoid schema:**

```sql
CREATE TABLE events (
    id UUID PRIMARY KEY,
    type TEXT NOT NULL,
    -- Structured metadata varies by event type
    metadata JSONB NOT NULL DEFAULT '{}',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index specific JSONB paths you query
CREATE INDEX idx_events_metadata_user_id 
ON events ((metadata->>'user_id'))
WHERE metadata->>'user_id' IS NOT NULL;

-- GIN index for containment queries (@>, ?)
CREATE INDEX idx_events_metadata_gin 
ON events USING GIN (metadata);
```

**Query patterns:**

```sql
-- Extract value
SELECT metadata->>'user_id' AS user_id FROM events;

-- Filter by JSONB value
SELECT * FROM events WHERE metadata->>'type' = 'purchase';

-- Containment (uses GIN index)
SELECT * FROM events WHERE metadata @> '{"source": "web"}';

-- Check key exists
SELECT * FROM events WHERE metadata ? 'error';
```

### Arrays

**Use for small, bounded lists:**

```sql
CREATE TABLE posts (
    id UUID PRIMARY KEY,
    title TEXT NOT NULL,
    tags TEXT[] NOT NULL DEFAULT '{}',
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- GIN index for array containment
CREATE INDEX idx_posts_tags ON posts USING GIN (tags);
```

**Query patterns:**

```sql
-- Contains element
SELECT * FROM posts WHERE 'rust' = ANY(tags);

-- Contains all elements
SELECT * FROM posts WHERE tags @> ARRAY['rust', 'async'];

-- Overlaps (has any of)
SELECT * FROM posts WHERE tags && ARRAY['rust', 'go'];
```

---

## Migrations

### File Structure

```
migrations/
  000001_create_users.up.sql
  000001_create_users.down.sql
  000002_create_orders.up.sql
  000002_create_orders.down.sql
  000003_add_user_preferences.up.sql
  000003_add_user_preferences.down.sql
```

### Migration Rules

1. **One concern per migration** - Don't mix unrelated changes
2. **Always reversible** - Write both up and down
3. **Idempotent when possible** - Use `IF NOT EXISTS`, `IF EXISTS`
4. **No data loss in down** - Or document clearly
5. **Test both directions** - Run up, verify, run down, verify

### Safe Migration Patterns

**Adding columns:**

```sql
-- up.sql
ALTER TABLE users 
ADD COLUMN preferences JSONB NOT NULL DEFAULT '{}';

-- down.sql
ALTER TABLE users 
DROP COLUMN preferences;
```

**Adding NOT NULL column to existing table:**

```sql
-- up.sql (3-step process for large tables)
-- Step 1: Add nullable
ALTER TABLE users ADD COLUMN phone TEXT;

-- Step 2: Backfill (in batches for large tables)
UPDATE users SET phone = '' WHERE phone IS NULL;

-- Step 3: Add constraint
ALTER TABLE users ALTER COLUMN phone SET NOT NULL;
ALTER TABLE users ALTER COLUMN phone SET DEFAULT '';

-- down.sql
ALTER TABLE users DROP COLUMN phone;
```

**Renaming columns (zero-downtime):**

```sql
-- Migration 1: Add new column
ALTER TABLE users ADD COLUMN full_name TEXT;
UPDATE users SET full_name = name;
ALTER TABLE users ALTER COLUMN full_name SET NOT NULL;

-- Deploy code that writes to both columns
-- Deploy code that reads from new column

-- Migration 2: Drop old column (after code deployed)
ALTER TABLE users DROP COLUMN name;
```

**Adding indexes concurrently:**

```sql
-- up.sql
-- CONCURRENTLY prevents table locks (but can't be in transaction)
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders (user_id);

-- down.sql
DROP INDEX CONCURRENTLY idx_orders_user_id;
```

### Dangerous Operations

**Avoid in production migrations:**
- `DROP TABLE` without backup verification
- `TRUNCATE` on important tables
- `ALTER TABLE ... ALTER COLUMN TYPE` on large tables (rewrites table)
- Adding `UNIQUE` constraint without checking duplicates first
- `CREATE INDEX` without `CONCURRENTLY` on large tables

---

## Query Patterns

### Basic CRUD

**Insert with returning:**

```sql
-- name: CreateUser :one
INSERT INTO users (id, email, name, created_at)
VALUES ($1, $2, $3, now())
RETURNING *;
```

**Insert with conflict handling:**

```sql
-- name: UpsertUser :one
INSERT INTO users (id, email, name)
VALUES ($1, $2, $3)
ON CONFLICT (email) DO UPDATE SET
    name = EXCLUDED.name,
    updated_at = now()
RETURNING *;
```

**Batch insert:**

```sql
-- name: CreateOrderItems :copyfrom
INSERT INTO order_items (order_id, product_id, quantity, price_cents)
VALUES ($1, $2, $3, $4);
```

**Select with pagination:**

```sql
-- name: ListUsers :many
SELECT *
FROM users
WHERE deleted_at IS NULL
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;
```

**Cursor-based pagination (preferred for large datasets):**

```sql
-- name: ListUsersAfter :many
SELECT *
FROM users
WHERE deleted_at IS NULL
  AND (created_at, id) < ($1, $2)  -- cursor: (last_created_at, last_id)
ORDER BY created_at DESC, id DESC
LIMIT $3;
```

**Update with returning:**

```sql
-- name: UpdateUser :one
UPDATE users
SET 
    name = COALESCE($2, name),
    email = COALESCE($3, email),
    updated_at = now()
WHERE id = $1
  AND deleted_at IS NULL
RETURNING *;
```

**Soft delete:**

```sql
-- name: DeleteUser :exec
UPDATE users
SET deleted_at = now()
WHERE id = $1
  AND deleted_at IS NULL;
```

### Joins

**Inner join (both must exist):**

```sql
-- name: GetOrderWithUser :one
SELECT 
    o.id,
    o.total_cents,
    o.created_at,
    u.email AS user_email,
    u.name AS user_name
FROM orders o
INNER JOIN users u ON u.id = o.user_id
WHERE o.id = $1;
```

**Left join (include even if no match):**

```sql
-- name: GetUserWithOrders :many
SELECT 
    u.id,
    u.email,
    o.id AS order_id,
    o.total_cents
FROM users u
LEFT JOIN orders o ON o.user_id = u.id
WHERE u.id = $1
ORDER BY o.created_at DESC;
```

**Multiple joins:**

```sql
-- name: GetOrderDetails :many
SELECT 
    o.id AS order_id,
    o.created_at,
    u.email AS user_email,
    p.name AS product_name,
    oi.quantity,
    oi.price_cents
FROM orders o
INNER JOIN users u ON u.id = o.user_id
INNER JOIN order_items oi ON oi.order_id = o.id
INNER JOIN products p ON p.id = oi.product_id
WHERE o.id = $1;
```

### Aggregations

**Basic aggregation:**

```sql
-- name: GetUserOrderStats :one
SELECT 
    COUNT(*) AS total_orders,
    COALESCE(SUM(total_cents), 0) AS total_spent_cents,
    COALESCE(AVG(total_cents), 0)::INTEGER AS avg_order_cents,
    MAX(created_at) AS last_order_at
FROM orders
WHERE user_id = $1
  AND status = 'completed';
```

**Group by with having:**

```sql
-- name: GetTopCustomers :many
SELECT 
    user_id,
    COUNT(*) AS order_count,
    SUM(total_cents) AS total_spent_cents
FROM orders
WHERE status = 'completed'
  AND created_at >= $1  -- since date
GROUP BY user_id
HAVING COUNT(*) >= 5    -- at least 5 orders
ORDER BY total_spent_cents DESC
LIMIT $2;
```

### Common Table Expressions (CTEs)

**Readable multi-step queries:**

```sql
-- name: GetUserDashboard :one
WITH user_orders AS (
    SELECT 
        COUNT(*) AS total_orders,
        COALESCE(SUM(total_cents), 0) AS total_spent
    FROM orders
    WHERE user_id = $1 AND status = 'completed'
),
recent_orders AS (
    SELECT id, total_cents, created_at
    FROM orders
    WHERE user_id = $1
    ORDER BY created_at DESC
    LIMIT 5
)
SELECT 
    u.id,
    u.email,
    u.name,
    uo.total_orders,
    uo.total_spent,
    COALESCE(
        json_agg(json_build_object(
            'id', ro.id,
            'total', ro.total_cents,
            'date', ro.created_at
        )) FILTER (WHERE ro.id IS NOT NULL),
        '[]'
    ) AS recent_orders
FROM users u
CROSS JOIN user_orders uo
LEFT JOIN recent_orders ro ON true
WHERE u.id = $1
GROUP BY u.id, u.email, u.name, uo.total_orders, uo.total_spent;
```

**Recursive CTE (hierarchical data):**

```sql
-- name: GetCategoryTree :many
WITH RECURSIVE category_tree AS (
    -- Base case: root categories
    SELECT id, name, parent_id, 0 AS depth, ARRAY[id] AS path
    FROM categories
    WHERE parent_id IS NULL
    
    UNION ALL
    
    -- Recursive case: children
    SELECT c.id, c.name, c.parent_id, ct.depth + 1, ct.path || c.id
    FROM categories c
    INNER JOIN category_tree ct ON ct.id = c.parent_id
    WHERE ct.depth < 10  -- prevent infinite loops
)
SELECT * FROM category_tree
ORDER BY path;
```

### Window Functions

**Row numbering:**

```sql
-- name: GetUserOrdersRanked :many
SELECT 
    id,
    total_cents,
    created_at,
    ROW_NUMBER() OVER (ORDER BY created_at DESC) AS order_number,
    RANK() OVER (ORDER BY total_cents DESC) AS spend_rank
FROM orders
WHERE user_id = $1;
```

**Running totals:**

```sql
-- name: GetDailyRevenueRunning :many
SELECT 
    DATE(created_at) AS date,
    SUM(total_cents) AS daily_revenue,
    SUM(SUM(total_cents)) OVER (ORDER BY DATE(created_at)) AS cumulative_revenue
FROM orders
WHERE status = 'completed'
  AND created_at >= $1
GROUP BY DATE(created_at)
ORDER BY date;
```

**Partitioned calculations:**

```sql
-- name: GetProductSalesWithCategoryRank :many
SELECT 
    p.id,
    p.name,
    p.category_id,
    COUNT(oi.id) AS total_sold,
    RANK() OVER (
        PARTITION BY p.category_id 
        ORDER BY COUNT(oi.id) DESC
    ) AS category_rank
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.id
GROUP BY p.id, p.name, p.category_id;
```

---

## Indexing

### Index Types

| Type | Use Case | Example |
|------|----------|---------|
| B-tree (default) | Equality, range, sorting | `WHERE status = 'active'`, `ORDER BY created_at` |
| Hash | Equality only (rarely used) | `WHERE id = $1` |
| GIN | Arrays, JSONB, full-text | `WHERE tags @> ARRAY['rust']` |
| GiST | Geometric, range types | PostGIS, `tsrange` |
| BRIN | Large sequential data | Time-series, append-only logs |

### Index Strategy

**Index for your queries, not your schema:**

```sql
-- Look at your WHERE clauses
WHERE user_id = $1 AND status = 'active'
-- Index: (user_id, status)

-- Look at your ORDER BY
ORDER BY created_at DESC
-- Index: (created_at DESC)

-- Combine for covering index
WHERE user_id = $1 ORDER BY created_at DESC
-- Index: (user_id, created_at DESC)
```

**Partial indexes (filtered):**

```sql
-- Only index active orders (smaller, faster)
CREATE INDEX idx_orders_user_active 
ON orders (user_id, created_at DESC)
WHERE status = 'active';

-- Only index non-deleted users
CREATE INDEX idx_users_email_active
ON users (email)
WHERE deleted_at IS NULL;
```

**Expression indexes:**

```sql
-- Index lowercase email for case-insensitive lookup
CREATE INDEX idx_users_email_lower 
ON users (lower(email));

-- Query must match expression exactly
SELECT * FROM users WHERE lower(email) = lower($1);
```

**Covering indexes (include columns):**

```sql
-- Include columns to avoid table lookup
CREATE INDEX idx_orders_user_covering
ON orders (user_id)
INCLUDE (status, total_cents, created_at);

-- This query can be answered from index alone
SELECT status, total_cents, created_at
FROM orders
WHERE user_id = $1;
```

### Anti-Patterns

**Don't index:**
- Low-cardinality columns alone (`status`, `is_active`)
- Columns rarely used in WHERE/ORDER BY
- Every foreign key blindly (only if you query by it)

**Do analyze:**

```sql
-- Check if index is being used
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM orders WHERE user_id = $1;

-- Check index usage stats
SELECT 
    indexrelname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

---

## Performance

### EXPLAIN ANALYZE

**Always analyze slow queries:**

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders WHERE user_id = $1;
```

**What to look for:**
- `Seq Scan` on large tables = missing index
- `Nested Loop` with high row counts = consider Hash Join
- `Sort` with high memory = add index for ORDER BY
- `Buffers: shared read` high = data not in cache

### Query Optimization

**Use EXISTS instead of COUNT for existence checks:**

```sql
-- Bad: counts all matching rows
SELECT COUNT(*) > 0 FROM orders WHERE user_id = $1;

-- Good: stops at first match
SELECT EXISTS (SELECT 1 FROM orders WHERE user_id = $1);
```

**Use ANY instead of multiple ORs:**

```sql
-- Bad
SELECT * FROM users WHERE id = $1 OR id = $2 OR id = $3;

-- Good
SELECT * FROM users WHERE id = ANY($1::uuid[]);
```

**Avoid SELECT *:**

```sql
-- Bad: fetches all columns
SELECT * FROM users WHERE id = $1;

-- Good: fetch only what you need
SELECT id, email, name FROM users WHERE id = $1;
```

**Use LIMIT with ORDER BY:**

```sql
-- Bad: sorts entire table
SELECT * FROM orders ORDER BY created_at DESC;

-- Good: limit the sort
SELECT * FROM orders ORDER BY created_at DESC LIMIT 100;
```

### Connection Pooling

**Always use a connection pooler in production:**

- **PgBouncer** - Lightweight, transaction/statement pooling
- **Supabase Supavisor** - If using Supabase
- **Built-in** - sqlx, pgx have built-in pools

**Pool sizing rule of thumb:**

```
connections = (CPU cores * 2) + effective_spindle_count
```

For most apps: 10-20 connections per application instance.

---

## Security

### Parameterized Queries

**Always use parameters, never string concatenation:**

```sql
-- NEVER do this (SQL injection vulnerable)
SELECT * FROM users WHERE email = '" + email + "';

-- Always use parameters
SELECT * FROM users WHERE email = $1;
```

### Least Privilege

**Create specific roles:**

```sql
-- Application role (limited permissions)
CREATE ROLE app_user WITH LOGIN PASSWORD 'secret';
GRANT CONNECT ON DATABASE myapp TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;

-- Read-only role for reporting
CREATE ROLE readonly WITH LOGIN PASSWORD 'secret';
GRANT CONNECT ON DATABASE myapp TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
```

### Row-Level Security (RLS)

**For multi-tenant applications:**

```sql
-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Policy: users can only see their own orders
CREATE POLICY orders_isolation ON orders
    FOR ALL
    USING (user_id = current_setting('app.current_user_id')::uuid);

-- Set user context in application
SET app.current_user_id = 'user-uuid-here';
SELECT * FROM orders;  -- Only returns user's orders
```

---

## Testing

### Test Database Setup

```sql
-- Create test database
CREATE DATABASE myapp_test TEMPLATE myapp;

-- Or use schemas for isolation
CREATE SCHEMA test_tenant_1;
SET search_path TO test_tenant_1, public;
```

### Test Data Patterns

**Factory functions:**

```sql
CREATE OR REPLACE FUNCTION test_create_user(
    p_email TEXT DEFAULT 'test@example.com',
    p_name TEXT DEFAULT 'Test User'
) RETURNS users AS $$
DECLARE
    v_user users;
BEGIN
    INSERT INTO users (id, email, name)
    VALUES (gen_random_uuid(), p_email, p_name)
    RETURNING * INTO v_user;
    RETURN v_user;
END;
$$ LANGUAGE plpgsql;
```

**Transaction rollback testing:**

```go
// Go example with sqlc
func TestCreateUser(t *testing.T) {
    tx, _ := db.Begin(ctx)
    defer tx.Rollback(ctx)  // Always rollback
    
    q := New(tx)
    user, err := q.CreateUser(ctx, CreateUserParams{...})
    // assertions...
}
```

### Query Testing

Test your actual queries, not mocks:

```go
func TestListUserOrders(t *testing.T) {
    // Setup
    tx, _ := db.Begin(ctx)
    defer tx.Rollback(ctx)
    q := New(tx)
    
    user, _ := q.CreateUser(ctx, ...)
    _, _ = q.CreateOrder(ctx, CreateOrderParams{UserID: user.ID, ...})
    _, _ = q.CreateOrder(ctx, CreateOrderParams{UserID: user.ID, ...})
    
    // Test
    orders, err := q.ListUserOrders(ctx, user.ID)
    
    // Assert
    assert.NoError(t, err)
    assert.Len(t, orders, 2)
}
```

---

## Tooling Integration

### sqlc (Go)

```yaml
# sqlc.yaml
version: "2"
sql:
  - engine: "postgresql"
    queries: "queries/"
    schema: "migrations/"
    gen:
      go:
        package: "db"
        out: "internal/db"
        sql_package: "pgx/v5"
        emit_json_tags: true
        emit_prepared_queries: true
```

### SQLx (Rust)

```rust
// Compile-time checked
let user = sqlx::query_as!(
    User,
    "SELECT id, email, name FROM users WHERE id = $1",
    user_id
)
.fetch_one(&pool)
.await?;
```

### Squirrel (Gleam)

```gleam
// Generated from SQL files
pub fn get_user(db: pog.Connection, id: String) -> Result(User, pog.QueryError) {
  sql.get_user(db, id)
}
```

---

## Checklist

Before deploying schema changes:

- [ ] Migration has both up and down scripts
- [ ] Tested migration on copy of production data
- [ ] Large table changes use `CONCURRENTLY`
- [ ] New columns have sensible defaults or are nullable
- [ ] Indexes added for new query patterns
- [ ] Foreign keys have appropriate ON DELETE action
- [ ] Constraints push validation to database level
- [ ] No personally identifiable data in logs/errors

Before deploying queries:

- [ ] EXPLAIN ANALYZE shows index usage
- [ ] No N+1 query patterns
- [ ] Parameters used (no string concatenation)
- [ ] LIMIT used with ORDER BY
- [ ] Appropriate columns selected (no SELECT *)
- [ ] Error handling for not found / constraint violations
