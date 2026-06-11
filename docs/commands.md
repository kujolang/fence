# Commands

All commands run as `kujo run fence.kujo -- <command> [options]`. Arguments
after `--` are passed to Fence.

## `init`

Create a starter `fence.toml`.

```bash
kujo run fence.kujo -- init
kujo run fence.kujo -- init --template hexagonal
kujo run fence.kujo -- init --force          # overwrite an existing config
```

| Flag | Meaning |
| --- | --- |
| `--template <name>` | `layered` (default), `cli`, `web-app`, `hexagonal`, `mvc`, `feature-sliced` |
| `--force` | Overwrite an existing `fence.toml` |

Refuses to overwrite without `--force` (exit `2`).

## `check`

Scan source files and report boundary violations.

```bash
kujo run fence.kujo -- check
kujo run fence.kujo -- check --format json
kujo run fence.kujo -- check --format markdown --output FENCE_REPORT.md
kujo run fence.kujo -- check --format sarif --output fence.sarif
kujo run fence.kujo -- check --fail-on warning
kujo run fence.kujo -- check --changed-only --base origin/main
kujo run fence.kujo -- check --baseline
kujo run fence.kujo -- check --quiet
```

| Flag | Meaning |
| --- | --- |
| `--format <fmt>` | `human` (default), `json`, `markdown`, `sarif` |
| `--output <path>` | Write the report to a repo-relative file (path-safe) |
| `--fail-on <level>` | `none`, `warning`, `error` (overrides config) |
| `--changed-only` | Only scan files changed vs a Git base |
| `--base <ref>` | Git base ref for `--changed-only` (default `HEAD`) |
| `--baseline` | Suppress violations recorded in `fence-baseline.json` |
| `--quiet` | Print only a one-line status |
| `--summary-only` | Print only the summary line (no violation list) |
| `--no-color` | Accepted for CI compatibility (output is already plain) |

Exit `0` when clean at the threshold, `1` when violations reach it.

## `explain <path>`

Show how Fence classifies one file.

```bash
kujo run fence.kujo -- explain src/ui/LoginForm.tsx
kujo run fence.kujo -- explain src/domain/user.ts --format json
```

Prints the matched zone (and a note if multiple zones matched), allowed/denied
dependencies, and an `allowed` / `denied` / `external` / `ungoverned` decision
for each detected import.

## `graph`

Print the architecture dependency graph (allowed direction).

```bash
kujo run fence.kujo -- graph
kujo run fence.kujo -- graph --format mermaid
kujo run fence.kujo -- graph --format dot --output architecture.dot
kujo run fence.kujo -- graph --format json
kujo run fence.kujo -- graph --cycles          # report dependency cycles
```

| Flag | Meaning |
| --- | --- |
| `--format <fmt>` | `human` (default), `json`, `dot`, `mermaid` |
| `--output <path>` | Write the graph to a repo-relative file |
| `--cycles` | Report dependency cycles in allowed edges (exit `1` if any) |

## `baseline create`

Record current violations so an existing repo can adopt Fence gradually.

```bash
kujo run fence.kujo -- baseline create     # writes fence-baseline.json
```

Then run `check --baseline` to suppress those exact violations; any **new**
violation still fails. Commit `fence-baseline.json` and shrink it over time.

## `validate`

Validate `fence.toml`.

```bash
kujo run fence.kujo -- validate
```

Reports invalid thresholds/policies/severities, missing or undefined zones,
allow/deny conflicts, pathless zones, overlapping zone paths, dependency
cycles, and unsupported config versions. Exit `2` on errors, `0` otherwise.

## `doctor`

Environment diagnostics.

```bash
kujo run fence.kujo -- doctor
```

Prints version, working directory, Git detection + branch + changed-file count,
config path, source roots, zone count, enabled language detectors, and config
diagnostics.

## `help` / `--help`

```bash
kujo run fence.kujo -- help
kujo run fence.kujo -- --help
```

Prints usage text and exits `0`.

## `version` / `--version`

```bash
kujo run fence.kujo -- version
kujo run fence.kujo -- --version
```

Prints the Fence release string and exits `0`.
