# Contributing

Thanks for helping improve this Kujo ecosystem project.

This guide is intended for standalone Kujo tools and primitives. It does not
cover the core Kujo language repo, Kujo Skills, or Kujo Workflows when those
projects have their own contribution rules.

## Development Principles

- Keep changes focused, reviewable, and tied to one user-visible concern.
- Prefer deterministic, local-first behavior.
- Do not add network calls, provider calls, timestamps, or machine-specific
  output to core command paths unless the feature explicitly requires it.
- Preserve redaction, path safety, guarded cleanup, and stable output ordering.
- Add tests for behavior changes. Bug fixes should include regression coverage.
- Avoid speculative refactors unless they directly simplify the change at hand.

For Fence specifically:

- Keep tool code in `.kujo`; scanned languages are not implementation languages.
- Preserve deterministic, local-first behavior with no network calls.
- Preserve path-safe `--output` handling and safe `--changed-only --base`
  validation.
- Keep functions small and call chains shallow.

## Local Setup

Use the Kujo runtime expected by this repository. Most repos support one of
these environment variables:

```bash
export KUJO_BIN=/path/to/kujo
export KUJO=/path/to/kujo
```

Fence entry points:

```text
fence.kujo
fence.sh
```

Project layout:

```text
fence.kujo              CLI entry point
src/*.kujo              implementation modules
tests/fence_tests.kujo  test harness
docs/                   documentation
agent/                  ignored historical planning artifacts
```

Check the repo README, `Makefile`, `tests/`, and `scripts/` directory for the
authoritative local commands.

## Agent And Example Hygiene

Start with `README.md`, `CONTRIBUTING.md`, relevant docs, and examples before
broad source sweeps.

Treat user-facing examples as canonical copyable surfaces. Examples should be
short, runnable, and representative of the idioms humans and agents should copy.

For Fence, start with `README.md`, this file, and the focused page under
`docs/` that matches the task. Treat `agent/**` as archived implementation
history, not canonical usage examples.

Exclude generated and bulk paths from broad searches unless the task explicitly
targets them. For normal cleanup work, skip `tests/fixtures/**`, generated
reports such as `FENCE_REPORT.md`, `fence-baseline.json`, `*.sarif`, and
archived planning files under `agent/**`.

```bash
rg "pattern" README.md docs src tests fence.kujo \
  -g '!agent/**' -g '!MEGA_PROMPT.md' -g '!tests/fixtures/**' \
  -g '!FENCE_REPORT.md' -g '!fence-baseline.json' -g '!*.sarif'
```

Document any important search exclusions in larger cleanup or audit PRs.

## Code Standards

- Match the surrounding code style before introducing a new abstraction.
- Keep command output readable and stable.
- Prefer small local helpers for repeated output, error, section, or key/value
  formatting once repetition distracts from the behavior.
- Keep CLI contracts explicit: flags, exit codes, JSON fields, artifact paths,
  and documented examples should agree with parser behavior.
- Keep config honest. A config key should either change observable behavior or
  be clearly documented as reserved.
- Preserve compatibility entrypoints and wrappers when a repo provides them.
- When editing docs or examples, keep command blocks short, runnable, and paired
  with representative output when that output clarifies success or failure.

## Kujo Runtime Notes

Kujo ecosystem tools often follow these defensive patterns:

- Prefer `while` loops in complex functions.
- Avoid duplicate local names across branches in the same function.
- Keep imports at the top of the file.
- Export functions that are imported by another module.
- Guard dictionary access with `has_key()` or local helper wrappers.
- Remember that some builtins return int-like `1`/`0` instead of booleans.
- Guard parsing operations such as JSON or TOML parsing and validate the result.
- Keep deep tree walks iterative where recursion risks VM stack limits.
- Be careful with byte-based string indexes versus character-based substring
  operations; use existing repo helpers when available.

Fence source has stricter VM rules:

- Use `while` loops; at most one `for` per function.
- Do not use duplicate `let` names across `if` branches in one function.
- Imports are `from src.x import name`; do not call qualified `src.x.f()`.
- Export imported functions with `export func`.
- Read `ProcessResult` fields via dot access, such as `r.success`.
- `has_key(...)` and string `contains(...)` return `1`, not `true`; use
  `dict_has` and `truthy` from `util.kujo`.
- Multi-line strings use `\n`; escape quotes with `\"`.
- `pop(a)` returns `[new_array, element]`.
- Tree walks must be iterative, never recursive.
- Keep call chains flat, around six user frames or fewer.

## Validation

Before opening a pull request, run the strongest local validation available for
the repo.

Fence development loop:

```bash
KUJO=/path/to/kujo

# Lint every source file you touched.
$KUJO check src/<file>.kujo

# Run the full test suite.
$KUJO run tests/fence_tests.kujo
```

Smoke-test behavior against a scratch repo when command behavior, config
templates, resolution, output formats, or path safety changes:

```bash
TMP="$(mktemp -d)"
cp -r tests/fixtures/sample/src "$TMP"/
cd "$TMP"
$KUJO run /path/to/fence/fence.kujo -- init
$KUJO run /path/to/fence/fence.kujo -- check --format json
```

Every behavior change needs matching assertions in `tests/fence_tests.kujo`.
Tests should stay offline and deterministic unless the repo explicitly marks a
live-provider or network test as opt-in.

## Documentation And Changelog

Update docs when behavior, configuration, command output, flags, schemas,
examples, or security expectations change.

For Fence source changes, check:

- `README.md`
- `docs/getting-started.md`
- `docs/commands.md`
- `docs/configuration.md`
- `docs/ci.md`
- `docs/architecture.md`
- `docs/ENHANCEMENTS.md`
- examples
- `CHANGELOG.md`

User-visible behavior changes should include a changelog entry when the repo has
a changelog.

## Pull Requests

A good PR includes:

- Problem statement.
- Change summary.
- User-visible impact.
- Test evidence with commands and outcomes.
- Documentation or changelog updates.
- Known risks or follow-up work, if any.

Keep generated artifacts out of commits unless the artifact is the reviewed
output of the change.

## Adding A Language Extractor

Follow the steps in
`docs/architecture.md#adding-a-language-extractor`.
