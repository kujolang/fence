# Getting started

## Prerequisites

Fence runs on the [Kujo](https://github.com/) runtime. You need the `kujo`
binary on your `PATH` (or invoke it by absolute path). Fence requires no other
dependencies and never touches the network.

## Install

Fence is a set of `.kujo` files — clone or vendor the directory containing
`fence.kujo` and `src/`. No build step is required.

```bash
# from anywhere inside your project
kujo run /path/to/fence/fence.kujo -- --version
```

Optionally add the one-line wrapper to your `PATH`:

```bash
./fence.sh --version    # == kujo run fence.kujo -- --version
```

> **How resolution works:** module imports (`from src.x import ...`) resolve
> relative to `fence.kujo`'s directory, while file scanning happens in your
> current working directory. That means you keep Fence in one place and run it
> from inside any repository you want to check.

## First run

```bash
cd your-project
kujo run /path/to/fence/fence.kujo -- init      # writes fence.toml
kujo run /path/to/fence/fence.kujo -- validate  # sanity-check the config
kujo run /path/to/fence/fence.kujo -- check     # scan and report
```

`init` writes a starter `fence.toml` using the `layered` template. Pick a
different starting point with `--template`:

```bash
kujo run fence.kujo -- init --template hexagonal
```

Templates: `layered` (default), `cli`, `web-app`, `hexagonal`, `mvc`,
`feature-sliced`. Edit the generated zones to match your real directories, then
re-run `check`.

## Understand a single file

When a file is classified in a surprising way, ask Fence to explain it:

```bash
kujo run fence.kujo -- explain src/ui/LoginForm.tsx
```

This prints the matched zone, allowed/denied dependencies, and an
allowed/denied/external/unknown decision for every detected import.

## Adopt on an existing (messy) repo

If `check` reports many pre-existing violations, record them as a baseline so
only **new** violations fail going forward:

```bash
kujo run fence.kujo -- baseline create     # writes fence-baseline.json
kujo run fence.kujo -- check --baseline    # passes now; new violations fail
```

## The agent workflow

Fence is designed to be handed to autonomous coding agents as a deterministic
architectural constraint.

```text
Before implementation:
1. kujo run fence.kujo -- graph     # learn the allowed boundaries
2. kujo run fence.kujo -- check     # see the current state

During implementation:
- Do not import across denied architecture boundaries.
- Put shared types/helpers in the correct shared/core zone.
- Do NOT weaken fence.toml just to make violations disappear.

After implementation:
1. kujo run fence.kujo -- check
2. Fix violations before handoff.
3. Include the Fence result (JSON or markdown) in the final report.
```

Next: [Configuration](configuration.md) · [Commands](commands.md) ·
[CI integration](ci.md).
