---
name: astro-frontend
description: Astro content-driven websites with Islands Architecture, zero JS by default, Content Collections, Astro Actions, and selective hydration. Use for blogs, marketing sites, docs, and e-commerce storefronts.
---

# AGENTS.md - Astro Frontend Project Guidelines

## Project Philosophy

Astro is for **content-driven websites** — blogs, marketing sites, documentation, e-commerce storefronts. We follow the **Islands Architecture**: ship zero JavaScript by default, hydrate only interactive components. Prefer static generation unless dynamic content is explicitly required.

### Project Tiers

Not every site needs the same architecture. Choose your tier:

| Tier | Description | Architecture |
|------|-------------|--------------|
| **Tier 1** | Static marketing sites, blogs, docs | Full SSG, zero or minimal islands, focus on build-time optimization |
| **Tier 2** | E-commerce, authenticated content, dashboards | Hybrid (static + SSR), selective hydration, API endpoints, actions |
| **Tier 3** | Real-time apps, collaborative tools | Heavy islands with shared state, WebSockets, edge functions, consider migrating to SvelteKit/SolidStart |

> **Rule:** Start with Tier 1, move to Tier 2 when you need user sessions/carts, only use Tier 3 if Astro can handle it comfortably otherwise migrate to a full SPA framework.

### Islands Philosophy

"Zero JS by default" means we ship HTML and CSS, not an empty `<div id="root">`. We hydrate only when necessary. A blog post needs 0KB of JS; a shopping cart drawer needs 15KB. Choose `client:visible` over `client:load`, `client:idle` over `client:visible`.

---

## Tech Stack

### Core

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Framework** | Astro 6 | **Required** | Latest stable |
| **Language** | TypeScript | **Required** | Strict mode enabled |
| **Runtime** | Bun | **Recommended** | Fastest for Astro, DX superior |
| **Package Manager** | Bun/npm/pnpm | **Flexible** | Bun recommended, pnpm acceptable, avoid yarn |
| **Bundler** | Vite | **Included** | Via Astro |
| **Linting** | oxlint | **Recommended** | Fast Rust-based linter |
| **Formatting** | oxc format / Prettier | **Flexible** | oxc preferred but Prettier acceptable |
| **Testing** | Bun test + Playwright | **Required** | Unit + E2E |

### Styling & UI

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **CSS Framework** | Tailwind CSS | **Recommended** | Utility-first, purge unused |
| **UI Islands** | Svelte 5 or Solid | **Recommended** | Svelte for most, Solid for heavy interactivity |
| **Icons** | lucide-astro or tabler | **Recommended** | Tree-shakeable |

### Content & Data

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Content** | Content Collections | **Required** | Zod schemas required |
| **Validation** | Zod 4 | **Required** | Content schemas + form validation |
| **API Client** | ky | **Recommended** | Islands only, fetch acceptable |
| **Forms** | Astro Actions | **Recommended** | Server-side validation |

### Infrastructure

| Category | Tool | Status | Notes |
|----------|------|--------|-------|
| **Deployment** | Cloudflare Pages | **Recommended** | Edge SSR, first-class Astro support |
| **CDN** | Cloudflare | **Recommended** | Built-in with Pages |
| **CI/CD** | GitHub Actions | **Required** | Build, test, deploy |
| **VCS** | Jujutsu (jj) | **Recommended** | Better UX, Git-compatible |

---

## File Structure

### Tier 1: Content Site (Blog/Docs/Marketing)

```
src/
  content/
    blog/
      first-post.md
      second-post.mdx
    config.ts              # Content collections config

  layouts/
    BaseLayout.astro
    BlogLayout.astro

  components/
    ui/                    # Reusable UI (Button, Card)
    content/               # Content-specific (Prose, CodeBlock)

  pages/
    index.astro
    blog/
      index.astro          # List page
      [slug].astro         # Post page

  lib/
    utils.ts               # cn(), formatDate()

  styles/
    global.css
```

### Tier 2: Dynamic Site (E-commerce/SaaS)

```
src/
  content/
    products/
      config.ts

  features/                # Organize by feature, not layer
    cart/
      components/
        CartDrawer.svelte  # Island (client:visible)
        AddToCart.svelte   # Island
      actions/
        add-to-cart.ts     # Astro Action
      schemas/
        cart.schema.ts     # Zod schemas
      stores/
        cart.svelte.ts     # Svelte 5 runes store
      index.ts             # Public API

    auth/
      components/
        LoginForm.svelte
        UserMenu.svelte    # client:idle
      actions/
        login.ts
        logout.ts

    newsletter/
      components/
        NewsletterForm.svelte
      actions/
        subscribe.ts

  components/
    ui/                    # shadcn/ui style components
      Button.astro
      Input.astro
      Dialog.svelte        # Islands in ui/
    layout/
      Header.astro
      Footer.astro
    seo/
      SEO.astro
      SchemaMarkup.astro

  layouts/
    BaseLayout.astro
    DashboardLayout.astro  # Auth-required layout

  pages/
    index.astro
    shop/
      index.astro          # Static generation
      [slug].astro         # getStaticPaths or SSR
    api/                   # API endpoints
      search.ts
    dashboard/
      index.astro          # prerender: false (SSR)

  lib/
    api/
      client.ts            # ky instance for islands
      server.ts            # Server-side fetch wrapper
    utils/
      format.ts
      cn.ts                # tailwind-merge
    validation/
      schemas.ts           # Shared Zod schemas

  middleware/
    index.ts               # Astro middleware (auth)

  actions/
    index.ts               # Central action exports

tests/
  unit/                    # Bun test
  e2e/                     # Playwright

public/
astro.config.mjs
content.config.ts
tailwind.config.ts
tsconfig.json
justfile
```

---

## Islands Architecture

### Hydration Strategy

| Directive | Cost | Use For |
|-----------|------|---------|
| `client:load` | 100% | Critical UI above fold (search bar, nav) |
| `client:idle` | 80% | Below-fold interactivity (related products) |
| `client:visible` | 40% | Scroll-dependent (comment section, footer) |
| `client:media` | 20% | Mobile-specific (hamburger menu on small screens) |
| `client:only` | 0% SSR | Browser-only APIs (maps, charts) |

**Default Rule:** Start with no directive (static HTML), escalate only when interactive.

### Island Best Practices

- **Keep islands small:** <50KB JS per island
- **Share state via Nano Stores** or Svelte 5 context, not props drilling
- **Lazy load heavy libs:** `import('chart.js')` on mount
- **Use server islands** (Astro 6): Ship component HTML from server, hydrate selectively

```astro
---
// Server Island (Astro 6): HTML generated on server, ships to client
// No JS unless client directive added
---
<div>
  <HeavyDataTable data={complexQuery()} />
</div>
```

---

## Content Collections

### Configuration (content.config.ts)

```typescript
import { defineCollection, z } from 'astro:content';

const blog = defineCollection({
  type: 'content_layer',
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string().max(100),
    description: z.string().max(200),
    pubDate: z.coerce.date(),
    updatedDate: z.coerce.date().optional(),
    heroImage: z.string().optional(),
    tags: z.array(z.string()).default([]),
    draft: z.boolean().default(false),
  }),
});

// Type-safe data (YAML/JSON)
const authors = defineCollection({
  type: 'data',
  schema: z.object({
    name: z.string(),
    email: z.string().email(),
    twitter: z.string().optional(),
  }),
});

export const collections = { blog, authors };
```

### Live Collections (Astro 6)

For dynamic content in static sites:

```typescript
import { defineLiveCollection } from 'astro:content';

const comments = defineLiveCollection({
  loader: async () => {
    // Fetched at request time, not build time
    const res = await fetch('https://api.comments.com');
    return res.json();
  },
  schema: commentSchema,
});
```

---

## Astro Actions

### Pattern: Validated Server Functions

Centralize in `src/actions/index.ts`:

```typescript
import { defineAction } from 'astro:actions';
import { z } from 'zod';

export const server = {
  newsletter: defineAction({
    accept: 'form',
    input: z.object({
      email: z.string().email(),
      source: z.string().default('footer'),
    }),
    handler: async ({ email, source }) => {
      // Rate limiting (Cloudflare KV or Durable Object)
      const key = `subscribe:${email}`;
      const recent = await env.RATE_LIMIT.get(key);
      if (recent) {
        throw new ActionError({
          code: 'TOO_MANY_REQUESTS',
          message: 'Please wait before subscribing again',
        });
      }

      // Business logic
      await subscribeEmail(email, source);
      await env.RATE_LIMIT.put(key, '1', { expirationTtl: 60 });

      return { success: true };
    },
  }),

  cart: {
    add: defineAction({
      accept: 'json',
      input: z.object({
        productId: z.string().uuid(),
        quantity: z.number().min(1).max(10),
      }),
      handler: async (input, context) => {
        // Session validation
        const session = await getSession(context);
        if (!session) {
          throw new ActionError({
            code: 'UNAUTHORIZED',
            message: 'Please log in',
          });
        }

        return addToCart(session.userId, input);
      },
    }),
  },
};
```

### Client Usage

```svelte
<!-- features/newsletter/NewsletterForm.svelte -->
<script>
  import { actions, isActionError } from 'astro:actions';

  let status = 'idle';
  let message = '';

  async function handleSubmit(e) {
    const formData = new FormData(e.target);
    const { data, error } = await actions.newsletter(formData);

    if (isActionError(error)) {
      message = error.message;
      status = 'error';
    } else {
      status = 'success';
    }
  }
</script>

<form on:submit|preventDefault={handleSubmit}>
  <input type="email" name="email" required />
  <button type="submit" disabled={status === 'submitting'}>
    Subscribe
  </button>
  {#if message}
    <p class="error">{message}</p>
  {/if}
</form>
```

### Rate Limiting in Actions

Always rate limit mutation actions:

```typescript
handler: async (input, context) => {
  const ip = context.request.headers.get('cf-connecting-ip');
  const key = `rate_limit:${ip}:contact`;

  const current = await env.RATE_LIMIT.get(key);
  if (current && parseInt(current) > 5) {
    throw new ActionError({
      code: 'TOO_MANY_REQUESTS',
      message: 'Rate limit exceeded',
    });
  }

  await env.RATE_LIMIT.put(key, 
    String((parseInt(current || '0') + 1)), 
    { expirationTtl: 300 }
  );

  // ... process action
}
```

---

## Hydration Boundaries

### Component Size Guidelines

| Type | Max Lines | Strategy |
|------|-----------|----------|
| Astro (.astro) | 150 | Static HTML, data fetching |
| Island (.svelte) | 100 | Reactive UI, client-side state |
| UI Component | 50 | Pure presentational |

### Extraction Strategy

When an Astro component grows:

1. **Extract data fetching** -> `lib/data/{feature}.ts`
2. **Extract markup** -> Child components in `features/{name}/components/`
3. **Extract client state** -> Island with reactive store

---

## Security

### Content Security Policy (Astro 6)

Configure strict CSP in `astro.config.mjs`:

```javascript
export default defineConfig({
  security: {
    checkOrigin: true,  // CSRF protection
  },
  // CSP headers via middleware or Cloudflare
});
```

Recommended CSP (Cloudflare Pages headers):

```toml
# public/_headers
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob: https:; font-src 'self'; connect-src 'self' https://api.yoursite.com; frame-ancestors 'none';
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
```

### Environment Variables

```typescript
// astro.config.mjs
import { defineConfig, envField } from 'astro/config';

export default defineConfig({
  env: {
    schema: {
      PUBLIC_STRIPE_KEY: envField.string({
        context: 'client',
        access: 'public',
      }),
      PRIVATE_API_SECRET: envField.string({
        context: 'server',
        access: 'secret',
      }),
    },
  },
});
```

**Access patterns:**
- `import.meta.env.PUBLIC_*` — Client-safe
- `import.meta.env.PRIVATE_*` — Server-only
- Actions get validated types automatically

---

## Performance Optimization

### Build Checklist

- [ ] Zero JS on content pages (blog posts, marketing)
- [ ] `<Image />` used for all images (WebP/AVIF auto-conversion)
- [ ] Fonts preloaded with `font-display: swap`
- [ ] Client islands <50KB each
- [ ] Dynamic imports for heavy libraries (`import('chart.js')`)
- [ ] `getStaticPaths()` for all dynamic routes (when possible)
- [ ] Cloudflare caching headers set

### Font Optimization (Astro 6)

```astro
---
import { Font } from 'astro:assets';
---
<link rel="preload" href="/fonts/inter.woff2" as="font" type="font/woff2" crossorigin />
<Font cssVariable="--font-inter" preload />
```

### Image Optimization

```astro
---
import { Image } from 'astro:assets';
import heroImage from '~/assets/hero.jpg';
---

<!-- Auto-optimized, responsive, lazy-loaded -->
<Image 
  src={heroImage} 
  alt="Hero" 
  widths={[240, 540, 720, 1200]}
  sizes="(max-width: 360px) 240px, (max-width: 720px) 540px, (max-width: 1600px) 720px, 1200px"
/>

<!-- Remote image (configured in astro.config) -->
<Image 
  src="https://cdn.example.com/photo.jpg" 
  alt="Photo" 
  width={800} 
  height={600}
/>
```

---

## Deployment

### Cloudflare Pages (Recommended)

**Static Sites:**
- Connect GitHub repo
- Build command: `bun run build`
- Output directory: `dist`

**SSR/Hybrid:**
```bash
bunx astro add cloudflare
```

```javascript
// astro.config.mjs
import { defineConfig } from 'astro/config';
import cloudflare from '@astrojs/cloudflare';

export default defineConfig({
  output: 'hybrid',
  adapter: cloudflare({
    imageService: 'cloudflare',
    platformProxy: {
      enabled: true,
    },
  }),
});
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
    bun run build && bunx @astrojs/check-bundle --size

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
    bunx astro check

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

# Content
sync:
    bunx astro sync

check-content:
    bunx astro check

# Deployment
preview-prod:
    bun run build && bun run preview

dry-run-deploy:
    bun run build
    echo "Build successful - ready to deploy"

# Utilities
clean:
    rm -rf dist/
    rm -rf .astro/
    rm -rf node_modules/.cache

# Full CI simulation
ci: lint test build
    @echo "All checks passed!"
```

---

## Code Quality Checklist

Before committing:

- [ ] Content schemas validate frontmatter (Zod)
- [ ] Islands use appropriate hydration (`client:visible` preferred)
- [ ] No JS shipping on static content pages
- [ ] Images use `<Image />` with proper sizing
- [ ] Actions have rate limiting
- [ ] TypeScript strict mode passes (`astro check`)
- [ ] oxlint passes
- [ ] No `console.log` in production code
- [ ] Environment variables use `envField` schema
- [ ] CSP headers configured (Tier 2+)
- [ ] E2E tests cover critical flows (checkout, auth)

---

## Prohibited Patterns

- **Never hydrate static content** (blog posts, about pages)
- **Never skip Zod validation** for content or forms
- **Never store secrets in `PUBLIC_`** env vars
- **Never use `client:load`** without measuring impact
- **Never skip alt text** on images
- **Never use `Astro.glob()`** (removed in v6, use `getCollection`)
- **Never ship 500KB of JS** for a contact form
- **Avoid SSR** when static generation works (cost + complexity)

---

## Migration Guide (Upgrading)

### Astro 5 -> 6

- **Check:** Update to Node 22+
- **Check:** Migrate Zod 3 -> 4 schemas
- **Check:** Move `src/content/config.ts` -> `content.config.ts` (project root)
- **Check:** Replace `Astro.glob()` with content collections
- **Check:** Update Cloudflare adapter to use `cloudflare:workers` import
- **Enable:** CSP in config
- **Enable:** View Transitions new import path

---

## Resources

- **Astro Docs:** https://docs.astro.build
- **Content Collections:** https://docs.astro.build/en/guides/content-collections/
- **Actions:** https://docs.astro.build/en/guides/actions/
- **View Transitions:** https://docs.astro.build/en/guides/view-transitions/
- **Cloudflare Adapter:** https://docs.astro.build/en/guides/integrations-guide/cloudflare/
- **Starlight (Docs):** https://starlight.astro.build/
