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
FENCE="$(CDPATH= cd "$(dirname "$0")/.." && pwd)/fence.kujo"
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

# Baseline lifecycle
expect_exit 0 "$(run baseline create)" "baseline create"
expect_exit 0 "$(run check --baseline)" "check --baseline suppresses"
printf 'import { y } from "../database/orders"\n' >> src/ui/Bad.tsx
printf 'export const y = 1\n' > src/database/orders.ts
expect_exit 1 "$(run check --baseline)" "check --baseline fails on new violation"

# Determinism: json output identical across two runs
A="$("$KUJO" run "$FENCE" -- check --format json 2>/dev/null)"
B="$("$KUJO" run "$FENCE" -- check --format json 2>/dev/null)"
if [ "$A" = "$B" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL: json output is deterministic"; fi

echo ""
echo "CLI smoke: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
