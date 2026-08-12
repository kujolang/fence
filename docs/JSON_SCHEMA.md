# Fence JSON Output Schema

`kujo run fence.kujo -- check --format json` emits a stable, deterministic JSON
document (no timestamps, sorted keys). This page is the contract that other
tools (Scout, Eval, PackWrite, ShipCheck, CI) may rely on.

## Versioning

The top-level `schema_version` integer identifies the **output contract**;
`version` is the Fence release that produced it. `schema_version` only changes on
a breaking shape change. Consumers should branch on `schema_version` and may
warn on values they do not recognize.

| Field | Meaning |
| --- | --- |
| `schema_version` | Output contract version (currently `1`). |
| `version` | Fence release string (e.g. `"1.0.0"`). |

## Top-level shape

```jsonc
{
  "schema_version": 1,
  "version": "1.0.0",
  "status": "passed" | "failed",
  "summary": {
    "files_scanned": 84,
    "imports_checked": 213,
    "violations": 3,
    "errors": 3,
    "warnings": 1,
    "skipped_files": 0,
    "ignored_violations": 0
  },
  "config": { "path": "fence.toml" },
  "zones": [
    { "name": "ui", "files": 18, "errors": 1, "warnings": 0 }
  ],
  "violations": [
    {
      "severity": "error" | "warning" | "info",
      "from_zone": "ui",
      "to_zone": "database",
      "file": "src/ui/LoginForm.tsx",
      "line": 12,
      "import": "../database/users",
      "resolved": "src/database/users.ts",
      "rule": "zones.ui.cannot_depend_on includes database",
      "message": "ui cannot depend on database",
      "suggestion": "Move database access behind a domain or service code."
    }
  ],
  "skipped_files": [],
  "ignored_violations": []
}
```

## Field reference

### `summary` (object)
| Key | Type | Notes |
| --- | --- | --- |
| `files_scanned` | int | Number of source files analyzed. |
| `imports_checked` | int | Total import statements evaluated. |
| `violations` | int | Total violations (all severities). |
| `errors` | int | Count of `error`-severity violations. |
| `warnings` | int | Count of `warning`-severity violations. |
| `skipped_files` | int | Source files Fence could not read. |
| `ignored_violations` | int | Findings suppressed by active structured exceptions. |

### `zones[]` (array of objects)
| Key | Type | Notes |
| --- | --- | --- |
| `name` | string | Zone name. |
| `files` | int | Files mapped to this zone. |
| `errors` | int | Error violations originating in this zone. |
| `warnings` | int | Warning violations originating in this zone. |

### `violations[]` (array of objects)
| Key | Type | Notes |
| --- | --- | --- |
| `severity` | string | `error`, `warning`, or `info`. |
| `from_zone` | string | Zone of the importing file. |
| `to_zone` | string | Target zone, or `unknown` when unmappable. |
| `file` | string | Repo-relative path of the importing file. |
| `line` | int | One-based line containing the detected import. |
| `import` | string | The import string exactly as written. |
| `resolved` | string | Resolved repo-relative target path, or `""`. |
| `rule` | string | The config rule that produced the verdict. |
| `message` | string | Human-readable summary. |
| `suggestion` | string | Deterministic fix suggestion. |

### Diagnostic arrays

`skipped_files[]` contains `{file, reason}` without source content.
`ignored_violations[]` contains `{file, line, import, reason, expires}` so policy
debt remains auditable.

## Stability guarantees

- No timestamps or environment-derived values are included.
- The same repository state and effective dated-exception policy produce
  byte-identical output.
- New optional fields may be added under the same `schema_version`; consumers
  should ignore unknown fields. Removing or renaming a field bumps
  `schema_version`.
- SARIF results include the same line as `physicalLocation.region.startLine`.

## Exit codes (companion to JSON)

`0` success · `1` violations at/above `fail_on` · `2` invalid usage/config ·
`3` parse error · `4` runtime · `5` IO · `6` internal.
