# Fence repository hardening — 2026-09-22

## Repository and scope

- Repository: `kujolang/fence`, branch `fix/confined-output-runtime`.
- Starting SHA: `fda049ed9aa55ba50c150b84bb9ca1bdf49af0dc`; initially clean.
- Implementation ending SHA: `5a6383d4c30c2e4c7d92b8c0f5b4ec85ea66d5ec`. A subsequent
  evidence commit contains this report, avoiding a self-referential commit hash.
- Purpose: deterministic, local-first architecture-boundary enforcement across
  Kujo, JS/TS, Python, Rust, PHP and Go source repositories.
- Dependencies: Kujo runtime; Git for changed-only/doctor; optional explicitly
  trusted parser-adapter executables. No package dependencies were added.
- Write scope: Fence only. Related runtime and Kennel manifest consumers were
  inspected read-only. No sibling repository was edited.

Reviewed entry/dispatch, every implementation module, configuration, resolution,
walk/extraction, caches/baselines, rules/exceptions, all output formats, scripts,
CI, packaging, contracts, unit/CLI harnesses, fixtures/examples and canonical
operating documentation. Archived `agent/` planning was excluded; no code was
removed based solely on search results. The independent security review examined
current source offline and retained a pre-remediation evidence snapshot. Its
[sealed report](receipts/2026-09-22/security-pre-remediation.md) records the three
pre-fix findings, not the final fixed state; the final regressions below verify
remediation. Daybreak access and security-tool token counts were unavailable.

## Baseline

Installed runtime: `kujo 1.4.0`, macOS. Commands use
`export PATH=/Users/robertdevore/.local/bin:$PATH` from the Fence root.
The original graph, JSON self-check and complete release gate passed before
implementation. The release gate includes all source static checks, unit/contract
and CLI suites, six passing/failing examples, self validation and deterministic
integrity artifact generation. No pre-existing gate failure was observed.

New regressions against pre-fix code produced **272 passed / 8 failed**: five
invalid exception cases and three missing total-budget checks. Those failures
are expected reproduction evidence, not relaxed assertions. An extra unit run
queued after the scale benchmark loaded the new tests; its receipt is named
`regressions-before-repeat.txt`, not an original-suite baseline.

Raw receipts are in [receipts/2026-09-22](receipts/2026-09-22/). A small resolver
probe independently reproduced an alias returning the misleading lexical path
`tests/fixtures/sample/src/ui/../database/users.ts`.

## Findings

| ID | Priority | Area | Finding and evidence | Action | Status |
|---|---|---|---|---|---|
| H01 | P1 | Boundary correctness | Alias/direct candidates retained `..`; filesystem opened database while zone glob saw UI. Resolver probe and independent source trace confirm same-zone allow bypass. | Normalize candidate identity before lookup/classification; test alias/direct/absolute forms and CLI denial. | Fixed |
| H02 | P1 | Scan completeness | POSIX literal backslashes were rewritten before stat, silently dropping or redirecting files. | Fail full walks on ambiguous directory entries with an actionable diagnostic. | Fixed |
| H03 | P2 | Presentation | Source-controlled controls/markup flowed into human and Markdown check/explain fields. | Escape C0/C1 controls and Markdown syntax at presentation boundaries; retain original machine evidence. | Fixed |
| H04 | P1 | Exception validation | Impossible expiry dates and non-string reasons/selectors passed validation; matching/auditing could disagree or crash. | Validate types and calendar round-trip; also reject non-string Go module prefixes. | Fixed |
| H05 | P2 | Resource limits | Baseline/observed graph skipped max_files; sequential shards reset import budgets. | Enforce file budgets in analysis and total import budgets across shards. | Fixed |
| H06 | P2 | Performance | Baseline create/apply/prune repeatedly linearly searched fingerprint arrays. 2,000-row baseline measured below. | Build per-operation dictionary indexes; preserve order, duplicate semantics and schema. | Fixed |
| H07 | P2 | Runtime/CI/docs | Manifest advertised Kujo 1.0.1 despite requiring newer native API; security/platform docs described obsolete implementation.  | Require 1.4.0, retain exact source minimum, update docs; retain existing platform gates. | Fixed |

## Changes implemented

### Import and scan identity (H01–H02)

`src/resolve.kujo` now normalizes dot segments for every candidate source,
including aliases and direct slash paths, before the returned path is matched to
zones. Rooted paths remain rooted; unresolved leading parents remain parents
rather than being clamped to the repository. Already-normal paths use a fast
path. Original import strings remain in evidence. This deliberately changes
incorrect decisions for disguised cross-zone dependencies.

`src/walk.kujo` rejects literal-backslash entries instead of interpreting them
as portable separators. CLI coverage proves failure even with `--fail-on none`.
Missing source roots, ordinary separator behavior, source symlink policy,
exclusion pruning and sorted outputs are otherwise preserved. Source symlinks
remain trusted layout, not a read-confinement guarantee.

### Failure contracts and budgets (H04–H05)

`src/validate.kujo` verifies reason/selector types and expiry date semantics
before matching or auditing. Valid leap dates remain accepted. `go_module`
receives an explicit string check. Invalid semantic configuration returns 2;
no format or configuration key was added.

`src/analyze.kujo` enforces file ceilings regardless of its command caller, and
sharded analysis carries remaining import budgets. Exhaustion fails before any
partial result can be published. CLI tests ensure baseline/graph sentinels remain
unchanged. Exact-boundary budgets still succeed, and zero still means unlimited.
Selection, extraction and rendering can allocate before some limits: these
budgets are policy ceilings, not process-memory sandboxing.

### Presentation and evidence (H03)

`src/util.kujo` provides shared text/row presentation escaping. `reports.kujo`
and `cmd_explain.kujo` apply it only to human/Markdown data fields. C0/C1 characters
are visible Unicode escapes; Markdown punctuation becomes entities. Tests cover
ESC, newline, C1, HTML/backticks and unmodified JSON evidence after rendering.
JSON/SARIF schemas, machine strings, counts and exit codes are unchanged.
Trusted configuration diagnostics and graph syntax are not advertised as a
universal untrusted-terminal sanitization interface. Reports remain untrusted
content for agents; escaping does not solve semantic prompt injection.

### Baseline indexing (H06)

`src/baseline.kujo` replaces repeated array membership scans with dictionary
indexes. Baseline creation remains sorted/deduplicated, suppression still counts
every matching violation, and prune preserves the pre-existing duplicate-entry
behavior. `tests/fence_tests.kujo` verifies these contracts.
`benchmarks/baseline_benchmark.kujo` measures all three operations, asserts
results and emits output hashes. The release gate statically checks the harness;
there is intentionally no flaky wall-time threshold.

### Runtime and regression gates (H07)

`kennel.toml`, README/getting-started, security/configuration/command/platform/performance/architecture
docs and changelog now match the implementation. Local Git ancestry verifies
`v1.4.0` contains native commit `97aa13a338b154646d96e5c257e5d17fed17bef9`.
The platform workflow retains that exact API-minimum pin. Existing unit/CLI CI
gates automatically run the new behavioral regressions; no redundant runtime
build, speculative CI change or unstable timing gate was added.

## Performance and efficiency

Same runtime, same 2,000 distinct violations, same benchmark script; individual
samples on a shared host with concurrent unrelated work, not statistical latency
budgets or service-level guarantees:

| Operation | Before (ms) | After (ms) | Equivalence |
|---|---:|---:|---|
| Baseline create | 10,556.178465 | 3,375.606477 | Identical baseline SHA-256 |
| Baseline apply | 7,145.578318 | 120.206516 | Identical applied-result SHA-256 |
| Baseline prune | 22,329.863582 | 7,486.036345 | Identical pruned-result SHA-256 |

Indexes use additional O(n) dictionary storage per operation, released afterward.
No peak-heap reduction is claimed. Kujo collection-copy behavior still affects
construction costs; no claim of universally linear execution time is made.

The existing 1,600-import scale harness was also run before/after: total scan
112,892.340236 ms before and 293,849.005544 ms after. The shared host became much
busier: unchanged fixture generation also rose from 19,619.109682 to
44,365.386588 ms, and filtering code was unchanged. These noisy samples do not
establish a code-attributable speedup or regression. An alternating 200-import
comparison is retained in `paired-scale.json`: before/after pairs were
14,263.36 / 11,049.80 ms and 9,661.44 / 9,260.37 ms, with identical functional
counters in all four runs. This did not reproduce a consistent scan slowdown;
it still does not justify an end-to-end speedup claim. The large fixture checks 1,601 files, 1,600
imports and zero violations with one resolution miss and 1,599 hits. No scan
speedup is attributed to the baseline-only optimization.

No AI provider, prompt builder, MCP schema or model replay exists here. Existing
quiet/summary paths already avoid unused report bodies; they remain covered.
The rendering harness retained the exact 337,380-byte eager / 0-byte quiet body
result; its 49.94 / 94.72 ms samples are dominated by host variability and are
not presented as a latency benefit.
Full evidence is kept in files with concise command receipts. No token reduction
is claimed, and no needed diagnostics/schema fields were removed. Dependencies
remain zero packages beyond the runtime and optional external executables.
Fence is distributed as source: there is no new binary-size/build-time target.
No cache expansion or speculative caching was introduced.

## Security and state review

Reviewed CLI/Git argv validation, adapter timeout/output bounds and trust,
config composition, source-path classification, output publication, cache
validation/retention, baseline suppression and report presentation. H01–H03 were
independently source-validated, then fixed with behavioral coverage. Configuration
is trusted policy, not executable unless adapters are explicitly enabled.
Adapter subprocesses are not sandboxed by Fence. Git uses structured argv and
NUL-delimited filenames. No new network or credential access was introduced.

Output/cache/baseline writes continue through the already-integrated confined
native atomic writer. Existing concurrent cache publication, symlink-parent,
final-symlink, no-overwrite and sentinel-preservation tests remain in the full
CLI gate. No extra sleeps, timeouts, retries or weaker assertions were added.
Caches stay bounded, disposable and unauthenticated. Native filesystem internals
were not re-audited exhaustively; their established ABI/identity contract is an
explicit dependency. No newly discovered unresolved vulnerability remains from
this review.

## Compatibility

- Public command/API names and callable arities are preserved; presentation
  helpers are additive. Incorrect path decisions and malformed config handling
  intentionally change as described above.
- JSON/SARIF/baseline formats and schema versions are unchanged; hashes prove
  baseline behavior equivalence for the measured fixture.
- No config key, environment variable or network interface was added/removed.
- Human/Markdown evidence with controls/markup is escaped; machine consumers
  retain exact values. Unsupported literal-backslash filenames now fail loudly.
- The package runtime minimum corrects previously inaccurate metadata; old
  runtimes already lacked the required native write API.
- Optional Scout/Eval/PackWrite/ShipCheck integrations were reviewed through the
  existing consumer matrix and available source/contracts. No new cross-repo
  consumer incompatibility or migration requirement was established. Historical
  PackWrite findings were not reclassified as new work without reproduction.

## Cross-repository follow-ups and remaining work

- P0/P1: none newly unresolved; no known regression introduced by this pass.
- P2/P3: no mandatory remaining implementation. Preserve existing public helper
  functions, best-effort extractors and roadmap documents rather than deleting
  uncertain external interfaces or redesigning parsers during cleanup.
- Needs more evidence: current hosted Linux/Windows run is still building the
  pinned native runtime; local release checks passed. Statistical latency/peak-memory profiling on an idle host;
  this report makes only the recorded single-sample claims.
- Not worth changing: cache authentication without an external trust anchor,
  speculative parallelism, arbitrary timing/token budgets and cosmetic churn.
- Cross-repo changes required: none. Native confinement still relies on the
  pinned Kujo API; that dependency was already implemented before this session.

## Verification receipt

Exact commands below run from Fence with the PATH setup above. Verbose outputs
remain in the dated receipts directory. No live external service test is needed
for this offline CLI. There is no separate formatter/build/typechecker: `kujo
check` and the existing release gate are the authoritative source/static gates.

| Command | Result |
|---|---|
| `kujo --version` | 1.4.0 |
| `kujo run fence.kujo -- graph` | Baseline and final PASS |
| `kujo run fence.kujo -- check --format json` | Baseline and final PASS |
| `kujo run scripts/verify_release.kujo` | Baseline and final PASS |
| `kujo run tests/fence_tests.kujo` | New-test reproduction: 8 failures; final 289 passed, 0 failed |
| `sh tests/cli_smoke.sh` | 87 passed, 0 failed |
| `kujo run benchmarks/fence_benchmark.kujo` | Baseline and final PASS |
| `kujo run benchmarks/fence_benchmark.kujo -- --files 200` (starting source copied to an ignored temporary tree; alternating with final source, twice each) | PASS; counters identical |
| `kujo run benchmarks/baseline_benchmark.kujo` | Before/after PASS; three output hashes identical |
| `kujo run benchmarks/report_benchmark.kujo` | PASS; byte counts preserved |
| `sh -n tests/cli_smoke.sh fence.sh` | PASS |
| `bash .github/scripts/check-kujo-tool-artifacts.sh` | PASS |
| `git diff --check` | PASS |

Two ad-hoc command wrappers attempted assignment to zsh's read-only `status`
variable after the tests had finished; source suites were unaffected. The final
release invocation captures its exit with `task_exit` and is authoritative.

Implementation commits: `7e6ce5c` (boundary/failure hardening), `b58fb53`
(baseline indexing), `5a6383d` (runtime documentation/metadata). Source verification
completed before those commits. Hosted platform verification is recorded below
only after an observed result; historical platform passes are not attributed to
this revision.

Hosted verification at handoff: [platform run 35769793524](https://github.com/kujolang/fence/actions/runs/35769793524)
for implementation SHA `5a6383d4c30c2e4c7d92b8c0f5b4ec85ea66d5ec` is in progress
(building/testing pinned Kujo on Linux and Windows); no pass is claimed yet.
[Artifact guard 35769793497](https://github.com/kujolang/fence/actions/runs/35769793497)
passed. The following evidence commit changes only documentation/receipts.
