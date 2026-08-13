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
- `check --cache` adds an opt-in persistent import cache keyed by source SHA-256,
  extractor schema, and parser-adapter fingerprint. A miss always executes the
  source extractor; warm and cold reports are byte-identical.

## Kujo-native benchmark harness

Run the checked-in generator and benchmark without Python:

```bash
kujo run benchmarks/fence_benchmark.kujo -- --files 1600 --shards 1
kujo run benchmarks/fence_benchmark.kujo -- --files 1600 --shards 4
kujo run benchmarks/fence_benchmark.kujo -- --files 10000
```

Measured on the August 12, 2026 development machine after cache and walk
fast-path hardening:

| Requested files | Shards | Traverse | Filter | Analyze | Total scan |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1,600 | 1 | 0.58 s | 12.70 s | 48.12 s | 61.41 s |
| 1,600 | 4 | 0.55 s | 13.05 s | 49.27 s | 62.86 s |
| 10,000 | 1 | 23.87 s | 63.96 s | 302.39 s | 390.23 s |

The harness adds one shared target file, so `files_scanned` is requested files
plus one. Timings are comparative developer-machine evidence, not a universal
service-level guarantee. All runs completed without stack overflow or failure.

The profile now separates directory traversal from glob filtering. At 10,000
files, filtering is 2.7× traversal, so glob evaluation—not filesystem walking—is
the next walk-stage optimization target.

## Parallel-analysis research result

Kujo's current supported process primitive is synchronous: `spawn_process`
waits for completion and there is no native task/future primitive exposed to
Fence. Fence therefore implements deterministic contiguous sharding and merge
semantics without unsafe shell backgrounding, but runs shards sequentially.
Four shards were 2.4% slower at 1,600 files and lost cache reuse across shard
boundaries. A 10,000-file baseline was recorded; a sharded 10,000 run cannot
produce a concurrency win with the current runtime and would only repeat that
known sequential overhead. Native parallel execution remains deferred until
Kujo exposes a supported concurrency primitive.

## Notes for optimizers

If a future change targets throughput (see `docs/ENHANCEMENTS.md`):

- The remaining hot paths are `walk`/`glob_match` (file filtering), first-time
  candidate probes, and import extraction.
- String sorting already uses the native `sort` builtin.
- `normalize_sep` avoids allocation when a path has no backslash.
- Reducing per-import function-call depth (the VM has notable call overhead) is
  likely the biggest lever; an AST/compiled fast path would be the largest.
