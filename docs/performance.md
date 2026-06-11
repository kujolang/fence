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

## Notes for optimizers

If a future change targets throughput (see `docs/ENHANCEMENTS.md`):

- The hot paths are `walk`/`glob_match` (file filtering) and `analyze_files`
  (per-import `resolve_import` + `match_zone`).
- String sorting already uses the native `sort` builtin.
- `normalize_sep` avoids allocation when a path has no backslash.
- Reducing per-import function-call depth (the VM has notable call overhead) is
  likely the biggest lever; an AST/compiled fast path would be the largest.
