# Security Policy

## Design posture

Fence is local-first and minimizes its trust surface by design:

- **No network access.** Fence never makes network calls.
- **No code execution from config.** `fence.toml` is parsed as data only; it is
  never evaluated.
- **No shell interpolation of untrusted input.** The only subprocesses are Git
  commands for `--changed-only` / diagnostics. Ref names (`--base`) are
  length-capped, character-restricted, option-safe, and rejected when they use
  ambiguous range/reflog or invalid ref syntax.
- **Path-safe writes.** File output (`init`, `--output`, `baseline create`) is
  restricted to the working directory: absolute paths, `~`, `..`, and
  drive-letter paths are rejected, and a symlinked parent that would escape the
  tree is rejected via canonical-ancestor resolution.
- **No secret exposure.** Fence does not print file contents (only import lines
  and paths) and does not read or log environment secrets.

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
