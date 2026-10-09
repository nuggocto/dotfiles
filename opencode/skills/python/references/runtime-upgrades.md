# Python runtime upgrades

Read this reference when changing the Python runtime, `requires-python`, CI
matrix, deployment image, annotation behavior, multiprocessing behavior, or
free-threaded support.

## Version policy

- Preserve a library's declared support range unless the task includes a
  compatibility change.
- For a new application, choose the latest stable Python release supported by
  its dependencies and deployment platform.
- For each supported Python line, use its latest maintenance or security patch.
  Check release status as well as patch numbers: Python 3.10 reached end of life
  on 2026-10-01. Preserve library compatibility separately from selecting a
  maintained production runtime.
- Pin the full interpreter version in owned containers, standalone artifacts,
  and tool-managed runtimes. On managed platforms or distribution packages,
  use the strongest available control and record the resolved runtime in build
  or deployment output.

## Upgrade review

- Read the versioned What's New document and changelog for every skipped minor
  version.
- Audit syntax, standard-library availability, and event-loop setup against the
  supported versions. In Python 3.14, `asyncio.get_event_loop()` raises without a
  current loop; customize application runners with `loop_factory` instead of
  deprecated event-loop policies.
- Check annotation evaluation, direct `__annotations__` access, forward
  references, runtime introspection, and consumers of `from __future__ import
  annotations` when crossing an annotation-semantics change.
- Check multiprocessing defaults, picklability, import-time effects,
  `if __name__ == "__main__"` guards, frozen executables, and inherited process
  state when start-method defaults change.
- Treat free-threaded CPython as a separate runtime configuration. Verify the
  GIL state after loading production extensions and test the complete native
  dependency set before claiming support.
- Check `sys.flags.thread_inherit_context` and
  `sys.flags.context_aware_warnings`. In Python 3.14 they default to true for a
  free-threaded build and false for a GIL-enabled build, which changes context
  propagation and concurrent `warnings.catch_warnings` behavior.
- Measure memory and capacity on the deployed free-threaded build. It typically
  uses more memory because of object-layout, allocator, reclamation, and
  reference-counting differences.
- Run the affected minimum and maximum Python versions, relevant operating
  systems, optional dependencies, typing checks, package builds, and real
  deployment smoke tests.

## Warning policy

- Fail CI on unexpected warnings from project-owned code.
- Filter dependency warnings by category, module, or message. Review and expire
  each ignore rather than suppressing all third-party warnings.
- Use development mode, asyncio debug mode, and resource warnings in focused
  jobs where their overhead and dependency noise are understood.

## Sources

- Active releases: `https://www.python.org/downloads/`
- Versioned docs: substitute `X.Y` in `https://docs.python.org/X.Y/`
- What's New: `https://docs.python.org/X.Y/whatsnew/`
- Warnings filter: `https://docs.python.org/X.Y/library/warnings.html`
- Free-threading HOWTO: `https://docs.python.org/X.Y/howto/free-threading-python.html`
- Packaging specifications: `https://packaging.python.org/specifications/`
