# Changelog

All notable changes to Fence are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Remaining audit work (2026-09-07)
- Bounded disposable built-in caches to 4 MiB and 10,000 records; compacted
  retention to files visited in the current scan and preserved all shards.
  Hashing and extraction now use one source snapshot. Custom adapters always
  execute, so changes outside their argv cannot reuse stale results.
- Shared check/explain dependency decisions, including Go modules, external
  policy, active ignores, and configured adapters. Explain import rows add
  confidence, ignored, ignore_reason, and ignore_expires. Invalid formats/configs
  fail with exit 2; failed extraction or import ceilings fail with exit 4.
- Quiet/summary checks skip unused report bodies while preserving output files,
  configured report limits, format validation, and exit codes.

### Repository hardening (2026-09-07)
- Fixed changed-only scans with empty excludes and preserved quoted, Unicode,
  and whitespace-containing Git paths using structured argv and NUL records.
  Incomplete Git output now fails instead of silently omitting source files.
- Pruned fully excluded subtrees, deduplicated identical roots, rejected directory
  symlink cycles, and made directory traversal errors fatal.
- Incomplete checks now return runtime exit 4 and failed status while retaining
  skipped-file evidence; baseline and observed-graph generation refuse incomplete scans.
- Made report/cache/baseline writes atomic and mapped write failures to IO exit 5.
- Validated config containers and cache import records before use; hardened adapter
  output checks and confined cache-file symlinks as well as its directory.
- Fixed default-severity inheritance, omitted-file ignore matching, and mixed-language
  resolution-cache identity. JSON/SARIF baseline reports remain a single JSON object.
- Escaped generated workspace TOML and rejected normalized zone collisions before
  writing; cycle witnesses now omit nodes merely downstream of a cycle.
- Added cache and adapter modules to self-policy coverage, with an all-module gate.
- Enforced import ceilings during analysis, pinned CI runtime source to the existing
  v1.0.1 commit, and added behavioral and traversal regression gates.

### Enterprise hardening
- Added opt-in output-root confinement and file/import/UTF-8 report resource
  limits with deterministic runtime failures.
- Added unreadable-source diagnostics across human, JSON, Markdown, and SARIF.
- Added reasoned, expiring structured ignores that remain visible in reports.
- Added manifest-backed `workspace init`, observed-edge graph comparison, and
  safe `baseline prune` maintenance.
- Added JavaScript/TypeScript multiline imports, nested Rust groups, grouped PHP
  namespaces, and Go module-prefix resolution.
- Added versioned JSON/SARIF fixtures and passing/failing CLI, web-app, and
  monorepo examples.
- Added a Kujo-native scale harness with 1,600- and 10,000-file evidence.
- Added deterministic checksum, SPDX SBOM, and in-toto/SLSA provenance generation.
- Added opt-in content-digest import caching with explicit schema, extractor,
  and parser-adapter invalidation.
- Added trusted offline parser adapters, versioned six-language conformance
  fixtures, and `exact`/`best_effort` confidence in JSON and SARIF.
- Added local-only config composition with cycle/depth/path confinement, zone
  owners, and `ignores list/check` governance gates.
- Added Kennel package metadata, keyless release attestations, and native
  Linux/Windows release verification.

### Fixed
- Reject invalid `--fail-on` overrides and malformed baseline schemas instead
  of silently passing or misapplying them.
- Correct JavaScript import-string selection and imports following inline block
  comments, Go aliased single imports, and PHP `__DIR__` includes.
- Resolve Rust `mod`, `self::`, and `super::` paths relative to their declaring
  modules, and prefer the longest matching configured alias prefix.
- Report actionable shallow-checkout guidance when a changed-only base is not
  available locally.

### Added
- Launch readiness spec and deterministic Eval suite for prelaunch review evidence.
- Python grouped imports such as `import os, package.module as alias` now emit
  one dependency record per imported module.
- Tests cover grouped Python imports, leading-dash Git refs, and `.git/` output
  paths.
- Import and violation records carry one-based source lines; SARIF locations now
  include `region.startLine`.
- Added the `monorepo` starter template for `apps/`, `packages/`, and `tools/`.
- Rust grouped `use` statements and root-qualified PHP namespaces are detected.

### Performance
- Memoize import resolution and zone classification within each analysis run to
  avoid repeated filesystem probes and glob matching while preserving contextual
  relative-import semantics.
- Profile traversal and glob filtering separately and establish deterministic
  shard/merge semantics for future native Kujo concurrency.

### Security
- `--changed-only --base` now rejects refs beginning with `-` to prevent Git
  option injection.
- Git refs also reject ambiguous ranges/reflogs, repeated slashes, `.lock`
  suffixes, and trailing dots/slashes.
- Report output paths now reject `.git` path segments in addition to existing
  absolute-path, home, parent-traversal, and symlink-parent escape guards.

### Documentation
- Moved local implementation prompt history under the ignored `agent/` archive
  and updated the public project layout/docs to keep the root production-focused.
- Added a runnable demo, enterprise adoption guide, release checklist, and a new
  production-readiness backlog.

## [1.0.0] - 2026-06-10

### Added
- Multi-line Python import detection and JS/TS comment-aware extraction
  (commented-out imports are ignored; `export ... from` re-exports detected).
- Richer glob matching: `?` single-character wildcard and multiple `*` per
  segment (iterative, UTF-8-safe matcher).
- Canonical output-path safety: symlinked-parent escapes are now rejected.
- Validation: overlapping zone-path warnings, dependency-cycle detection
  (`validate` and `graph --cycles`), and an unsupported config-version warning.
- External dependency allow/deny lists (`[external]`, plus per-zone
  `external_allow`/`external_deny`).
- New `init` templates: `hexagonal`, `mvc`, `feature-sliced`.
- `check --format sarif` (SARIF 2.1.0 output).
- `check --quiet`, `--summary-only`, and `--no-color`.
- Baseline adoption: `baseline create` + `check --baseline`.
- JSON output carries a `schema_version`; documented in `docs/JSON_SCHEMA.md`.
- Enterprise docs set: getting-started, configuration, commands, CI, FAQ,
  troubleshooting, architecture; plus `CONTRIBUTING`, `SECURITY`,
  `CODE_OF_CONDUCT`, `LICENSE`, and this changelog.

## [0.1.0] - 2026-06-02

### Added
- Initial Kujo-native release.
- Commands: `init`, `check`, `explain`, `graph`, `validate`, `doctor`, `help`,
  `--version`.
- `fence.toml` configuration with zones, severities, aliases, and
  `unknown_dependency_policy`.
- Best-effort import detection for Kujo, JavaScript/TypeScript, Python, Rust,
  PHP, and Go.
- Import resolution (internal / external / unknown), zone mapping, and the
  dependency rule engine with deterministic fix suggestions.
- Report renderers: human, JSON, and Markdown (with an AI/Human Handoff section).
- Graph output: human, JSON, DOT, and Mermaid.
- Safe Git integration for `--changed-only` / `--base` with strict ref
  validation.
- Path-safe file output and CI-friendly exit codes.
- Run-mode test harness.
