# Runnable examples

Each architecture has a passing and deliberately failing repository. Run Fence
from inside a directory, pointing back to the repository entrypoint:

```bash
cd examples/cli/passing
kujo run ../../../fence.kujo -- check --summary-only
cd ../failing
kujo run ../../../fence.kujo -- check --summary-only
```

The failing variants are teaching fixtures: fix the import boundary rather than
weakening their `fence.toml`.
