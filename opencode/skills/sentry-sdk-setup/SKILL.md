---
name: sentry-sdk-setup
description: >
  Set up Sentry for this user's common stack: Elixir/Phoenix, browser
  JavaScript/Astro/Svelte frontends, Cloudflare Workers/Pages, and Go. Use when
  asked to add Sentry, install an SDK, or set up error monitoring in a project.
license: Apache-2.0
role: router
---

# Sentry SDK Setup

Set up Sentry error monitoring, tracing, and session replay for this user's common stack. This page helps you find the right installed SDK skill for the project.

## How to Fetch Skills

Use `curl` to download skills — they are 10–20 KB files that fetch tools often summarize, losing critical details.

    curl -sL https://skills.sentry.dev/sentry-browser-sdk/SKILL.md

Append the path from the `Path` column in the table below to `https://skills.sentry.dev/`. Do not guess or shorten URLs.

## Start Here — Read This Before Doing Anything

**Do not skip this section.** Do not assume which SDK the user needs based on their project files. Do not start installing packages or creating config files until you have confirmed the user's intent.

1. **Detect the platform** from project files (`package.json`, `go.mod`, `wrangler.jsonc`, `wrangler.toml`, etc.).
2. **Tell the user what you found** and which SDK you recommend.
3. **Wait for confirmation** before fetching the skill and proceeding.

Each SDK skill contains its own detection logic, prerequisites, and step-by-step configuration. Trust the skill — read it carefully and follow it. Do not improvise or take shortcuts.

---

## SDK Skills

| Platform | Skill | Path |
|---|---|---|
| Svelte and SvelteKit | [`sentry-svelte-sdk`](../sentry-svelte-sdk/SKILL.md) | `sentry-svelte-sdk/SKILL.md` |
| browser JavaScript | [`sentry-browser-sdk`](../sentry-browser-sdk/SKILL.md) | `sentry-browser-sdk/SKILL.md` |
| Cloudflare Workers and Pages | [`sentry-cloudflare-sdk`](../sentry-cloudflare-sdk/SKILL.md) | `sentry-cloudflare-sdk/SKILL.md` |
| Elixir, Phoenix, Plug, LiveView, Oban | [`sentry-elixir-sdk`](../sentry-elixir-sdk/SKILL.md) | `sentry-elixir-sdk/SKILL.md` |
| Go | [`sentry-go-sdk`](../sentry-go-sdk/SKILL.md) | `sentry-go-sdk/SKILL.md` |

### Platform Detection Priority

When multiple SDKs could match, prefer the more specific one:

- **Cloudflare** (`wrangler.toml` or `wrangler.jsonc`) → `sentry-cloudflare-sdk`
- **Elixir / Phoenix** (`mix.exs`) → `sentry-elixir-sdk`
- **Go** (`go.mod`) → `sentry-go-sdk`
- **Svelte / SvelteKit** (`svelte` or `@sveltejs/kit` in `package.json`) → `sentry-svelte-sdk`
- **Browser JS / static front-end / Astro** (`astro` in `package.json`, static site, vanilla browser JS) → `sentry-browser-sdk`
- **No match** → direct user to [Sentry Docs](https://docs.sentry.io/platforms/)

## Quick Lookup

Match your project to a skill by keywords. Append the path to `https://skills.sentry.dev/` to fetch.

| Keywords | Path |
|---|---|
| browser, vanilla js, javascript, astro, cdn, static site | `sentry-browser-sdk/SKILL.md` |
| svelte, sveltekit, @sentry/svelte, @sentry/sveltekit | `sentry-svelte-sdk/SKILL.md` |
| cloudflare, cloudflare workers, cloudflare pages, wrangler, durable objects, d1 | `sentry-cloudflare-sdk/SKILL.md` |
| elixir, phoenix, plug, liveview, oban, quantum, mix.exs | `sentry-elixir-sdk/SKILL.md` |
| go, golang, gin, echo, fiber | `sentry-go-sdk/SKILL.md` |

---

## Finding the DSN

If the user doesn't have their DSN, guide them to find it:

1. Open the Sentry project settings page: `https://sentry.io/settings/projects/`
2. Select the project
3. Click **"Client Keys (DSN)"** in the left sidebar
4. Copy the DSN

You can help the user open the page directly:
```bash
open https://sentry.io/settings/projects/        # macOS
xdg-open https://sentry.io/settings/projects/    # Linux
start https://sentry.io/settings/projects/        # Windows
```

> **Note:** The DSN is public and safe to include in source code. It is not a secret — it only identifies where to send events.

---

Looking for workflows or feature configuration instead? Use [sentry-workflow](../sentry-workflow/SKILL.md) or [sentry-feature-setup](../sentry-feature-setup/SKILL.md).
