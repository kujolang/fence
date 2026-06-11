# Contributing to Fence

Thanks for helping improve Fence. This guide covers the layout, the rules the
Kujo runtime imposes, and how to make a clean change.

## Principles

- **Kujo only.** All tool code is `.kujo`. No Rust/JS/Python/Go/PHP in the
  implementation (those are *scanned* languages). The only non-Kujo shipping
  file is the one-line `fence.sh` wrapper.
- **Deterministic & local-first.** No network, no timestamps, stable ordering.
- **Small functions, shallow calls.** The Kujo VM stack is shallow.

## Project layout

See [docs/architecture.md](docs/architecture.md) for the full module map. In
short: `fence.kujo` is the entry point; `src/*.kujo` are the modules;
`tests/fence_tests.kujo` is the test harness; `docs/` is documentation.

## Development loop

```bash
KUJO=/path/to/kujo           # e.g. kujo on PATH

# 1) lint every source file you touched
$KUJO check src/<file>.kujo

# 2) run the full test suite (must stay green)
$KUJO run tests/fence_tests.kujo

# 3) smoke-test against a scratch repo
TMP=$(mktemp -d); cp -r tests/fixtures/sample/src "$TMP"/; cd "$TMP"
$KUJO run /path/to/fence/fence.kujo -- init
$KUJO run /path/to/fence/fence.kujo -- check --format json
```

Every behavior change needs matching assertions in `tests/fence_tests.kujo`.

## Kujo VM rules you must follow

These are verified runtime/compiler constraints (see `agent/DECISIONS.md` D4):

- Use `while` loops; **at most one `for` per function**.
- **No duplicate `let` names** across `if` branches in one function.
- Imports are `from src.x import name`; **no qualified `src.x.f()`**. Export with
  `export func`.
- `ProcessResult` fields via dot: `r.success`, `r.stdout`.
- `has_key(...)` / string `contains(...)` return `1`, not `true` — use
  `dict_has` / `truthy` from `util.kujo`.
- Multi-line strings use `\n` (no literal newlines); `\"` escapes a quote.
- `pop(a)` returns `[new_array, element]`.
- Tree walks must be iterative (explicit stack), never recursive.
- Keep call chains flat (~6 user frames max).

## Adding a language extractor

Follow the five steps in
[docs/architecture.md#adding-a-language-extractor](docs/architecture.md#adding-a-language-extractor).

## Roadmap

Open work is tracked as an agent-executable checklist in
[docs/ENHANCEMENTS.md](docs/ENHANCEMENTS.md).

## Commits

Keep commits focused and descriptive. Run lint + tests before pushing.
