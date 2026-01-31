---
name: svelte-frontend
description: SvelteKit frontend development with Svelte 5 runes, progressive enhancement, SSR/SSG, Superforms, TanStack Query, and Tailwind CSS. Use for building web applications with SvelteKit.
---

# AGENTS.md - SvelteKit Frontend Project Guidelines

## Project Philosophy

SvelteKit enables **progressive enhancement** with server-side rendering capabilities. We follow a **minimal dependencies** approach with framework-native patterns, leveraging Svelte 5 runes for fine-grained reactivity. The architecture is **feature-based** — organize by domain/feature rather than technical layer.

### Project Tiers

SvelteKit adapts to project complexity through its file-based routing and load functions:

| Tier | Description | Architecture |
|------|-------------|--------------|
| **Tier 1** | Marketing sites, blogs, simple CRUD | Full SSR/SSG, minimal client JS, `+page.server.ts` for data |
| **Tier 2** | Dashboards, authenticated apps, real-time | Universal load functions, TanStack Query, streamed promises, form actions |
| **Tier 3** | Complex SPAs, heavy client interactivity | Client-side routing dominance, stores for global state, optimistic UI, consider migrating to SolidStart for extreme cases |

> **Rule:** Start with Tier 1 (server-first), move to Tier 2 when you need rich interactions, use Tier 3 only when client-side state dominates. SvelteKit excels at Tiers 1-2; consider alternatives for heavy Tier 3.

### Progressive Enhancement Philosophy

"Server-first" means forms work without JavaScript, data loads on the server, and navigation is instant. We enhance progressively: SSR for baseline, client hydration for interactivity, service workers for offline. The app should work with JavaScript disabled, then get better with it enabled.

---

## Tech Stack

### Core

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Framework** | SvelteKit | **Required** | Latest stable |
| **Language** | TypeScript | **Required** | Strict mode |
| **Runtime** | Bun/Node | **Recommended** | Bun for dev, Node for deployment |
| **Package Manager** | Bun/pnpm/npm | **Flexible** | Bun recommended, pnpm acceptable, avoid yarn |
| **Bundler** | Vite | **Included** | Via SvelteKit |
| **Linting** | oxlint | **Recommended** | Fast Rust-based |
| **Formatting** | oxc format/Prettier | **Flexible** | oxc preferred |
| **Testing** | Bun test + Playwright | **Required** | Unit + E2E |

### Data & State

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **HTTP Client** | ky | **Recommended** | Retries, timeouts |
| **Server State** | TanStack Query | **Recommended** | For complex client caching |
| **Forms** | Superforms | **Recommended** | Type-safe forms with Zod |
| **Validation** | Zod 4 | **Required** | Runtime + compile-time safety |

### UI & Styling

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Styling** | Tailwind CSS | **Recommended** | Utility-first |
| **UI Primitives** | Melt UI / Bits UI | **Recommended** | Headless, accessible |
| **Icons** | lucide-svelte | **Recommended** | Tree-shakeable |

### Infrastructure

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Deployment** | Vercel/Netlify/Cloudflare | **Flexible** | Edge-compatible |
| **CI/CD** | GitHub Actions | **Required** | |
| **VCS** | Jujutsu (jj) | **Recommended** | |

---

## File Structure

### Tier 1: Content/SEO Site

```
src/
  routes/
    +layout.svelte             # Root layout
    +layout.server.ts          # Root data loading
    +page.svelte               # Home
    blog/
      +page.server.ts          # Load posts
      +page.svelte             # List
      [slug]/
        +page.server.ts        # Load single post
        +page.svelte           # Article
    about/
      +page.svelte
  lib/
    utils.ts                   # cn(), formatters
  app.html
  app.css
```

### Tier 2: Full-Stack Application (Feature-Based)

```
src/
  features/                    # Domain vertical slices
    auth/
      components/
        LoginForm.svelte
        RegisterForm.svelte
        UserMenu.svelte
      api/
        auth.ts                # ky instance calls
        auth.queries.ts        # TanStack Query (if needed)
      schemas/
        login.schema.ts        # Zod
        register.schema.ts
      stores/
        auth.store.ts          # Svelte stores (client-only state)
      types/
        auth.types.ts
      utils/
        token.ts
      index.ts                 # Barrel exports

    donations/
      components/
        DonationList.svelte
        DonationCard.svelte
        CreateForm.svelte
      api/
        donations.ts
      schemas/
        donation.schema.ts

    dashboard/
      components/
        Stats.svelte
        Chart.svelte           # Heavy - lazy load

  routes/
    (app)/                     # Route group - authenticated
      +layout.svelte           # App shell
      +layout.server.ts        # Auth check, load user
      +page.svelte             # /dashboard (default)

      donations/
        +page.server.ts        # Load data
        +page.svelte           # Display
        +page.ts               # Universal load (if needed)
        create/
          +page.server.ts      # Form action
          +page.svelte         # Form UI
        [id]/
          +page.server.ts      # Load single
          +page.svelte
          +error.svelte        # Not found handling

      settings/
        +page.server.ts
        +page.svelte

    (public)/                  # Public routes
      +layout.svelte
      login/
        +page.server.ts        # Login action
        +page.svelte
      register/
        +page.server.ts
        +page.svelte

    api/
      webhook/
        +server.ts             # POST handler

  shared/                      # Generic, domain-agnostic
    components/                # Design system
      Button.svelte
      Input.svelte
      Modal.svelte
      Toast/
        Toast.svelte
        Toaster.svelte
        toast.ts               # Toast state
    actions/                   # Svelte actions
      clickOutside.ts
      tooltip.ts
      portal.ts
    utils/
      format.ts
      cn.ts                    # clsx + tailwind-merge
    types/
      api.types.ts

  lib/                         # SvelteKit lib ($lib)
    api/
      client.ts                # Configured ky
      errors.ts                # Error handling
    server/
      auth.ts                  # Session validation
      db.ts                    # Database (if using)
    query/
      client.ts                # TanStack Query client
      keys.ts                  # Query key factory
    config/
      env.ts                   # Validated env

  hooks.server.ts              # Server hooks (auth, logging)
  app.d.ts                     # App types
  app.html
  app.css                      # Tailwind

static/
tests/
  unit/
  e2e/

svelte.config.js
vite.config.ts
tsconfig.json
justfile
```

---

## Svelte 5 Runes

### State with `$state`

Reactive variables in components:

```svelte
<script lang="ts">
  let count = $state(0);           // Primitive
  let user = $state<User | null>(null);  // Typed

  function increment() {
    count++;  // Automatic reactivity
  }
</script>

<button on:click={increment}>
  Count: {count}
</button>
```

### Derived State with `$derived`

Computed values that auto-update:

```svelte
<script lang="ts">
  let items = $state<Item[]>([]);
  let filter = $state('');

  // Re-computes only when items or filter changes
  const filteredItems = $derived(
    items.filter(item => 
      item.name.toLowerCase().includes(filter.toLowerCase())
    )
  );

  // By for expensive computations
  const total = $derived.by(() => {
    return items.reduce((sum, item) => sum + item.price, 0);
  });
</script>
```

**Rule:** Use `$derived` for values computed from state. Don't use `$effect` to set state.

### Effects with `$effect`

Side effects only (logging, external sync):

```svelte
<script lang="ts">
  let user = $state<User | null>(null);

  $effect(() => {
    if (user) {
      analytics.track('User Loaded', { id: user.id });
    }
  });

  // Cleanup
  $effect(() => {
    const subscription = websocket.subscribe();
    return () => subscription.unsubscribe();
  });
</script>
```

**Warning:** Don't use `$effect` to derive state. That's `$derived`.

### Props with `$props`

```svelte
<script lang="ts">
  interface Props {
    name: string;
    count?: number;
    children: Snippet;
  }

  let { name, count = 0, children }: Props = $props();
</script>

<div>
  <h1>{name}</h1>
  <p>Count: {count}</p>
  {@render children()}
</div>
```

**Bindable props (two-way):**
```svelte
<script lang="ts">
  interface Props {
    value: string;
  }

  let { value = $bindable() }: Props = $props();
</script>

<input bind:value />
```

### Snippets

Reusable template blocks:

```svelte
<script lang="ts">
  interface Props {
    items: Item[];
    header?: Snippet<[string]>;  // With parameter
  }

  let { items, header }: Props = $props();
</script>

{#if header}
  {@render header('Items List')}
{/if}

{#snippet itemRow(item: Item)}
  <div class="item">
    <h3>{item.name}</h3>
    <p>{item.description}</p>
  </div>
{/snippet}

<div class="list">
  {#each items as item}
    {@render itemRow(item)}
  {/each}
</div>
```

---

## Component Standards

### Size Guidelines

- **Target:** <120 lines for UI components, <180 for page components
- **Extract when:** Logic is reused, file exceeds limits, or concerns separate
- **Exception:** Complex forms with validation may reach 250 lines

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Components | PascalCase | `LoginForm.svelte`, `DonationCard.svelte` |
| Routes | PascalCase | `+page.svelte`, `+layout.svelte` |
| Server files | camelCase | `+page.server.ts`, `+layout.server.ts` |
| Stores | camelCase with store | `auth.store.ts` |
| Schemas | PascalCase with Schema | `LoginSchema.ts` |
| Actions | camelCase | `clickOutside.ts` |
| Types | PascalCase | `User.ts`, `ApiResponse.ts` |

### Script Organization

Order in `.svelte` files:
1. `<script lang="ts">` - Imports, props, state
2. `$derived` calculations
3. `$effect` declarations
4. Functions/handlers
5. Markup
6. `<style>` (rarely needed with Tailwind)

---

## State Management Strategy

### The Hierarchy

```
1. Local $state              → Component-level
        ↓
2. Derived $derived          → Computed from state
        ↓
3. URL state                 → $page.url.searchParams
        ↓
4. Server data               → +page.server.ts load
        ↓
5. Global stores             → Svelte stores (rare)
```

### When to Use Stores (Tier 2+)

Use Svelte stores sparingly:
- Cross-component communication outside routes
- Theme/preferences
- Feature flags
- Shopping cart (cross-page)

**Store pattern:**
```typescript
// features/cart/cart.store.ts
import { writable, derived } from 'svelte/store';
import type { CartItem } from './types';

function createCartStore() {
  const { subscribe, set, update } = writable<CartItem[]>([]);

  return {
    subscribe,
    addItem: (item: CartItem) => update(items => [...items, item]),
    removeItem: (id: string) => update(items => items.filter(i => i.id !== id)),
    clear: () => set([]),
    total: derived({ subscribe }, $items => 
      $items.reduce((sum, item) => sum + item.price * item.quantity, 0)
    )
  };
}

export const cart = createCartStore();
```

---

## Data Fetching

### Server Load Functions

```typescript
// routes/donations/+page.server.ts
import type { PageServerLoad } from './$types';
import { error } from '@sveltejs/kit';

export const load: PageServerLoad = async ({ locals, url }) => {
  const page = parseInt(url.searchParams.get('page') ?? '1');
  const limit = 20;

  const [donations, count] = await Promise.all([
    locals.db.donations.findMany({
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' }
    }),
    locals.db.donations.count()
  ]);

  return {
    donations,
    pagination: {
      page,
      totalPages: Math.ceil(count / limit),
      hasNext: page * limit < count
    }
  };
};
```

### Form Actions

```typescript
// routes/donations/create/+page.server.ts
import type { Actions } from './$types';
import { fail, redirect } from '@sveltejs/kit';
import { superValidate } from 'sveltekit-superforms';
import { zod } from 'sveltekit-superforms/adapters';
import { DonationSchema } from '$features/donations/schemas';

export const load = async () => {
  const form = await superValidate(zod(DonationSchema));
  return { form };
};

export const actions: Actions = {
  default: async ({ request, locals }) => {
    const form = await superValidate(request, zod(DonationSchema));

    if (!form.valid) {
      return fail(400, { form });
    }

    try {
      const donation = await locals.db.donations.create({
        data: form.data
      });

      throw redirect(303, `/donations/${donation.id}`);
    } catch (e) {
      return fail(500, { form, error: 'Failed to create' });
    }
  }
};
```

**Progressive enhancement:**
```svelte
<!-- +page.svelte -->
<script lang="ts">
  import { superForm } from 'sveltekit-superforms';

  let { data } = $props();

  const { form, errors, enhance, submitting } = superForm(data.form, {
    validators: zodClient(DonationSchema),
    onError: ({ result }) => toast.error(result.error.message)
  });
</script>

<form method="POST" use:enhance>
  <input 
    name="amount" 
    type="number" 
    bind:value={$form.amount}
    aria-invalid={$errors.amount ? 'true' : undefined}
  />
  {#if $errors.amount}
    <span class="error">{$errors.amount}</span>
  {/if}

  <button type="submit" disabled={$submitting}>
    {$submitting ? 'Creating...' : 'Create Donation'}
  </button>
</form>
```

---

## HTTP Client (ky)

```typescript
// lib/api/client.ts
import ky from 'ky';
import { browser } from '$app/environment';

export const api = ky.create({
  prefixUrl: browser ? '/api' : import.meta.env.VITE_API_URL,
  timeout: 10000,  // 10s timeout
  retry: {
    limit: 2,
    methods: ['get', 'post'],
    statusCodes: [408, 413, 429, 500, 502, 503, 504]
  },
  hooks: {
    beforeRequest: [
      async (request) => {
        if (browser) {
          const token = getAuthToken();
          if (token) {
            request.headers.set('Authorization', `Bearer ${token}`);
          }
        }
      }
    ],
    afterResponse: [
      async (request, options, response) => {
        if (response.status === 401) {
          if (browser) {
            window.location.href = '/login';
          }
        }
        return response;
      }
    ]
  }
});
```

---

## Security

### CSRF Protection

SvelteKit form actions include CSRF protection by default. For custom API endpoints:

```typescript
// hooks.server.ts
export const handle: Handle = async ({ event, resolve }) => {
  // CSRF check for non-GET requests
  if (event.request.method !== 'GET') {
    const origin = event.request.headers.get('origin');
    if (origin !== event.url.origin) {
      throw error(403, 'Invalid origin');
    }
  }

  return resolve(event);
};
```

### XSS Prevention

Svelte auto-escapes by default. Never use `{@html}` with user content:

```svelte
<!-- BAD -->
{@html userInput}

<!-- GOOD -->
{userInput}

<!-- If must render HTML (Markdown) -->
{@html DOMPurify.sanitize(markdownHtml)}
```

---

## Justfile

```justfile
set dotenv-load

dev:
    bun run dev

build:
    bun run build

preview:
    bun run preview

install:
    bun install

update:
    bun update

lint:
    bunx oxlint .

typecheck:
    bunx svelte-check --tsconfig ./tsconfig.json

format:
    bunx oxc format --write .

format-check:
    bunx oxc format --check .

test:
    bun test

test-e2e:
    bunx playwright test

check: lint typecheck test
    @echo "All checks passed!"

clean:
    rm -rf .svelte-kit/
    rm -rf build/
    rm -rf node_modules/.cache
```

---

## Code Quality Checklist

Before committing:

- [ ] Components <180 lines (or documented)
- [ ] Svelte 5 runes used ($state, not let; $derived, not $:)
- [ ] Form validation with Zod (Superforms)
- [ ] Progressive enhancement (forms work without JS)
- [ ] Loading states (streaming with `{#await}`)
- [ ] Error boundaries (`+error.svelte`)
- [ ] No `{@html}` with user content
- [ ] TypeScript strict mode passes
- [ ] svelte-check passes
- [ ] oxlint passes
- [ ] Feature code in features/, not scattered

---

## Prohibited Patterns

- Never use `npm`, `yarn`, or `pnpm` — use Bun (or pnpm if required)
- Never use ESLint or Prettier — use oxc
- Never use `$:` reactive statements — use Svelte 5 runes
- Never use `{@html}` with user content (XSS)
- Never store tokens in localStorage — use httpOnly cookies + server loads
- Never put business logic in `+page.svelte` — use `+page.server.ts`
- Never ignore form validation errors
- Never skip progressive enhancement without reason
- Avoid prop drilling — use snippets or stores
- Avoid client-side state when server state suffices
