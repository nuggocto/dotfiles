---
name: solid-frontend
description: SolidStart frontend development with fine-grained reactivity, signals, createMemo, TanStack Query, and Tailwind CSS. Use for building reactive web applications with SolidJS/SolidStart.
---

# AGENTS.md - SolidStart Frontend Project Guidelines

## Project Philosophy

SolidStart enables **fine-grained reactivity** with server-side rendering capabilities. We follow a **minimal dependencies** approach with framework-native patterns, preferring built-in SolidStart solutions over third-party libraries. Components run once (not on every render), making dependency tracking explicit and debugging predictable.

### Project Tiers

SolidStart scales from simple SPAs to complex full-stack applications:

| Tier | Description | Architecture |
|------|-------------|--------------|
| **Tier 1** | Client-side SPA, static marketing sites | `solid-js` only (no Start), client routing, minimal server functions |
| **Tier 2** | Full-stack apps with auth, dashboards, data | SolidStart with SSR/SSG, TanStack Query, server functions, file-based routing |
| **Tier 3** | Real-time collaborative apps, heavy interactivity | Server-sent events, WebSockets, granular reactivity optimization, edge deployment |

> **Rule:** Start with Tier 1 if you just need a reactive UI, use Tier 2 when you need SEO or server-side data, escalate to Tier 3 for real-time features or extreme performance requirements.

### Reactivity Philosophy

"Components run once" means your JavaScript code executes one time, not on every state change like React. Signals trigger granular DOM updates directly. This changes how you architect: don't fear derived state, prefer signals over stores, and use effects only for side effects, not synchronization.

---

## Tech Stack

### Core

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Framework** | SolidStart | **Required** | Latest stable with Solid 2.0 |
| **Language** | TypeScript | **Required** | Strict mode enabled |
| **Runtime** | Bun/Node | **Recommended** | Bun for dev, Node for deployment flexibility |
| **Package Manager** | Bun/pnpm/npm | **Flexible** | Bun recommended but pnpm/npm acceptable (no yarn) |
| **Bundler** | Vite (via Vinxi) | **Included** | SolidStart's meta-framework layer |
| **Linting** | oxlint/ESLint | **Recommended** | oxlint preferred, ESLint acceptable |
| **Formatting** | oxc format/Prettier | **Flexible** | oxc preferred but Prettier acceptable |
| **Testing** | Bun test + Playwright | **Required** | Unit + E2E |

### Data & State

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **HTTP Client** | ky | **Recommended** | Lightweight, retries, timeouts |
| **Server State** | TanStack Query | **Required** | Caching, background refetch, mutations |
| **Validation** | Zod 4 | **Required** | Runtime validation + TypeScript inference |
| **Forms** | Modular Forms / Felte | **Recommended** | Type-safe form handling |

### UI & Styling

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Styling** | Tailwind CSS | **Recommended** | Utility-first |
| **UI Components** | Kobalte / shadcn-solid | **Recommended** | Accessible, unstyled primitives |
| **Icons** | lucide-solid | **Recommended** | Tree-shakeable |

### Infrastructure

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Deployment** | Vercel/Netlify/Cloudflare | **Flexible** | Edge-compatible platforms |
| **CI/CD** | GitHub Actions | **Required** | Build, test, deploy |
| **VCS** | Jujutsu (jj) | **Recommended** | Better UX, Git-compatible |

---

## File Structure

### Tier 2: Full-Stack SolidStart (Feature-Based)

```
src/
  features/                    # Domain-specific vertical slices
    auth/
      components/
        LoginForm.tsx
        RegisterForm.tsx
        PasswordStrength.tsx   # client-only component
      api/
        auth.ts                # ky HTTP calls
        auth.queries.ts        # TanStack Query hooks
        auth.actions.ts        # Server actions
      schemas/
        login.schema.ts        # Zod schemas
        register.schema.ts
      signals/
        auth.signals.ts        # Auth state (client only)
      types/
        auth.types.ts
      utils/
        token.ts               # Client-side token handling
      index.ts                 # Barrel exports

    donations/
      components/
        DonationList.tsx
        DonationCard.tsx
      api/
        donations.queries.ts   # listDonations(), getDonation(id)
        donations.actions.ts   # createDonation(), updateDonation()
      schemas/
        donation.schema.ts
      stores/                  # Alternatives to signals for complex state
        donation.store.ts      # createStore for forms

    dashboard/
      components/
        Stats.tsx
        Chart.tsx              # Heavy - lazy load

  routes/                      # SolidStart file routing
    (app)/                     # Route group - layout wrapper
      layout.tsx               # Auth layout (checks session)
      dashboard/
        index.tsx              # /dashboard
      donations/
        index.tsx              # /donations
        [id]/
          index.tsx            # /donations/:id
          edit.tsx             # /donations/:id/edit
    (public)/
      layout.tsx               # Public layout
      login.tsx
      register.tsx
      [...404].tsx             # Catch-all
    index.tsx                  # Home page
    api/
      webhook.ts               # API routes

  shared/                      # Truly generic code
    components/                # Design system primitives
      Button.tsx
      Input.tsx
      Modal.tsx
      Card.tsx
      Toast/                   # Toast system
        Toast.tsx
        ToastContainer.tsx
        toaster.ts             # Signal-based toaster
    hooks/                     # Generic hooks (3+ uses)
      useClickOutside.ts
      useDebounce.ts
      useLocalStorage.ts
      useMediaQuery.ts
    directives/                # Solid directives (use:action)
      clickOutside.ts
      tooltip.ts
      trapFocus.ts
    utils/
      format.ts                # Date, number formatters
      cn.ts                    # tailwind-merge + clsx
      validation.ts            # Shared Zod helpers
    types/
      api.types.ts             # Generic API types
    config/
      constants.ts
      env.ts                   # Typed env validation

  lib/                         # Framework/infrastructure
    api/
      client.ts                # Configured ky instance
      errors.ts                # API error handling
    query/
      queryClient.ts           # TanStack Query client
      queryKeys.ts             # Centralized query keys
    server/                    # Server-only utilities
      auth.ts                  # Session validation, middleware
      db.ts                    # Database connection (if needed)

  entry-client.tsx
  entry-server.tsx
  app.tsx                      # Root component
  app.config.ts                # SolidStart configuration
  global.d.ts                  # TypeScript declarations

public/
  favicon.ico
  robots.txt
  manifest.json

tests/
  unit/                        # Bun test
    features/
  e2e/                         # Playwright
    auth.spec.ts
    donations.spec.ts

app.config.ts
vite.config.ts
tailwind.config.ts
package.json
bun.lockb
.env
.env.example
justfile
```

---

## Solid Reactivity Primitives

### Signals with `createSignal`

The foundation of Solid. Returns `[getter, setter]`.

```tsx
function Counter() {
  const [count, setCount] = createSignal(0);

  return (
    <button onClick={() => setCount(c => c + 1)}>
      Count: {count()}  {/* Function call! */}
    </button>
  );
}
```

**Critical Rule:** Always call the getter (`count()` not `count`). The function call is how Solid tracks dependencies.

### Derived State with `createMemo`

Cache expensive computations. Only re-runs when dependencies change.

```tsx
const [items, setItems] = createSignal<Item[]>([]);
const [filter, setFilter] = createSignal('');

// Expensive operation cached
const filteredItems = createMemo(() => {
  return items().filter(item => 
    item.name.toLowerCase().includes(filter().toLowerCase())
  );
});

// In JSX - calling the memo evaluates it if deps changed
<ul>
  <For each={filteredItems()}>{item => <li>{item.name}</li>}</For>
</ul>
```

Use `createMemo` instead of `createEffect` for derived values.

### Effects with `createEffect`

For side effects only (logging, DOM manipulation, external sync):

```tsx
const [user, setUser] = createSignal<User | null>(null);

createEffect(() => {
  // Runs whenever user() changes
  if (user()) {
    analytics.track('User Loaded', { id: user()!.id });
  }
});
```

**Warning:** Don't use effects to set state that derives from other state. That's a memo.

### Stores with `createStore`

For complex nested state that updates partially:

```tsx
const [state, setState] = createStore({
  user: { name: 'John', preferences: { theme: 'dark' } },
  posts: []
});

// Fine-grained updates - only touches user.name
setState('user', 'name', 'Jane');

// Array operations
setState('posts', posts => [...posts, newPost]);
```

**When to use:**
- Form state with nested fields
- Complex objects with independent fields
- State spread across multiple components (with context)

**When to use signals instead:**
- Simple primitive values
- Values that update together
- Top-level component state

---

## Component Standards

### Component Size

- **Target:** <100 lines for logic components, <150 for container components
- **Exception:** Complex forms with validation may reach 200 lines
- **Rule:** Extract when you need to scroll or when logic/mix concerns

### Props Handling (CRITICAL)

**Never destructure props directly.** This breaks reactivity.

```tsx
// BAD - Breaks reactivity
function UserCard({ name, email }: UserProps) {
  return <div>{name}</div>;  // Not reactive!
}

// GOOD - Props as getter object
function UserCard(props: UserProps) {
  return <div>{props.name}</div>;  // Tracks name changes
}

// GOOD - Split props for local vs rest
function UserCard(props: UserProps) {
  const [local, others] = splitProps(props, ['name', 'email']);

  return (
    <div {...others}>
      <h2>{local.name}</h2>
      <p>{local.email}</p>
    </div>
  );
}
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Components | PascalCase | `LoginForm.tsx`, `DonationCard.tsx` |
| Functions | camelCase | `handleSubmit`, `validateInput` |
| Signals | camelCase | `count`, `user` |
| Stores | camelCase with State | `formState`, `cartState` |
| Query hooks | camelCase with use | `useDonations`, `useUser` |
| Actions | camelCase | `createDonation`, `updateProfile` |
| Schemas | PascalCase with Schema | `LoginSchema`, `UserSchema` |
| Types | PascalCase | `User`, `ApiResponse` |

### Control Flow Components

Always use Solid's control flow, never JS logic in JSX:

```tsx
import { Show, For, Switch, Match, Suspense, ErrorBoundary } from 'solid-js';

// Conditional - use Show
<Show when={user()} fallback={<LoginPrompt />}>
  <UserProfile user={user()} />
</Show>

// List - use For (keyed by reference, most efficient)
<For each={posts()}>
  {(post, index) => <PostCard post={post} index={index()} />}
</For>

// Multiple conditions - use Switch/Match
<Switch fallback={<DefaultView />}>
  <Match when={status() === 'loading'}>
    <Spinner />
  </Match>
  <Match when={status() === 'error'}>
    <ErrorMessage />
  </Match>
  <Match when={status() === 'success'}>
    <Content />
  </Match>
</Switch>

// Async - use Suspense
<Suspense fallback={<Loading />}>  
  <AsyncComponent />
</Suspense>

// Error handling - use ErrorBoundary
<ErrorBoundary fallback={(err) => <ErrorMessage error={err} />}>
  <RiskyComponent />
</ErrorBoundary>
```

---

## State Management Strategy

### The Hierarchy (Simplest First)

```
1. Local signal              → createSignal
        ↓
2. Derived value             → createMemo
        ↓
3. URL state                 → useSearchParams (SolidStart)
        ↓
4. Server data               → createResource / TanStack Query
        ↓
5. Global client state       → Context + signals (last resort)
```

**Rule:** Start at level 1, escalate only when necessary. Most state is local or server.

### Context Pattern

```tsx
// features/cart/cart.context.tsx
const CartContext = createContext<ReturnType<typeof makeCartStore>>();

function makeCartStore() {
  const [items, setItems] = createStore<CartItem[]>([]);

  const addItem = (item: CartItem) => {
    setItems(items => [...items, item]);
  };

  const total = createMemo(() => 
    items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  );

  return { items: () => items, addItem, total };
}

export function CartProvider(props: { children: JSX.Element }) {
  const store = makeCartStore();
  return (
    <CartContext.Provider value={store}>
      {props.children}
    </CartContext.Provider>
  );
}

export function useCart() {
  return useContext(CartContext)!;
}
```

---

## Data Fetching

### TanStack Query (Recommended for apps)

```tsx
// features/donations/api/donations.queries.ts
import { createQuery, createMutation, useQueryClient } from '@tanstack/solid-query';

const queryKeys = {
  all: ['donations'] as const,
  lists: (filters: Filter) => [...queryKeys.all, 'list', filters] as const,
  detail: (id: string) => [...queryKeys.all, 'detail', id] as const,
};

export function useDonations(filters: Accessor<Filter>) {
  return createQuery(() => ({
    queryKey: queryKeys.lists(filters()),
    queryFn: () => fetchDonations(filters()),
    staleTime: 30 * 1000,  // 30s
  }));
}

export function useDonation(id: Accessor<string>) {
  return createQuery(() => ({
    queryKey: queryKeys.detail(id()),
    queryFn: () => fetchDonation(id()),
    staleTime: 60 * 1000,
  }));
}

export function useCreateDonation() {
  const queryClient = useQueryClient();

  return createMutation({
    mutationFn: createDonation,
    onSuccess: () => {
      // Invalidate and refetch lists
      queryClient.invalidateQueries({ queryKey: queryKeys.all });
    },
  });
}
```

### Server Functions (SolidStart)

```tsx
// Server function with "use server"
const createDonation = action(async (data: DonationInput) => {
  "use server";

  // This runs on the server only
  const donation = await db.donations.create({
    data: validateDonation(data),
  });

  return { success: true, donation };
});

// In component
function DonationForm() {
  const [result, submit] = createForm(createDonation);

  return (
    <form action={submit} method="post">
      {/* Form fields */}
    </form>
  );
}
```

### Request Timeouts & Retries (ky)

```tsx
// lib/api/client.ts
import ky from 'ky';

export const api = ky.create({
  prefixUrl: import.meta.env.VITE_API_URL,
  timeout: 10000,  // 10s timeout
  retry: {
    limit: 2,
    methods: ['get', 'post'],  // Retry POSTs for idempotency keys
    statusCodes: [408, 413, 429, 500, 502, 503, 504],
  },
  hooks: {
    beforeRequest: [
      async (request) => {
        const token = getAuthToken();
        if (token) {
          request.headers.set('Authorization', `Bearer ${token}`);
        }
      },
    ],
    afterResponse: [
      async (request, options, response) => {
        if (response.status === 401) {
          logout();
        }
        return response;
      },
    ],
  },
});
```

---

## Forms & Validation

### Zod Schema + Modular Forms

```tsx
import { createForm } from '@modular-forms/solid';
import { zodFormValidator } from '@modular-forms/zod';
import { z } from 'zod';

const LoginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
  remember: z.boolean().default(false),
});

type LoginForm = z.infer<typeof LoginSchema>;

function LoginForm() {
  const [form, { Form, Field }] = createForm<LoginForm>({
    validate: zodFormValidator(LoginSchema),
  });

  const handleSubmit = async (values: LoginForm) => {
    await login(values);
  };

  return (
    <Form onSubmit={handleSubmit}>
      <Field name="email">
        {(field, props) => (
          <div>
            <input {...props} type="email" value={field.value} />
            {field.error && <span>{field.error}</span>}
          </div>
        )}
      </Field>

      <button type="submit" disabled={form.submitting}>
        {form.submitting ? 'Logging in...' : 'Login'}
      </button>
    </Form>
  );
}
```

---

## Directives (use:)

Create reusable DOM behavior:

```tsx
// shared/directives/clickOutside.ts
import { onCleanup } from 'solid-js';

export function clickOutside(el: HTMLElement, accessor: () => () => void) {
  const onClick = (e: MouseEvent) => {
    if (!el.contains(e.target as Node)) {
      accessor()();  // Call the provided function
    }
  };

  document.addEventListener('click', onClick);
  onCleanup(() => document.removeEventListener('click', onClick));
}

// Register for TypeScript
declare module 'solid-js' {
  namespace JSX {
    interface Directives {
      clickOutside: () => void;
    }
  }
}

// Usage
function Dropdown() {
  const [isOpen, setIsOpen] = createSignal(false);

  return (
    <div use:clickOutside={() => setIsOpen(false)}>
      <button onClick={() => setIsOpen(true)}>Open</button>
      <Show when={isOpen()}>
        <DropdownMenu />
      </Show>
    </div>
  );
}
```

---

## Routing (SolidStart)

### Route Groups & Layouts

```tsx
// routes/(app)/layout.tsx
import { RouteDefinition, createAsync } from '@solidjs/router';
import { getUser } from '~/lib/server/auth';

export const route = {
  load: () => {
    // Preload on server
    void getUser();
  },
} satisfies RouteDefinition;

export default function AppLayout() {
  const user = createAsync(() => getUser(), { deferStream: true });

  return (
    <Show when={user()} fallback={<Navigate href="/login" />}>
      <div class="layout">
        <Nav user={user()} />
        <main>
          <Outlet />  {/* Child routes render here */}
        </main>
      </div>
    </Show>
  );
}
```

### Route Definitions

| Pattern | URL | File |
|---------|-----|------|
| Static | `/about` | `routes/about.tsx` |
| Dynamic | `/user/:id` | `routes/user/[id].tsx` |
| Catch-all | `/*404` | `routes/[...404].tsx` |
| Nested | `/blog/post` | `routes/blog/post.tsx` |
| Layout | N/A | `routes/layout.tsx` |

---

## Security

### XSS Prevention

Solid auto-escapes by default. Never use innerHTML:

```tsx
// BAD - XSS vulnerability
<div innerHTML={userInput} />

// GOOD - Solid escapes automatically
<div>{userInput}</div>

// If you must render HTML (Markdown, etc.), sanitize first
import DOMPurify from 'dompurify';
<div innerHTML={DOMPurify.sanitize(htmlContent)} />
```

---

## Justfile

```justfile
set dotenv-load

# Development
dev:
    bun run dev

# Building
build:
    bun run build

build-analyze:
    bun run build -- --analyze

preview:
    bun run preview

# Dependencies
install:
    bun install

update:
    bun update

# Quality
lint:
    bunx oxlint@latest .

typecheck:
    bunx tsc --noEmit

format:
    bunx oxc format --write .

format-check:
    bunx oxc format --check .

# Testing
test:
    bun test

test-e2e:
    bunx playwright test

test-e2e-ui:
    bunx playwright test --ui

# Full check
check: lint typecheck test
    @echo "All checks passed!"

# Utilities
clean:
    rm -rf dist/
    rm -rf .vinxi/
    rm -rf node_modules/.cache

# Production simulation
preview-prod: build
    bun run preview
```

---

## Code Quality Checklist

Before committing:

- [ ] Components <150 lines (or documented if larger)
- [ ] Props never destructured (use props.name or splitProps)
- [ ] `<For>` used instead of `.map()` for dynamic lists
- [ ] `<Show>` used instead of ternary for conditionals
- [ ] `createMemo` used for derived values (not useEffect pattern)
- [ ] No `console.log` in production code
- [ ] Loading and error states handled (Suspense/ErrorBoundary)
- [ ] Keyboard accessible (tabindex, onKeyDown)
- [ ] Responsive (mobile-first Tailwind)
- [ ] TypeScript strict mode passes
- [ ] Tests cover critical paths
- [ ] Feature code stays in feature folder (not leaked to shared/)

---

## Prohibited Patterns

- Never destructure props (breaks reactivity)
- Never use `.map()` in JSX (use `<For>`)
- Never use ternary for conditional rendering (use `<Show>`)
- Never use `createEffect` to set derived state (use `createMemo`)
- Never store tokens in localStorage (httpOnly cookies)
- Never use `any` type (unknown with type guards instead)
- Never import from feature internals (use barrel files)
- Never ignore query errors (handle in ErrorBoundary)
- Avoid `innerHTML` (XSS risk)
- Avoid prop drilling >3 levels (use context or composition)

---

## Resources

- **Solid Docs:** https://docs.solidjs.com/
- **SolidStart Docs:** https://docs.solidjs.com/solid-start
- **TanStack Query for Solid:** https://tanstack.com/query/latest/docs/framework/solid/overview
- **Kobalte (UI):** https://kobalte.dev/
- **Modular Forms:** https://modularforms.dev/
