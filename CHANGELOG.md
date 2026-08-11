# Changelog

All notable changes to Fence are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Reject invalid `--fail-on` overrides and malformed baseline schemas instead
  of silently passing or misapplying them.
- Correct JavaScript import-string selection and imports following inline block
  comments, Go aliased single imports, and PHP `__DIR__` includes.
- Resolve Rust `mod`, `self::`, and `super::` paths relative to their declaring
  modules, and prefer the longest matching configured alias prefix.

### Added
- Launch readiness spec and deterministic Eval suite for prelaunch review evidence.
- Python grouped imports such as `import os, package.module as alias` now emit
  one dependency record per imported module.
- Tests cover grouped Python imports, leading-dash Git refs, and `.git/` output
  paths.

### Security
- `--changed-only --base` now rejects refs beginning with `-` to prevent Git
  option injection.
- Report output paths now reject `.git` path segments in addition to existing
  absolute-path, home, parent-traversal, and symlink-parent escape guards.

### Documentation
- Moved local implementation prompt history under the ignored `agent/` archive
  and updated the public project layout/docs to keep the root production-focused.

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
