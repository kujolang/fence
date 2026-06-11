# Configuration

Fence is configured by a single `fence.toml` at your repo root. A `fence.json`
file with the same shape is accepted as a fallback. Generate a starter with
`kujo run fence.kujo -- init`.

## Full example

```toml
version = 1
source_roots = ["src"]
default_severity = "error"
fail_on = "error"
unknown_dependency_policy = "warn"

[scan]
include = [
  "src/**/*.ts", "src/**/*.tsx", "src/**/*.js", "src/**/*.jsx",
  "src/**/*.py", "src/**/*.rs", "src/**/*.php", "src/**/*.go", "src/**/*.kujo"
]
exclude = ["node_modules/**", "dist/**", "build/**", "**/*.min.js", "**/*.generated.*"]

[aliases]
"@" = "src"
"~" = "src"

# Optional: treat specific third-party packages as forbidden.
[external]
deny = ["lodash"]
allow = []

[zones.ui]
paths = ["src/ui/**", "src/components/**", "src/pages/**"]
can_depend_on = ["domain", "shared"]
cannot_depend_on = ["database", "infra"]
severity = "error"

[zones.domain]
paths = ["src/domain/**", "src/core/**"]
can_depend_on = ["shared"]
cannot_depend_on = ["ui", "http", "database", "infra"]
severity = "error"
```

## Top-level keys

| Key | Type | Default | Meaning |
| --- | --- | --- | --- |
| `version` | int | `1` | Config schema version. Non-`1` produces a warning. |
| `source_roots` | string[] | `["src"]` | Directories Fence walks. |
| `default_severity` | string | `"error"` | Fallback severity for zones without one. |
| `fail_on` | string | `"error"` | Threshold that fails the command: `none`/`warning`/`error`. |
| `unknown_dependency_policy` | string | `"warn"` | What to do with unmappable targets: `allow`/`warn`/`deny`. |

## `[scan]`

| Key | Type | Meaning |
| --- | --- | --- |
| `include` | string[] | Glob patterns a file must match to be scanned. Empty = include all. |
| `exclude` | string[] | Glob patterns that remove files from scanning. `.git` is always skipped. |

Glob support is pragmatic: `**/*.ext` (suffix), `prefix/**` (tree),
`prefix/**/*.ext`, a single `*` or `?` and multiple `*` within one segment.
No `{}`, `[]`.

## `[aliases]`

Maps an import prefix to a real directory. `"@" = "src"` makes `@/domain/user`
resolve as `src/domain/user`. Both exact (`@`) and prefixed (`@/x`) forms work.

## `[external]` (optional)

| Key | Type | Meaning |
| --- | --- | --- |
| `deny` | string[] | Third-party packages that are violations when imported. |
| `allow` | string[] | Packages explicitly allowed (wins over `deny`). |

Matching is by exact name or subpath (`lodash` matches `lodash` and
`lodash/fp`). By default all external packages are allowed. Per-zone overrides
are supported via `external_allow` / `external_deny` inside a `[zones.*]` block.

## `[zones.<name>]`

| Key | Type | Meaning |
| --- | --- | --- |
| `paths` | string[] | Globs that define zone membership. First matching zone wins. |
| `can_depend_on` | string[] | Zones this zone may import from. |
| `cannot_depend_on` | string[] | Zones this zone may **not** import from. |
| `severity` | string | `info` / `warning` / `error` for this zone's violations. |
| `external_allow` | string[] | (optional) zone-scoped external allow-list. |
| `external_deny` | string[] | (optional) zone-scoped external deny-list. |

### Rule precedence

For a dependency `from_zone -> to_zone`:

1. Same zone → always allowed.
2. `to_zone` in `cannot_depend_on` → **violation** (explicit deny wins).
3. `to_zone` in `can_depend_on` → allowed.
4. Otherwise → `unknown_dependency_policy` (`allow` / `warn` / `deny`).

## Severities & thresholds

Violation severities: `info`, `warning`, `error`. The `fail_on` threshold
decides which fail the command:

- `fail_on = "error"` — only error-level violations fail.
- `fail_on = "warning"` — warnings and errors fail.
- `fail_on = "none"` — everything is reported but nothing fails.

Override per-run with `check --fail-on <level>`.

## Validation

`kujo run fence.kujo -- validate` checks for: invalid `fail_on` /
`unknown_dependency_policy` / severities, missing zones, references to undefined
zones, allow/deny conflicts, zones with no paths, **overlapping zone paths**,
**dependency cycles** in allowed edges, and unsupported `version`.
