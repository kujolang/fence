# CI integration

Fence is built for CI: deterministic output, predictable exit codes, no network,
and machine-readable formats.

## Minimal gate

Fail the build on error-level violations and capture a PR-ready report:

```bash
kujo run fence.kujo -- check --format markdown --output FENCE_REPORT.md --fail-on error
```

Exit `1` means "violations at/above the threshold"; the surrounding job fails
automatically.

## Scope to the pull request

Only scan files changed against the base branch — fast, and focuses review on
the diff:

```bash
kujo run fence.kujo -- check --changed-only --base origin/main --fail-on error
```

`--base` refs are strictly validated (`^[A-Za-z0-9._/~^-]+$`) before being passed
to Git, so untrusted branch names cannot inject shell commands. If the workspace
is not a Git repo, the command fails clearly.

## Adopting on a legacy codebase

Record existing violations once, commit the baseline, and fail only on new ones:

```bash
kujo run fence.kujo -- baseline create
git add fence-baseline.json
# in CI:
kujo run fence.kujo -- check --baseline --fail-on error
```

## Code scanning (SARIF)

Emit SARIF 2.1.0 for code-scanning dashboards:

```bash
kujo run fence.kujo -- check --format sarif --output fence.sarif --fail-on error
```

Upload `fence.sarif` to your platform's code-scanning ingest.

## Quiet mode

For terse logs, print only a one-line status (exit code still reflects result):

```bash
kujo run fence.kujo -- check --quiet --fail-on error
# -> Fence: FAILED - 84 files, 2 violations (2 errors, 0 warnings)
```

## Example GitHub Actions workflow

> The workflow file is YAML configuration, not an implementation language — this
> is allowed alongside the Kujo-only tool. Adjust the Kujo install step to your
> environment (or use a prebuilt Kujo binary/container).

```yaml
name: fence
on: [pull_request]
jobs:
  architecture:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # needed for --changed-only --base
      - name: Install Kujo
        run: |
          # provide the `kujo` binary on PATH (build or download per your setup)
          echo "ensure kujo is on PATH"
      - name: Fence check
        run: |
          kujo run path/to/fence/fence.kujo -- check \
            --changed-only --base origin/${{ github.base_ref }} \
            --format sarif --output fence.sarif --fail-on error
      - name: Upload SARIF
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: fence.sarif
```

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Success, no threshold-failing violations |
| 1 | Violations at or above `fail_on` |
| 2 | Invalid usage or invalid config |
| 3 | Parse/config error |
| 4 | Runtime error |
| 5 | IO failure |
| 6 | Internal failure |
