# Fence Enhancement Checklist

An agent-executable backlog for taking Fence from a working v1 to an
enterprise-grade release. Each task is self-contained: it states the **goal**,
the **files** to touch, the **approach**, and **acceptance criteria** an agent
or reviewer can verify.

## Ground rules (read first)

- Implementation stays **Kujo-only** (`.kujo` files). No Rust/JS/Python/Go/PHP in
  the tool itself; an optional one-line shell wrapper is the only exception.
- Use the local Kujo binary at `kujo`.
- Validate every change: `kujo check <file>.kujo` for each touched file, and
  `kujo run tests/fence_tests.kujo` (must stay green; add assertions for new code).
- Respect Kujo VM quirks already encoded in this repo (see `agent/DECISIONS.md`
  D4 and the Fence memory note): `while` loops only (no >1 `for` per function);
  unique `let` names per function (no reuse across `if` branches); `from src.x
  import name` imports (no qualified `src.x.f()`); `export func` for exports;
  ProcessResult via dot (`r.success`); never compare `has_key(...) == true`
  (returns `1`) — use `dict_has`/`truthy`; multi-line strings use `\n` and `\"`;
  `pop(a)` returns `[newarr, elem]`; tree walks stay iterative.
- Keep output deterministic (no timestamps, stable ordering) and local-first
  (no network).
- Commits (if any) must be authored solely under the `robertdevore` account with
  **no** AI/assistant references.

---

## A. Fix known limitations

- [x] **A1. Multi-line Python imports.** `from foo import (\n a,\n b,\n)` is not
  detected today.
  - Files: `src/imports.kujo` (`extract_python`).
  - Approach: when a `from ... import (` line opens an unclosed paren, set an
    "in import block" flag (like the Go block handler in `imports_ext.kujo`) and
    keep the record; the module path is already captured from the opening line.
  - Acceptance: a fixture `.py` with a parenthesized multi-line import yields one
    `from` record with the correct path; add a test assertion.

- [x] **A2. Multi-line / grouped JS-TS imports & comment stripping.** Imports
  inside `/* ... */` or `//` comments can produce false positives; bare
  `export ... from "x"` re-exports are missed.
  - Files: `src/imports.kujo` (`extract_javascript`).
  - Approach: skip lines whose import-ish token is preceded by `//`; add an
    `export ... from "x"` pattern; keep it line-based and documented as
    best-effort.
  - Acceptance: fixtures covering a commented-out import (ignored) and an
    `export { x } from "./x"` (detected); tests added.

- [x] **A3. Richer glob support (`?`, single-char, multiple `*` per segment).**
  - Files: `src/glob.kujo` (`segment_match`).
  - Approach: generalize `segment_match` to a small backtracking matcher over a
    segment supporting `*` (multiple) and `?` (one char). Keep `**` handling as-is.
  - Acceptance: new tests for `src/a?c.ts`, `src/*a*b.ts`; existing glob tests
    still pass; README "Limitations" updated.

- [x] **A4. Canonical-ish output path safety.** Current safety is textual.
  - Files: `src/paths.kujo` (`is_safe_output`), `src/output.kujo`.
  - Approach: if/when the Kujo runtime exposes a canonical/realpath helper, add a
    post-resolution check that the absolute target is still under
    `os_getcwd()`. Until then, additionally reject symlinked parent dirs where
    detectable. Document whichever guarantee is achievable.
  - Acceptance: a test proving a symlink-escape attempt is rejected (or a
    documented note that the VM cannot detect it yet).

- [x] **A5. Validate-time overlapping-zone warning.** Multiple zones matching one
  file is only surfaced in `explain`.
  - Files: `src/validate.kujo`, optionally `src/cmd_validate.kujo`.
  - Approach: Fence cannot know real files at validate time, but it CAN flag
    zones whose `paths` patterns are provably overlapping (identical or
    prefix-subsumed globs). Emit a `warning` diagnostic.
  - Acceptance: a config with two zones sharing `src/ui/**` produces a warning;
    test added.

- [x] **A6. Config schema version guard.** `version` is read but not enforced.
  - Files: `src/validate.kujo`.
  - Approach: warn when `version != 1`; reserve behavior for future schema bumps.
  - Acceptance: `version = 2` yields a clear warning; test added.

---

## B. Future-work features (from README "Future extension points")

- [x] **B1. Baseline adoption (`baseline create` + `check --baseline`).** Let
  existing repos adopt Fence without failing on pre-existing violations.
  - Files: new `src/baseline.kujo`, new `src/cmd_baseline.kujo`, wire into
    `src/cli.kujo`, extend `src/cmd_check.kujo`.
  - Approach: `baseline create` writes a deterministic `fence-baseline.json` of
    current violation fingerprints (zone-from/zone-to/file/import). `check
    --baseline` subtracts baselined fingerprints; NEW violations still fail.
  - Acceptance: create baseline on a violating repo → `check --baseline` exits 0;
    introduce a new violation → exits 1; tests with fixtures.

- [x] **B2. External dependency allow/deny lists.** Today externals are never
  violations.
  - Files: `src/config.kujo` (parse `[external]` allow/deny), `src/rules.kujo`,
    `src/analyze.kujo` (`judge`).
  - Approach: optional `[external] deny = ["axios", ...]` / `allow = [...]` with
    per-zone overrides; an external import matching a deny entry becomes a
    violation with severity from config.
  - Acceptance: config that denies `lodash` flags a `ui` file importing it;
    tests + README config section.

- [x] **B3. Dependency-cycle detection between zones.** Catch `a→b→a` allowed-edge
  cycles in `fence.toml`.
  - Files: new `src/cycles.kujo`, surfaced via `validate` and/or `graph
    --cycles`.
  - Approach: build the allowed-edge graph (`graph.build_edges`) and run an
    iterative DFS/Tarjan (no recursion — explicit stack) to report cycles.
  - Acceptance: a cyclic config reports the cycle path; acyclic reports none;
    tests added.

- [x] **B4. SARIF output (`check --format sarif`).** For code-scanning
  integrations.
  - Files: `src/reports.kujo` (add `render_sarif`), `src/cmd_check.kujo`.
  - Approach: emit minimal SARIF 2.1.0 JSON via `to_json_pretty` (rules +
    results with `physicalLocation`). Keep deterministic.
  - Acceptance: output validates against the SARIF schema shape; golden-string
    test asserts key fields.

- [x] **B5. More framework templates.** e.g. `hexagonal`, `mvc`, `feature-sliced`.
  - Files: `src/templates.kujo`, `src/cmd_init.kujo` (`template_by_name`),
    `src/meta.kujo` help text.
  - Acceptance: each new `init --template <name>` produces a config that
    round-trips through `parse_toml` and passes `validate`; tests added.

- [x] **B6. `check --quiet` / `--summary-only` and `--no-color` flags.** CI
  ergonomics.
  - Files: `src/cmd_check.kujo`, `src/reports.kujo`, `src/meta.kujo`.
  - Acceptance: `--quiet` prints only the status line + exit code; documented.

- [x] **B7. Ecosystem integration hooks.** Stable JSON contract consumed by
  Scout/Eval/PackWrite/ShipCheck.
  - Files: `docs/JSON_SCHEMA.md` (new), no behavior change.
  - Approach: freeze and document the `check --format json` schema with a
    `schema_version` field; add it to the JSON output.
  - Acceptance: schema doc exists; `version`/`schema_version` present and tested.

---

## C. Docs / README — enterprise-grade polish

- [x] **C1. Top-of-README badges & identity.** Add a title banner, one-line
  tagline, and status badges (build, tests-passing, license, Kujo version).
  Use static shields-style markdown (no live network calls required to render).
  - Files: `README.md`, `docs/README.md`.
  - Acceptance: README opens with project name, tagline, badge row, and a
    1-paragraph "what/why".

- [x] **C2. Table of contents + consistent heading hierarchy.** Add an anchored
  TOC; ensure a single H1 and logical H2/H3 nesting throughout.
  - Files: `README.md`, `docs/README.md`.

- [x] **C3. Copy-paste-safe examples & expected output blocks.** Every command
  example should show representative output. Verify each example actually runs
  against `tests/fixtures/sample`.
  - Files: `README.md`.
  - Acceptance: a reviewer can paste each block and get the shown result.

- [x] **C4. Dedicated docs set.** Split the monolithic README into
  `docs/` pages: `getting-started.md`, `configuration.md`, `commands.md`,
  `ci.md`, `json-schema.md`, `architecture.md`, `faq.md`, `troubleshooting.md`,
  with the root README as a concise landing page linking out.
  - Files: new `docs/*.md`, trimmed `README.md`.

- [x] **C5. CONTRIBUTING + module map.** Document the 26-module layout, the Kujo
  VM gotchas (lift from `agent/DECISIONS.md` D4), how to add a language extractor,
  and how to run/extend tests.
  - Files: new `CONTRIBUTING.md`, `docs/architecture.md`.

- [x] **C6. LICENSE, SECURITY.md, CODE_OF_CONDUCT.md, CHANGELOG.md.** Standard
  enterprise/OSS hygiene files. Seed `CHANGELOG.md` with a `1.0.0` entry.
  - Files: repo root.

- [x] **C7. Visual assets.** Add a Mermaid architecture diagram of the zone model
  and a sample `graph --format mermaid` render embedded in the docs.
  - Files: `docs/architecture.md`.

- [x] **C8. "Why deterministic guardrails for agents" narrative.** A short,
  polished section aimed at engineering leaders (risk, drift, CI gating).
  - Files: `README.md` or `docs/getting-started.md`.

---

## D. Testing, CI & release hardening

- [x] **D1. Expand the test harness.** Add assertions for every new feature above
  and for currently-thin areas: markdown/human renderer golden strings, `doctor`
  fields, `graph` dot/json output, exclude-pattern behavior, alias edge cases.
  - Files: `tests/fence_tests.kujo`, more under `tests/fixtures/`.
  - Acceptance: assertion count grows; all green; no flakiness across 3 runs.

- [x] **D2. CLI exit-code integration tests.** A small Kujo/shell harness that
  invokes `fence.kujo` for each command and asserts exit codes (0/1/2/3/5).
  - Files: new `tests/cli_smoke.sh` (the one allowed shell wrapper) or a
    `tests/fence_cli_tests.kujo` that shells out via `execute_status`.
  - Acceptance: documented `make test` / single command runs unit + CLI tests.

- [x] **D3. CI workflow doc + script.** Provide a ready-to-use CI snippet
  (build/obtain Kujo, run `kujo check` on all sources, run tests, run
  `fence check --fail-on error`). Keep it provider-neutral plus one concrete
  example.
  - Files: `docs/ci.md`, optional `.github/workflows/fence.yml` example (YAML
    config, not an implementation language — allowed).

- [x] **D4. Self-dogfood config.** Add a `fence.toml` describing Fence's own
  module zones (e.g. `cli`, `commands`, `core`, `io`, `shared`) and make
  `fence check` pass on its own `src/` tree; wire into CI.
  - Files: new root `fence.toml`, possibly minor import adjustments.
  - Acceptance: `kujo run fence.kujo -- check` is clean on this repo.

- [x] **D5. Determinism guard.** A test that runs `check --format json` twice and
  asserts byte-identical output.
  - Files: `tests/fence_tests.kujo` or `tests/cli_smoke.sh`.

- [x] **D6. Performance smoke.** Generate a large synthetic tree (e.g. 1–2k files)
  and confirm `check` completes without VM stack overflow or quadratic blowup;
  record timing in `docs/`.
  - Acceptance: documented run on N files; note any call-depth/limits hit.

---

## E. Code quality / robustness

- [x] **E1. Centralize ProcessResult & predicate helpers.** Audit for any
  remaining `has_key(...) == true`, string `contains(...) == 1`, or bracket
  access on ProcessResults; route through `util.dict_has`/`truthy`.
  - Files: all `src/*.kujo`. Acceptance: grep shows no fragile comparisons.

- [x] **E2. Graceful IO error handling.** Wrap `read_file`/`list_dir` in
  `try/except` so an unreadable file warns-and-skips instead of aborting `check`.
  - Files: `src/walk.kujo`, `src/imports.kujo`, `src/analyze.kujo`.
  - Acceptance: a permission-denied fixture (where feasible) is skipped with a
    warning; exit code unaffected.

- [x] **E3. Consistent diagnostics object.** Unify the `{ok,error,code}` result
  shape used across `config`, `output`, `git`, and command modules into one
  documented convention.
  - Files: cross-module; document in `docs/architecture.md`.

- [x] **E4. `--version`/`fence_version()` single source of truth.** Ensure the
  version string in `src/meta.kujo` is the only place a version is defined and is
  reflected in JSON/SARIF output and CHANGELOG.

---

## How to verify the whole suite after changes

```bash
KUJO=kujo
# 1) lint every source file
for f in fence.kujo src/*.kujo tests/*.kujo; do $KUJO check "$f"; done
# 2) unit tests (must stay green; add assertions for new code)
$KUJO run tests/fence_tests.kujo
# 3) end-to-end smoke in a scratch repo (the sample fixture has no fence.toml)
TMP=$(mktemp -d) && cp -r tests/fixtures/sample/src "$TMP"/ && cd "$TMP"
$KUJO run /path/to/kujo-fence/fence.kujo -- init
$KUJO run /path/to/kujo-fence/fence.kujo -- check --format json
```

> Note: `tests/fixtures/sample/` intentionally has no `fence.toml` (the unit
> tests build configs in-memory). Task **D4** adds a real `fence.toml` for
> dogfooding Fence on its own source tree.

When all three are clean and the relevant checklist boxes are ticked with
matching tests, the enhancement is done.
