#!/bin/sh
# tests/cli_smoke.sh
# CLI exit-code integration tests for Fence. This is the single allowed shell
# wrapper (the tool itself is 100% Kujo). It drives fence.kujo end-to-end and
# asserts exit codes and a determinism property.
#
# Usage:
#   KUJO=/path/to/kujo sh tests/cli_smoke.sh
# KUJO defaults to `kujo` on PATH.

set -u
KUJO="${KUJO:-kujo}"
ROOT="$(CDPATH= cd "$(dirname "$0")/.." && pwd)"
if [ "${KUJO#/}" = "$KUJO" ] && [ -x "$ROOT/$KUJO" ]; then
  KUJO="$ROOT/$KUJO"
fi
if [ -n "${KUJO_MODULE_PATH:-}" ] && [ "${KUJO_MODULE_PATH#/}" = "$KUJO_MODULE_PATH" ] && [ -d "$ROOT/$KUJO_MODULE_PATH" ]; then
  export KUJO_MODULE_PATH="$ROOT/$KUJO_MODULE_PATH"
elif [ -z "${KUJO_MODULE_PATH:-}" ] && [ -d "$ROOT/../kujo/modules" ]; then
  export KUJO_MODULE_PATH="$ROOT/../kujo/modules"
fi
FENCE="$ROOT/fence.kujo"
PASS=0
FAIL=0

expect_exit() { # <expected> <label> ; command already run, $? captured by caller
  if [ "$1" = "$2" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: $3 (exit $2, expected $1)"; fi
}

run() { "$KUJO" run "$FENCE" -- "$@" >/dev/null 2>&1; echo $?; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 6
mkdir -p src/ui src/database
printf 'export const x = 1\n' > src/database/users.ts
printf 'export const ok = 1\n' > src/ui/Clean.tsx

# init -> 0
expect_exit 0 "$(run init)" "init creates config"
# direct help/version entrypoints -> 0
expect_exit 0 "$(run help)" "help command"
expect_exit 0 "$(run version)" "version command"
expect_exit 0 "$(run --help)" "bare --help"
expect_exit 0 "$(run --version)" "bare --version"
# init again without --force -> 2
expect_exit 2 "$(run init)" "init refuses overwrite"
# init --force -> 0
expect_exit 0 "$(run init --force)" "init --force overwrites"
# validate clean -> 0
expect_exit 0 "$(run validate)" "validate clean config"
# check clean -> 0
expect_exit 0 "$(run check)" "check with no violations"
# graph -> 0
expect_exit 0 "$(run graph --format mermaid)" "graph mermaid"
expect_exit 0 "$(run graph --observed --format json)" "graph observed json"
# doctor -> 0
expect_exit 0 "$(run doctor)" "doctor"
# explain missing file -> 5
expect_exit 5 "$(run explain src/does/not/exist.ts)" "explain missing file"
# unknown command -> 2
expect_exit 2 "$(run frobnicate)" "unknown command"
# unsafe output path -> 5
expect_exit 5 "$(run check --output ../escape.md)" "unsafe output rejected"

# Introduce a real violation (ui -> database) -> check exits 1
printf 'import { users } from "../database/users"\n' > src/ui/Bad.tsx
expect_exit 1 "$(run check)" "check with violation fails"
# fail-on none -> 0 despite violation
expect_exit 0 "$(run check --fail-on none)" "fail-on none does not fail"
# Invalid threshold values are usage errors, not an implicit pass.
expect_exit 2 "$(run check --fail-on bogus)" "invalid fail-on is rejected"
expect_exit 2 "$(run check --fail-on)" "missing fail-on value is rejected"

# Baseline lifecycle
expect_exit 0 "$(run baseline create)" "baseline create"
expect_exit 0 "$(run check --baseline)" "check --baseline suppresses"
printf 'import { y } from "../database/orders"\n' >> src/ui/Bad.tsx
printf 'export const y = 1\n' > src/database/orders.ts
expect_exit 1 "$(run check --baseline)" "check --baseline fails on new violation"
expect_exit 0 "$(run baseline prune)" "baseline prune"
# A syntactically-valid but structurally-invalid baseline must not be accepted.
printf '{"schema_version":1,"tool":"fence","fingerprints":"not-an-array"}\n' > fence-baseline.json
expect_exit 3 "$(run check --baseline)" "invalid baseline schema is rejected"

# Manifest-backed workspace generation in an isolated target.
mkdir -p "$WORK/workspace/apps/web" "$WORK/workspace/packages/core"
printf '{}\n' > "$WORK/workspace/apps/web/package.json"
printf 'name = "core"\n' > "$WORK/workspace/packages/core/kujo.toml"
cd "$WORK/workspace" || exit 6
expect_exit 0 "$(run workspace init)" "workspace init"
expect_exit 0 "$(run validate)" "workspace config validates"

# Resource ceilings and output-root confinement.
rm fence.toml
mkdir -p src/a src/b reports
printf 'export const a = 1\n' > src/a/a.ts
printf 'export const b = 1\n' > src/b/b.ts
printf '%s\n' '{"version":1,"source_roots":["src"],"output_roots":["reports"],"limits":{"max_files":1},"scan":{"include":["src/**/*.ts"]},"zones":{"all":{"paths":["src/**"]}}}' > fence.json
expect_exit 4 "$(run check)" "max-files resource limit"
printf '%s\n' '{"version":1,"source_roots":["src"],"output_roots":["reports"],"scan":{"include":["src/**/*.ts"]},"zones":{"all":{"paths":["src/**"]}}}' > fence.json
expect_exit 5 "$(run check --output outside.json)" "output-root policy rejects sibling"
expect_exit 0 "$(run check --output reports/fence.json)" "output-root policy allows child"
cd "$WORK" || exit 6

# Determinism: json output identical across two runs
A="$("$KUJO" run "$FENCE" -- check --format json 2>/dev/null)"
B="$("$KUJO" run "$FENCE" -- check --format json 2>/dev/null)"
if [ "$A" = "$B" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: json output is deterministic"; fi

# Incremental cache: warm output is identical and a source change invalidates it.
C="$("$KUJO" run "$FENCE" -- check --cache --format json 2>/dev/null)"
D="$("$KUJO" run "$FENCE" -- check --cache --format json 2>/dev/null)"
if [ "$C" = "$D" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: cache warm output is deterministic"; fi
printf 'import { z } from "../database/new-target"\n' >> src/ui/Bad.tsx
printf 'export const z = 1\n' > src/database/new-target.ts
E="$("$KUJO" run "$FENCE" -- check --cache --format json 2>/dev/null)"
if [ "$D" != "$E" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: cache invalidates changed source"; fi

# Governed exception inventory and CI expiry gate.
cat >> fence.toml <<'EOF'

[[ignores]]
from_zone = "ui"
to_zone = "database"
reason = "temporary migration"
expires = "2999-01-01"

[[ignores]]
from_zone = "ui"
to_zone = "database"
reason = "expired migration"
expires = "2000-01-01"
EOF
expect_exit 0 "$(run ignores list --format json)" "ignores list"
expect_exit 1 "$(run ignores check)" "ignores check fails expired"
expect_exit 2 "$(run ignores list --within-days nope)" "ignores rejects non-integer review window"

echo ""
echo "CLI smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
