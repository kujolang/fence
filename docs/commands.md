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
| `--template <name>` | `layered` (default), `cli`, `web-app`, `hexagonal`, `mvc`, `feature-sliced`, `monorepo` |
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
kujo run fence.kujo -- check --cache
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
| `--cache` | Reuse content-digest import extraction under `.fence/cache-v1.json` |
| `--quiet` | Print only a one-line status |
| `--summary-only` | Print only the summary line (no violation list) |
| `--no-color` | Accepted for CI compatibility (output is already plain) |

Exit `0` when clean at the threshold, `1` when violations reach it. An incomplete
scan returns `4`, even with `--fail-on none`; check reports retain skipped-file
details and use failed status. Directory cycles or traversal failures abort the
scan. Baseline and observed-graph generation refuse incomplete analysis.
The `--base` value must be a shell-safe, unambiguous Git ref and may not start
with `-`. Revision ranges, reflog selectors, repeated slashes, `.lock` suffixes,
and trailing dots/slashes are rejected before Git runs.

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
kujo run fence.kujo -- graph --observed --format json
```

| Flag | Meaning |
| --- | --- |
| `--format <fmt>` | `human` (default), `json`, `dot`, `mermaid` |
| `--output <path>` | Write the graph to a repo-relative file |
| `--cycles` | Report dependency cycles in allowed edges (exit `1` if any) |
| `--observed` | Compare configured and observed internal edges (`human`/`json`) |

## `baseline create` / `baseline prune`

Record current violations so an existing repo can adopt Fence gradually.

```bash
kujo run fence.kujo -- baseline create     # writes fence-baseline.json
```

JSON and SARIF remain a single JSON object when suppression occurs; no prose
footer is appended. Human and Markdown output retain the suppression receipt.

Then run `check --baseline` to suppress those exact violations; any **new**
violation still fails. Commit `fence-baseline.json` and shrink it over time.

`kujo run fence.kujo -- baseline prune` removes fingerprints no longer present
in a full current scan and prints removed/remaining counts.

## `workspace init`

`kujo run fence.kujo -- workspace init` discovers direct children of `apps/`
and `packages/` with common local manifests and generates one deterministic zone
per package. Names are quoted as TOML data; names that normalize to the same
zone cause exit `2` before writing. It refuses to overwrite an existing `fence.toml`.

## `ignores list` / `ignores check`

Audit structured exceptions without running a source scan.

```bash
kujo run fence.kujo -- ignores list --within-days 30
kujo run fence.kujo -- ignores check --format json
kujo run fence.kujo -- ignores check --fail-expiring
```

`list` is informational. `check` exits `1` when any exception is expired;
`--fail-expiring` also fails exceptions within the selected review window.
`--within-days` accepts `0..3650` and defaults to `30`.

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

### Cache lifecycle and suppressed reports

`check --cache` stores disposable built-in extraction records in
`.fence/cache-v1.json`. The file is capped at 4 MiB and 10,000 entries; oversized
or incompatible caches are ignored. Each successful save retains only files
visited in that scan, including all sequential shards. Deleted, excluded and
unselected paths are removed; changed-only runs can therefore reduce later hit
rates. Entries exceeding retention limits are still analyzed completely.
Extractor version 3 invalidates older entries automatically. Custom parser
adapters always execute, including with `--cache`, so changes to adapter scripts,
environment and dependencies remain visible. Cache contents are trusted local
state, not authenticated evidence; omit `--cache` for untrusted cache provenance.

`--quiet` and `--summary-only` skip generating the report body when no output
file and no report-byte ceiling consume it. Invalid formats still fail. An
explicit `--output` receives the complete report, and a configured
`max_report_bytes` still applies to the complete selected-format body.

### Explanation parity

`explain` uses the same adapter extraction, Go module resolution, external
package rules and expiring-ignore decisions as `check`. Each JSON import row
adds `confidence`, `ignored`, `ignore_reason`, and `ignore_expires`; existing
fields and decision strings remain. A waived violation is `allowed` with its
ignore evidence. Expired exceptions do not waive violations. Invalid config or
format returns 2, failed extraction or an import ceiling returns 4, and a
missing file still returns 5. Explanation of a denied dependency still exits 0;
`check` is the enforcement command.

Confined output requires the source runtime pinned in README. Use real directory
paths for output parents; replace symlink aliases with their in-repository target
paths. Reports, caches and baselines fail with IO exit 5 on rejected destinations.
