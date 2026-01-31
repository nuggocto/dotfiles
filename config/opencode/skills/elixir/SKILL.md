---
name: elixir
description: Elixir/Phoenix development following the BEAM way. Phoenix 1.8+, LiveView, Ecto, Oban, Bandit, Finch. Covers contexts, LiveView patterns, changesets, PubSub, testing with ExUnit, and deployment with Mix releases.
---

# Elixir/Phoenix Project Guidelines

## Project Philosophy

This project follows **the BEAM way**: fault-tolerant, concurrent, and explicit. We leverage OTP supervision trees for resilience, immutable data transformations, and explicit process communication. Phoenix LiveView is the default interface layer.

### Project Tiers

| Tier | Description | Architecture |
|------|-------------|--------------|
| **Tier 1** | Startup/MVP, < 10 LiveViews | LiveView monolith, flat contexts, minimal JS hooks |
| **Tier 2** | Standard SaaS, multiple domains | Bounded Contexts, Domain-driven design, PubSub, Oban |
| **Tier 3** | Distributed systems, high availability | Event sourcing, GenStage/Broadway pipelines, cluster-aware ETS |

> **Rule:** Start with Tier 1, refactor to Tier 2 when crossing domain boundaries, escalate to Tier 3 when you need event replay or cross-node coordination.

### The BEAM Philosophy

**"Let it crash"** means supervisors handle failure, not defensive coding:
- Process isolation over try/catch
- Explicit message passing over shared state
- Functions return `{:ok, result} | {:error, reason}` over exceptions

---

## Tech Stack

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **HTTP Server** | Bandit | **Required** | HTTP/1 & HTTP/2, replaces Cowboy |
| **Web Framework** | Phoenix 1.8+ | **Required** | LiveView as default layer |
| **UI Layer** | Phoenix LiveView | **Required** | Streams 1.0+, AsyncResult |
| **Database** | PostgreSQL 15+ | **Required** | JSONB for flexible attrs |
| **ORM** | Ecto | **Required** | Changesets for validation |
| **Background Jobs** | Oban | **Required** | PostgreSQL-backed, retries, cron |
| **HTTP Client** | Finch | **Required** | HTTP/1 & HTTP/2 pooling |
| **Clustering** | DNSCluster | **Required** | Fly.io/K8s service discovery |
| **PubSub** | Phoenix.PubSub | **Required** | PG or Redis adapters |
| **Email** | Swoosh | **Required** | Adapters for Mailgun, SES |
| **Assets** | esbuild + Tailwind | **Required** | No Node.js in production |
| **Testing** | ExUnit | **Required** | Async by default |
| **Security** | Sobelow | **Required** | Static analysis |
| **Formatting** | mix format | **Required** | Enforced in CI |
| **Linting** | Credo | **Recommended** | Code consistency |

---

## File Structure

### Tier 1: LiveView Monolith

```
lib/
  my_app/
    application.ex          # OTP supervision tree
    repo.ex                 # Ecto repo

    accounts/               # Context: User/Auth
      user.ex               # Schema + changesets
      user_live/            # Colocated LiveViews
        index.ex
        form_component.ex
      user_notifier.ex      # Swoosh mailer

    components/             # Shared function components
      core_components.ex
      layouts.ex

    router.ex               # Verified routes (~p syntax)
    endpoint.ex

config/
  runtime.exs               # 12-factor config (env vars)

test/
  support/
    conn_case.ex
    data_case.ex
  live/
    user_live_test.exs
```

### Tier 2: Domain-Driven Contexts

```
lib/
  my_app/
    iam/                    # Bounded Context
      accounts.ex           # Public API (context facade)
      accounts/
        user.ex
        user_token.ex
        policy.ex

    billing/                # Bounded Context
      subscriptions.ex
      subscriptions/
        subscription.ex
        stripe_client.ex

    infrastructure/         # Cross-cutting
      oban_jobs.ex
      mailer.ex
      http_client.ex
```

---

## The Flow

```
HTTP/WebSocket Request
    ↓
BANDIT → ENDPOINT → ROUTER
    ↓
LIVEVIEW (mount → handle_params → handle_event)
    ↓
CONTEXT FACADE (accounts.ex)
    ↓
ECTO SCHEMA (user.ex) + REPO
    ↓
Database
```

---

## Layer Responsibilities

| Layer | Does | Does NOT |
|-------|------|----------|
| **LiveView** | Handle events, manage form state, render HEEx, PubSub | Direct DB calls, business rules |
| **Context** | Orchestrate schemas, enforce business rules | HTTP concerns, HTML rendering |
| **Schema** | Data validation, changesets, relationships | Business logic, side effects |
| **Component** | Pure rendering (function components) | DB calls, event handling |

---

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| **Files** | snake_case | `user_live.ex`, `accounts.ex` |
| **Modules** | PascalCase, nested | `MyApp.Iam.Accounts` |
| **Contexts** | Domain noun | `Accounts`, `Billing` |
| **Schemas** | Singular noun | `User`, `Post` |
| **LiveViews** | Resource + Action | `UserLive.Index`, `UserLive.Edit` |
| **Jobs** | Worker suffix | `EmailWorker` |

### Function Patterns

| Pattern | Return Type | Example |
|---------|-------------|---------|
| `list_*` | `[%Schema{}]` | `list_users/1` |
| `get_*` | `{:ok, struct} \| {:error, :not_found}` | `get_user/1` |
| `fetch_*` | `struct \| nil` | `fetch_user/1` |
| `create_*` | `{:ok, struct} \| {:error, changeset}` | `create_user/1` |
| `update_*` | `{:ok, struct} \| {:error, changeset}` | `update_user/2` |
| `delete_*` | `{:ok, struct} \| {:error, changeset}` | `delete_user/1` |
| `change_*` | `Ecto.Changeset.t()` | `change_user/2` |

---

## Functional Patterns

### The `with` Statement

```elixir
def create_user_with_org(attrs, org_id) do
  with {:ok, org} <- Billing.fetch_org(org_id),
       {:ok, user} <- Accounts.create_user(attrs),
       {:ok, _} <- Accounts.associate_user_org(user, org) do
    {:ok, user}
  else
    {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    {:error, :org_not_found} -> {:error, :invalid_organization}
  end
end
```

### Ecto.Multi for Transactions

```elixir
Ecto.Multi.new()
|> Ecto.Multi.insert(:user, User.changeset(attrs))
|> Ecto.Multi.run(:profile, fn _repo, %{user: user} ->
  Profiles.create_default_profile(user)
end)
|> Repo.transaction()
|> case do
  {:ok, %{user: user}} -> {:ok, user}
  {:error, _step, changeset, _} -> {:error, changeset}
end
```

---

## Schema Design

```elixir
defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :confirmed_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email, :password])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/)
    |> validate_length(:password, min: 12)
    |> unique_constraint(:email)
    |> update_change(:email, &String.downcase/1)
  end
end
```

---

## LiveView Patterns

### Verified Routes

```elixir
<.link navigate={~p"/users/#{user}"}>Profile</.link>
redirect(to: ~p"/users/#{user.id}/edit")
```

### Streams for Performance

```elixir
def mount(_params, _session, socket) do
  {:ok, stream(socket, :posts, Posts.list_posts())}
end

def handle_event("delete", %{"id" => id}, socket) do
  post = Posts.get!(id)
  {:ok, _} = Posts.delete_post(post)
  {:noreply, stream_delete(socket, :posts, post)}
end
```

### Async Operations

```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:weather, AsyncResult.loading())
   |> start_async(:weather_task, fn -> WeatherAPI.fetch() end)}
end

def handle_async(:weather_task, {:ok, result}, socket) do
  {:noreply, assign(socket, :weather, AsyncResult.ok(result))}
end
```

### Function Components

```elixir
attr :user, User, required: true
attr :class, :string, default: nil

def user_card(assigns) do
  ~H"""
  <div class={["bg-white rounded-lg shadow", @class]}>
    <h3>{@user.email}</h3>
  </div>
  """
end
```

---

## Background Jobs (Oban)

```elixir
defmodule MyApp.Workers.EmailWorker do
  use Oban.Worker, queue: :mailers, max_attempts: 3

  @impl Oban.Worker
  def perform(%{args: %{"user_id" => user_id, "template" => template}}) do
    user = Accounts.get_user!(user_id)
    UserNotifier.deliver(user, template)
    :ok
  end
end

# Enqueueing
Oban.insert(%{user_id: user.id, template: "welcome"})
```

---

## HTTP Client (Finch)

```elixir
defmodule MyApp.StripeClient do
  @base_url "https://api.stripe.com/v1"

  def create_customer(email) do
    Finch.build(:post, "#{@base_url}/customers", headers())
    |> Finch.request(MyApp.Finch)
    |> case do
      {:ok, %{status: 200, body: body}} -> Jason.decode(body)
      {:ok, %{status: status}} -> {:error, "API returned #{status}"}
      {:error, reason} -> {:error, reason}
    end
  end
end
```

---

## Testing

### ExUnit Async

```elixir
defmodule MyApp.AccountsTest do
  use MyApp.DataCase, async: true

  describe "register_user/1" do
    test "creates user with valid data" do
      assert {:ok, %User{} = user} = Accounts.register_user(%{
        email: "test@example.com",
        password: "validpass123"
      })
      assert user.email == "test@example.com"
    end

    test "requires email uniqueness" do
      existing = user_fixture()
      assert {:error, changeset} = Accounts.register_user(%{email: existing.email})
      assert "has already been taken" in errors_on(changeset).email
    end
  end
end
```

### LiveView Testing

```elixir
test "creates user", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/users/new")

  assert view
  |> form("#user-form", user: %{password: "short"})
  |> render_change() =~ "should be at least 12"

  {:ok, _, html} =
    view
    |> form("#user-form", user: valid_user_attributes())
    |> render_submit()
    |> follow_redirect(conn, ~p"/users")

  assert html =~ "User created"
end
```

---

## CI/CD (GitHub Actions)

```yaml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.18'
          otp-version: '27'

      - run: mix deps.get
      - run: mix format --check-formatted
      - run: mix credo --strict
      - run: mix sobelow --config
      - run: mix compile --warnings-as-errors
      - run: mix test --warnings-as-errors
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost/myapp_test
```

---

## Deployment (Mix Release)

### Dockerfile

```dockerfile
FROM hexpm/elixir:1.18.0-erlang-27.0-alpine-3.20 AS builder
ENV MIX_ENV=prod
WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV && mix deps.compile

COPY config config
COPY priv priv
COPY lib lib
COPY assets assets

RUN mix assets.deploy && mix compile && mix release

FROM alpine:3.20
RUN apk add --no-cache libstdc++ openssl ncurses-libs
WORKDIR /app
COPY --from=builder /app/_build/prod/rel/my_app ./

ENV HOME=/app
EXPOSE 4000
CMD ["bin/my_app", "start"]
```

---

## Justfile

```justfile
set dotenv-load

dev:
    iex -S mix phx.server

test:
    mix test

lint: fmt credo sobelow

fmt:
    mix format

credo:
    mix credo --strict

sobelow:
    mix sobelow --config

migrate:
    mix ecto.migrate

db-reset:
    mix ecto.reset

release:
    mix release
```

---

## Code Quality Checklist

- [ ] `mix format` passes
- [ ] `mix credo --strict` passes
- [ ] `mix sobelow` shows no security issues
- [ ] `mix test` passes
- [ ] Database operations in transactions (Multi or Repo.transaction)
- [ ] N+1 queries eliminated (preload in queries)
- [ ] Changesets validate at schema level
- [ ] LiveView handles `{:error, _}` tuples
- [ ] Oban jobs idempotent
- [ ] Health check endpoint at `/health`

---

## Quick Reference

**Mix tasks:**
- `mix phx.new app --live` - New LiveView app
- `mix phx.gen.live Context Schema attrs` - CRUD with LiveView
- `mix ecto.create/migrate/rollback` - DB ops
- `mix release` - Production build

**Common imports:**
```elixir
import Ecto.Query
import Ecto.Changeset
alias MyApp.Repo
alias Phoenix.LiveView
```

**LiveView lifecycle:**
```
mount -> handle_params -> render
handle_event/handle_info -> render
```

**OTP fundamentals:**
```elixir
GenServer.call(pid, :get)     # Sync
GenServer.cast(pid, {:set, v}) # Async
Phoenix.PubSub.subscribe(MyApp.PubSub, "topic")
```
