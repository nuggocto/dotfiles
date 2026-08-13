# Gleam ecosystem guidance

Read only the sections for packages present in `gleam.toml` or `manifest.toml`,
or packages being evaluated or added by the task. Resolve exact installed or
candidate versions first, then verify every API, limitation, and advisory against
versioned HexDocs and package changelogs. For new projects, use the latest stable
compatible package releases. Preserve locked versions during unrelated work. Do
not treat versions named in old examples or advisories as current minimums.

## Mist and Wisp

- Mist is an Erlang-target HTTP server. Wisp adds handler, body, cookie, form,
  security-helper, simulation, and middleware conventions. Add Wisp only when
  those features reduce total complexity.
- Prefer supervised server ownership in OTP applications. Bind only to the
  required interface and define graceful shutdown.
- Verify the selected Mist version's HTTP protocol, streaming, file response,
  WebSocket, SSE, and chunked-response support before relying on it.
- Request bodies are lazy. Enforce route-specific and cumulative limits before
  reading JSON, uploads, streams, or chunks.
- Authenticate before WebSocket or SSE upgrades. Bound connections, messages,
  subscriptions, and fan-out, and validate browser origins.
- Trust forwarding headers only from reviewed proxies. Resolve file paths from
  an allowlisted root with traversal and symlink-escape protection supported by
  the selected adapter and operating system.
- Recheck Wisp and Mist advisories before selecting or upgrading versions.
- Uploaded filenames are untrusted. Verify the selected adapter's temporary-file
  lifecycle and move validated files before handler cleanup if they must persist.
- Signed cookies provide integrity, not confidentiality. Use a stable key of the
  documented size across replicas, apply CSRF protection to cookie-authenticated
  state changes, and keep safe HTTP methods free of requested business-state
  mutation. Logging and cache population remain valid incidental effects.
- Escape user-controlled HTML or use typed rendering. Apply a complete
  application-specific security-header policy; nonce CSP middleware is useful
  but does not supply every required header or policy.
- Treat crash-to-500 middleware as an HTTP boundary, not observability or
  recovery. Log crashes with useful context, monitor recurrence, and fix their
  cause without exposing internal details to clients.

## Pog and Squirrel

- Pog owns the runtime PostgreSQL pool. Add its supervised child before
  consumers and pass a connection or typed application dependency directly.
- Parameterize values. Map identifiers and sort expressions through a closed
  allowlist.
- Size pools across all replicas against database capacity. Define checkout
  timeouts, queue shedding, readiness, transaction scope, and shutdown.
- Require verified TLS over untrusted networks. Disabled TLS is acceptable only
  inside a reviewed, separately secured transport boundary.
- Keep transactions short and avoid external calls while holding a connection
  and locks. A decoder failure occurs after PostgreSQL has executed the
  statement and does not prove an out-of-transaction write rolled back.
- Do not map exact decimal domains to `Float` without accepting precision loss.
- Squirrel is a development-time SQL generator, not an ORM, migration system, or
  runtime pool. Keep it in development dependencies, commit reviewed generated
  output, and run its drift check in CI.
- Generate against a migrated disposable or dedicated database with least
  privilege. Verify current PostgreSQL requirements, TLS support, type mapping,
  and nullable-parameter inference in the installed Squirrel version.
- Load the matching database skill before schema or performance-sensitive SQL
  changes.

## Lustre

- Choose SPA, Web Component, HTML/SSR, or server-component mode deliberately.
  Match examples to the installed major version.
- Keep initialization, update, and view pure where possible. Put I/O in effects
  and feed results back as messages.
- Prefer ordinary view functions. Use stateful components only when an isolated
  update loop and lifecycle help.
- Use keyed elements for reordered collections. Add memoization only after
  measuring.
- Prefer typed elements and text nodes. Treat unsafe raw HTML and hydration data
  as trust boundaries, escape untrusted content at any raw-HTML boundary, and
  include no secrets in client state.
- Treat executable downloads by development tools as supply-chain inputs. Pin or
  provide reviewed local binaries when policy requires it.
- Verify whether the selected production build fingerprints assets. If it does
  not, add content hashing or versioning before immutable cache headers.
- Authenticate and authorize server-component connections, verify CSRF and
  browser origin server-side, bound connection and message growth, and remove
  subscriptions on disconnect.
- Use simulation for pure model and message behavior. Use browser tests for DOM,
  hydration, accessibility, focus, effects, Web Components, and reconnection.

## Sources

- Mist: `https://hexdocs.pm/mist/`
- Wisp: `https://hexdocs.pm/wisp/`
- Pog: `https://hexdocs.pm/pog/`
- Squirrel: `https://hexdocs.pm/squirrel/`
- Lustre: `https://hexdocs.pm/lustre/`
- Hex advisories: `https://hex.pm/docs/security`
