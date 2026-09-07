# Fence remaining hardening work — 2026-09-07

> Current status (2026-09-07): F12 is implemented in Kujo and integrated into Fence.
> Linux/Windows release gates and local macOS verification pass. See the
> [implementation and final verification receipt](confined-output-implementation.md).
> Open F12 statements below are historical.

## Repository and baseline

Repository: kujolang/fence. Branch: main. Starting SHA:
`981e6064a6ffa17b5898ab8a703f0acf5cdb28df`. Implementation ending SHA:
`10961e20b3c8bd1c7eb4d3ff9a9a5e2eb4013f52`; the subsequent evidence commit
contains this report.
Fence is a Kujo-native architecture-boundary CLI with optional trusted parser
subprocesses. Runtime minimum and package dependencies are unchanged. Scope is
Fence only; Kujo native filesystem APIs were inspected read-only.

This follows [the original audit](repository-hardening.md), preserving its
historical measurements and verification. The current-turn pre-edit graph and
JSON check passed. The pre-edit release attempt failed on host process spawning
(`os error 35`, resource temporarily unavailable), not on a Fence assertion.
The earlier committed complete baseline remains 243 assertions / 52 CLI checks.
No timeouts or assertions were weakened to accommodate the host error.

## Findings

| ID | Priority | Area | Finding / evidence | Action | Status |
|---|---|---|---|---|---|
| F15 | P2 | Cache | Old cache retained unvisited entries indefinitely; argv fingerprint could reuse changed adapter scripts | Per-scan compaction, 4 MiB/10,000 record retention, version 3, adapter bypass, same-snapshot hash/extract | Fixed lifecycle and freshness; trusted-cache provenance remains explicit |
| F16 | P2 | Contracts | Explain bypassed adapters, Go resolution, external rules and ignores | Shared decision module, matching extraction/resolution, additive exception evidence, fail-closed errors | Fixed |
| F17 | P2 | Efficiency | Quiet/summary rendered bodies subsequently discarded | Skip unused bodies; keep validation, output and ceiling semantics | Fixed |
| F12 | Needs native work | Security | Canonical ancestor check and path-based publication are separate operations | Wrote native API proposal and required adversarial regression contract | Open; scope authorization required |

## Changes implemented

### Cache lifecycle and authority

`src/cache.kujo` loads at most 4 MiB of a stable cache file and rejects envelopes
with more than 10,000 records. Per-run retention has the same byte/record limits
with envelope space reserved. Entries that cannot be retained are still fully
analyzed. Only this scan's visited built-in entries are published as compact
JSON; unvisited/deleted paths disappear. Cache version 3 intentionally discards
older derived data without migration. `src/analyze.kujo` propagates retention
through sequential shards, including the empty scan case.

Built-in digest and extraction use the same read snapshot. Configured adapters
always execute because argv does not identify executable/script/environment
inputs. This trades adapter cache hits for correctness; no performance gain is
claimed for adapter-heavy workloads. Local cache JSON is not authenticated.
Deliberate forgery by a workspace writer remains outside the trusted-cache model;
use uncached checks where provenance is not trusted. Pre/post read byte checks
are not a guarantee against hostile file mutation while reading.

Tests cover cold/warm equality, source changes, missing files, entry/byte
retention ceilings, multi-shard retention, deleted paths, oversized on-disk cache
replacement, changed adapter scripts with identical argv, and two simultaneous
cache writers producing identical reports and valid compact cache JSON. The
concurrency test verifies publication correctness, not hostile path confinement.

### Consistent explanation

`src/decisions.kujo` holds dependency/ignore decisions formerly private to
analysis. `src/analyze.kujo` and `src/cmd_explain.kujo` use it. Explain now uses
configured adapters, Go module resolution, external restrictions and expiring
exceptions. Existing row keys remain; confidence and ignore evidence are added.
Ungoverned source imports are classified as ungoverned. Invalid config/format
returns 2, failed extraction or an import ceiling 4, missing file 5. A successful
explanation still exits 0 even when describing denial. Regression tests cover
Go/external denial, active and expired ignores, ungoverned sources, adapter
extraction/failure, and format validation. `fence.toml` governs the new module.

### Avoid unused rendering

`src/cmd_check.kujo` skips body generation only when quiet/summary has no output
file or configured byte ceiling. Report-byte counting is skipped when no ceiling
exists. It still analyzes every selected source and preserves status/errors,
validation, output, and limit enforcement. Unit and CLI contracts lock this in.
`benchmarks/report_benchmark.kujo` gives a reproducible isolated comparison;
`scripts/verify_release.kujo` now statically checks that harness. No flaky timing
threshold was added. Command, architecture, performance and changelog docs match
the implemented behavior.

## Performance and efficiency

| Relevant dimension | Before | After | Evidence / limit |
|---|---|---|---|
| Quiet JSON body constructed for 1,000 violations | 337,380 bytes | 0 bytes | Same result; status remains failed |
| Isolated rendering path, one sample | 34.424506 ms | 16.722882 ms | Kujo 1.2.3/macOS, not total scan speed |
| Persistent cache retention | No explicit byte/record ceiling; stale entries retained | 4 MiB / 10,000 records; only current visited files | Code bounds plus regression tests |
| Adapter cache reuse | Argv/source identity could hide script changes | Always executes configured adapter | Same argv / changed script CLI regression |
| Dependencies | Kujo runtime only plus optional configured adapters | Unchanged | No new runtime/build dependency |

No measured peak-memory, token, build-time, or binary-size claim applies. Output
verbosity is unchanged; the avoided body was already hidden from users. Cache
metadata bounds are not bounds on source files, adapter payloads, runtime heap
or hostile concurrent writers.

## Security, compatibility and cross-repository work

Reviewed cache input/provenance, parser subprocess identity, output publication,
exception policy and failure propagation. Cache corruption is disposable and
adapter failures do not become successful explanations. Atomic output remains
path-based. [The F12 proposal](confined-output-runtime-contract.md) defines the
required native mechanism and synchronization-based adversarial test matrix.
It requires **kujo** changes and a deliberate Fence minimum-runtime update.
No sibling repository was modified and no exploit reproduction is claimed.

Public CLI commands and configuration/environment variables are unchanged.
Explain JSON has additive fields and corrected decisions/errors as documented;
check JSON/SARIF contracts remain unchanged. Disposable cache extractor version
changes from 2 to 3 while its pathname/envelope schema remain v1. Consumers of
strict explanation schemas should accept/document the additive fields. No
external consumer must change for F15-F17. F12 cannot be completed by another
path check or a script-level fallback.

## Remaining work

- P0/P1: no known regression introduced by this pass remains.
- F12: native implementation and platform verification require Kujo write scope.
- Needs more evidence: Linux/Windows and pinned-minimum-runtime CI execution;
  no remote pass is claimed. Independent memory/end-to-end timing remains
  unmeasured, not a promised optimization.
- Intentional trust boundary: unauthenticated workspace cache; not worth adding
  hashes that pretend to authenticate against the same workspace writer.
- Existing unrelated roadmap ideas remain separate from this audit.

## Verification receipt

All commands run from Fence with `/Users/robertdevore/.local/bin` on PATH.
Reviewed outputs live in `receipts/remaining/`.

| Exact command | Result |
|---|---|
| `kujo run fence.kujo -- graph` | Pre-edit and final PASS |
| `kujo run fence.kujo -- check --format json` | Pre-edit and final PASS |
| `kujo run scripts/verify_release.kujo` | Pre-edit host spawn error 35; updated source gate PASS: static checks, unit/CLI, self config/architecture, six examples, release artifacts |
| `kujo run tests/fence_tests.kujo` | 266 passed, 0 failed |
| `sh tests/cli_smoke.sh` | Final 70 passed, 0 failed; includes five cache lifecycle/concurrency checks added after the complete release run |
| `kujo run benchmarks/report_benchmark.kujo` | PASS; exact receipt retained |
| `sh -n tests/cli_smoke.sh fence.sh` | PASS |
| `bash .github/scripts/check-kujo-tool-artifacts.sh` | PASS |
| `git diff --check` | PASS |

A warm-cache mutation error and invalid new adapter-test envelope were found
and corrected during development; both final suites pass. Historical original
audit receipts are unchanged. No tests were disabled or relaxed.
