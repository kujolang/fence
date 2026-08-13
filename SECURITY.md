# Security Policy

## Design posture

Fence is local-first and minimizes its trust surface by design:

- **No network access.** Fence never makes network calls.
- **Explicit adapter trust boundary.** Config is parsed as data and never
  evaluated. Optional `[parser_adapters]` entries do launch configured argv
  directly, without a shell; treat repositories enabling adapters as trusted
  executable policy and pin/review the adapter installation.
- **No shell interpolation of untrusted input.** Subprocesses are structured
  argv calls for Git and explicitly configured parser adapters. Ref names (`--base`) are
  length-capped, character-restricted, option-safe, and rejected when they use
  ambiguous range/reflog or invalid ref syntax.
- **Path-safe writes.** File output (`init`, `--output`, `baseline create`) is
  restricted to the working directory: absolute paths, `~`, `..`, and
  drive-letter paths are rejected, and a symlinked parent that would escape the
  tree is rejected via canonical-ancestor resolution.
- **No secret exposure.** Fence does not print file contents (only import lines
  and paths) and does not read or log environment secrets.
- **Optional output confinement.** Enterprises can restrict `--output` to
  configured repo-relative `output_roots`.
- **Resource ceilings.** Optional file, import, and UTF-8 report-byte limits
  bound work on hostile or accidentally huge repositories.
- **Auditable exceptions.** Structured ignores require a reason and expiry and
  remain visible in machine reports.
- **Confined composition.** `extends` is local-only, depth/cycle limited, and
  rejects traversal, absolute paths, and symlink escapes.
- **Confined cache.** The optional `.fence` cache rejects symlinked-directory
  escapes and never stores source content, only source digests and import records.

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
