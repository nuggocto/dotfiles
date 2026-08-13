# Go toolchain upgrades

Read this reference when changing the Go toolchain, `go` or `toolchain`
directives, or code whose behavior changed across Go releases.

## Version policy

- Preserve the repository's declared support floor unless the task includes an
  upgrade.
- For new projects, select the latest stable Go release.
- For existing supported lines, use the latest available patch release. Check
  `https://go.dev/doc/devel/release` at execution time rather than copying a
  patch number from this file.
- Read the release notes for every skipped minor release and inspect security
  fixes for the selected patch.

## Upgrade review

- Treat the `go` directive as more than a toolchain floor. It selects the
  language version for packages in the module and changes `go` command and
  module behavior. Since Go 1.21 it is also a mandatory minimum toolchain
  requirement and must be at least the `go` version required by dependencies.
- Review effective GODEBUG defaults as part of a `go` directive or toolchain
  change. Toolchain defaults are amended to match the main module or workspace
  `go` version, then overridden by `godebug` or `//go:debug` directives. Use
  `go list -f '{{.DefaultGODEBUG}}'` on affected main packages to inspect the
  compiled defaults when compatibility behavior matters.
- Confirm `GOTOOLCHAIN`, CI images, local tooling, release builders, and
  production use the intended version.
- Run the existing test, race, static-analysis, benchmark, cgo, platform, and
  build-tag matrix affected by the upgrade.
- Regression-test public `net/http`, URL, proxy, cookie, TLS, crypto, and parser
  behavior when release notes mention those packages.
- Inspect the selected release's `go fix` support. Review its diff before
  applying modernizations, and keep optional cleanup out of unrelated work.
- Re-run representative allocation, GC, latency, memory, cgo, and profile checks
  when the toolchain can affect a measured hot path.

## Testing additions

- Use `t.Log` or failure messages for normal diagnostics.
- If the selected Go version provides test artifact directories, use them for
  files worth preserving, such as traces, profiles, images, or generated
  fixtures. Do not turn ordinary log lines into files.
- Derive benchmark APIs and crypto testing hooks from version-matched package
  docs. Do not assume a hook from a newer release exists in the project.

## Sources

- Release history and support policy: `https://go.dev/doc/devel/release`
- Toolchain selection: `https://go.dev/doc/toolchain`
- GODEBUG compatibility defaults: `https://go.dev/doc/godebug`
- Release notes: use `https://go.dev/doc/go1.N` for the selected minor release
- Standard library: `https://pkg.go.dev/std`
