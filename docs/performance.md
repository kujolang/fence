# Performance

Fence runs on the Kujo VM (interpreted), so throughput is dominated by
per-file interpreter overhead rather than I/O. It is deterministic and has no
network cost, but it is not a compiled binary — plan scope accordingly.

## Measured run

Synthetic repository, ~1,600 TypeScript files across four zones, ~1,600 imports,
on a developer laptop:

| Stage | Time |
| --- | --- |
| Walk + filter (1,602 files) | ~18–22 s |
| Analyze (extract → resolve → zone → rules, 1,608 imports) | ~64–74 s |
| **Total `check`** | **~80–95 s** |

No crashes, stack-overflow, or call-depth limits were hit at this size — the
iterative walk and shallow call chains hold up. Cost scales roughly linearly
with `files × imports`, i.e. ~40–55 ms per file on this machine.

## Guidance

- **Use `--changed-only` in CI.** Scoping to a pull request's changed files keeps
  runs in the sub-second-to-low-seconds range regardless of repo size:

  ```bash
  kujo run fence.kujo -- check --changed-only --base origin/main --fail-on error
  ```

- **Tighten `[scan].include`/`exclude`.** Fewer scanned files means less work;
  exclude generated/vendored trees aggressively.
- **Typical interactive repos** (tens to low hundreds of files) complete in a few
  seconds for a full scan.

## Current optimizations

- Import resolution is memoized per run. Repo-root, alias, and external imports
  share a raw-import cache entry; relative and Rust module imports include the
  importer path in the key so context-dependent resolution stays correct.
- Zone classification is memoized by normalized repository path for both source
  files and resolved targets.
- Both caches are process-local, deterministic, and discarded after each check.

## Kujo-native benchmark harness

Run the checked-in generator and benchmark without Python:

```bash
kujo run benchmarks/fence_benchmark.kujo -- --files 1600
kujo run benchmarks/fence_benchmark.kujo -- --files 10000
```

Measured on the August 12, 2026 development machine after cache and walk
fast-path hardening:

| Requested files | Walk | Analyze | Total scan | Resolution hits/misses | Zone hits/misses |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1,600 | 10.8 s | 30.1 s | 40.8 s | 1,599 / 1 | 1,600 / 1,601 |
| 10,000 | 155.0 s | 292.3 s | 447.3 s | 9,999 / 1 | 10,000 / 10,001 |

The harness adds one shared target file, so `files_scanned` is requested files
plus one. Timings are comparative developer-machine evidence, not a universal
service-level guarantee. Both runs completed without stack overflow or failure.

## Notes for optimizers

If a future change targets throughput (see `docs/ENHANCEMENTS.md`):

- The remaining hot paths are `walk`/`glob_match` (file filtering), first-time
  candidate probes, and import extraction.
- String sorting already uses the native `sort` builtin.
- `normalize_sep` avoids allocation when a path has no backslash.
- Reducing per-import function-call depth (the VM has notable call overhead) is
  likely the biggest lever; an AST/compiled fast path would be the largest.
