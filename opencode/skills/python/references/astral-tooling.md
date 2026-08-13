# Astral tooling and FastAPI

Use uv, Ruff, and ty for all Python work. They are the canonical environment,
dependency, execution, formatting, linting, and type-checking toolchain even
when a repository still contains older tooling. Resolve their versions from
project metadata, `uv.lock`, CI actions, and toolchain metadata before relying
on new flags or rules.

## uv

- Use uv to install Python, create and sync environments, add or remove
  dependencies, maintain `uv.lock`, run commands, build distributions, and test
  built artifacts.
- When older package-manager configuration or lockfiles exist, make uv reproduce
  the required environments and artifacts before removing redundant files.
- Commit `uv.lock` for applications. For libraries, test both the locked
  development environment and fresh resolutions across the declared dependency
  range.
- Use `uv run` for project commands and `uvx` for isolated tools that do not
  belong in project dependencies. In CI and deployment use frozen or locked
  modes where manifest drift must fail.
- Pin the uv installer, container image, or setup action. Do not use a floating
  `latest` image in a reproducible deployment.

## Ruff

- Configure Ruff in `pyproject.toml`. Use `ruff format` and `ruff check`; remove
  Black, isort, Flake8, and other overlapping formatters and linters.
- Select rules deliberately, set `target-version` from the minimum supported
  Python, review fixes before applying them broadly, and distinguish safe from
  unsafe fixes.
- Run `uv run ruff check .` and `uv run ruff format --check .` in local and CI
  verification.

## ty

- Configure ty under `[tool.ty]` in `pyproject.toml` and run
  `uv run ty check`. Keep rule overrides and suppressions narrow and reviewable.
- Use ty as the type checker for every project. Python 3.7 through 3.9 can be
  selected, but ty's bundled standard-library stubs do not fully cover them;
  verify questionable diagnostics against the target runtime and documentation.
- Align ty's Python version and environment discovery with `requires-python`, uv,
  and the CI matrix. Verify library typing on the minimum supported Python.

## FastAPI

- Load the `fastapi` skill in addition to the Python skill. Keep framework,
  Starlette, Pydantic, ASGI lifecycle, API-contract, and deployment guidance
  there rather than duplicating it here.
- Manage FastAPI and its extras with uv, run development and production commands
  through `uv run`, and lock the complete resolved stack.
- Before finishing FastAPI work, run Ruff, ty, the established test suite, and
  OpenAPI checks.

## Sources

- uv: `https://docs.astral.sh/uv/`
- uv with FastAPI: `https://docs.astral.sh/uv/guides/integration/fastapi/`
- Ruff: `https://docs.astral.sh/ruff/`
- ty: `https://docs.astral.sh/ty/`
- ty Python-version support: `https://docs.astral.sh/ty/python-version/`
