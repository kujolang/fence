# Fence Next Enhancement Checklist

This is the next-session backlog after the June 19, 2026 hardening review. The
current codebase is strong enough to present as a polished Kujo-native v1, but
these items would make Fence more universally useful in larger enterprise repos.

## Ground rules

- Keep the implementation Kujo-only (`.kujo`) except for the existing shell
  wrapper and test smoke script.
- Preserve deterministic, local-first behavior: no network calls, no timestamps
  in normal reports, stable ordering.
- Validate with:

```bash
KUJO=/Users/robertdevore/2026/Kujolang/kujo-repos/kujo/target/release/kujo
for f in fence.kujo src/*.kujo tests/*.kujo; do $KUJO check "$f"; done
$KUJO run tests/fence_tests.kujo
$KUJO run fence.kujo -- validate
$KUJO run fence.kujo -- check --format json
```

## A. Performance

- [ ] **A1. Import-resolution memoization.**
  - Goal: avoid repeated `file_exists` candidate probes for identical import
    resolution inputs in large repos.
  - Files: `src/analyze.kujo`, `src/resolve.kujo`, `tests/fence_tests.kujo`.
  - Approach: add a per-run cache keyed by current file directory + raw import +
    source roots/aliases shape, or introduce a batch resolver helper that keeps
    cache state in `analyze_files`.
  - Acceptance: tests prove repeated imports return the same result; a synthetic
    performance note shows no regression and preferably lower large-tree time.

- [ ] **A2. Zone-match memoization.**
  - Goal: avoid rematching the same resolved target path against every zone.
  - Files: `src/analyze.kujo`, `src/zones.kujo`.
  - Approach: keep a path-to-zone map during analysis and use it for both source
    files and resolved internal imports.
  - Acceptance: all tests pass; performance smoke records before/after timing.

- [ ] **A3. Changed-only fallback clarity.**
  - Goal: make `--changed-only` easier to use in shallow CI checkouts.
  - Files: `src/git.kujo`, `src/cmd_check.kujo`, `docs/ci.md`.
  - Approach: improve the error when `git diff <base>` fails, including a hint
    to fetch the base ref.
  - Acceptance: invalid/missing base refs still exit `4`, but the message is
    actionable.

## B. Security and robustness

- [ ] **B1. Harden Git ref validation against ambiguous revision syntax.**
  - Goal: keep allowing normal branch/tag refs while rejecting ambiguous or
    surprising revision expressions.
  - Files: `src/git.kujo`, `tests/fence_tests.kujo`, `docs/ci.md`.
  - Approach: consider rejecting `..`, `...`, trailing `.`, trailing `/`, and
    repeated slash after checking which real workflow refs need support.
  - Acceptance: common refs like `origin/main`, `feature/a-b`, `HEAD`, and
    `HEAD^` still work; ambiguous forms are tested and rejected.

- [ ] **B2. Output-path policy modes.**
  - Goal: support stricter enterprise policies without changing defaults.
  - Files: `src/output.kujo`, `src/paths.kujo`, `docs/configuration.md`.
  - Approach: optionally restrict `--output` to configured report directories
    such as `reports/**` or `.fence/**`.
  - Acceptance: default behavior remains compatible; configured restrictions are
    enforced and covered by tests.

- [ ] **B3. Unreadable-file diagnostics.**
  - Goal: make skipped unreadable files visible without breaking local-first
    determinism.
  - Files: `src/imports.kujo`, `src/analyze.kujo`, `src/reports.kujo`.
  - Approach: return skipped-file diagnostics from import detection and include a
    warning count in human/JSON/Markdown output.
  - Acceptance: unreadable files do not crash `check`; reports tell users what
    was skipped.

## C. Functionality

- [ ] **C1. Line numbers for violations.**
  - Goal: make SARIF and human reports jump directly to the import line.
  - Files: `src/imports*.kujo`, `src/reports.kujo`, `docs/JSON_SCHEMA.md`.
  - Approach: add `line` to import records and violation records.
  - Acceptance: JSON/SARIF include stable line numbers; schema version is bumped
    only if the contract requires it.

- [ ] **C2. More language import edge cases.**
  - Goal: reduce false negatives in common enterprise stacks.
  - Files: `src/imports.kujo`, `src/imports_ext.kujo`, tests.
  - Approach: add coverage for Python `import (invalid)` rejection, JS import
    assertions, TypeScript `export * from`, Rust grouped `use foo::{bar,baz}`,
    Go aliased imports, and PHP namespace variants.
  - Acceptance: each added syntax has a focused assertion and documented
    limitations remain honest.

- [ ] **C3. Monorepo preset templates.**
  - Goal: make Fence easier to adopt in workspaces with `apps/*` and
    `packages/*`.
  - Files: `src/templates.kujo`, `docs/getting-started.md`,
    `docs/configuration.md`.
  - Approach: add templates such as `monorepo-apps-packages` and `package-core`.
  - Acceptance: generated configs parse, validate, and appear in help text.

## D. Presentation and adoption

- [ ] **D1. Add a runnable demo transcript.**
  - Goal: let new users see the full value loop in under two minutes.
  - Files: `docs/demo.md`, `README.md`.
  - Approach: use the existing sample fixture and show init, violation, fix, and
    clean output.
  - Acceptance: every command in the transcript is pasteable from a fresh clone.

- [ ] **D2. Create an enterprise adoption guide.**
  - Goal: explain rollout through baseline, changed-only CI, SARIF, and policy
    ownership.
  - Files: `docs/adoption.md`, `README.md`, `docs/README.md`.
  - Approach: include phases for observe-only, baseline, PR gate, and shrinking
    the baseline.
  - Acceptance: a team lead can use it as a rollout plan without reading source.

- [ ] **D3. Add release-readiness checklist.**
  - Goal: make future releases consistent.
  - Files: `docs/release.md`, `CHANGELOG.md`.
  - Approach: capture lint/test/smoke commands, version bump location, changelog
    update, docs checks, and tag/push steps.
  - Acceptance: checklist references only commands that work in this repo.
