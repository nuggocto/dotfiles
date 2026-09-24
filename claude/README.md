# Claude Code

## Install

Install Claude Code and `jq`, then run from the dotfiles checkout:

```sh
./install.sh --claude-only
```

The full `./install.sh` also runs this setup. Close Claude Code before reapplying
the config so it cannot overwrite the settings during installation.

- `settings.json` is linked to `~/.claude/settings.json`.
- `mcp.json` is merged into the user-scoped `mcpServers` in `~/.claude.json`.
  Re-running updates the listed servers and preserves unrelated servers and all
  other state. Removing an entry here does not remove a previously installed
  server; use `claude mcp remove --scope user <name>` for that.
- Existing files are backed up under
  `${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-backup-<timestamp>/claude/`.

The settings retain the Opus 1M model, effort preferences, theme, attribution
preferences, and 20 enabled plugins. Stripe, data-engineering, Pinecone, and PostHog are
absent from the enabled plugin list.

On a fresh machine, install the configured plugins after installing the settings
(run this block in Bash):

```bash
claude plugin marketplace add anthropics/claude-plugins-official
while IFS= read -r plugin; do
  claude plugin install --scope user "$plugin" || break
done < <(jq -r '.enabledPlugins | to_entries[] | select(.value == true) | .key' claude/settings.json)
```

On an existing machine, if the removed plugins are still installed, uninstall
them once:

```sh
claude plugin uninstall --scope user stripe@claude-plugins-official
claude plugin uninstall --scope user data-engineering@claude-plugins-official
claude plugin uninstall --scope user pinecone@claude-plugins-official
claude plugin uninstall --scope user posthog@claude-plugins-official
```

## Connect and authenticate

These HTTP servers use browser-based OAuth; no API keys belong in the JSON.
The Cloudflare documentation server is public and needs no login.

Run each command and complete its browser sign-in before proceeding:

```sh
claude mcp login planetscale
claude mcp login sentry
claude mcp login resend
claude mcp login cloudflare-api
claude mcp login cloudflare-bindings
claude mcp login cloudflare-builds
claude mcp login cloudflare-observability
```

Choose the organizations/accounts and permissions you want at each provider's
authorization screen. Use `--no-browser` with `claude mcp login` over SSH.
On older Claude Code versions without `mcp login`, open `claude`, run `/mcp`,
select the server, and choose its authentication action.

Check the connections:

```sh
claude mcp list
```

Restart Claude Code, then use `/mcp` to inspect or reconnect a server. A server
disabled for the current project must also be re-enabled there. To change an
OAuth grant, run `claude mcp logout <name>` followed by `claude mcp login <name>`.

| Server | Endpoint |
| --- | --- |
| `planetscale` | `https://mcp.pscale.dev/mcp/planetscale` |
| `sentry` | `https://mcp.sentry.dev/mcp?utm_source=plugin` |
| `resend` | `https://mcp.resend.com/mcp` |
| `cloudflare-api` | `https://mcp.cloudflare.com/mcp` |
| `cloudflare-docs` | `https://docs.mcp.cloudflare.com/mcp` |
| `cloudflare-bindings` | `https://bindings.mcp.cloudflare.com/mcp` |
| `cloudflare-builds` | `https://builds.mcp.cloudflare.com/mcp` |
| `cloudflare-observability` | `https://observability.mcp.cloudflare.com/mcp` |

The PlanetScale, Sentry, Cloudflare, and Resend plugins also bundle these servers.
Claude Code deduplicates plugin servers by endpoint, preferring these user-scoped
definitions. Sentry's query string matches its plugin endpoint for that reason.
The plugins remain enabled for their skills and other components.

## Local state

Only `settings.json`, `mcp.json`, and this README are tracked in this directory.
`~/.claude.json`, credentials, OAuth tokens, local permission approvals, history,
plugin caches, and synced skills stay on the machine. The installer links only
the settings file, never the whole `~/.claude` directory or `~/.claude.json`.

Settings edits through Claude may appear in the linked file. Keep credentials
out of `settings.json`; use the provider's OAuth flow for these MCP servers.
