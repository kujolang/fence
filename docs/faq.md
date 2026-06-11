# FAQ

### Is Fence really written entirely in Kujo?

Yes. `fence.kujo` plus 29 `src/*.kujo` modules and a Kujo test harness. The only
non-Kujo file that ships is a one-line shell wrapper (`fence.sh`) and the docs.
No Rust, JavaScript, Python, Go, or PHP is used to implement the tool. Those
languages are *scanned targets* only.

### Does Fence need network access or an LLM?

No. Fence is fully local and deterministic. The same repository state always
produces byte-identical output. It never calls a model or a remote service.

### How accurate is import detection?

It is best-effort and line-based — not an AST parser. It reliably handles the
common import forms for Kujo, JS/TS, Python, Rust, PHP, and Go (including
JS comments, re-exports, and parenthesized Python imports). Exotic or generated
syntax may be missed. This is a deliberate v1 tradeoff; the extractors are easy
to replace with AST-based ones later.

### Why are some imports reported as `unknown`?

`unknown` means the import looked internal (relative or aliased) but did not
resolve to a real file, **or** it resolved to a file that no zone claims. How
Fence treats `unknown` is controlled by `unknown_dependency_policy`
(`allow` / `warn` / `deny`).

### Are third-party packages violations?

By default, no — external packages are allowed. Add an `[external]` `deny` list
(or per-zone `external_deny`) to forbid specific packages.

### What's the difference between `cannot_depend_on` and `unknown_dependency_policy`?

`cannot_depend_on` is an explicit deny for a *known* zone (always a violation).
`unknown_dependency_policy` governs targets that are neither explicitly allowed
nor explicitly denied — including unmappable ones.

### How do I adopt Fence on a large repo that already has violations?

Run `baseline create`, commit `fence-baseline.json`, and run
`check --baseline`. Existing violations are suppressed; new ones still fail.
Shrink the baseline over time.

### Can I run Fence from outside the repo?

Yes. Invoke `fence.kujo` by absolute path. Module imports resolve relative to
`fence.kujo`; file scanning uses your current working directory.

### Why a run-mode test harness instead of `kujo test-run`?

Kujo's `test "..." {}` framework cannot see file-level imports or top-level
functions, so it cannot exercise Fence's modules. The harness
(`tests/fence_tests.kujo`) imports the real modules, asserts, and exits non-zero
on failure — which actually tests the implementation code and stays CI-friendly.

### Does `--output` let me write anywhere?

No. Output paths are restricted to the working directory: absolute paths, `~`,
`..`, and drive-letter paths are rejected, and a symlinked parent that would
escape the tree is also rejected.
