# Go toolchain upgrades

Read this reference when changing the Go toolchain, `go` or `toolchain`
directives, cryptographic code or tests, or code whose behavior changed across
Go releases.

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
  compiled defaults when compatibility behavior matters. Go 1.27 removes settings
  such as `asynctimerchan`; a removed setting cannot restore its old behavior.
- Confirm `GOTOOLCHAIN`, CI images, local tooling, release builders, and
  production use the intended version.
- Run the existing test, race, static-analysis, benchmark, cgo, platform, and
  build-tag matrix affected by the upgrade.
- Regression-test public `net/http`, URL, proxy, cookie, TLS, crypto, JSON, and
  parser behavior. Go 1.27's v2-backed `encoding/json` preserves v1 semantics but
  can change error text; direct v2 adoption changes decoding defaults.
- Inspect the selected release's `go fix` support. Review its diff before
  applying modernizations, and keep optional cleanup out of unrelated work.
- Re-run representative allocation, GC, latency, memory, cgo, and profile checks
  when the toolchain can affect a measured hot path.

## HTTP, TLS, and cryptographic compatibility

- Use Argon2id only for human-chosen passwords. Generate opaque bearer tokens with `crypto/rand` or use a vetted token format, and avoid logging secrets or raw tokens.
- Do not introduce RSA PKCS #1 v1.5 encryption. Use OAEP for RSA encryption, and retain v1.5 decryption only for reviewed legacy protocol compatibility.

- Regression-test TLS interoperability after toolchain upgrades. Prefer fixing incompatible peers over retaining temporary compatibility settings.
- Regression-test `ServeMux` redirects, request methods and bodies, virtual hosts, cookies, proxies, and URL rejection after a toolchain upgrade when those behaviors are public contracts.
- Read the selected toolchain's release notes before changing cryptographic code or tests. Do not assume caller-supplied randomness hooks or deterministic-test techniques behave the same across Go releases.

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
