# Two-minute demo

This transcript uses Fence's checked-in sample repository. Run it from a fresh
Fence clone; every command is local and deterministic.

```bash
DEMO_DIR=$(mktemp -d)
FENCE_ROOT=$(pwd)
cp -R tests/fixtures/sample/src "$DEMO_DIR"/
cd "$DEMO_DIR"
kujo run "$FENCE_ROOT/fence.kujo" -- init
kujo run "$FENCE_ROOT/fence.kujo" -- check --summary-only
```

The first check exits `1` and reports:

```text
Fence: FAILED - 9 files, 2 violations (2 errors, 0 warnings)
```

The sample deliberately lets UI and domain code reach into the database. Move
the shared user module behind the domain boundary and update both imports:

```bash
mv src/database/users.ts src/domain/users.ts
sed -i.bak 's#../database/users#../domain/users#' src/ui/Login.tsx
sed -i.bak 's#from ..database import users#from .users import users#' src/domain/user.py
rm src/ui/Login.tsx.bak src/domain/user.py.bak
kujo run "$FENCE_ROOT/fence.kujo" -- check --summary-only
```

The architecture is clean without weakening the policy:

```text
Fence: PASSED - 9 files, 0 violations (0 errors, 0 warnings)
```

Use `check --format markdown` for a pull-request report, or `explain <path>`
when a classification is surprising.
