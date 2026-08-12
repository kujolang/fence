# Enterprise adoption

Fence works best as a progressively tightened repository contract owned by the
same people who own the architecture. Keep `fence.toml` and any temporary
`fence-baseline.json` in review like application code.

## 1. Observe

Generate the closest template, tailor its zones, and validate before gating CI:

```bash
kujo run fence.kujo -- init --template monorepo
kujo run fence.kujo -- validate
kujo run fence.kujo -- check --fail-on none --format markdown --output FENCE_REPORT.md
```

Review unknown dependencies before changing `unknown_dependency_policy`. Broad
allow rules make adoption look clean while preserving the drift Fence is meant
to expose.

## 2. Baseline legacy violations

If immediate cleanup is impractical, record the exact current violations:

```bash
kujo run fence.kujo -- baseline create
git add fence.toml fence-baseline.json
kujo run fence.kujo -- check --baseline --fail-on error
```

The baseline suppresses only matching fingerprints. New crossings still fail.

## 3. Gate pull requests

Fetch the base branch with enough history, then scope analysis to the diff:

```bash
git fetch origin main
kujo run fence.kujo -- check --changed-only --base origin/main \
  --baseline --fail-on error --format sarif --output fence.sarif
```

Upload SARIF to the platform's code-scanning service and retain the process exit
code as the authoritative gate. Fence performs no upload or network call.

## 4. Shrink the baseline

Remove a fingerprint whenever its underlying violation is fixed. Periodically
run a full-repository check so renamed and untouched areas remain covered:

```bash
kujo run fence.kujo -- check --baseline --fail-on error
```

## Ownership

- Architecture owners approve zone and policy changes.
- Feature teams fix code crossings; they do not relax policy as a shortcut.
- Platform teams own the CI invocation and SARIF retention.
- Release owners run the full check and verify deterministic output.

For rollout incidents, start with `validate`, then `doctor`, then
`explain <path>`. See [CI integration](ci.md) and
[troubleshooting](troubleshooting.md) for operational details.
