# Fence repository hardening audit

> Current status (2026-09-07): F12 is implemented in Kujo and integrated into Fence.
> Linux/Windows release gates and local macOS verification pass. See the
> [implementation and final verification receipt](confined-output-implementation.md).
> Open F12 statements below are historical.

Date: 2026-09-07. Repository: kujolang/fence. Branch: main.
Starting SHA: fc7a000ba837050bf8bffee6252835ef0ceb55a0 (clean checkout).
Ending implementation SHA: 4a91a40f5385f49456e319fa5b30f378e8e3f5da.
The subsequent documentation commit records this report and receipts; use
`git log -1 --format=%H -- docs/audits/repository-hardening.md` to identify it.

## Purpose, scope, and ground truth

Fence is a Kujo-native, offline architecture-boundary CLI. It reads local
TOML/JSON policy, walks source, extracts imports, resolves/classifies targets,
applies rules and exceptions, and produces human, JSON, Markdown, or SARIF
reports. Commands additionally support configured/observed graphs, adoption
baselines, workspace generation, config validation, diagnostics, and explain.

Inspected all 34 src modules, entrypoint/wrapper, unit and CLI harnesses,
conformance and contract fixtures, benchmark/release scripts, package metadata,
self-policy, CI workflows, security and canonical usage docs. Bulk agent history
and generated artifacts were excluded. Related Kujo runtime source at v1.0.1
was read to verify atomic-file and structured-process contracts. Consumer
integration docs and relevant Scout/PackWrite/ShipCheck source were read only.
No sibling repository was modified.

Dependencies: Kujo >=1.0.1, Git for changed-only/doctor, and optional explicitly
trusted argv parser adapters. kennel.toml declares no package dependencies.
Fence has no model, provider, MCP, network client, database, or server in its
core execution path. Release workflows build the same existing Kujo v1.0.1,
now pinned to commit 86690e62ec323b9e836fa0e98592b83eecb4a494. Runtime
transitive dependencies remain owned by Kujo; no advisory-clear claim is made.

## Baseline

Host: macOS; installed `/Users/robertdevore/.local/bin/kujo` reports 1.2.3.
PATH was explicitly extended with that directory. The default login-shell
launcher initially failed to create a process; non-login /bin/sh worked.
Existing release verification passed before source changes: static checks,
unit/contracts, CLI smoke, config/self-check, six passing/failing examples,
and release artifact generation. The original graph and self-check were saved.
No existing release-suite failure was observed.

New regression tests reproduced three changed-only failures before the fix
(35 passed, 3 failed), and default severity/omitted-file ignores failed in the
new unit cases. These were gaps in the original passing suite. Intermediate
implementation mistakes (helper arity and exception syntax) were corrected;
final failure tests assert actionable cycle text as well as exit code. Import
budget failure is tested at the CLI boundary: the in-harness catch did not
contain the propagated analysis exception, while a minimal direct throw/catch
probe passed on both installed 1.2.3 and local 1.3.1. No general runtime defect
is inferred from that harness behavior.

Evidence is under [receipts](receipts/); original source snapshots and temporary
logs remain ignored in .audit-evidence. Full scripts are checked in; receipts
retain concise output instead of copying entire source trees.

## Findings

| ID | Priority | Area | Finding and evidence | Action | Status |
|---|---|---|---|---|---|
| F01 | P0 | Enforcement | Empty exclude list matched everything in changed-only; quoted Git paths were split/trimmed. New end-to-end cases returned 0 instead of 1. | Correct empty-list semantics; argv, NUL records, stable sort; reject truncated/failed Git output. | Fixed |
| F02 | P1 | Machine output | Baseline suppression appended prose after JSON/SARIF. | Keep machine output one JSON document; regression parses the entire output. | Fixed |
| F03 | P1 | Data integrity | write_safe deleted existing files before replacement and leaked IO exceptions. | Existing Kujo atomic publication; structured IO failure; preserve existing files on failures. | Fixed |
| F04 | P1 | Traversal/resources | Excluded subtrees were fully collected; repeated roots duplicated work; directory cycles were unbounded. | Conservative subtree pruning, identical-path deduplication, ancestor cycle detection, fail on directory IO errors, skip special non-files. | Fixed |
| F05 | P1 | Cache/adapters | Cache accepted malformed import arrays; only cache directory was checked for escapes; adapter truncation/optional field types unchecked. | Validate records; canonicalize existing cache file; reject truncated/malformed adapter output. | Fixed within trusted-cache model |
| F06 | P1 | Policy | Zone normalization overwrote default severity with error; omitted ignore file did not match nested files. Unit repros failed. | Inherit configured severity and explicitly match default all-file ignores. | Fixed |
| F07 | P1 | Input validation | Malformed containers reached downstream indexing/normalization. | Reject known malformed tables, string lists, zone objects, aliases, and ignores containers during load. Preserve unknown keys. | Fixed for reviewed containers |
| F08 | P1 | Failure semantics | Source/adapter failures could yield a successful check or adoption artifact. | Failed status and exit 4 with check evidence; refuse baseline/observed graph on incomplete scans. | Fixed |
| F09 | P1 | Resolution | Raw-string cache identity crossed language semantics, including Go module prefixes; separator keys could collide. | Structured, extension-aware keys; relative/Rust keys retain importer identity. Mixed TS/Go regression. | Fixed |
| F10 | P1 | Resource limits | Import ceiling checked only after complete analysis. | Stop analysis as the ceiling is crossed; retain postselection/report ceilings. | Fixed, not a memory sandbox |
| F11 | P1 | Architecture gate | Existing cache and adapter modules had no self-policy zone. | Classify both as core; assert every src module is governed. No rules weakened. | Fixed |
| F12 | Needs evidence | Confinement | Canonical ancestor check and publication are separate path operations; concurrent adversarial replacement remains possible by source inspection. | Document stable-workspace trust boundary; preserve upstream review finding. | Open; no race exploit claimed |
| F13 | P1 | Generated config | Workspace names were inserted into TOML without escaping; normalized names could collide. | Serialize names/paths as data, parse generated TOML before writing; quote/collision smoke tests. | Fixed |
| F14 | P2 | Diagnostics | Kahn remainder includes downstream nodes; forward walk could return a sink as the cycle. | Walk predecessors and reverse the closed witness; sink regression. | Fixed |
| F15 | P2 | Cache lifecycle | Cache retains stale entries and is not authenticated; adapter fingerprint covers argv, not executable contents. | Document trusted cache; preserve cold mode; defer versioned lifecycle/adapter identity design. | Open |
| F16 | P2 | Explain parity | explain still uses built-in extraction/basic resolution and does not explain all adapter/Go/external/ignore decisions used by check. Source-supported pre-existing divergence. | Preserve established explanation fields/decision meanings pending a shared decision contract and compatibility tests. | Deferred |
| F17 | P2 | Output efficiency | Quiet/summary modes still construct the full report before suppressing display. | Preserve validation and max_report_bytes semantics; no speculative renderer shortcut. | Deferred; profile separately |

## Implemented changes and compatibility

- **Selection and traversal** — src/git.kujo, src/cmd_check.kujo, src/walk.kujo:
  corrected a false-pass boundary, eliminated provably useless traversal, and
  bounded directory-cycle behavior. Tests cover full/changed report equivalence,
  staged/untracked quoted Unicode paths, empty excludes, excluded collection
  counts, duplicate roots, and actual cycle diagnostics. Existing include/glob
  syntax remains intact; selected regular-file ordering remains deterministic.
- **Policy and input boundaries** — src/config.kujo, src/ignores.kujo,
  src/analyze.kujo, src/cache.kujo, src/parser_adapters.kujo: correct defaults,
  validate disposable/untyped inputs, preserve language-dependent resolution,
  and enforce import limits during work. Tests cover malformed cache records,
  config shapes, ignored nested paths, mixed-language imports, and budget errors.
  No cache format/version or public config key was added. Invalid cache records
  are re-extracted. Authenticated source equivalence is not promised for a
  deliberately forged structurally valid cache.
- **Failure and publication** — src/output.kujo, src/paths.kujo,
  src/reports.kujo, src/cmd_baseline.kujo, src/cmd_graph.kujo: atomic writes,
  actionable exceptions, failed incomplete checks, protected adoption state,
  and valid machine output. Regression cases preserve original file contents,
  check IO code 5, parse baseline JSON, and reject failed-adapter scans/artifacts.
- **Generated policy and diagnostics** — src/cmd_workspace.kujo and
  src/cycles.kujo: quote generated TOML, reject collisions before writing,
  and provide a real closed cycle rather than a downstream path. Existing zone
  name normalization is retained; ordinary config semantics remain identical.
- **Regression infrastructure** — fence.toml, tests, benchmark, release script,
  and workflows: complete self-policy coverage, expanded source/script lint,
  correct --kujo option validation and forwarding to the shell harness, immutable
  runtime source pin, and deterministic traversal-count ratchet. Existing
  conformance, JSON/SARIF fixtures, replay-free/offline tests, and six example
  gates remain enabled. No assertion or gate was weakened.

Public exported function signatures and output object schemas are preserved;
only private helpers changed signatures. Commands and flags are preserved.
Intentional bug-fix behavior changes: incomplete checks report failed/exit 4;
malformed config containers fail during config load (3); failed writes map to
IO 5; ambiguous workspace zone names fail before writing (2); default severity
and ignores now follow their documented configuration. Directory cycles/errors
abort rather than silently passing or looping. Non-file special entries are
not read. Identical roots no longer double-count findings. JSON/SARIF suppression
footers are removed so existing machine parsers work. No environment variable
or file format version changed. Consumers relying on false passes must honor
these corrected exits; ordinary valid reports retain their existing keys.

## Performance and efficiency

Both measurements used Kujo 1.2.3 on the same concurrently loaded host. Single
samples are reproducible receipts, not portable speed guarantees or isolated
CPU comparisons. The original 1,600-file harness ran before source changes.
The pruning harness was run against src from the exact starting commit and
against the final walker with the same generated layout.

| Workload / metric | Before | After |
|---|---:|---:|
| Pruning fixture: generated files | 1,100 | 1,100 |
| Collected paths retained for filtering | 1,100 | 100 |
| Selected files | 100 | 100 |
| Traverse + filter | 27,267.66 ms | 2,155.51 ms |
| Standard scale: selected files/imports/violations | 1,601 / 1,600 / 0 | 1,601 / 1,600 / 0 |
| Standard scale: total scan | 224,839.63 ms | 156,138.11 ms |
| Standard scale: resolution hits/misses | 1,599 / 1 | 1,599 / 1 |
| Standard scale: zone hits/misses | 1,600 / 1,601 | 1,600 / 1,601 |
| Fence package dependencies | 0 | 0 |

The attributable structural improvement is 1,000 fewer retained paths in the
excluded-tree fixture (90.9% fewer), with identical selected paths. The much
larger all-included scan's timing change cannot be attributed to this patch
because CPU contention varied; its counts and cache behavior are equivalent.
No RSS, allocation-byte, build-time, binary-size, or model-token saving is claimed.
Fence is shipped source, and source is still buffered per file. Caches, rendered
reports, and configuration composition can allocate before applicable checks.
There is no new cache policy or hidden truncation.

Agent/context review found no prompt dispatch or tool-schema surface to shrink.
Existing focused documentation and quiet/summary/file-output modes are useful;
this pass keeps detailed evidence on disk, ensures machine JSON is parseable,
and adds a focused audit reference. It does not claim model-token reductions.
No speculative dependency replacement, exported-code deletion, or cosmetic
refactor was justified. Sequential sharding remains unchanged.

## Security and state review

Reviewed CLI refs, repository paths/names, config composition, imports, adapter
argv/results, cache input, file publication, baseline suppression, resource
ceilings, and release build inputs. No new network call, credential read, shell
interpolation, package dependency, or provider coupling was introduced.

Atomic publication prevents partial output visibility and delete-before-write
loss. Concurrent cache writers can still overwrite each other's acceleration
entries (last complete writer wins); cold extraction remains available. Config,
source and adapter state can change during a scan; no repository snapshot or
hostile-filesystem sandbox is claimed. Extending that guarantee requires native
handle-relative IO or external isolation. Cache size/expiry and adapter executable
identity need an explicit compatibility/invalidation design. Best-effort language
extraction remains best-effort, with optional trusted parser adapters.

Human/Markdown/DOT/Mermaid text escaping and exact AST/manifest fidelity are not
certified by this review. Use structured JSON for machine ingestion. Source
paths are potentially sensitive even though Fence does not inspect secrets.

## Cross-repository follow-ups and remaining work

- **Kujo / F12, needs more evidence:** consider descriptor-relative no-follow
  publication if Fence must operate with hostile concurrent filesystem writers.
  Evidence: output.kujo validates an ancestor, then calls path-based atomic write.
  Current trusted local operation does not require a runtime change. Preserve
  minimum-runtime compatibility and platform semantics before adopting new APIs.
- **PackWrite, existing duplicate:** docs/consumer-contract-matrix.md records an
  entrypoint/src module-resolution collision. Existing SignalBox capture
  cap_a977e928-51ea-4b88-b6ac-fdbdc86ccf71 and signal
  sig_d6bb0676-05f8-494f-933d-eb9934fa2b84 already cover it. Not re-created or
  presented as freshly reproduced; no current Fence fix depends on it.
- **P0:** no known introduced failure remains.
- **P1:** no additional verified release-blocking defect is claimed; this is not
  certification of absence of vulnerabilities.
- **P2:** F15 cache lifecycle/executable identity, F16 explanation parity,
  F17 conditional rendering; shared decision/validation design needs follow-up.
- **P3 / not worth changing:** cosmetic layout, duplicate tiny extraction helpers
  across architectural layers, established source-only dependency packaging.
- **Needs more evidence:** adversarial races, independent memory profiling,
  uncontended timing samples, live Linux/Windows and minimum-runtime CI results.
  Local verification is macOS/Kujo 1.2.3. Existing CI still tests pinned 1.0.1;
  this report does not claim that remote run has passed.

## Verification receipt

Commands were run from Fence unless a different directory is stated; PATH
included /Users/robertdevore/.local/bin. Captured outputs are in receipts/.

| Exact command | Result |
|---|---|
| kujo --version | 1.2.3 |
| kujo run scripts/verify_release.kujo | Baseline and final PASS; static checks, full suite, CLI smoke, self validation/check, six examples, artifact generation |
| kujo run tests/fence_tests.kujo | 243 passed, 0 failed |
| sh tests/cli_smoke.sh | 52 passed, 0 failed |
| kujo run fence.kujo -- graph | PASS; baseline graph retained |
| kujo run fence.kujo -- check --format json | PASS; final self-policy governs every module |
| kujo run benchmarks/fence_benchmark.kujo -- --files 1600 | Before/after PASS, equivalent counts and cache metrics |
| kujo run benchmarks/pruning_benchmark.kujo | PASS; 100 selected, 100 collected after pruning |
| kujo run benchmark.kujo (starting-src snapshot in .audit-evidence/tree-before) | PASS; same pruning harness, 100 selected, 1,100 collected |
| kujo check src/git.kujo; kujo check src/output.kujo; kujo check src/cmd_check.kujo; kujo check src/walk.kujo; kujo check src/config.kujo; kujo check src/cmd_workspace.kujo; kujo check src/cycles.kujo; kujo check benchmarks/pruning_benchmark.kujo | Targeted checks PASS; expanded release gate checks all sources |
| sh -n tests/cli_smoke.sh fence.sh | PASS |
| bash .github/scripts/check-kujo-tool-artifacts.sh | PASS |
| git diff --check | PASS |

No build, Rust lint, model-token test, network E2E, or server check applies to
Fence itself. Remote consumer execution was not rerun because the documented
workflow stages files in sibling repositories; local versioned contract fixtures
and renderer tests ran without expanding write scope. No release/tag was made.

## Durable records

Strata consolidation: one session handoff/current-state note in Agent Notes,
3d5ad346-b262-4c00-91ea-a6dc553900a0 (Session Memory · Fence · Repository
hardening · 2026-09-07). Exact lookup and conceptual search passed. It preserves
verified implementation provenance, corrected contracts, measured path counts,
and the next audit starting points; no duplicate atomic recap was created.
The create request returned an error after saving; exact-ID retrieval confirmed
the record, so the write was not retried.
SignalBox: one Fence-specific source-supported F12 capture
cap_ef12bf13-f5bc-44af-8ecb-9e8f313f21c8 and review signal
sig_761544f9-4032-4305-928f-d2b4f232a05b. Both verified by exact ID; concept
searches returned the capture and signal. Related CaseFile evidence was linked, not copied.
The existing PackWrite finding was skipped as a duplicate. Completed fixes,
normal verification, raw logs, and implementation recaps were rejected as
SignalBox candidates. F15-F17 remain in this scoped audit as design follow-ups.

## Follow-up status

The user-requested remaining-work pass resolves F15-F17. Read
[the follow-up audit](remaining-hardening.md) for current status, compatibility
changes and new receipts. F12 remains an explicit native-runtime dependency;
this original report retains its historical baseline and findings.
