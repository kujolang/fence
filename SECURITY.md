# Security Policy

## Design posture

Fence is local-first and minimizes its trust surface by design:

- **Offline core.** Fence itself never makes network calls. Configured parser
  adapters are trusted executables, not network-sandboxed by Fence.
- **Explicit adapter trust boundary.** Config is parsed as data and never
  evaluated. Optional `[parser_adapters]` entries do launch configured argv
  directly, without a shell; treat repositories enabling adapters as trusted
  executable policy and pin/review the adapter installation.
- **No shell interpolation of untrusted input.** Subprocesses are structured
  argv calls for Git and explicitly configured parser adapters. Ref names (`--base`) are
  length-capped, character-restricted, option-safe, and rejected when they use
  ambiguous range/reflog or invalid ref syntax.
- **Path-safe writes.** File output (`init`, `--output`, baselines and cache)
  uses Kujo's `write_file_atomic_beneath` with held directory handles. Absolute
  paths, `~`, `..`, drive/stream paths and `.git` components are rejected.
  Symlink parents (even within the repository) and stable final symlinks are
  rejected. Atomic publication prevents torn output and no-replace publication
  cannot overwrite a competing winner. Confinement is to directory identity,
  not continuous ancestry: an already-open directory can be moved. See the
  [native contract](docs/audits/confined-output-implementation.md).
- **Consistent import identity.** Candidate paths are lexically normalized before
  filesystem lookup and zone matching, including alias and direct imports.
  Literal backslashes in source directory entries fail a full scan instead of
  being silently interpreted as separators. Source symlinks and configured roots
  remain trusted repository layout; Fence is not a filesystem read sandbox.
- **Presentation safety.** Human check/explain fields escape C0/C1 controls;
  Markdown check fields additionally escape markup. JSON/SARIF retain original
  evidence. Treat report contents as untrusted data, never agent instructions.
- **No secret exposure.** Fence does not print file contents (only import lines
  and paths) and does not read or log environment secrets.
- **Optional output confinement.** Enterprises can restrict `--output` to
  configured repo-relative `output_roots`.
- **Resource ceilings.** Optional file, import, and UTF-8 report-byte limits
  reject over-budget checks. Selection and rendering still allocate before their
  respective checks; these settings do not provide a process-memory sandbox.
- **Auditable exceptions.** Structured ignores require a reason and expiry and
  remain visible in machine reports.
- **Confined composition.** `extends` is local-only, depth/cycle limited, and
  rejects traversal, absolute paths, and symlink escapes.
- **Confined cache.** The optional `.fence` cache rejects symlinked-directory
  escapes, including a cache-file symlink, and validates import-record shapes.
  It stores source digests and import records, not complete files. The cache is
  trusted local acceleration data, not authenticated evidence: a writer can forge
  a structurally valid entry. Omit `--cache` for adversary-writable cache state.

## Supported versions

| Version | Supported |
| --- | --- |
| 1.0.x | ✅ |

## Reporting a vulnerability

If you discover a security issue, please report it privately to the maintainer
rather than opening a public issue. Include:

- a description of the issue and its impact,
- steps to reproduce (a minimal `fence.toml` / repo layout if relevant),
- the Fence version (`kujo run fence.kujo -- --version`).

You will receive an acknowledgement and a remediation timeline. Please allow a
reasonable disclosure window before publishing details.
